---
domain: implementation-patterns
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: linter
contributing-agents: [linter, implementer, code-reviewer]
---

> このドキュメントは `.claude/meta/references/examples/implementation-patterns.md` の日本語訳です。英語版が原文（Source of Truth）です。

> **読み取り専用リファレンス。** このファイルは ECC Base Template に同梱された作業事例であり、実際のプロジェクトで多くのセッションを重ねた後の knowledge ファイルがどのような状態になるかを示すためのものです。これはあなた自身の knowledge ファイルでは**ありません**。あなた自身の knowledge ファイルは `.claude/learn/knowledge/implementation-patterns.md` に置かれ、エージェントが実際の作業を通じて拡充するまでは空の状態です。エージェントは `.claude/meta/references/examples/` 配下を読んだり参照したり書き込んだりしません — このツリーは人間の読者専用です。設計の意図については [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) を参照してください。

---

## このファイルの読み方

knowledge ファイルの各エントリは 1 つの**コンセプト** — ドメイン内の持続的なトピック — をカバーします。エントリは日付やセッションではなく、コンセプト別に整理されています。すべてのエントリは 1 つ以上のレベルマーカーを持ちます:

| マーカー | 対象読者 | カバーする内容 |
|--------|----------|----------------|
| `[JUNIOR]` | このコンセプトに初めて触れる | 第一原理からの説明; 用語は使用前に導入; 素朴な代替案を挙げて比較 |
| `[MID]` | このスタックに不慣れな有能なエンジニア | 非自明な慣用的応用; 初心者が推測しないことを実践者がすること |
| `[SENIOR]` | 非デフォルトのトレードオフ評価 | プロジェクトが非デフォルトのオプションを選んだ理由; 何を手放したか; いつ見直すか |

1 つのコンセプトエントリが複数のマーカーを持つ場合があります。`[JUNIOR]` と `[MID]` の節は 1 つのエントリ内で順序立てて構築されます; `[SENIOR]` の節はトレードオフに名前を付け、何を手放したかを明示します。`[SENIOR]` マーカーのみを持つエントリは、強制する事態に直面するまで junior 開発者が読み飛ばせる決定を記録します。

**これまでの理解と修正済みのエントリ** は、理解がどのように発展してきたかを示します。これらは自分自身の knowledge ファイルを始める前に読む最も価値あるエントリです — knowledge ベースは静的なスナップショットではなく生きた記録であることを示しています。

---

## 早期リターンとガード節  [JUNIOR]

### 第一原理からの説明  [JUNIOR]

関数がその論理の残りを無関係にする条件に遭遇した場合、残りの論理を条件ブロックでラップするのではなく、即座に返すことができます。このパターンを**早期リターン**または**ガード節**と呼びます。

代替案 — ネストされた条件分岐 — は、条件ごとにメインロジックをより深く押し込みます:

```go
// ネスト: メインロジックが 3 段階のインデントの底にある
if condition1 {
    if condition2 {
        if condition3 {
            // メインロジック、埋もれている
        }
    }
}
```

早期リターンは、条件を満たさない場合に終了することでこの構造をフラット化します:

```go
// 早期リターン: メインロジックがトップレベルに
if !condition1 {
    return err
}
if !condition2 {
    return err
}
if !condition3 {
    return err
}
// メインロジックはここ、トップレベルに
```

読者は事前条件を最初に理解し、ネストされたインデントの追跡という認知的負荷なしにメインロジックを読めます。このパターンは、認可チェックとバリデーションチェックがビジネスロジックより多いことが多いサービスレイヤーで特に価値があります。

### 慣用的な応用  [MID]

Meridian では早期リターンをリントルールとして強制しています。`service/` のすべてのサービスメソッドは事前条件チェックから始まります: 認可、ワークスペースメンバーシップ、リソースの存在確認。すべてのガードを通過して初めて、メソッドはコアのビジネスロジックを実行します。

```go
// service/task.go — Meridian スタイル
func (s *TaskService) AssignTask(ctx context.Context, taskID, userID, callerID uuid.UUID) error {
    // ガード 1: リソースの存在確認
    task, err := s.tasks.Get(ctx, taskID)
    if err != nil {
        return err
    }

    // ガード 2: 呼び出し側の認可チェック
    callerWorkspace, err := s.workspaceForUser(ctx, callerID)
    if err != nil {
        return err
    }
    if task.WorkspaceID != callerWorkspace {
        return &domain.AuthorizationError{Action: "assign", Resource: "task"}
    }

    // ガード 3: アサイニーがワークスペースに存在するか確認
    if err := s.users.VerifyMembership(ctx, callerWorkspace, userID); err != nil {
        return &domain.ValidationError{Field: "assignee_id", Message: "user is not a workspace member"}
    }

    // メインロジック: アサインメントを実行
    if err := s.tasks.AddAssignee(ctx, taskID, userID); err != nil {
        return err
    }

    // 副作用: ベストエフォートの通知
    if err := s.notify.NotifyTaskAssigned(ctx, task); err != nil {
        log.Warn("notification failed", "task_id", taskID)
    }
    return nil
}
```

