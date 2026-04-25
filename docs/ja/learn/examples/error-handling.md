> このドキュメントは `docs/en/learn/examples/error-handling.md` の日本語訳です。英語版が原文（Source of Truth）です。

---
domain: error-handling
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: implementer
contributing-agents: [implementer, code-reviewer]
---

> **読み取り専用リファレンス。** このファイルは ECC Base Template に同梱されたサンプルです。実際のプロジェクト上で多くのセッションを重ねた後の、ポピュレートされたナレッジファイルの見た目を示すために提供されています。**あなた自身のナレッジファイルではありません。** あなたのナレッジファイルは `learn/knowledge/error-handling.md` に置かれ、エージェントが実際の作業の中で拡充するまでは空の状態で始まります。エージェントは `docs/en/learn/examples/` 配下を読んだり引用したり書き込んだりしません — このツリーは人間の読者専用です。設計根拠については [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) を参照してください。

---

## このファイルの読み方

各セクションのレベルマーカーは、その想定読者を示します。
- `[JUNIOR]` — 第一原理からの説明。事前知識なしを前提とします
- `[MID]` — このスタックにおける自明でない慣用的な適用方法
- `[SENIOR]` — 非デフォルトのトレードオフの評価。何を諦めたかを明示します

---

## Domain Error Type Hierarchy  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

アプリケーションはさまざまな種類のエラーに遭遇します。ユーザーが無効なメールアドレスを含むフォームを送信する、データベースクエリが 0 行を返す、外部 API がタイムアウトする、到達するはずのないコードパスに到達してしまう。これらのエラーはそれぞれ、原因が異なり、対象となる読者（ユーザー対オペレーター）が異なり、適切なレスポンスが異なります（ユーザーに入力の修正を促す、404 を返す、リトライする、エンジニアにアラートを上げる）。すべてを同一視すること — すべてを 500 としてログに記録する、または生のエラー文字列をユーザーに返す — はセキュリティとユーザビリティの失敗です。

**ドメインエラー型階層**は、すべてのエラーに名前付きセマンティクスを持つカテゴリを割り当てます。カテゴリが決めるのは以下の事項です。
1. API が返す HTTP ステータスコード。
2. ユーザーに表示されるメッセージ（あれば）。
3. 構造化ログに書き込まれるコンテキスト。
4. 操作を自動的にリトライすべきかどうか。

Go では慣用的なアプローチは `error` インターフェースを実装し `errors.As` で検出できるエラー型を定義することです。エラーコード（文字列型で壊れやすい）とは異なり、型付きエラーはコンパイラがチェックします。ハンドラーが存在しない型を参照すれば、ビルドが失敗します。

### Idiomatic Variation  [MID]

Meridian は `domain/errors.go` に 3 つのトップレベルエラーカテゴリを定義しています。

```go
// domain/errors.go

// NotFoundError is returned when a requested resource does not exist.
type NotFoundError struct {
    Resource string
    ID       string
}

func (e *NotFoundError) Error() string {
    return fmt.Sprintf("%s with id %s not found", e.Resource, e.ID)
}

func (e *NotFoundError) HTTPStatus() int { return http.StatusNotFound }
func (e *NotFoundError) Title() string   { return "Not Found" }
func (e *NotFoundError) Type() string    { return "not-found" }
func (e *NotFoundError) Detail() string  { return e.Error() }

// ValidationError is returned when input fails business-rule validation.
// (Distinct from binding errors, which are handler-layer concerns.)
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation error on field %s: %s", e.Field, e.Message)
}
func (e *ValidationError) HTTPStatus() int { return http.StatusUnprocessableEntity }
func (e *ValidationError) Title() string   { return "Validation Error" }
func (e *ValidationError) Type() string    { return "validation-error" }
func (e *ValidationError) Detail() string  { return e.Message }

// AuthorizationError is returned when the caller lacks permission.
type AuthorizationError struct {
    Action   string
    Resource string
}

func (e *AuthorizationError) Error() string {
    return fmt.Sprintf("not authorized to %s %s", e.Action, e.Resource)
}
func (e *AuthorizationError) HTTPStatus() int { return http.StatusForbidden }
func (e *AuthorizationError) Title() string   { return "Forbidden" }
func (e *AuthorizationError) Type() string    { return "authorization-error" }
func (e *AuthorizationError) Detail() string  {
    // Safe to surface: no internal details exposed
    return fmt.Sprintf("You are not authorized to %s this %s.", e.Action, e.Resource)
}
```

