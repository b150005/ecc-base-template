> このドキュメントは `docs/en/learn/examples/api-design.md` の日本語訳です。英語版が原文（Source of Truth）です。

---
domain: api-design
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: architect
contributing-agents: [architect, code-reviewer]
---

> **読み取り専用リファレンス。** このファイルは ECC Base Template に同梱されたサンプルです。実際のプロジェクト上で多くのセッションを重ねた後の、ポピュレートされたナレッジファイルの見た目を示すために提供されています。**あなた自身のナレッジファイルではありません。** あなたのナレッジファイルは `learn/knowledge/api-design.md` に置かれ、エージェントが実際の作業の中で拡充するまでは空の状態で始まります。エージェントは `docs/en/learn/examples/` 配下を読んだり引用したり書き込んだりしません — このツリーは人間の読者専用です。設計根拠については [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) を参照してください。

---

## このファイルの読み方

各セクションのレベルマーカーは、その想定読者を示します。
- `[JUNIOR]` — 第一原理からの説明。事前知識なしを前提とします
- `[MID]` — このスタックにおける自明でない慣用的な適用方法
- `[SENIOR]` — 非デフォルトのトレードオフの評価。何を諦めたかを明示します

---

## Resource Hierarchy: Tasks and Assignments  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

REST API はドメインを**リソース** — 作成、読み取り、更新、削除ができるもの — としてモデル化します。リソースはその関係性を反映した URL 階層に整理されます。設計上の中心的な問いは、その階層をどれだけ深くネストするかです。

深いネスト（`/workspaces/{wid}/projects/{pid}/tasks/{tid}/assignments/{aid}`）は、URL 内でリソースのコンテキストを明示します。呼び出し元は常に、タスクがどのワークスペースとプロジェクトに属するかを把握できます。しかし深いネストは URL を長くし、ルートを覚えにくくし、リソース間を移動するたびにフルパスを再構築することを呼び出し元に強いります。タスクがプロジェクト間で移動されると URL が変わり、古い URL をキャッシュしたクライアントは壊れます。

浅いネストは関係を 1 レベルに限定します。タスクはワークスペースに属しますが、ワークスペース ID はクエリパラメータとして渡されるか、URL セグメントではなくタスク ID にエンコードされます。

### Idiomatic Variation  [MID]

Meridian はコレクションリソースのネストを 1 レベルに、個別リソースのネストを 0 レベルに保っています。

```
GET    /v1/workspaces/{workspace_id}/tasks        # list tasks in workspace
POST   /v1/workspaces/{workspace_id}/tasks        # create task in workspace
GET    /v1/tasks/{task_id}                        # get specific task (no workspace in path)
PATCH  /v1/tasks/{task_id}                        # update task
DELETE /v1/tasks/{task_id}                        # delete task

POST   /v1/tasks/{task_id}/assignments            # assign task to user
DELETE /v1/tasks/{task_id}/assignments/{user_id}  # remove assignment
GET    /v1/tasks/{task_id}/assignments            # list assignees
```

アサインメントはタスクのサブリソースです。アサインメントは独立した存在を持たないからです — どのタスクに属するかを知らなければ、取得・更新・削除ができません。タスクのコンテキストは常に意味を持ちます。一方、`/v1/tasks/{task_id}` にパス中のワークスペース ID が含まれないのは、呼び出し元はすでにタスク ID を知っており、タスクのワークスペースコンテキストはレスポンスボディに含まれるからです。

### Trade-offs and Constraints  [SENIOR]

浅い階層の意味するところは、`GET /v1/tasks/{task_id}` がバックエンドに、URL 内にワークスペース ID なしで呼び出し元をタスクのワークスペースに対して認可することを要求するということです。ハンドラーはタスクを取得し、そのワークスペースを見つけ、呼び出し元がそのワークスペースのメンバーかどうかを確認しなければなりません。これはワークスペース ID が URL にあり、タスクテーブルに触れる前にチェックできる深いネスト設計と比べて、1 クエリ余分にかかります。