このパターンは強制可能です: ハンドラがサービスを呼び出してエラーを受け取る場合、サービスのガード節がメインロジックに入る前に境界条件をドメインエラーに変換するため、ハンドラはすでに正しいエラー型（domain.AuthorizationError、domain.ValidationError）を受け取っています。

### トレードオフと制約  [SENIOR]

早期リターンはエラー処理をより可視化する（呼び出し側が各条件を見る）場合と、より不透明にする（呼び出し側がどのエラーが可能かを知るためにすべてのガードをトレースしなければならない）場合があります。Meridian は簡潔さよりも可視性を選びました: 各ガードは 1 行であり、コメントが意図を明確に示しています。トレードオフは若干長いメソッドですが — 長さのみで、認知的複雑さではありません。

1 つのコスト: ガードが欠けている場合、バグが明白になります。Meridian の以前のコードレビューで、6 段階ネストのハンドラにある認可チェックが、ネストの底に位置していたため最初のレビューで見落とされました。早期リターンへの切り替えで、欠けているガードが明白になりました: `AssignTask` にはワークスペースメンバーシップガードがなく、他のすべてのメソッドにはありました。これにより本番前に CRITICAL なアクセスコントロールの脆弱性が発見されました。早期リターンはコードレビュワーのリントチェックリストの助けになります。

### 事例（Meridian）

上記の `AssignTask` メソッドがパターンの実際の動作を示しています。このサービスメソッドを呼び出すハンドラは薄い変換器です:

```go
// handler/task.go
func (h *TaskHandler) AssignTask(c *gin.Context) {
    var req AssignTaskRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, errorResponse(err))
        return
    }
    callerID := c.GetString("user_id") // 認証ミドルウェアから
    if err := h.svc.AssignTask(c.Request.Context(), req.TaskID, req.UserID, callerID); err != nil {
        h.writeError(c, err)
        return
    }
    c.JSON(http.StatusOK, gin.H{"status": "assigned"})
}
```

ハンドラは認可チェックを繰り返しません — サービスがそれを強制し、違反をドメインエラーに変換することを信頼しており、`h.writeError` がそれを HTTP レスポンスに変換します。この関心の分離により、ハンドラはパーミッションシステムをモックすることなくテスト可能になり、サービスは HTTP サーバーなしでテスト可能になります。

### 関連節

