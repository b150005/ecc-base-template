> このドキュメントは `.claude/meta/references/examples/testing-discipline.md` の日本語訳です。英語版が原文（Source of Truth）です。

---
domain: testing-discipline
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: test-runner
---

> **読み取り専用リファレンス。** このファイルは ECC Base Template に同梱されたサンプルです。実際のプロジェクト上で多くのセッションを重ねた後の、ポピュレートされたナレッジファイルの見た目を示すために提供されています。**あなた自身のナレッジファイルではありません。** あなたのナレッジファイルは `.claude/learn/knowledge/testing-discipline.md` に置かれ、エージェントが実際の作業の中で拡充するまでは空の状態で始まります。エージェントは `.claude/meta/references/examples/` 配下を読んだり引用したり書き込んだりしません — このツリーは人間の読者専用です。設計根拠については [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) を参照してください。

---

## このファイルの読み方

各セクションのレベルマーカーは、その想定読者を示します。
- `[JUNIOR]` — 第一原理からの説明。事前知識なしを前提とします
- `[MID]` — このスタックにおける自明でない慣用的な適用方法
- `[SENIOR]` — 非デフォルトのトレードオフの評価。何を諦めたかを明示します

---

## The Meridian Test Pyramid  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

テストとは、挙動についての主張を証明するものです。主張の種類が違えば必要な根拠のレベルも異なり、根拠のレベルが違えば収集にかかるコストも異なります。

**テストピラミッド**はこの非対称性を体系化したものです。土台には多数の高速なユニットテスト — 関数ひとつ、メソッドひとつ、モジュールひとつを証明するもの。中段には数少ない統合テスト — 実際のシステム境界でコンポーネントが連携することを証明するもの。頂点にはわずかな E2E テスト — ユーザーが重要なフローを完了できることを証明するもの。

ピラミッドの中段を飛ばしたくなることがあります。ユニットテストと E2E テストで全体をカバーできると感じるからです。しかし実際にはそうではありません。ユニットテストは、関数が正しい SQL クエリ文字列を生成することを証明します。しかし、PostgreSQL がそのクエリを受け付けること、結果が正しくデシリアライズされること、そのクエリが依存するインデックスが存在することは証明できません。E2E テストは、ボタンクリック後に UI がレンダリングされることを証明します。しかし、ハンドラー、サービス、リポジトリ、データベース接続のどこで失敗したのかは教えてくれません。

各レベルは他のレベルが証明できないことを証明します。あるレベルを飛ばすということは、その種の障害を本番環境に持ち越すことを意味します。

### Idiomatic Variation  [MID]

Meridian のテスト各層はツールに次のように対応しています。

| レイヤー | ツール | スコープ | 典型的な実行時間 |
|-------|------|-------|-----------------|
| ユニット | Go `testing` パッケージ、`testify` | 単一の関数またはメソッド、すべての依存はモック | テストあたり 10 ms 未満 |
| 統合 | Go `testing` + `testcontainers-go` を使った Docker 上の実 PostgreSQL | 実スキーマに対するリポジトリメソッド | テストあたり 1〜5 秒 |
| E2E | Playwright | デプロイ済み React フロントエンドを通じた重要なユーザーフロー | テストあたり 10〜60 秒 |

統合テストはインプロセスの SQLite やモックではなく実データベースを使います。Meridian が SQLite を使わない理由は、制約違反とタイムスタンプ精度に関するエッジケースで SQLite の挙動が PostgreSQL と乖離することを発見したからです。実際の Postgres イメージを使うと速度は落ちますが、乖離は完全になくなります。

E2E スイートは localhost ではなく CI 上のステージングデプロイメントに対して実行されます。レイテンシは増えますが、localhost では捕捉できない環境固有の障害（環境変数の欠落、CORS の設定ミス）を検出できます。

### Trade-offs and Constraints  [SENIOR]

統合テストで実データベースを使うコストは、CI のレイテンシとイメージのプル時間です。Meridian の統合スイートは、ワークフローで `postgres:16` イメージをキャッシュ済みの GitHub Actions ランナー上で約 4 分で完了します。このコストを受け入れる決断は、SQLite がテストで黙って無視していた PostgreSQL の制約によって発生した本番インシデントの後に下されました。PR あたり 4 分のオーバーヘッドは、本番ロールバックよりも安上がりです。

ステージングベースの E2E テストのコストは、ステージングが不安定なときのフレーキーリスクです。Meridian はこのリスクを、Playwright 実行前にステージングの健全性を確認するスモークチェックを CI ワークフローに追加することで軽減しました。スモークチェックが失敗した場合、E2E ステップはスキップされ、ステージングが回復した後に再実行するよう PR がフラグを立てられます。