ハンドラー変換層のための `Error` インターフェース:

```go
// domain/errors.go (continued)
type Error interface {
    error
    HTTPStatus() int
    Title() string
    Type() string
    Detail() string
}

// Sentinel for quick equality checks
var ErrNotFound = &NotFoundError{}
```

ハンドラーの `writeError` は `errors.As(err, &domainErr)` を呼び出して、エラーが `domain.Error` かどうかを確認します。そうであれば、エラー自身のメソッドを使って RFC 9457 レスポンスを組み立てます。そうでなければ（ライブラリからの認識できないエラーや予期しない状態）、500 を返してコンテキスト付きの完全なエラーをログに記録します。

### Trade-offs and Constraints  [SENIOR]

型付きエラー階層は、エラーを正しく伝播させるためのすべてのレイヤーでの規律を必要とします。リポジトリメソッドが Postgres の制約違反に遭遇したとき、それを返す前に `ValidationError` または `NotFoundError` に変換しなければなりません — 生の `pq.Error` を返してはいけません。Postgres 固有のエラーがリポジトリ境界を越えて漏れると、ハンドラーはそれを認識する（データベースクライアントライブラリにハンドラーを結合させる）か、500 として扱う（本当のエラーカテゴリを黙って飲み込む）しかありません。

Meridian での強制メカニズムはコードレビューです。エラーを返すリポジトリメソッドはドメインエラー型を返さなければなりません。code-reviewer エージェントは生の `pq.Error` の返却を CRITICAL の発見事項としてフラグを立てます。これは文化的な強制であり、コンパイラによる強制ではありません — Go にはチェック済み例外がありません。代替案（リンタールール）は検討されましたが実装されていません。現在のチームサイズでは手動レビューで十分なほどパターンが単純です。

### Example (Meridian)

サービスメソッドでの使用例:

```go
// service/task.go
func (s *TaskService) GetTask(ctx context.Context, id uuid.UUID, callerID uuid.UUID) (domain.Task, error) {
    task, err := s.tasks.Get(ctx, id)
    if err != nil {
        return domain.Task{}, err // NotFoundError from repository, propagated as-is
    }
    if task.WorkspaceID != s.getMemberWorkspace(callerID) {
        return domain.Task{}, &domain.AuthorizationError{Action: "read", Resource: "task"}
    }
    return task, nil
}
```

### Related Sections

