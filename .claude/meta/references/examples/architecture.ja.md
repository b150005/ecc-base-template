> このドキュメントは `.claude/meta/references/examples/architecture.md` の日本語訳です。英語版が原文（Source of Truth）です。

---
domain: architecture
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: architect
---

> **読み取り専用リファレンス。** このファイルは ECC Base Template に同梱されたサンプルです。実際のプロジェクト上で多くのセッションを重ねた後の、ポピュレートされたナレッジファイルの見た目を示すために提供されています。**あなた自身のナレッジファイルではありません。** あなたのナレッジファイルは `.claude/learn/knowledge/architecture.md` に置かれ、エージェントが実際の作業の中で拡充するまでは空の状態で始まります。エージェントは `.claude/meta/references/examples/` 配下を読んだり引用したり書き込んだりしません — このツリーは人間の読者専用です。設計根拠については [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) を参照してください。

---

## このファイルの読み方

各セクションのレベルマーカーは、その想定読者を示します。
- `[JUNIOR]` — 第一原理からの説明。事前知識なしを前提とします
- `[MID]` — このスタックにおける自明でない慣用的な適用方法
- `[SENIOR]` — 非デフォルトのトレードオフの評価。何を諦めたかを明示します

---

## Hexagonal Split  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

レイヤードアーキテクチャはシステムを水平な層に分割し、各層は自分の下の層だけを呼び出すことを許可します。目的はビジネスロジックをインフラストラクチャの関心事から隔離することです。そうすることで、ビジネスロジックを実行中のデータベース、HTTP サーバー、外部 API なしにテストできます。

ヘキサゴナルアーキテクチャ（ポートとアダプターとも呼ばれます）は、語彙によってこの隔離を明示的にします。**ドメイン**（純粋なビジネスロジック）が中心に置かれます。**ポート**はドメインが必要とするものを表現するために定義するインターフェースです — 「ID でタスクを見つけられるもの」「通知を送信できるもの」。**アダプター**はそれらのポートを実際のインフラストラクチャに接続する具体的な実装です — タスク検索ポートの PostgreSQL 実装、通知ポートの Slack 実装。

この分離の帰結として、アダプターは交換可能です。通知システムが Slack からメールに変わっても、変更されるのは通知アダプターだけです。ドメインロジック、サービス層、ハンドラー層には触れません。

### Idiomatic Variation  [MID]

Meridian は教科書的な厳格なヘキサゴナルアーキテクチャを実装していません。チームは、その利点を儀式なしに享受できる実用的な 3 層分割を使っています。

```
cmd/
  server/
    main.go               # wiring: instantiate repos, services, handlers, run Gin

internal/
  handler/                # HTTP layer: decode request → call service → encode response
    task.go
    webhook.go

  service/                # Business logic: orchestrate domain rules, call repositories
    task.go
    notification.go

  repository/             # Persistence layer: SQL queries, Redis calls
    task.go
    idempotency.go

  domain/                 # Pure types and error definitions — no imports from other layers
    task.go
    errors.go
```

依存の方向は厳格です。`handler` は `service` をインポートし、`service` は（`domain` で定義された）リポジトリインターフェースをインポートし、具体的なリポジトリ実装は `domain` をインポートします。`domain` は他の内部パッケージを一切インポートしません。これにより循環が防がれ、ドメインをインフラストラクチャなしにテスト可能に保ちます。

Go では、リポジトリインターフェースはサービスが使う側 — `service` パッケージまたは `domain` パッケージ — で定義されます。`repository` パッケージではありません。これが「インターフェースを受け取る」慣用句です。呼び出し側が必要なインターフェースを定義します。

### Trade-offs and Constraints  [SENIOR]

3 層構造は Meridian の現在の規模（バックエンドサービス 1 つ、ドメインエンティティ約 15 個）ではよく機能します。複雑さが高まると — 多数のチームが同一サービスで多数の機能を書く — `service` パッケージが調整問題になります。複数のエンジニアが `task.go` と `notification.go` を同時に変更し、マージコンフリクトと関係のない機能間の暗黙の結合が生まれます。

その規模では、ドメインアグリゲートごとにサブディレクトリ（`service/task/`、`service/notification/`）に分割するか、別サービスへの分割が価値を持ちます。1 つのサービスに留まる決断は、Meridian の現段階で意識的に下されました。複数サービスの運用上の複雑さ（別々のデプロイメント、サービス横断トランザクション、分散トレーシング）は、それが解決する調整問題よりも高くつきます。

この決断を見直す基準: 任意のサービスパッケージファイルが 600 行を超え、かつ 2 つを超えるドメインアグリゲートのロジックを含む場合、パッケージ境界が溶解しており分割が遅れているサインです。

