---
domain: concurrency-and-async
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: implementer
contributing-agents: [implementer]
---

> このドキュメントは `docs/en/learn/examples/concurrency-and-async.md` の日本語訳です。英語版が原文（Source of Truth）です。

> **読み取り専用リファレンス。** このファイルは ECC Base Template に同梱された作業事例であり、実際のプロジェクトで多くのセッションを重ねた後の knowledge ファイルがどのような状態になるかを示すためのものです。これはあなた自身の knowledge ファイルでは**ありません**。あなた自身の knowledge ファイルは `learn/knowledge/concurrency-and-async.md` に置かれ、エージェントが実際の作業を通じて拡充するまでは空の状態です。エージェントは `docs/en/learn/examples/` 配下を読んだり参照したり書き込んだりしません — このツリーは人間の読者専用です。設計の意図については [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) を参照してください。

---

## このファイルの読み方

レベルマーカーは、各節の対象読者を示します。
- `[JUNIOR]` — 第一原理からの説明。事前知識を前提としない
- `[MID]` — このスタックにおける非自明な慣用的応用
- `[SENIOR]` — 非デフォルトのトレードオフ評価。何を手放したかを明示する

---

## 通知のファンアウト: 単一ゴルーチン vs. ファンアウトパターン  [JUNIOR]

### 第一原理からの説明  [JUNIOR]

Meridian でタスクが変更されると、Slack・メール・アプリ内フィードの 3 つのダウンストリームシステムに通知を送る必要があります。素朴な実装では各通知を逐次呼び出します — それぞれが 100ms かかるとすれば、合計 300ms がユーザーのタスク更新コストとして加算されます。**ファンアウトパターン** では 3 つの呼び出しを並行してディスパッチするため、最も遅い処理の時間だけがオーバーヘッドとなります。

```
タスク変更 ──┬── Slack 通知  ─┐
             ├── メール通知  ─┤── 3 つ完了 → return
             └── アプリ内通知 ─┘
```

コストはエラーの意味論にあります。逐次呼び出しでは、失敗した正確なステップが明示されます。並行ファンアウトでは部分的な結果が返されます — 2 つのチャネルが成功し 1 つが失敗する場合があり、呼び出し側がその意味を決定しなければなりません。

### 慣用的な応用  [MID]

Meridian は `golang.org/x/sync` の `errgroup` を使ってファンアウトを管理しています。

```go
// service/notification.go
func (s *slackEmailInAppNotifier) NotifyTaskAssigned(
    ctx context.Context, task domain.Task, assignee domain.User,
) error {
    g, ctx := errgroup.WithContext(ctx)
    g.Go(func() error { return s.slack.SendTaskAssigned(ctx, task, assignee) })
    g.Go(func() error { return s.email.SendTaskAssigned(ctx, task, assignee) })
    g.Go(func() error { return s.inApp.RecordTaskAssigned(ctx, task, assignee) })
    return g.Wait()
}
```

`errgroup.WithContext` は最初のエラー発生時にキャンセルされる派生コンテキストを生成します。`g.Wait()` はすべてのゴルーチンが終了するまでブロックします — どのゴルーチンも関数のスコープを超えて生存しないため、fire-and-forget ファンアウトに伴うゴルーチンリークのリスクがありません。