- [api-design → Error Envelope: RFC 9457](./api-design.md#error-envelope-rfc-9457) — これらのドメインエラーが HTTP レスポンスに変換される方法。
- [architecture → Hexagonal Split](./architecture.md#hexagonal-split) — 各エラー型が生成される場所と変換される場所を決めるレイヤー構造。

### Coach Illustration (default vs. hints)

> **例示目的のみ。** ライブエージェントの契約の一部ではありません。`.claude/skills/learn/coach-styles/` が定義します。

**シナリオ:** 学習者が `TaskService.CreateTask` に「タスクタイトルの重複」チェックを追加しており、適切なエラーをどう返すか尋ねます。

**`default` スタイル** — エージェントは重複チェックを追加し、`domain/errors.go` に `ConflictError` 型を作成し、サービスからそれを返し、`writeError` の変換テーブルに追加（HTTP 409）し、テストを書き、型付きエラー対エラーコードに関する `## Learning:` トレーラーを付けます。

**`hints` スタイル** — エージェントは定義すべき型（`domain.Error` を実装する `ConflictError`）に名前を付け、HTTP ステータス（409 Conflict）に名前を付け、`writeError` での変換に関するヒントを出力します。学習者が型を定義し、HTTP 変換を結線します。

---

## Boundary Translation: Postgres to Domain Errors  [MID]

### First-Principles Explanation  [JUNIOR]

永続化層（リポジトリ）は Postgres の言葉を話します。サービス層はドメイン型の言葉を話します。Postgres のクエリが失敗すると、リポジトリは Postgres エラー — 5 文字の SQLSTATE コードと Postgres 固有のメッセージを持つ `*pq.Error` — を受け取ります。リポジトリがそのエラーをそのまま返すと、サービスはそれを解釈するために Postgres について知らなければなりません。その結合はリポジトリパターンの目的を損ないます。サービスは背後のデータベースについて無知であるべきです。

**境界変換**とは、リポジトリがすべての Postgres エラーをインターセプトし、分類し、適切なドメインエラー型を返すことです。サービスはドメイン型のみを受け取り、どのデータベースエンジンがリポジトリの背後にあるかを知らずにそれらを処理できます。

### Idiomatic Variation  [MID]

Meridian のリポジトリ層はヘルパー関数を使って Postgres エラーを変換しています。

```go
// repository/errors.go
import "github.com/lib/pq"

func translatePostgresError(err error) error {
    if err == nil {
        return nil
    }
    if errors.Is(err, sql.ErrNoRows) {
        return domain.ErrNotFound
    }
    var pgErr *pq.Error
    if errors.As(err, &pgErr) {
        switch pgErr.Code {
        case "23505": // unique_violation
            return &domain.ConflictError{
                Field:   pgErr.Constraint,
                Message: "a resource with this value already exists",
            }
        case "23503": // foreign_key_violation
            return &domain.ValidationError{
                Field:   pgErr.Constraint,
                Message: "the referenced resource does not exist",
            }
        case "23514": // check_violation
            return &domain.ValidationError{
                Field:   pgErr.Constraint,
                Message: "the value violates a database constraint",
            }
        }
    }
    return err // unknown error; propagate as-is for 500 treatment
}
```

すべてのリポジトリメソッドはエラーの戻り値を `translatePostgresError(err)` でラップします。Postgres クライアントライブラリは `repository` パッケージの外には現れません。

### Trade-offs and Constraints  [SENIOR]

変換テーブルは最も一般的な SQLSTATE コードをカバーしています。新しいマイグレーションがビジネスロジックによって違反される可能性のある制約を追加するとき、変換テーブルも更新しなければなりません。更新されなければ、制約違反は不明なエラーとして伝播し、呼び出し元は 409 や 422 ではなく 500 を受け取ります。

Meridian のプロセスは次のとおりです。マイグレーションがアプリケーションコードから到達可能な（直接 DB 書き込みだけでなく）新しい制約を追加する場合、PR には対応する `translatePostgresError` の更新が含まれなければなりません。これはコントリビューションガイドにドキュメント化されていますが、自動的には強制されません。code-reviewer エージェントは制約を導入する新しいマイグレーションを確認し、変換の更新がなければ HIGH としてフラグを立てます。

### Example (Meridian)

```go
// repository/task.go
func (r *postgresTaskRepository) Create(ctx context.Context, params domain.CreateTaskParams) (domain.Task, error) {
    var t domain.Task
    err := r.db.QueryRowContext(ctx, `
        INSERT INTO tasks (workspace_id, title, assignee_id, status)
        VALUES ($1, $2, $3, 'active')
        RETURNING id, workspace_id, title, assignee_id, status, created_at
    `, params.WorkspaceID, params.Title, params.AssigneeID).
        Scan(&t.ID, &t.WorkspaceID, &t.Title, &t.AssigneeID, &t.Status, &t.CreatedAt)

    return t, translatePostgresError(err)
}
```

### Related Sections

- [persistence-strategy → Indexing Strategy](./persistence-strategy.md#indexing-strategy) — この変換が処理する `23505` コードを生成するユニーク制約。
- [testing-discipline → The Meridian Test Pyramid](./testing-discipline.md#the-meridian-test-pyramid) — この変換がユニットレベルではなく統合レベルでテストされる理由。

---

## Idempotent Retry on the Slack Webhook  [MID]

### First-Principles Explanation  [JUNIOR]

操作が途中で失敗すると、呼び出し元はリトライするかもしれません。操作に副作用がある場合（データベースへの書き込み、Slack へのメッセージ送信）、リトライは重複した副作用を生み出す可能性があります。冪等性がこれを防ぎます。操作が冪等であるとは、複数回実行しても 1 回実行した場合と同じ効果を持つことです。

Meridian の Slack webhook エンドポイントでは、Slack の配信保証が at-least-once であることが課題です。Slack の配信確認がタイムアウトすると、同じイベントが複数回届くことがあります。Meridian はそれを何回の HTTP リクエストが運んできても、各論理イベントをちょうど 1 回処理しなければなりません。

### Idiomatic Variation  [MID]

冪等性メカニズムは Redis を重複排除ストアとして使います。Slack イベントが届くと、ハンドラーはそのイベントの ID が以前に見られたかどうかを確認します。見られていれば、ハンドラーは処理せずに即座に 200 を返します。見られていなければ、ハンドラーは ID を Redis に記録し（TTL 24 時間）、イベントを処理します。

```go
// service/idempotency.go
type IdempotencyService struct {
    redis *redis.Client
}

func (s *IdempotencyService) CheckAndRecord(ctx context.Context, key string, ttl time.Duration) (alreadySeen bool, err error) {
    // SET NX (only set if key does not exist) — atomic check-and-set
    set, err := s.redis.SetNX(ctx, "idempotency:"+key, "1", ttl).Result()
    if err != nil {
        return false, fmt.Errorf("idempotency check failed: %w", err)
    }
    // set=true means the key was just written (first time seen)
    // set=false means the key already existed (already processed)
    return !set, nil
}
```

`SET NX`（存在しない場合のみセット）Redis コマンドはアトミックです。「確認」と「セット」の間に並行リクエストが割り込む窓はありません。

### Trade-offs and Constraints  [SENIOR]

Redis `SET NX` アプローチは処理が完了する前にキーを記録します。処理後にキーが記録された後（Postgres の書き込み失敗、ダウンストリームサービスの不可用）、キーはまだ Redis にあり、イベントは次の Slack 配信でリトライされません。これは「処理前にマーク」セマンティクスであり、保証された配信よりもちょうど 1 回の配信を優先します。

代替案は「処理後にマーク」セマンティクスです。処理が成功した後にのみキーを記録します。処理が失敗してもキーは記録されず、次のリトライでイベントを再処理します。これは配信を保証しますが、「処理後のマーク」ステップ自体が失敗した場合（Postgres の書き込みは成功し、Redis の書き込みは失敗 — イベントは処理されたが記録されていないため、次の Slack リトライで再び処理される）に重複処理のリスクがあります。

Meridian が「処理前にマーク」を選んだのは、通知イベントがビジネスレベルで冪等だからです。同じタスクアサインメントについて Slack チャンネルに 2 回通知することは迷惑ですが、データの整合性問題ではありません。もしイベントが金融トランザクションであれば、トレードオフは異なる評価になります — 分散トランザクションや 2 フェーズコミットを使った「処理後にマーク」が必要になります。

### Example (Meridian)

完全なハンドラーフローは [api-design → Idempotency Key Handling](./api-design.md#idempotency-key-handling) に示されています。上記の `CheckAndRecord` 関数がそのハンドラーを支える実装です。

### Related Sections

- [api-design → Idempotency Key Handling](./api-design.md#idempotency-key-handling) — この冪等性サービスを呼び出す HTTP ハンドラー。
- [testing-discipline → Contract Testing the Slack Integration](./testing-discipline.md#contract-testing-the-slack-integration) — 重複排除の挙動をテストで検証する方法。

---

## Panic Usage Policy  [SENIOR]

### First-Principles Explanation  [JUNIOR]

Go において `panic` は現在のゴルーチンを即座に停止し、スタックを巻き戻し、ゴルーチンが終了する前に登録された `defer` 関数を実行するメカニズムです。他の言語の未処理例外に相当します。明示的なエラーリターンとは異なり、`panic` は通常のエラー伝播チェーンをバイパスします。

通常のエラー条件（データベースエラー、バリデーション失敗、ネットワークタイムアウト）に `panic` を使うことはアンチパターンです。エラーフローを予測不能にし、エラーログをバイパスし、回復されなければプロセス全体をクラッシュさせる可能性があります。Go のエラーリターン規約はまさにエラーフローを明示的でローカルなものにするために存在します。

### Idiomatic Variation  [MID]

Meridian は `panic` を**真の不変式違反** — ランタイムで回復できず、黙って飲み込むべきでないプログラミングエラーを示す状態 — にのみ使います。

1. **初期化の失敗** — 起動時に必要な依存（データベース接続、Redis クライアント、設定値）をセットアップできない場合、プロセスはパニックします。データベース接続なしにデータベースバックサービスを提供しようとすることは一貫性がありません。プロセスはリクエストの処理を試みるべきではありません。

2. **内部コードでの不可能な型アサーション** — 現在の型システム下で正しいことが証明可能なコードが、コンパイラが検証できない型アサーションを必要とし、そのアサーションの失敗がコードベースの別の場所でコントラクトが違反されたことを示す場合。これらのアサーションには、正しいコードではアサーションが失敗し得ない理由を説明するコメントが付きます。

その他すべてのエラーは明示的な `error` リターンを使います。ハンドラーの `writeError` は Gin のリカバリーミドルウェア経由でパニックから回復して 500 を返しますが、このリカバリーは設計戦略ではなくセーフティネットです。

### Trade-offs and Constraints  [SENIOR]

「不変式にのみパニック」ポリシーは、すべての外部依存を初期化時に検証することを必要とします。これにより起動の複雑さが増します。Meridian の `main.go` は各依存を確認し、明確なエラーメッセージとともに失敗時にパニックする明示的な起動シーケンスを持っています。帰結はフェイルファスト: 設定ミスのデプロイメントは起動時にパニックし、一部のリクエストは正常に提供し他は不透明に失敗するのではなく。

コスト: 依存（例えば Redis）が起動後に利用不可になると、後続の呼び出しはパニックではなくエラーを返します。これは正しい挙動です — Redis の不可用性はランタイム状態であり、起動の不変式ではありません。区別は「Redis が起動時に到達不能」（不変式 — サービスは起動すべきでない）対「Redis がこのリクエストでタイムアウトを返した」（ランタイムエラー — 呼び出し元はエラーレスポンスを受け取るべき）です。

### Example (Meridian)

```go
// cmd/server/main.go
func main() {
    db, err := sql.Open("postgres", os.Getenv("DATABASE_URL"))
    if err != nil {
        panic(fmt.Sprintf("failed to open database: %v", err))
    }
    if err := db.PingContext(context.Background()); err != nil {
        panic(fmt.Sprintf("database not reachable at startup: %v", err))
    }
    // ... continue wiring
}
```

`panic` メッセージにはエラーとコンテキストが含まれているため、デプロイメントログには何が設定ミスだったかが正確に示されます。起動時のパニックはスタックトレースを書き込み、`main.go` を直接指します。ゴルーチン内のランタイムパニックとは容易に区別できます。

### Related Sections

- [architecture → Hexagonal Split](./architecture.md#hexagonal-split) — これらの起動パニックが保護する初期化結線。
- [operational-awareness → Logging for Ops](./operational-awareness.md#logging-for-ops) — 起動パニックが構造化ログにどのように現れるか。

---

## Corrected: Wrap Everything as 500  [JUNIOR]

> Superseded 2025-10-18: 元のエラーハンドリング戦略は、not-found の状態やバリデーション失敗を含む、エラーの種類に関係なくすべてのエラーに HTTP 500 を返していました。これは誤りでした。クライアントから実行可能なステータスコードを奪い、正当な「タスクが見つからない」状態がモニタリングダッシュボードにサーバーエラーとして現れる原因になっていました。

> 元の実装（誤り）:
> ```go
> // handler/task.go — original
> func (h *TaskHandler) GetTask(c *gin.Context) {
>     task, err := h.svc.GetTask(c.Request.Context(), id, callerID)
>     if err != nil {
>         c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
>         return
>     }
>     c.JSON(http.StatusOK, task)
> }
> ```

**訂正後の理解:**

HTTP ステータスコードは API の主なエラー分類シグナルです。クライアントは「このタスクは存在しない」（404、ユーザーエラー、クライアントはローカル状態を更新すべき）と「サーバーが予期しない障害を起こした」（500、システムエラー、クライアントはリトライするかアラートを上げるべき）を区別できなければなりません。すべてに 500 を返すことはこの区別を崩壊させます。

訂正されたアプローチ — `writeError` 変換を持つ型付きドメインエラー階層 — は、すべてのエラークラスが特定の HTTP ステータスと特定のユーザー向けメッセージにマップされることを保証します。モニタリングダッシュボードには今や 404 が 5xx とは異なるシグナルとして表示されます。404 の急増はクライアント側のバグまたは削除されたリソースを示す可能性がある一方、5xx の急増はバックエンドの障害を示します。修正前は、両方のシナリオが同一に見えていました。

修正は、非 2xx レスポンスをエラーとして扱う TanStack Query をフロントエンドチームが採用したのと同じ PR で行われました。フロントエンドはすでに UI 内で 4xx と 5xx を異なる方法で処理していました — バックエンドがシグナルを提供していなかっただけです。

### Related Sections

- [api-design → Corrected: HTTP Status for Not Found](./api-design.md#corrected-http-status-for-not-found) — この変更に伴った対応する API 設計の修正。
- [error-handling → Domain Error Type Hierarchy](#domain-error-type-hierarchy) — 「すべてを 500 でラップ」アプローチを置き換えたアーキテクチャ。