### Example (Meridian)

```go
// integration/task_repository_test.go
func TestTaskRepository_Create_ReturnsCreatedTask(t *testing.T) {
    // Arrange
    db := testhelper.MustOpenTestDB(t) // starts postgres container, runs migrations
    repo := repository.NewTaskRepository(db)
    params := domain.CreateTaskParams{
        WorkspaceID: uuid.New(),
        Title:       "Write integration tests",
        AssigneeID:  uuid.New(),
    }

    // Act
    task, err := repo.Create(context.Background(), params)

    // Assert
    require.NoError(t, err)
    assert.Equal(t, params.Title, task.Title)
    assert.NotZero(t, task.ID)
    assert.NotZero(t, task.CreatedAt)
}
```

`testhelper.MustOpenTestDB` ヘルパーはテストパッケージ単位（テスト関数単位ではなく）で新鮮な Postgres コンテナを起動し、すべてのマイグレーションを実行し、コンテナをティアダウンする `t.Cleanup` を登録します。データベース状態を必要とする各テスト関数は自身の行を個別に作成します。

### Related Sections

- [error-handling → Boundary Translation](./error-handling.md#boundary-translation-from-postgres-to-domain-errors) — 統合テストが Postgres の制約エラーをドメインエラーとして表面化させる仕組み。
- [architecture → Hexagonal Split](./architecture.md#hexagonal-split) — 統合テストがサービス層ではなくリポジトリ層を対象とする理由。

### Coach Illustration (default vs. hints)

> **例示目的のみ。** ライブエージェントの契約の一部ではありません。`.claude/skills/learn/coach-styles/` が定義します。

**シナリオ:** 学習者がエージェントに `TaskRepository.Archive` の統合テストを書くよう依頼します。

**`default` スタイル** — エージェントは完全なテスト関数を作成します。Arrange（タスクを作成し、アクティブであることを確認）、Act（`repo.Archive` を呼び出す）、Assert（タスクステータスが `archived` で、`archived_at` タイムスタンプがセットされている）。統合テストとユニットテストの選択理由、およびこれが統合層に属する理由を説明する `## Learning:` トレーラーを付けます。

**`hints` スタイル** — エージェントは Arrange/Act/Assert のセクションがコメントアウトされた空のテストスタブスケルトンを書き、次のヒントを出力します。

```
## Coach: hint
Step: Arrange a real task row in the test database, then assert the archived_at column is set.
Pattern: Arrange-Act-Assert with testcontainers-go real database.
Rationale: repo.Archive changes a database row; only an integration test against real
Postgres can verify the SQL and the constraint that prevents archiving already-archived tasks.
```

`<!-- coach:hints stop -->`

---

## Fixtures Are Test-Local, Never Shared Mutable State  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

テストフィクスチャとは、テストがテスト対象コードを実行する前に必要とするデータや状態のことです。最もやってしまいがちなフィクスチャ設計は共有セットアップです。データベース状態を生成する 1 つの関数をスイート内のすべてのテストの前に呼び出すという方法です。共有セットアップはアンチパターンです。状態を共有するテストは暗黙のうちに結合するからです。テスト A は、テスト B が削除する行に依存しているかもしれません。テスト C は、テスト A が作成する行なしには通らないかもしれませんが、それをテスト C 自体は宣言していません。

結果として、テストを単独で実行すると通るが、特定の順序では失敗するテストスイートになるか、テスト A のセットアップを変更するとテスト C が壊れるが、両者の間に明白な関係が見当たらないという状態になります。

Meridian のルールは、**各テストは必要なデータだけを、過不足なく自分で作成する**というものです。2 つのテストが同じユーザー行を必要とする場合、それぞれが独立して作成します。冗長さは許容します。見えない結合は許容しません。

### Idiomatic Variation  [MID]

Meridian はグローバルなフィクスチャではなくビルダーパターンをテストデータに使っています。ビルダーは、合理的なデフォルト値を持つドメインオブジェクトを生成するフルーエントなメソッドを持つ構造体で、テストごとにオーバーライドできます。

```go
// testhelper/builders.go
type TaskBuilder struct {
    title      string
    workspaceID uuid.UUID
    assigneeID  uuid.UUID
    status     domain.TaskStatus
}

func NewTaskBuilder() *TaskBuilder {
    return &TaskBuilder{
        title:      "Default Task Title",
        workspaceID: uuid.New(),
        assigneeID:  uuid.New(),
        status:     domain.TaskStatusActive,
    }
}

func (b *TaskBuilder) WithTitle(title string) *TaskBuilder {
    b.title = title
    return b
}

func (b *TaskBuilder) Build(t *testing.T, db *sql.DB) domain.Task {
    t.Helper()
    // inserts into DB, returns the created task
    task, err := insertTask(db, b.title, b.workspaceID, b.assigneeID, b.status)
    require.NoError(t, err)
    return task
}
```

特定のタスクタイトルが必要なテストは `NewTaskBuilder().WithTitle("…").Build(t, db)` を呼びます。すべてのテストが自身のデータを宣言します。あるテストが他のテストの副作用に依存することはありません。

### Trade-offs and Constraints  [SENIOR]

ビルダーパターンの冗長さは実際のコストです。5 つの関連エンティティが必要な複雑なシナリオでは、1 つの共有セットアップよりもコードが増えます。Meridian がこのコストを受け入れたのは、3 人の異なるエンジニアが 6 ヶ月かけて書いた 5 つのテストの要件が蓄積した共有 `beforeEach` フィクスチャが引き起こした 2 時間のデバッグセッションの後でした。そのデバッグセッションにかかったコストは、冗長さのコストをはるかに上回っていました。

ビルダーパターンはテストヘルパーを本番パッケージの型システムの中に置くことにもなります。ビルダーは本番コードと同じドメイン型を使います。ドメイン型が変更されると、古いテストデータを黙って生成し続けるのではなく、コンパイル時にビルダーが壊れます。

### Example (Meridian)

上記の `NewTaskBuilder()` のコードは Meridian の実際のテストヘルパーから取っています。検討された代替案は、グローバルな `TestDB` 変数とトランザクションロールバックのアプローチ（各テストはクリーンアップ時にロールバックされるトランザクション内で実行される）でした。ロールバックアプローチが却下されたのは、マルチトランザクション挙動をテストするテストを壊すからです — 具体的には、Meridian の楽観的ロックロジックのテストがこれに該当し、2 つの並行トランザクションを必要とするため単一のロールバックトランザクション内ではテストできません。

### Related Sections

- [testing-discipline → The Meridian Test Pyramid](#the-meridian-test-pyramid) — ビルダーパターンが使われるテスト層。
- [persistence-strategy → Indexing Strategy](./persistence-strategy.md#indexing-strategy) — テストデータが連番整数ではなく現実的な UUID を使う理由。

---

## Contract Testing the Slack Integration  [MID]

### First-Principles Explanation  [JUNIOR]

Meridian がタスク通知を Slack に送信するとき、Slack の API に HTTP 呼び出しを行います。その呼び出しを CI 上の実際の Slack ワークスペースでテストするのは非現実的です。実際のトークンが必要で、実際のメッセージが投稿され、レート制限があり、Slack の可用性に依存します。代替案としてテスト自体をスキップすることも考えられますが、それでは Slack インテグレーションのバグはユーザーが発見することになります。

**コントラクトテスト**はこの 2 つの選択肢の中間に位置します。実際の Slack API を呼び出す代わりに、送信リクエストの形（「コントラクト」）をアサートする HTTP モックを使います。実際の Slack API がコントラクトを変更した場合、モックはそれを検出しません — Slack のサンドボックス環境に対して行う別のコントラクトテスト実行が検出します。ユニットテストスイートの中では、モックは Meridian のコードがドキュメント化された API に対して正しいリクエスト形を生成することを証明します。

### Idiomatic Variation  [MID]

Meridian は `httpmock`（github.com/jarcoal/httpmock）を使って Slack クライアントからの送信 HTTP 呼び出しをインターセプトします。モックは特定の Slack webhook URL に対するレスポンダーを登録し、リクエストボディをアサートします。

```go
// service/notification_test.go
func TestNotificationService_NotifyTaskAssigned_PostsToSlack(t *testing.T) {
    httpmock.Activate()
    defer httpmock.DeactivateAndReset()

    var capturedBody slackMessage
    httpmock.RegisterResponder(
        "POST",
        "https://slack.com/api/chat.postMessage",
        func(req *http.Request) (*http.Response, error) {
            json.NewDecoder(req.Body).Decode(&capturedBody)
            return httpmock.NewStringResponse(200, `{"ok":true}`), nil
        },
    )

    svc := notification.NewService(slackClient, ...)
    err := svc.NotifyTaskAssigned(ctx, task, assignee)

    require.NoError(t, err)
    assert.Equal(t, "#task-alerts", capturedBody.Channel)
    assert.Contains(t, capturedBody.Text, task.Title)
    assert.Equal(t, 1, httpmock.GetTotalCallCount())
}
```

`httpmock.GetTotalCallCount()` のアサーションは、Slack API がちょうど 1 回呼び出されたことを検証します — 0 回（サイレントな失敗）でも 2 回（重複通知）でもなく。

### Trade-offs and Constraints  [SENIOR]

`httpmock` ベースのコントラクトテストは送信リクエストの形を証明しますが、Slack がそのリクエストを受け付けることは証明できません。Meridian は、実際の API コントラクトが変更されていないことを確認するためのナイトリージョブを Slack のサンドボックス環境に対して実行しています。このナイトリージョブはユニットテストスイートとは独立しており、PR をブロックしません。失敗するとアラートが上がります。この分離は意図的なものです。外部 API の可用性に PR をブロックさせることは CI を不安定にします。

このアプローチのコストは、Slack API の変更がナイトリー実行まで検出されないことです。ビジネス判断として、タスク通知は重要だがミッションクリティカルではないため、24 時間の検出ウィンドウは許容範囲です。もし通知がミッションクリティカルであれば、ナイトリージョブは毎時実行となり PagerDuty でアラートが上がるでしょう。

### Example (Meridian)

上記の `httpmock` スニペットを参照してください。Slack webhook 呼び出しの重複排除キー（リトライ時の二重送信を防ぐ）は、Redis 冪等性ストアを実行する統合テストで別途テストされています — [error-handling → Idempotent Retry on Slack Webhook](./error-handling.md#idempotent-retry-on-the-slack-webhook) を参照してください。

### Related Sections

- [error-handling → Idempotent Retry on Slack Webhook](./error-handling.md#idempotent-retry-on-the-slack-webhook) — これらのテストが実行するリトライと重複排除のロジック。
- [api-design → Idempotency Key Handling](./api-design.md#idempotency-key-handling) — Meridian のインバウンド webhook エンドポイント全体にわたる冪等性パターン。

---

## Prior Understanding: E2E Coverage Scope  [SENIOR]

### Prior Understanding (revised 2026-02-14)

最初のアプローチ（Meridian の初回 CI 設定、2025 年 9 月ごろ）は、Playwright E2E テストでユーザー向けアプリケーション全体をカバーすることでした。すべてのページ、すべてのインタラクション、すべてのエッジケースが対象でした。「UI にあるものには E2E テストがある」という方針です。

以下の理由からこの方針は見直されました。

1. E2E スイートは 340 テストに膨れ上がり、GitHub Actions ランナー上で 47 分かかるようになりました。PR は CI を待って約 1 時間滞留しました。開発者のフィードバックループが崩壊しました。
2. E2E の失敗のおよそ 60% はフレーキーなもの — 実際の欠陥ではなく、タイミングの問題、アニメーションの遅延、テスト環境の不安定さに起因 — でした。エンジニアたちは失敗を調査するのではなく CI を再実行することを覚え、スイートの目的が失われました。
3. これらの 340 テストでテストされていたビジネスロジックはすでにユニットテストと統合テストでカバーされていました。E2E テストは UI のレンダリングと API コントラクトへの信頼を追加しましたが、ビジネスロジックへの信頼は追加していませんでした。

**訂正後の理解:**

E2E テストは**重要なユーザーパスのみ**をカバーします — 失敗がユーザーの主要な目標を直接妨げるフローです。ワークスペースの作成、タスクのアサイン、タスクボードの閲覧、Slack インテグレーション確認画面です。非重要なフロー（プロフィール設定、通知設定、請求ページ）はユニットテストと統合テストに依存します。

スコープ縮小後、E2E スイートは 28 テストになり 6 分で実行できます。フレーキーさは 5% 以下に低下しました。アニメーション依存のアサーションを削除し、決定論的な `waitForSelector` 条件に置き換えたことによるものです。

原則として、E2E テストは書くのにコストがかかり、維持するのにコストがかかり、実行するのにコストがかかります。失敗がユーザー向けのインシデントとなるフロー — 単なる不便ではなく — に限って使うべきです。

### Related Sections

- [testing-discipline → The Meridian Test Pyramid](#the-meridian-test-pyramid) — この見直しによって形作られた、より広いテスト戦略。
- [operational-awareness → Incident Response](./operational-awareness.md#incident-response) — スコープ縮小のきっかけとなった本番インシデント。