`service/task.go` 側の呼び出しコードでは、通知エラーは非致命的として扱われます — 通知の失敗はタスクのアサインメント失敗を意味せず、ログに記録した上で操作はサクセスを返します。製品上の意図については [architecture → Cross-Cutting Concern: Notifications](./architecture.md#cross-cutting-concern-notifications) を参照してください。

### トレードオフと制約  [SENIOR]

`errgroup` は最初のエラー以外をすべて破棄します。Slack とメールの両方が失敗した場合、呼び出し側は Slack のエラーしか受け取りません。Meridian のベストエフォート通知セマンティクスではこれで問題ありませんが、「失敗したチャネルのみ再試行する」という要件があれば、戻り値の型を単一の `error` ではなくチャネルごとの結果スライスにする必要があります。

もう一つのコスト: すべてのゴルーチンが同じコンテキストのデッドラインを共有します。Slack の遅い呼び出しがアプリ内書き込みをキャンセルしないよう、Meridian では各チャネルの `g.Go` ボディ内で、親コンテキストから派生した独自の `context.WithTimeout` を与えています。順序は保証されません — ディスパッチの順序はスケジューラーが決定します。通知の場合はこれで問題ありませんが、順序付きイベントログには適しません。

### 関連節

- 部分的なファンアウト後のリトライにおける重複排除については [error-handling → Idempotent Retry on the Slack Webhook](./error-handling.md#idempotent-retry-on-the-slack-webhook) を参照してください。
- ファンアウトのレイテンシが問題になった場合の非同期化アップグレードパスについては [architecture → Cross-Cutting Concern: Notifications](./architecture.md#cross-cutting-concern-notifications) を参照してください。

---

## コンテキスト伝播: リクエストからリポジトリまで  [JUNIOR]

### 第一原理からの説明  [JUNIOR]

すべての HTTP リクエストにはライフサイクルがあります。そのリクエストによって起動された作業 — データベースクエリ、外部 API 呼び出し、生成されたゴルーチン — はそのライフサイクルを尊重すべきです。クライアントが切断した場合、サーバーは完了まで処理を続けるのではなく、そのクライアントのための作業を停止してリソースを解放すべきです。

`context.Context` は Go のキャンセルキャリアです。チェーン内のすべての関数呼び出しにリクエストコンテキストを渡すことで、キャンセルされたコンテキストを渡された Postgres クエリが即座に中断し、コネクションをプールに戻します。この規律は**伝播**です: リクエスト境界で生成されたコンテキストは、特定のサブタイムアウトが必要な場合を除き、すべてのダウンストリーム呼び出しに変更なしで渡されます。

### 慣用的な応用  [MID]

Meridian の Gin スタックでは、コンテキストはハンドラで生成され、サービスを経由してリポジトリまで変更なしで流れます。

```go
// handler/task.go
ctx := c.Request.Context()
task, err := h.svc.UpdateTask(ctx, taskID, params)
```

```go
// service/task.go
func (s *TaskService) UpdateTask(ctx context.Context, ...) (domain.Task, error) {
    task, err := s.tasks.Update(ctx, id, params) // ctx → Postgres
    if err != nil { return domain.Task{}, err }
    s.notify.NotifyTaskUpdated(ctx, task)         // ctx → fanout goroutines
    return task, nil
}
```

```go
// repository/task.go
err := r.db.QueryRowContext(ctx, `UPDATE tasks SET ...`, ...).Scan(...)
```

クライアントが切断すると、Postgres ドライバーは `ctx.Done()` のクローズを検知してインフライトクエリを中断します。コネクションは完了を待たずにプールに返されます。

### トレードオフと制約  [SENIOR]

厳密な伝播により、すべてのダウンストリーム操作がリクエストタイムアウト（Meridian の Gin デフォルトは 30 秒）に縛られます。これは通常正しい動作です。例外は、リクエストより長生きしなければならない作業です。Meridian のバックグラウンドリコンサイラーはプロセスのライフタイムで動作するため、明示的に `context.Background()` を使用しています。

診断のルール: 関数がリクエスト中に `context.Background()` を生成してキャンセルを回避しようとする場合、その作業はリクエストパスではなくバックグラウンドワーカーに属します。この判断が、リクエストスコープのゴルーチンとプロセススコープのゴルーチンの主な境界線です。

チャネルごとの通知タイムアウトは中間的なケースです — 各 `g.Go` ボディは `context.WithTimeout(ctx, 3*time.Second)` を使って単一チャネルを制限しつつ、親リクエストコンテキストがキャンセルされた場合には早期に終了します。

### 関連節

- リコンサイラーが実行されるプロセスライフタイムの `context.Background()` を確立するスタートアップ初期化については [error-handling → Panic Usage Policy](./error-handling.md#panic-usage-policy) を参照してください。

---

## ゴルーチンのオーナーシップと管理されたリコンサイラー  [MID]

### 第一原理からの説明  [JUNIOR]

明示的な join なしに起動されたゴルーチンは「fire-and-forget」です。本番環境ではこれはリスクになります: panic は起動スコープでは回復不能であり、リクエストごとにリークが蓄積し、クローズ済みチャネルへの書き込みはプロセスをクラッシュさせます。**「すべてのゴルーチンにはオーナーがいる」** という原則は、ゴルーチンが終了するまで待機し、その結果を処理する責任を持つスコープが正確に 1 つ存在することを意味します。

### 慣用的な応用  [MID]

Meridian ではこれをコードベース規約として強制しています: すべての `go func()` 呼び出しは `errgroup.Go` の内部か、`wg.Add(1)` 呼び出しに隣接して現れなければなりません。code-reviewer エージェントはカウントされていないゴルーチンを HIGH の指摘として扱います。

バックグラウンドのデッドラインリコンサイラーは唯一の例外 — プロセスのライフタイムで動作します。呼び出し関数で join されるのではなく、OS シグナルハンドラによって管理されます。

```go
// cmd/server/main.go
ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
defer stop()

go reconciler.Run(ctx) // ctx は SIGINT/SIGTERM でキャンセルされる

srv.ListenAndServe()   // シャットダウンまでブロック
// return 後: ctx がキャンセルされ、リコンサイラーはグレースピリオド内にドレインして終了
```

リコンサイラーはコンテキストを所有し、OS シグナルがコンテキストのキャンセルを所有します。プロセスは `ListenAndServe` が戻り、グレースピリオドのタイムアウトが経過した後にのみ終了します。

### トレードオフと制約  [SENIOR]

このポリシーはゴルーチンリークを防ぎますが、長時間実行される作業をスタートアップ時の登録に押し込みます。ハンドラ内でアドホックにゴルーチンを生成して、レスポンス送信後も実行し続けることはできません。失われるのは、「ベストエフォート」のバックグラウンドタスクを fire-and-forget で扱う利便性です。Meridian は非同期ロギングをロガー実装内でバッファリングすることで対応しています — ハンドラはバッファに同期的に書き込み、`main.go` だけが登録する単一のバックグラウンドゴルーチンがフラッシュを担当します。ハンドラはフラッシャーを生成しません。

---

## デッドラインリマインダージョブのワーカープール  [MID]

### 第一原理からの説明  [JUNIOR]

Meridian のデッドラインリマインダージョブは 5 分ごとに実行され、5,000 万行の tasks テーブルから今後 24 時間以内にデッドラインを迎えるレコードを検索します。結果セットは数万件のタスクに達する可能性があります。逐次で通知を送ると数分かかり、タスクごとに無制限のゴルーチンを生成すると Slack API のレート制限に達し、Postgres のコネクションプールを枯渇させます。

**有界ワーカープール** は、固定数のゴルーチンに並行性を制限します。すべてのスロットが占有されると、プロデューサーはブロックします — これがバックプレッシャーです。プールサイズは調整可能で、外部の制約（コネクションプールサイズ、ダウンストリーム API の制限）によって上限が定まります。

### 慣用的な応用  [MID]

Meridian はバッファードチャネルをセマフォとして使用しています。

```go
// background/deadline_reconciler.go
const workerPoolSize = 20

func (r *DeadlineReconciler) runRound(ctx context.Context) {
    tasks, _ := r.repo.ListDueSoon(ctx, 24*time.Hour)

    sem := make(chan struct{}, workerPoolSize)
    var wg sync.WaitGroup

    for _, task := range tasks {
        select {
        case sem <- struct{}{}: // 取得; 20 ワーカーがアクティブな場合はブロック
        case <-ctx.Done():
            break
        }
        wg.Add(1)
        go func(t domain.Task) {
            defer wg.Done()
            defer func() { <-sem }()           // 終了時に解放
            notifyCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
            defer cancel()
            if err := r.notifier.NotifyDeadlineMissed(notifyCtx, t); err != nil {
                r.log.Warn("deadline notification failed", "task_id", t.ID, "err", err)
            }
        }(task)
    }
    wg.Wait() // return 前に全件 join
}
```

`ctx.Done()` を使った `select` により、シャットダウン時にエンキューループが即座に終了します。`wg.Wait()` は既にディスパッチ済みのゴルーチンが `runRound` から return する前に完了するまでドレインします。

### トレードオフと制約  [SENIOR]

プールサイズ 20 は Postgres のコネクションプール上限（25 接続）に対してキャリブレーションされています。20 の並行ワーカーがそれぞれコネクションを保持する可能性を考えると、プールに若干のヘッドルームが残ります。50 に増やせば、フルラウンドでコネクションが枯渇してリトライが発生し、合計時間が延びるという逆効果になります。

失われるもの: エラーを 1 つの戻り値にまとめられる `errgroup` とセマフォの組み合わせが考えられますが、通知エラーはポリシー上非致命的 — ログ記録が正しい対応であり、伝播ではありません。専用の受信者ゴルーチンを持つチャネルベースのワークキューはより明確ですが、大量のボイラープレートが増えます。セマフォパターンは Go では十分慣用的であり、チームはその簡潔さを受け入れました。

グレースフルシャットダウンについて: `select <-ctx.Done()` でエンキューループが終了し、`wg.Wait()` でディスパッチ済みワーカーがドレインされ、`main.go` のシャットダウンシーケンスの `context.WithTimeout` でドレインにかかる時間の上限を定め、時間を超えたらプロセスが強制終了されます。

### 関連節

- タスクごとの通知失敗がアラートノイズなしで構造化ログに記録される方法については [operational-awareness → Logging for Ops](./operational-awareness.md#logging-for-ops) を参照してください。

---

## 修正済み: すべての通知タイプで共有するグローバルゴルーチンプール  [MID]

> 2026-01-14 に supersede: 元の通知サービスは、すべてのワークロードタイプとすべてのテナントで共有する単一のグローバル有界プールを使用していました。本番メトリクスにてテナント間の干渉が確認されました: 大量のテナントのデッドラインリマインダーラウンドが 50 スロットをすべて占有し、他のテナントのタイムセンシティブなタスクアサインメント通知を遅延させていました。この共有プール設計は、ワークロードのレイテンシ要件が混在するマルチテナントシステムに適していませんでした。

> 元の実装（誤り）:
> ```go
> // service/notification.go — original
> var globalPool = make(chan struct{}, 50)
>
> func dispatchNotification(ctx context.Context, fn func()) {
>     globalPool <- struct{}{}
>     go func() { defer func() { <-globalPool }(); fn() }()
> }
> ```
> すべての通知タイプが同じ 50 スロットを奪い合っていました。

**修正後の理解:**

この修正では **コンテキストごとのプール** を導入しました — 論理的なワークロードタイプごとに独立したセマフォを持ち、その並行性とレイテンシ要件に合わせてサイズを設定します。

| プール | サイズ | 理由 |
|------|------|-----------|
| 通知ファンアウト | 3 | チャネルごとに 1 スロット（Slack、メール、アプリ内） |
| デッドラインリコンサイラー | 20 | ラウンドごとの高スループット; コネクションプールで上限 |
| Webhook インジェスト | 10 | バースト処理; Slack API レート制限以下に制限 |

20 スロットをすべて占有するデッドラインリマインダーラウンドは、独立した 3 スロットを持つリアルタイムファンアウトに影響しません。この変更後、本番のレイテンシメトリクスからテナント間の干渉が解消されました。

コスト: プールサイズはそれぞれ独自の根拠を持つ調整可能な定数です。新しいワークロードタイプを追加する際には、共有デフォルトを継承するのではなく、意図的なサイズ決定が必要です。

### 関連節

- 現在のリコンサイラープールの実装については [concurrency-and-async → Worker Pool for the Deadline-Reminder Job](#worker-pool-for-the-deadline-reminder-job) を参照してください。

---

## コーチイラストレーション（default vs. hints）

> **説明のみ。** 以下は、このドメインのタスクに対して 2 つのコーチングスタイルがどのように異なるかを示す作業事例です。ライブエージェントのコントラクトの一部ではありません。実際のエージェントの動作は `.claude/skills/learn/coach-styles/` のスタイルファイルによって規定されます。

**シナリオ:** 学習者がエージェントに対し、Meridian のタスクアサインメントイベントの通知ファンアウトを実装するよう依頼します。Slack・メール・アプリ内に並行してディスパッチする実装です。

**`default` スタイル** — エージェントは完全な `NotifyTaskAssigned` 実装を生成します: `errgroup.WithContext` ファンアウト、チャネルごとの `context.WithTimeout` サブコンテキスト、`TaskService.AssignTask` における「エラーはログ記録するが伝播しない」呼び出しサイト、そして部分的な失敗ケースをカバーするテーブル駆動ユニットテストです。`## Learning:` トレーラーが `errgroup` のオーナーシップセマンティクスとベストエフォートエラーポリシーを説明します。

**`hints` スタイル** — エージェントは関数シグネチャと `g, ctx := errgroup.WithContext(ctx)` を書き、3 つの `g.Go(...)` ボディを空のままにします。次のメッセージを出力します:

```
## Coach: hint
Step: Add three g.Go blocks — one per channel (Slack, email, in-app).
Pattern: errgroup fan-out; all three run concurrently, g.Wait() joins them.
Rationale: errgroup.WithContext cancels sibling goroutines on first error and
guarantees no goroutine outlives the function, preventing leaks.
```

`<!-- coach:hints stop -->`

学習者が `g.Go` ボディを記述します。次のターンでエージェントがレビューし、チャネルごとのタイムアウトサブコンテキストが欠けていれば追加します。