Meridian がこのコストを受け入れたのは、クライアント側の利点 — プロジェクト間のタスク移動後も安定したリソース URL — がサーバー側の 1 クエリの余分なコストを上回ったからです。タスクの移動は Meridian の中核機能（競合製品との差別化点）です。URL が安定することで、Slack で共有されたタスクリンクは移動後も壊れません。

### Example (Meridian)

タスクリソースの Gin ルーター登録:

```go
// router/router.go
func RegisterRoutes(r *gin.Engine, h *handlers.Handlers, auth middleware.AuthMiddleware) {
    v1 := r.Group("/v1")
    v1.Use(auth.RequireWorkspaceMember())

    workspaces := v1.Group("/workspaces/:workspace_id")
    workspaces.GET("/tasks", h.Task.ListTasks)
    workspaces.POST("/tasks", h.Task.CreateTask)

    tasks := v1.Group("/tasks")
    tasks.GET("/:task_id", h.Task.GetTask)
    tasks.PATCH("/:task_id", h.Task.UpdateTask)
    tasks.DELETE("/:task_id", h.Task.DeleteTask)
    tasks.POST("/:task_id/assignments", h.Task.AssignTask)
    tasks.DELETE("/:task_id/assignments/:user_id", h.Task.RemoveAssignment)
}
```

### Related Sections