### Example (Meridian)

```go
// domain/task.go — pure types, no infrastructure imports
package domain

type Task struct {
    ID          uuid.UUID
    WorkspaceID uuid.UUID
    Title       string
    AssigneeID  *uuid.UUID
    Status      TaskStatus
    CreatedAt   time.Time
    ArchivedAt  *time.Time
}

// TaskRepository is the port — defined in domain, implemented in repository
type TaskRepository interface {
    Create(ctx context.Context, params CreateTaskParams) (Task, error)
    Get(ctx context.Context, id uuid.UUID) (Task, error)
    List(ctx context.Context, params ListParams) ([]Task, error)
    Archive(ctx context.Context, id uuid.UUID) (Task, error)
}
```

```go
// service/task.go — imports domain types and interfaces, not repository package
package service

type TaskService struct {
    tasks  domain.TaskRepository  // interface from domain package
    notify NotificationService    // interface from this package
}
```

`TaskService` は具体的な型である `repository.TaskRepository` を決してインポートしません。インターフェースだけを知っています。テストでは、`domain.TaskRepository` を実装するモックが注入されます。

### Related Sections

- [api-design → Resource Hierarchy](./api-design.md#resource-hierarchy-tasks-and-assignments) — このレイヤー構造が HTTP ルーティング設計にどう対応するか。
- [error-handling → Domain Error Type Hierarchy](./error-handling.md#domain-error-type-hierarchy) — エラーがこれらの層をどのように伝播するか。

### Coach Illustration (default vs. hints)

> **例示目的のみ。** ライブエージェントの契約の一部ではありません。`.claude/skills/learn/coach-styles/` が定義します。

**シナリオ:** 学習者が Meridian に新しい「マイルストーン」機能を追加しており、マイルストーン集計ロジックをハンドラー、サービス、リポジトリのどこに置くか尋ねます。

**`default` スタイル** — エージェントは 3 層ルール（ビジネスロジックはサービスに、永続化はリポジトリに、変換はハンドラーに）を説明し、`MilestoneService` 構造体とインターフェースを書き、集計ロジックをサービスに置き、ハンドラーがそれをどう呼ぶかを示します。`## Learning:` トレーラーでヘキサゴナル分割の根拠を説明します。

**`hints` スタイル** — エージェントは層（サービス）に名前を付け、パターン（Thin Handler + Fat Service）に名前を付け、ヒントを出力します。学習者が `MilestoneService` のボディを書きます。

---

## Repository Pattern  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

**リポジトリパターン**は、各ドメインアグリゲートのすべてのデータベースアクセスを 1 つのインターフェースの背後に整理する方法です。ビジネスロジック（サービス層）は SQL クエリを書きません。リポジトリのメソッドを呼び出します: `tasks.Create(...)`、`tasks.Get(id)`、`tasks.Archive(id)`。リポジトリはそれらの呼び出しを SQL に変換し、結果をドメイン型にデシリアライズして、サービスに返します。

利点は隔離です。サービスはデータベースから独立しています。背後のストアが PostgreSQL か、テストダブルか、インメモリマップかを知りません。サービスのテスト時にはモックリポジトリが注入されます。リポジトリのテスト時には実データベースが注入されます。この 2 つのテスト層は独立しています。

コストは間接性です。すべてのデータベース操作がリポジトリインターフェースのメソッドを必要とします。小さなプロジェクトでは、これは儀式のように感じられます。同じテーブルが 10 の異なるサービスメソッドからアクセスされるプロジェクトでは、リポジトリがテーブルの構造を知っている唯一の場所です — スキーマの変更は 10 か所に散らばった SQL 文字列ではなく 1 つのファイルの変更です。

### Idiomatic Variation  [MID]

Meridian はデータベーステーブルグループごとに 1 つのリポジトリを実装しています。`TaskRepository` インターフェースは `tasks` テーブルと `task_assignments` テーブルを所有します（アサインメントは独立したライフサイクルを持たないため）。`WorkspaceRepository` は `workspaces` テーブルと `workspace_members` テーブルを所有します。

インターフェースは `domain/` で定義されています:

```go
// domain/repository.go
type TaskRepository interface {
    Create(ctx context.Context, params CreateTaskParams) (Task, error)
    Get(ctx context.Context, id uuid.UUID) (Task, error)
    List(ctx context.Context, params ListParams) ([]Task, Pagination, error)
    Update(ctx context.Context, id uuid.UUID, params UpdateTaskParams) (Task, error)
    Archive(ctx context.Context, id uuid.UUID) (Task, error)
    ListAssignees(ctx context.Context, taskID uuid.UUID) ([]User, error)
    AddAssignee(ctx context.Context, taskID, userID uuid.UUID) error
    RemoveAssignee(ctx context.Context, taskID, userID uuid.UUID) error
}
```

`repository/task.go` の具体的な実装は `*sql.DB` を保持し、すべてのメソッドを SQL で実装します。インターフェースは SQL を持ちません — SQL に関するコメントさえありません。

### Trade-offs and Constraints  [SENIOR]

リポジトリインターフェースはサービスがより多くのアクセスパターンを必要とするにつれて成長します。時間が経つと、15 のメソッドを持つ `TaskRepository` は神インターフェースになります。モックを注入するすべてのテストが、そのテストが 1 つしか実行しなくても 15 のメソッドすべてを実装しなければなりません。Meridian はまだこの限界に達していませんが（インターフェースは 8 メソッド）、達したときの対応は分割です。読み取り専用操作には `TaskReadRepository`、書き込みには `TaskWriteRepository` を作り、それぞれメソッドを少なくします。読み取り専用サービスロジックのテストは読み取りインターフェースだけを注入します。

もう 1 つのコストは、複雑なクロステーブルクエリ — タスク、アサインメント、ワークスペースメンバーの単一 SQL JOIN での集計 — が 1 つのリポジトリのメソッドにきれいに収まらないことです。Meridian はこれを専用の `ReportRepository` で処理しています。これは単一のドメインアグリゲートに縛られず、レポート目的のみのクエリオブジェクトです。

### Example (Meridian)

上記のインターフェース定義を参照してください。PostgreSQL 実装:

```go
// repository/task.go
type postgresTaskRepository struct {
    db *sql.DB
}

func (r *postgresTaskRepository) Get(ctx context.Context, id uuid.UUID) (domain.Task, error) {
    row := r.db.QueryRowContext(ctx, `
        SELECT id, workspace_id, title, assignee_id, status, created_at, archived_at
        FROM tasks
        WHERE id = $1 AND deleted_at IS NULL
    `, id)

    var t domain.Task
    err := row.Scan(&t.ID, &t.WorkspaceID, &t.Title, &t.AssigneeID,
                    &t.Status, &t.CreatedAt, &t.ArchivedAt)
    if errors.Is(err, sql.ErrNoRows) {
        return domain.Task{}, domain.ErrNotFound
    }
    return t, err
}
```

Postgres からドメインへのエラー変換（`sql.ErrNoRows` → `domain.ErrNotFound`）はサービスではなくリポジトリ内で行われます。完全な変換パターンは [error-handling → Boundary Translation](./error-handling.md#boundary-translation-from-postgres-to-domain-errors) を参照してください。

### Related Sections

- [error-handling → Boundary Translation](./error-handling.md#boundary-translation-from-postgres-to-domain-errors) — このリポジトリがデータベースエラーをドメインエラーに変換する方法。
- [persistence-strategy → Query Patterns](./persistence-strategy.md#query-patterns) — リポジトリ実装が従う SQL 規約。

---

## Cross-Cutting Concern: Notifications  [MID]

### First-Principles Explanation  [JUNIOR]

システムの一部の振る舞いは、単一のドメインアグリゲートが所有しているのではなく、多くの操作に参加します。タスクがアサインされたとき、締め切りが過ぎたとき、タスクがアーカイブされたときに通知を送る — これらはすべて、システムの異なる部分からトリガーされる通知の振る舞いです。これが**横断的関心事**です。

素朴な実装は通知呼び出しをいたるところに置きます。`task.go` の Create メソッド、`task.go` の Archive メソッド、`deadline.go` の期限切れチェックに。問題は通知の振る舞いがコードベース全体に散らばることです。通知の仕組みを変更するとき（Slack からメールへの切り替え、レート制限の追加）、すべての呼び出し箇所を見つけて更新する必要があります。

### Idiomatic Variation  [MID]

Meridian は通知を、それを必要とする任意のサービスに注入される `NotificationService` に隔離しています。

```go
// service/notification.go
type NotificationService interface {
    NotifyTaskAssigned(ctx context.Context, task domain.Task, assignee domain.User) error
    NotifyTaskArchived(ctx context.Context, task domain.Task) error
    NotifyDeadlineMissed(ctx context.Context, task domain.Task) error
}
```

`TaskService` はコンストラクタ注入で `NotificationService` を受け取ります。タスクがアサインされると、`TaskService.AssignTask` はリポジトリへの書き込みが成功した後に `notify.NotifyTaskAssigned` を呼び出します。通知サービスが Slack API 呼び出し、リトライ、冪等性キーの保存を処理します。

通知サービスは「ドメイン」の概念ではありません — タスクは通知について知りません。通知はアプリケーション層の関心事です。`NotificationService` を `domain` ではなく `service` パッケージに置くことで、これが明示的になります。これはドメインのルールではなく、アプリケーションの機能です。

### Trade-offs and Constraints  [SENIOR]

サービス層での同期的な通知呼び出しは、Slack API タイムアウトやエラーがタスク操作の失敗や応答の遅延を引き起こすことを意味します。Meridian は現在の規模でこれを受け入れています。タスク操作は高頻度ではなく、Slack クライアントは 1 回のリトライで 3 秒のタイムアウトを持つからです。タスク作成量が大幅に増えたり Slack の信頼性が低下したりすれば、正しい対応は通知配信を非同期にすることです。通知をキュー（`notifications` テーブルまたは Redis リスト）に書き込み、別のワーカーが配信します。インターフェースを変更する必要はありません — 実装だけが変わります。

これが遅延非同期パターンです。インターフェースを同期配信として設計し、規模が許す間は同期的に実装し、強制要因（タイムアウト予算、スループット目標）が来たとき非同期キューの実装に入れ替えます。インターフェースは同じ。実装の詳細が変わります。

### Example (Meridian)

```go
// service/task.go
func (s *TaskService) AssignTask(ctx context.Context, taskID, assigneeID uuid.UUID) error {
    task, err := s.tasks.Get(ctx, taskID)
    if err != nil {
        return err
    }
    if err := s.tasks.AddAssignee(ctx, taskID, assigneeID); err != nil {
        return err
    }
    assignee, err := s.users.Get(ctx, assigneeID)
    if err != nil {
        return err // notification failure does not undo the assignment
    }
    // Notification is best-effort; log but do not propagate the error
    if err := s.notify.NotifyTaskAssigned(ctx, task, assignee); err != nil {
        log.Warn("notification delivery failed", "task_id", taskID, "err", err)
    }
    return nil
}
```

通知エラーはログに記録されますが伝播しません。アサインメントは成功しています。通知はベストエフォートです。これは意図的なプロダクト判断です。Slack への通知失敗は、ユーザーのアサイン操作を失敗させるべきではありません。

### Related Sections

- [error-handling → Error Propagation and Recovery](./error-handling.md#idempotent-retry-on-the-slack-webhook) — 通知リトライの管理方法。
- [testing-discipline → Contract Testing the Slack Integration](./testing-discipline.md#contract-testing-the-slack-integration) — この通知パスのテスト方法。

---

## Prior Understanding: Package Layout by Type  [MID]

### Prior Understanding (revised 2025-12-03)

元のパッケージレイアウト（Meridian の最初のコミット）は、レイヤーではなくアーティファクト型でファイルをグループ化していました。

```
internal/
  models/       # all domain structs
  handlers/     # all HTTP handlers
  services/     # all service logic
  db/           # all database logic
```

この方針が見直されたのは、「型でグループ化」するレイアウトが見えない結合を生み出したからです。`handlers/task.go` と `handlers/webhook.go` はコードを共有していないのに隣り合わせに置かれ、`handlers/task.go` と `services/task.go` は密結合なのに別パッケージに置かれていました。新しいドメインエンティティ（マイルストーン）を追加するには、機能全体が論理的には 1 つの単位であるにもかかわらず、4 つのパッケージを同時に触る必要がありました — パッケージあたり 1 ファイル。

**訂正後の理解:**

現在のレイアウトはエンティティではなくレイヤー（handler、service、repository、domain）でグループ化します。これは Meridian の規模の Go プロジェクトでは標準的です。レイヤーがエンティティではなく自然なコンパイルとインポートの境界です。エンティティベースのグループ化（`internal/tasks/handler.go`、`internal/tasks/service.go`）は、各エンティティのパッケージが他のエンティティパッケージで使う型をエクスポートする必要があるときに適切ですが、その水準の境界の強制はこの規模のプロジェクトには時期尚早で循環インポートのリスクをもたらします。

改訂されたレイアウト（Hexagonal Split セクションに示されているもの）は、最初の機能追加（Slack インテグレーション）が「型でグループ化」のレイアウトでは機能のたびに 4 つのトップレベルパッケージにわたる変更の調整が必要だと明らかになった後に採用されました。

### Related Sections

- [architecture → Hexagonal Split](#hexagonal-split) — 型ベースのレイアウトを置き換えた現在のレイヤーベースのレイアウト。