- テストがパスしていても、ネストされたハンドラを CRITICAL としてレビュワーがフラグする理由については [review-taste → Authorization Check Visibility](./review-taste.md#authorization-check-visibility) を参照してください。
- ガード節がドメイン型としてエラーを伝播させる方法については [error-handling → Domain Error Type Hierarchy](./error-handling.md#domain-error-type-hierarchy) を参照してください。
- ハンドラレイヤーがサービスのガード節にどのように依存するかについては [architecture → Thin Handler Pattern](./architecture.md#thin-handler-pattern) を参照してください。

### コーチイラストレーション（default vs. hints）

> **説明のみ。** 以下は、このドメインのタスクに対して 2 つのコーチングスタイルがどのように異なるかを示す作業事例です。ライブエージェントのコントラクトの一部ではありません。実際のエージェントの動作は `.claude/skills/learn/coach-styles/` のスタイルファイルによって規定されます。

**シナリオ:** 学習者がタスクをアーカイブするサービスメソッドを書いており、認可チェックを最初に置くべきか、タスクを読み込んだ後の if 文の中でオーナーシップを確認すべきかを尋ねます。

**`default` スタイル** — エージェントが早期リターンを使うようコードをリファクタリングし、パターンを説明し、ガード節スタイルがレビュー可能な理由（レビュワーが関数のトップでのすべての事前条件を見られる）を示します。`## Learning:` トレーラーが早期リターンと Meridian のリント強制を説明します。

**`hints` スタイル** — エージェントがパターン（早期リターン）と配置（ガードが先、メインロジックが後）を特定し、次のメッセージを出力します:

```
## Coach: hint
Step: Reorder the archive logic: 1) check resource exists, 2) check authorization,
3) perform archive, 4) return.
Pattern: Guard clauses / early returns (authorization checks before business logic).
Rationale: Authorization errors must be detected before side effects. Early returns
make these checks reviewable — a reviewer can see all preconditions without tracing nested
blocks.
```

学習者がコードを並べ替えます。次のターンでエージェントはスキャフォールドを書き直すことなくエラーに応答します。

---

## サービスコンストラクタのファンクショナルオプションパターン  [MID]

### 第一原理からの説明  [JUNIOR]

インスタンス間で変わる可能性があるオプションの設定フィールドを持つ型には、2 つの設計アプローチがあります:

1. **Config 構造体**: すべてのオプションを持つ単一の `Config` 構造体を渡す。
2. **ファンクショナルオプション**: それぞれ 1 つのオプションを設定する可変長関数を渡す。

Config 構造体は馴染みがあります: `NewService(cfg ServiceConfig)`。しかし、呼び出し側が 1 つか 2 つのフィールドのみをオーバーライドする必要がある場合、省略したフィールドのセンチネル値も含む構造体全体を構築しなければなりません。さらに悪いことに、構造体に新しいフィールドを追加すると、すべての呼び出しサイトがそれを設定するかどうかを決める必要があります。

ファンクショナルオプションでは、各呼び出しサイトが適用する設定を選択できます:

```go
// ファンクショナルオプションスタイル
s := NewService(repo,
    WithLogger(myLogger),
    WithTimeout(30*time.Second),
)
```

各 `With*` 関数はデフォルト構築後にサービスを変更する `func(s *Service)` です。値を設定する必要のない呼び出しサイトは対応する `With*` 呼び出しを省略します。

### 慣用的な応用  [MID]

Meridian はオプションの可観測性フィールドや動作オーバーライドフィールドを持つサービスコンストラクタにファンクショナルオプションを使用しています。パターンは `service/task.go` に現れます:

```go
// service/task.go
type TaskService struct {
    tasks      domain.TaskRepository
    users      domain.UserRepository
    notify     NotificationService
    logger     Logger
    metricsCollector MetricsCollector
}

// 必須依存関係を持つコンストラクタ
func NewTaskService(tasks domain.TaskRepository, users domain.UserRepository) *TaskService {
    return &TaskService{
        tasks:      tasks,
        users:      users,
        notify:     newDefaultNotifier(), // 適切なデフォルト
        logger:     newNullLogger(),       // デフォルトでは no-op
        metricsCollector: newNullMetrics(), // デフォルトでは no-op
    }
}

// ファンクショナルオプション
func WithLogger(logger Logger) func(*TaskService) {
    return func(s *TaskService) {
        s.logger = logger
    }
}

func WithMetricsCollector(mc MetricsCollector) func(*TaskService) {
    return func(s *TaskService) {
        s.metricsCollector = mc
    }
}

func WithNotificationService(ns NotificationService) func(*TaskService) {
    return func(s *TaskService) {
        s.notify = ns
    }
}

// 使用例: 必須引数 + オプションのファンクショナルオプション
func buildServices(db *sql.DB) (*TaskService, error) {
    taskRepo := repository.NewTaskRepository(db)
    userRepo := repository.NewUserRepository(db)

    return NewTaskService(taskRepo, userRepo,
        WithLogger(globalLogger),
        WithMetricsCollector(prometheus.DefaultRegistry),
    ), nil
}
```

このパターンは関心を分離します: コアの依存関係（リポジトリ）は必須パラメータであり、可観測性フック（ロガー、メトリクス）はオプションです。

### トレードオフと制約  [SENIOR]

各ファンクショナルオプションは呼び出し時にクロージャをアロケートします。スタートアップ時に一度だけ構築されるサービスに対しては、このアロケーションコストは無視できます。毎秒数百万回構築される型（一時的なリクエストオブジェクトなど）に対しては、オーバーヘッドが測定可能になります。

Meridian はファンクショナルオプションをシングルトンまたは長期インスタンスにのみ使用しています: `cmd/server/main.go` のサービス、ミドルウェアファクトリ、リポジトリファクトリ。リクエストスコープの値（HTTP リクエストのコンテキストなど）はアロケーションパターンが異なるため Config 構造体を使用します。

もう一つのコストは、必須オプションがコンパイラによって強制されないことです。必須のリポジトリを渡さない `NewTaskService()` の呼び出しはコンパイルできますが、実行時にパニックするか誤った動作をします。Meridian の規約: フィールドがサービスの機能に必須であれば、それはオプションではなくコンストラクタの名前付きパラメータです。このパターンは真にオプションのフィールドにのみ使用します。

### 事例（Meridian）

```go
// cmd/server/main.go — サービスセットアップ
func main() {
    db, err := sql.Open("postgres", os.Getenv("DATABASE_URL"))
    // ... エラー処理、バリデーション ...

    logger := slog.New(slog.NewJSONHandler(os.Stderr, nil))

    taskService := service.NewTaskService(
        repository.NewTaskRepository(db),
        repository.NewUserRepository(db),
        service.WithLogger(logger),
        service.WithMetricsCollector(prometheus.DefaultRegistry),
    )

    // ... 残りの配線 ...
}
```

サービスはスタートアップ時に完全な可観測性スタックで一度構築されます。一方、テストはオブザーバーなしで構築できます:

```go
// service/task_test.go — 簡略化されたテストセットアップ
func TestArchiveTask(t *testing.T) {
    taskSvc := NewTaskService(mockTaskRepo, mockUserRepo)
    // ロガーとメトリクスは no-op; テストはビジネスロジックに集中

    err := taskSvc.ArchiveTask(ctx, taskID, callerID)
    // assert
}
```

### 関連節

- このパターンが拡張する一般的な Go コンストラクタパターンについては [ecosystem-fluency → Idiomatic Go Constructor Patterns](./ecosystem-fluency.md#idiomatic-go-constructor-patterns) を参照してください。
- no-op デフォルトがテストセットアップをどのように簡略化するかについては [testing-discipline → Test Isolation via Constructor Options](./testing-discipline.md#test-isolation-via-constructor-options) を参照してください。

---

## ドメインレイヤーでの不変性  [MID]

### 第一原理からの説明  [JUNIOR]

**不変性**とは、一度値が生成されると変更できないことを意味します。ミュータブルなコードは値をインプレースで変更します; イミュータブルなコードは変更を適用した新しい値を生成します。

言語レベルの不変性（Rust、Haskell）を持つ言語ではコンパイラがそれを強制します。Go にはそのような強制がありません — 構造体へのポインタを持つコードはどれでも構造体のフィールドを変更できます。Meridian はドメインレイヤーで規約によって不変性を強制しています: ドメイン型はセッターを公開せず、ミューテーション（必要な場合）はオリジナルを変更するのではなく新しいインスタンスを返します。

これは言語機能ではなく規律の選択です。利点は推論しやすさです: 2 つの異なるサービスメソッドに渡されたドメイン値は、一方によって変更されても他方に影響しません。コストは明示的にコピーを生成する必要があることです。

### 慣用的な応用  [MID]

Meridian の `domain/task.go` のドメイン型はプライベートフィールドと、バリデーションしてイミュータブルなインスタンスを返すコンストラクタを持ちます:

```go
// domain/task.go — イミュータブルなドメイン型
package domain

type Task struct {
    id          uuid.UUID
    workspaceID uuid.UUID
    title       string
    assigneeID  *uuid.UUID
    status      TaskStatus
    createdAt   time.Time
    archivedAt  *time.Time
}

// コンストラクタ: Task を生成する唯一の方法
func NewTask(id, workspaceID uuid.UUID, title string) (Task, error) {
    if title == "" {
        return Task{}, &ValidationError{Field: "title", Message: "title is required"}
    }
    if len(title) > 255 {
        return Task{}, &ValidationError{Field: "title", Message: "title must be <= 255 chars"}
    }
    return Task{
        id:          id,
        workspaceID: workspaceID,
        title:       title,
        status:      TaskStatusActive,
        createdAt:   time.Now(),
    }, nil
}

// アクセサ: 読み取り専用
func (t Task) ID() uuid.UUID       { return t.id }
func (t Task) WorkspaceID() uuid.UUID { return t.workspaceID }
func (t Task) Title() string       { return t.title }
func (t Task) Status() TaskStatus  { return t.status }
func (t Task) IsArchived() bool    { return t.archivedAt != nil }

// セッターなし。ミューテーションは新しい Task を返す:
func (t Task) Archive() (Task, error) {
    if t.archivedAt != nil {
        return Task{}, &ValidationError{Field: "status", Message: "task is already archived"}
    }
    archived := t
    now := time.Now()
    archived.archivedAt = &now
    return archived, nil
}

func (t Task) Reassign(to *uuid.UUID) (Task, error) {
    if to != nil && *to == *t.assigneeID {
        return Task{}, &ValidationError{Field: "assignee_id", Message: "no change"}
    }
    updated := t
    updated.assigneeID = to
    return updated, nil
}
```

リポジトリレイヤーはデータベースからタスクを受け取り `NewTask` を使ってドメインインスタンスを構築します。サービスレイヤーはリポジトリからタスクを受け取り、`Archive()` や `Reassign()` などのミューテーションメソッドを呼び出します。各ミューテーションは新しいインスタンスを返します。サービスはミュータブルなインスタンスをリポジトリに永続化します。

### トレードオフと制約  [SENIOR]

Go の言語レベルの不変性強制がないことは、この規律がコンパイラではなくコードレビューによって維持されることを意味します。不注意なエンジニアが `SetTitle(title string)` メソッドを追加してコントラクトを破る可能性があります。Meridian のリンターは、ドメイン型のメソッドで `*Task` 型のレシーバーを取りフィールドを変更するものをフラグします（チェックは `receiverMutatesField` であり、フロントエンドのドメイン型にはカスタム ESLint ルールとして、バックエンドには golangci-lint プラグインとして実装されています）。

もう一つのコストは API の摩擦です: 呼び出し側はミューテーションが新しいインスタンスを返すことを知っている必要があります。この認識がなければ、呼び出し側は次のように書くかもしれません:

```go
// 誤り: ミューテーションの結果が破棄される
task.Archive()
// task は変更されていない; Archive() は新しいインスタンスを返した
```

代わりに:

```go
// 正解: ミュータブルなインスタンスを代入する
task, err := task.Archive()
```

Meridian のドキュメントと事例はこのパターンを強調しています。これに違反するテストは、code-reviewer によって HIGH（ドメイン API の誤解）としてフラグされます。

### 事例（Meridian）

`service/task.go` でタスクをアーカイブする場合:

```go
func (s *TaskService) ArchiveTask(ctx context.Context, taskID uuid.UUID, callerID uuid.UUID) error {
    // イミュータブルなタスクを取得
    task, err := s.tasks.Get(ctx, taskID)
    if err != nil {
        return err
    }

    // 認可チェック
    if task.WorkspaceID != s.getMemberWorkspace(callerID) {
        return &domain.AuthorizationError{Action: "archive", Resource: "task"}
    }

    // ミューテーション: 新しい Task を返し、オリジナルを変更しない
    archivedTask, err := task.Archive()
    if err != nil {
        return err
    }

    // ミュータブルなインスタンスを永続化
    if err := s.tasks.Update(ctx, archivedTask.ID(), archivedTask); err != nil {
        return err
    }

    return nil
}
```

リポジトリから取得したタスクはイミュータブルです。ミューテーションは新しいタスクインスタンスを生成します。新しいインスタンスが永続化されます。永続化が失敗した場合、オリジナルのタスクは変更されておらず、再試行またはログ記録が可能です。

### 関連節

- 永続化レイヤーで不変性がモデル化される方法については [data-modeling → Immutability Contracts](./data-modeling.md#immutability-contracts) を参照してください。
- 不変性がテストセットアップをどのように簡略化するかについては [testing-discipline → Isolation via Copy Semantics](./testing-discipline.md#isolation-via-copy-semantics) を参照してください。

---

## コメントポリシー: 「何を」ではなく「なぜを」  [JUNIOR]

### 第一原理からの説明  [JUNIOR]

コードコメントは構文ではなく意図を説明します。良いコメントは「なぜこのようになっているのか?」に答えます。悪いコメントはコードが何をするかを語ります — コード自体がすでにより正確に述べていることを。

```go
// 悪い例: コメントがコードを言い直している
var count int
// count はカウンター
count++  // count をインクリメント

// 良い例: コメントが決定を説明している
var count int
// count は再試行回数を追跡する; 無限ループを避けるため 3 で上限を設ける
count++
```

悪いコメントはノイズです。Go を理解している読者はすでに `count++` がインクリメントすることを知っています。良いコメントは読者が持つかもしれない疑問に答えます: 「なぜここにカウンターがあるのか?」

### 慣用的な応用  [MID]

Meridian は 1 つの例外に従っています: **エクスポートされたパブリック関数と型には godoc コメントが必須** （Go のドキュメントフォーマット）。godoc コメントは機械可読であり生成されたドキュメントに表示されます。これらはオプションではありません。

```go
// TaskService はタスク操作を管理し認可を強制します。
// タスク関連のビジネスロジックのアプリケーションのサービスレイヤーです。
type TaskService struct { ... }

// ArchiveTask は呼び出し側が認可されている場合にタスクをアーカイブ済みとしてマークします。
// 呼び出し側がワークスペースメンバーでない場合は AuthorizationError を返します。
// タスクがすでにアーカイブ済みの場合は ValidationError を返します。
func (s *TaskService) ArchiveTask(ctx context.Context, taskID, callerID uuid.UUID) error { ... }
```

godoc コメントはコントラクトを説明します: 関数が何をするか、どのエラーを返す可能性があるか、呼び出し側が知っておくべきこと。これらはパブリック API のドキュメントです。

エクスポートされていない（プライベートな）関数とローカル変数については、コメントが非自明な決定の「なぜ」を説明します。コメントなしでは不明瞭なコードは、コメントを追加するのではなく変数の名前を変えるか関数を抽出するシグナルであることが多いです。

```go
// 悪い例: コードが不明瞭なためコメントが必要
if days > 30 {
    // 古いログを削除
    deleteOldLogs()
}

// 良い例: 変数名と関数名が自己文書化している
if daysOld > 30 {
    deleteLogsOlderThan(30 * time.Hour * 24)
}

// 良い例: 「なぜ」コメントが必要な場合はビジネスルールを説明する
// 90 日間更新されていないタスクは保持ポリシーに従って自動アーカイブされる。
// https://internal.meridian.app/docs/data-retention を参照
if daysUnmodified > 90 {
    archiveTasksSilently(workspace.ID)
}
```

### トレードオフと制約  [SENIOR]

「何をではなくなぜを」ルールには規律が必要です。コードが不明瞭な場合、リファクタリングするのではなくコメントを追加したくなります。Meridian の code-reviewer はコードを語るコメントを MEDIUM としてフラグします（「代わりに関数または変数の名前を変えてください」）。時間をかけて、このプレッシャーがより良い命名を促進します。

コストは、junior 開発者が読者はコードを理解しているとして、コメントを付けすぎない場合があることです。godoc コメントは必須です; 「なぜ」コメントは決定が非自明な場合に推奨されます。この区別には判断力が必要です。

### 事例（Meridian）

`service/task.go` から:

```go
// TaskService.resolveConflict は重複したタスクのアサインメントを削除します。
// これは、アサインメントがまだ保留中の間にタスクが再アサインされた場合に呼ばれ、
// 高負荷期間に発生するレースコンディションです。
func (s *TaskService) resolveConflict(ctx context.Context, taskID, userID uuid.UUID) error {
    // 競合確認のために現在のアサインメントを取得
    assignments, err := s.tasks.ListAssignees(ctx, taskID)
    if err != nil {
        return err
    }

    // ユーザーがすでにアサインされている場合は早期リターン（解決する競合なし）
    for _, a := range assignments {
        if a.UserID == userID {
            return nil
        }
    }

    // 同一ユーザーへの複数のアサインメントは、どちらかが永続化する前に 2 つの並行
    // リクエストが両方とも存在確認を通過した場合にのみ発生する。重複を削除する。
    return s.tasks.RemoveDuplicateAssignments(ctx, taskID, userID)
}
```

godoc コメント（最初の段落）はメソッドが何をし、なぜ存在するかを説明します。インラインコメントは非自明な制御フローを説明します。重複削除の上のコメントはビジネスコンテキスト（ロジックのバグではなくレースコンディション）を説明します。

### 関連節

- レビュワーがコメントの品質をどのように評価するかについては [review-taste → Comment Clarity vs. Code Clarity](./review-taste.md#comment-clarity-vs-code-clarity) を参照してください。
- Meridian が従う Go 固有の規約については [ecosystem-fluency → Godoc and Documentation Comments](./ecosystem-fluency.md#godoc-and-documentation-comments) を参照してください。

---

## 命名パターン: レシーバー、ブーリアン、頭字語  [MID]

### 第一原理からの説明  [JUNIOR]

命名はドキュメントの一形態です。よく選ばれた名前は、コメントなしに値が何を表すかを読者に伝えます。不適切に選ばれた名前は混乱を生み、明確化するためのコメントが必要になります。

関数のシグネチャでは、一貫した命名がコードを予測可能にします:

```go
// 一貫したレシーバー名でパターンが学習しやすくなる
func (t Task) Archive() (Task, error)
func (s TaskService) ArchiveTask(...) error
func (u User) IsActive() bool

// ブーリアン名は true/false を明確に示す述語を使う
func (t Task) IsArchived() bool
func (s Task) HasDueDate() bool
func (u User) CanEditWorkspace(wid uuid.UUID) bool
```

### 慣用的な応用  [MID]

Meridian はコードベース全体で 3 つの命名規約を一貫して適用しています:

**レシーバー名:** 型名から派生した 1 文字。
- Task メソッドには `(t *Task)`
- Service メソッドには `(s *Service)`
- User メソッドには `(u *User)`
- Handler メソッドには `(h *Handler)`

これは Go の規約であり `go fmt` によって強制されます。1 文字のレシーバーは簡潔ですが、型はメソッドのシグネチャに表示されるため曖昧ではありません。

**ブーリアンの述語:** 常に `is`、`has`、`can`、または `should` で始まる。
- `IsArchived()` — 状態
- `HasAssignee()` — 存在
- `CanEditWorkspace(wid)` — 能力
- `ShouldNotify()` — 条件ロジック

ブーリアンを `Active` や `Complete`（状態が不明確）、または `Check`（命令的なアクションのように聞こえ、クエリではない）と命名することは避けます。

**頭字語:** Meridian は一般的な頭字語に対して反慣習的なケーシングを使用しています。
- `Url` ではなく `URL`（すべて大文字の頭字語、HTTP 仕様と一般的な英語に合わせて）
- `Id` ではなく `ID`
- `Uuid` ではなく `UUID`
- `Http` ではなく `HTTP`

これは Go の通常の規約（`HTTPHandler` は慣用的な Go では `HttpHandler` になる）を破りますが、Meridian は業界ドキュメントが大文字の頭字語を使用するため、Go のリントルールとの一貫性よりも業界との一貫性を選びました。（Meridian のリンターは頭字語のケーシングチェックを抑制するよう設定されています。）

### トレードオフと制約  [SENIOR]

レシーバー名は機能的な影響のないスタイルの選択です。`(t Task)` vs. `(task Task)` は規約の問題です。Go のコミュニティは簡潔さのために 1 文字のレシーバーを選びました; Meridian はこの選択を Go のイディオムから継承しました。

ブーリアンの命名規約は冗長に感じる場合があります: `if user.CanEditWorkspace(...)` は `if user.CanEdit(...)` より長いですが、完全な名前はパーミッションのスコープを明確にします。コストは冗長さ; 利点は明確なパーミッションチェックです。

頭字語のケーシングは Go の `go vet` ルール（`ST1005: "URL" の不正なキャピタライゼーション`）を破ります。Meridian のリンターはこのチェックをグローバルに無効にしています。Meridian のコードベースを引き継ぐ新しい開発者は、`URL` が意図的なものであり、スタイルの違反ではないことを学ばなければなりません。

### 事例（Meridian）

`domain/task.go` から:

```go
type Task struct {
    id          uuid.UUID
    url         string  // Meridian は HTTP 仕様に合わせて Url ではなく URL を使用
    status      TaskStatus
    archivedAt  *time.Time
}

// レシーバー: 型（Task）から派生した 1 文字（t）
func (t Task) ID() uuid.UUID { return t.id }

// ブーリアンの述語: is/has/can
func (t Task) IsArchived() bool { return t.archivedAt != nil }
func (t Task) HasDueDate() bool { return t.dueDate != nil }

// 能力チェック: can/should パターン
func (t Task) CanBeAssignedBy(user User) bool {
    return !t.IsArchived() && user.CanEditWorkspace(t.workspaceID)
}
```

`handler/task.go` から:

```go
// レシーバー: 型（TaskHandler）から派生した 1 文字（h）
type TaskHandler struct { ... }

func (h *TaskHandler) GetTask(c *gin.Context) { ... }
func (h *TaskHandler) CreateTask(c *gin.Context) { ... }

// エラー変数は常に 'err' と命名。'e' や 'error_value' は使わない
if err := h.svc.GetTask(...); err != nil {
    return err
}
```

### 関連節

- Meridian の選択が Go のより広いイディオムにどのように関係するかについては [ecosystem-fluency → Go Naming Conventions](./ecosystem-fluency.md#go-naming-conventions) を参照してください。
- コードレビューでレビュワーが名前をどのように評価するかについては [review-taste → Clarity via Naming](./review-taste.md#clarity-via-naming) を参照してください。

---

## これまでの理解: 深いネストが標準だった  [JUNIOR]

### これまでの理解 (改訂 2026-03-15)

Meridian の開発の最初の月（2026-03-01 以前）、サービスメソッドは認可チェック、入力バリデーション、そしてビジネスロジックの実行に深くネストされた条件ブロックを使用していました:

```go
// 元のスタイル: 深くネストされた条件分岐
func (s *TaskService) CreateTask(ctx context.Context, req CreateTaskRequest, callerID uuid.UUID) (Task, error) {
    if req.Title != "" {
        if len(req.Title) <= 255 {
            workspace, err := s.getWorkspace(callerID)
            if err == nil {
                task, err := s.tasks.Create(ctx, workspace.ID, req.Title)
                if err == nil {
                    return task, nil
                } else {
                    return Task{}, err
                }
            } else {
                return Task{}, fmt.Errorf("workspace error: %w", err)
            }
        } else {
            return Task{}, &ValidationError{Field: "title", Message: "title too long"}
        }
    } else {
        return Task{}, &ValidationError{Field: "title", Message: "title is required"}
    }
}
```

このスタイルは機能し、メソッドは正しく動作していました。しかし、3 月初旬のセキュリティコードレビューで、類似のメソッドにクリティカルなアクセスコントロールのバグが発見されました:

```go
// 元のネストされたコードのセキュリティ問題
func (s *TaskService) DeleteTask(ctx context.Context, taskID uuid.UUID, callerID uuid.UUID) error {
    task, err := s.tasks.Get(ctx, taskID)
    if err == nil {
        if task.Status != Archived {
            // 深くネスト: 認可チェックが 3 段階下にある
            if s.isOwner(task, callerID) {
                return s.tasks.Delete(ctx, taskID)
            } else {
                return ErrUnauthorized
            }
        } else {
            return ErrAlreadyArchived
        }
    } else {
        return ErrNotFound
    }
}
```

レビュワーは最初のパスで認可チェックを見逃しました。それはリソース存在確認とステータスチェックの下、6 段階の深さにネストされていたためです。このバグにより、ユーザーが別のワークスペースに属するタスクを削除できる可能性がありました。

**修正後の理解:**

早期リターン（ガード節）はこの構造をフラット化し、認可チェックを関数のエントリポイントで可視にします。レビュワーが最初に見る場所です。修正されたスタイルはすべてのガードをトップに置きます:

```go
// 修正されたスタイル: 早期リターン、ガードがトップに
func (s *TaskService) DeleteTask(ctx context.Context, taskID uuid.UUID, callerID uuid.UUID) error {
    task, err := s.tasks.Get(ctx, taskID)
    if err != nil {
        return err
    }
    if task.Status == Archived {
        return &domain.ValidationError{Field: "status", Message: "archived tasks cannot be deleted"}
    }
    if !s.isOwner(task, callerID) {
        return &domain.AuthorizationError{Action: "delete", Resource: "task"}
    }

    // メインロジック: 今はすべてのガードの後でトップレベルに
    return s.tasks.Delete(ctx, taskID)
}
```

認可チェックはリソース存在確認の直後に可視になりました — レビュワーが最初にスキャンするレベルです。これはスタイルの好みではなくセキュリティパターンです。インシデント後、Meridian のリンターはサービスメソッドで早期リターンを強制するよう更新され、code-reviewer は認可ガードが 1 段階より深くネストされていないことを確認するようになりました。

### 関連節

- 修正されたパターンとその正当性については [implementation-patterns → Early Returns and Guard Clauses](#early-returns-and-guard-clauses) を参照してください。
- このリファクタリングのセキュリティ上の意味については [security-mindset → Authorization Check Visibility](./security-mindset.md#authorization-check-visibility) を参照してください。
- 完全なインシデントのポストモーテムについては [review-taste → How the Security Review Caught the Bug](./review-taste.md#how-the-security-review-caught-the-bug) を参照してください。

---

## コーチイラストレーション

> **説明のみ。** 以下は、このドメインのタスクに対して 2 つのコーチングスタイルがどのように異なるかを示す作業事例です。ライブエージェントのコントラクトの一部ではありません。実際のエージェントの動作は `.claude/skills/learn/coach-styles/` のスタイルファイルによって規定されます。

**シナリオ:** 学習者がタスクを更新するサービスメソッドを書いており、認可チェックをどこに置くべきかとエラー処理の構造についてエージェントに尋ねます。

**`default` スタイル** — エージェントがガード節をトップに、不変性の規律（ミューテーションは新しいインスタンスを返す）、適切なエラー伝播を持つ完全な実装を提供します。このサービスメソッドを呼び出すハンドラは薄い変換器として書かれます。エージェントは早期リターン、不変性、エラー境界の変換を説明する `## Learning:` トレーラーを追加します。

**`hints` スタイル** — エージェントがメソッドのシグネチャと最初のガード節（リソース存在確認）をスキャフォールドし、次のメッセージを出力します:

```
## Coach: hint
Step 1: Add authorization guard (check caller is workspace member and task owner).
Step 2: Call the mutation method on the task (Task.Update returns a new Task).
Step 3: Persist the mutated task via repository.
Pattern: Guard clauses (early returns); immutability (mutations return new instances).
Rationale: Guards at the top are reviewable — no buried authorization checks. Immutability
prevents the service from leaking mutable state to callers; mutations are explicit.
```

学習者が認可ガードを記入し、ミューテーションメソッドを呼び出し、エラーを処理します。次のターンでエージェントはスキャフォールドを書き直すことなくエラーに応答します。