- [architecture → Thin Handler Pattern](./architecture.md#thin-handler-pattern) — このリソースモデルとハンドラー層の関わり方。
- [api-design → Error Envelope: RFC 9457](#error-envelope-rfc-9457) — この階層内のすべてのエンドポイントからエラーが返される方法。

### Coach Illustration (default vs. hints)

> **例示目的のみ。** ライブエージェントの契約の一部ではありません。`.claude/skills/learn/coach-styles/` が定義します。

**シナリオ:** 学習者がタスクの一括アーカイブ API を設計しており、`POST /v1/tasks/bulk-archive` と `POST /v1/workspaces/{wid}/tasks/bulk-archive` のどちらを使うべきか尋ねます。

**`default` スタイル** — エージェントはリクエストボディにタスク ID を含む `POST /v1/tasks/bulk-archive` を推奨し、ワークスペースレベルのパスが認可上の利点を追加しない理由（サービスがいずれにせよ各タスクのワークスペースをチェックする）を説明し、リクエスト/レスポンスの形を示します。`## Learning:` トレーラーで浅いネストを解説します。

**`hints` スタイル** — エージェントは適切な HTTP メソッドとパスパターンを指摘し、「浅いネスト」の原則に名前を付け、トレードオフを挙げるヒントを出力します。学習者はリクエストボディの形を自分で設計します。

---

## Idempotency Key Handling  [MID]

### First-Principles Explanation  [JUNIOR]

ネットワーク呼び出しは曖昧な方法で失敗することがあります。リソースを作成する POST リクエストは、サーバーがリクエストを処理した後、レスポンスがクライアントに届く前に失敗することがあります。クライアントはリソースが作成されたかどうかを知りません。POST を再試行すると重複が生まれるかもしれません。これが「at-least-once delivery」問題です。

**冪等性キー**がこれを解決します。クライアントは各論理操作に対してユニークなキーを生成し、リクエストヘッダーに送信します。サーバーはリクエストを最初に処理したときにそのキーを記録し、結果を保存します。同じキーが再び届いた場合、サーバーはリクエストを再処理するのではなく保存された結果を返します。操作は冪等です。2 回送信しても 1 回送信したのと同じ効果になります。

### Idiomatic Variation  [MID]

Meridian は Slack webhook インジェストエンドポイントで冪等性キーを使っています。このエンドポイントは Meridian のボットコマンドが呼び出されたときに Slack の API からタスクイベントコールバックを受け取ります。Slack の webhook 配信保証は at-least-once です。同じイベントが複数回届くことがあります。`Idempotency-Key` ヘッダーには Slack 自身のイベント ID が入ります。

```go
// handler/webhook.go
func (h *WebhookHandler) IngestSlackEvent(c *gin.Context) {
    key := c.GetHeader("Idempotency-Key")
    if key == "" {
        c.JSON(http.StatusBadRequest, errorResponse(errors.New("missing Idempotency-Key")))
        return
    }

    seen, err := h.svc.CheckAndRecordIdempotencyKey(c.Request.Context(), key, 24*time.Hour)
    if err != nil {
        h.writeError(c, err)
        return
    }
    if seen {
        c.JSON(http.StatusOK, gin.H{"status": "already_processed"})
        return
    }

    var event slackEvent
    if err := c.ShouldBindJSON(&event); err != nil {
        c.JSON(http.StatusBadRequest, errorResponse(err))
        return
    }

    if err := h.svc.ProcessSlackEvent(c.Request.Context(), event); err != nil {
        h.writeError(c, err)
        return
    }
    c.JSON(http.StatusOK, gin.H{"status": "processed"})
}
```

冪等性ストアは TTL 24 時間の Redis です。キーは処理後ではなく処理前に確認・記録されます。そのため、処理の試みが失敗してもキーは「処理済み」とマークされません — クライアントは再試行でき、リクエストは再処理されます。

### Trade-offs and Constraints  [SENIOR]

処理前にキーを保存することは、失敗した操作をリトライ可能にしますが、最終的に永続的に失敗するリクエストに対しても、キーが 24 時間 Redis に保持されることを意味します。Meridian のトラフィック量ではこれは問題になりません。トラフィックが多いシステムでは、より短い TTL またはより選択的なキー保存戦略が必要になります。

24 時間の TTL は Slack のイベント配信リトライの最大ウィンドウに合わせて選ばれました。24 時間より古いイベントは Slack がリトライしないことを保証しているため、24 時間より古いキーは重複処理のリスクなしに安全に失効させられます。

### Example (Meridian)

Redis のキー形式は `idempotency:slack:{event_id}` です。Meridian 自身の書き込みエンドポイントのクライアント提供の冪等性キーには別の Redis キー名前空間（`idempotency:api:{client_key}`）が使われますが、これらのエンドポイントは公開されておらず、そのパターンはまだ OpenAPI 仕様にドキュメント化されていません。

### Related Sections

- [error-handling → Idempotent Retry on the Slack Webhook](./error-handling.md#idempotent-retry-on-the-slack-webhook) — エラーハンドリング層が冪等性キーチェックとどう連携するか。
- [testing-discipline → Contract Testing the Slack Integration](./testing-discipline.md#contract-testing-the-slack-integration) — このエンドポイントの冪等性挙動がどのようにテストされるか。

---

## Cursor-Based Pagination on Task Lists  [MID]

### First-Principles Explanation  [JUNIOR]

ページネーションは API がリクエストごとに返す結果の数を制限します。2 つの一般的な戦略が**オフセットページネーション**と**カーソルページネーション**です。

オフセットページネーション: クライアントは `page=2&limit=20` を送り、サーバーは `SELECT ... LIMIT 20 OFFSET 20` を実行します。実装も理解も簡単です。クライアントはページ番号で任意のページにジャンプできます。

カーソルページネーション: サーバーはレスポンスごとに `nextCursor` トークンを返します。クライアントは次のリクエストで `cursor=<token>&limit=20` を送ります。サーバーはカーソルをデコードして前のページが終わった場所を見つけ、そこから続けます。

### Idiomatic Variation  [MID]

Meridian はタスクリストエンドポイントにカーソルページネーションを使っています。カーソルは前のページの最後のアイテムの `(created_at, id)` タプルを base64 エンコードしたものです。

```json
// GET /v1/workspaces/{workspace_id}/tasks?limit=20
{
  "tasks": [...],
  "pagination": {
    "nextCursor": "eyJjcmVhdGVkX2F0IjoiMjAyNi0wNC0yMlQxMDowMDowMFoiLCJpZCI6InV1aWQifQ==",
    "hasMore": true
  }
}
```

```go
// The SQL query for cursor-based continuation
func (r *TaskRepository) List(ctx context.Context, params ListParams) ([]domain.Task, error) {
    q := `SELECT * FROM tasks WHERE workspace_id = $1`
    args := []interface{}{params.WorkspaceID}

    if params.Cursor != nil {
        q += ` AND (created_at, id) < ($2, $3)`
        args = append(args, params.Cursor.CreatedAt, params.Cursor.ID)
    }
    q += ` ORDER BY created_at DESC, id DESC LIMIT $` + strconv.Itoa(len(args)+1)
    args = append(args, params.Limit+1) // fetch one extra to detect hasMore
    // ...
}
```

`limit + 1` 行を取得してカウントが `limit` を超えるかどうかを確認するのは、別途 `COUNT(*)` クエリを発行せずに `hasMore` を判定するための標準的な手法です。

### Trade-offs and Constraints  [SENIOR]

カーソルページネーションは任意のページへのジャンプができません。「5 ページ目に移動」機能を作りたいクライアントはカーソルではできません — 1 ページ目から 4 ページ目まで順番にたどるしかありません。Meridian のタスクボード（継続スクロール方式で、ページ番号にはジャンプしない）では、これは制限になりません。もしレポート機能で「100 行目にスキップ」が必要になれば、そのエンドポイントだけオフセットページネーションが必要です。

オフセットページネーションはデータセットが大きく頻繁に変更される場合に劣化します。ページ間でタスクが作成・削除されると、オフセットページネーションはスキップまたは重複した結果を生成します。カーソルページネーションはこれを避けます。`(created_at, id)` タプルが位置を特定の行にアンカーするため、リストの他の部分での挿入・削除が現在位置に影響しません。

カーソルを選んだのは、Meridian のタスクリストがアクティブなスプリント中に高頻度の書き込みを受けることが期待されており（タスクの作成と更新）、ユーザーがページ間ジャンプではなく継続スクロールをするからです。

### Example (Meridian)

Idiomatic Variation セクションの SQL スニペットを参照してください。このクエリを効率的にするために、`tasks` テーブルの `(created_at, id)` 複合インデックスが必要です — インデックスの定義については [persistence-strategy → Indexing Strategy](./persistence-strategy.md#indexing-strategy) を参照してください。

### Related Sections

- [persistence-strategy → Indexing Strategy](./persistence-strategy.md#indexing-strategy) — カーソルページネーションを効率的にする複合インデックス。
- [implementation-patterns → Common Patterns](./implementation-patterns.md#common-patterns) — このクエリパターンをラップするページネーションユーティリティ。

---

## Error Envelope: RFC 9457  [MID]

### First-Principles Explanation  [JUNIOR]

API 呼び出しが失敗したとき、レスポンスには 2 つのことを伝える必要があります。何が問題だったか（クライアントがユーザーに表示したり、インテリジェントにリトライするため）と、サーバー側の開発者がログだけから問題を診断するのに十分なコンテキストです。素の HTTP ステータスコードでは不十分です。`400 Bad Request` はクライアントがエラーを起こしたことを示しますが、どのフィールドが無効でなぜかは教えてくれません。

HTTP API を構築するすべてのプロジェクトは、最終的にエラーレスポンス形式を必要とします。選択肢は、独自に考案するか、標準を採用するかです。カスタム形式を考案すると、すべてのクライアントライブラリがそのカスタム形式を学ぶ必要があります。標準を採用すると、その標準に対応済みのクライアントライブラリがそのまま動作します。

### Idiomatic Variation  [MID]

Meridian はエラーエンベロープ形式として RFC 9457（HTTP API のための問題詳細）を使っています。任意のエラーに対するレスポンスボディは次のとおりです。

```json
{
  "type": "https://api.meridian.app/errors/validation-error",
  "title": "Validation Error",
  "status": 400,
  "detail": "The 'title' field is required and must be between 1 and 255 characters.",
  "instance": "/v1/tasks",
  "extensions": {
    "fields": ["title"]
  }
}
```

`type` フィールドはエラークラスを一意に識別する URI です。Meridian のエラー型は `https://api.meridian.app/errors/` にドキュメント化されています（レスポンス内のライブ URL ではなく、内部ドキュメントページです）。`instance` フィールドはエラーを引き起こしたリクエストを識別します — クライアントに表示されるエラーをサーバーサイドのログエントリと照合するときに便利です。

`extensions` フィールドは RFC がカバーしていないドメイン固有のコンテキストを持ちます。バリデーションエラーに対しては、クライアントが `detail` 文字列を解析することなく正しいフォームフィールドをハイライトできるよう、無効なフィールド名のリストを持ちます。

### Trade-offs and Constraints  [SENIOR]

RFC 9457 は標準ですが、HTTP クライアントライブラリに普遍的にサポートされているわけではありません。Meridian の React フロントエンドは TanStack Query を使っており、これは生のエラーボディをサーフェスします。フロントエンドはどのエラー UI を表示するかを決めるために `type` フィールドを解析する必要があります。これはカスタム形式を解析することと比べて大幅に手間が増えるわけではありませんが、フロントエンドチームはエラーパースレイヤーを構築する必要がありました。

RFC とカスタム形式の選択は長期的な保守性のためになされました。Meridian が公開 API または SDK を出荷する場合、RFC 9457 はクライアント SDK 開発者が期待する形式です。カスタム形式はカスタム仕様を REST リソースのセマンティクスに加えてドキュメント化する必要があります。

### Example (Meridian)

ドメインエラーを RFC 9457 レスポンスに変換する Go ミドルウェア:

```go
// handler/errors.go
func (h *baseHandler) writeError(c *gin.Context, err error) {
    var domainErr *domain.Error
    if errors.As(err, &domainErr) {
        c.JSON(domainErr.HTTPStatus(), gin.H{
            "type":     "https://api.meridian.app/errors/" + domainErr.Type(),
            "title":    domainErr.Title(),
            "status":   domainErr.HTTPStatus(),
            "detail":   domainErr.Detail(),
            "instance": c.Request.URL.Path,
        })
        return
    }
    // Unknown error: log and return 500
    log.Error("unhandled error", "err", err, "path", c.Request.URL.Path)
    c.JSON(http.StatusInternalServerError, gin.H{
        "type":   "https://api.meridian.app/errors/internal-error",
        "title":  "Internal Server Error",
        "status": 500,
        "detail": "An unexpected error occurred. Please try again or contact support.",
    })
}
```

### Related Sections

- [error-handling → Domain Error Type Hierarchy](./error-handling.md#domain-error-type-hierarchy) — この変換に渡される `domain.Error` 型。

---

## Corrected: HTTP Status for Not Found  [JUNIOR]

> Superseded 2025-11-03: 元の API 設計では、存在しないリソースに対して空のボディを持つ `200 OK` を返していました。これは誤りでした。存在しないリソースには `404 Not Found` が正しいステータスコードです。

> 元の実装（誤り）:
> ```go
> task, err := repo.Get(ctx, id)
> if err == sql.ErrNoRows {
>     c.JSON(http.StatusOK, nil) // incorrect: 200 with null body
>     return
> }
> ```

**訂正後の理解:**

存在しないリソースは `200 OK` ではなく `404 Not Found` を返すべきです。元の挙動は Meridian の最初のスプリントで、フロントエンドチームがまだステータスコードを解析しておらず null レスポンスボディを確認していた時点で導入されました。フロントエンドが TanStack Query のエラーハンドリング（非 2xx レスポンスをエラーとして扱う）を使うようリファクタリングされたとき、`200` の挙動はエラー表示を壊しました。修正は TanStack Query リファクタと同じ PR で行われました。

訂正後の実装:

```go
task, err := repo.Get(ctx, id)
if errors.Is(err, domain.ErrNotFound) {
    h.writeError(c, domain.NewNotFoundError("task", id))
    return
}
```

原則として、HTTP ステータスコードはコントラクトです。`200` はリクエストが成功し、レスポンスボディに要求されたリソースが含まれることを意味します。`404` はリソースが存在しないことを意味します。null ボディで `200` を返すことは「成功」と「見つからない」を混同させ、クライアントが標準的な HTTP エラーハンドリングパターンを使えなくします。

### Related Sections

- [error-handling → Domain Error Type Hierarchy](./error-handling.md#domain-error-type-hierarchy) — 訂正後の実装で使われる `domain.ErrNotFound` 型。
