> このドキュメントは `.claude/meta/references/examples/performance-intuition.md` の日本語訳です。英語版が原文（Source of Truth）です。

---
domain: performance-intuition
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: performance-engineer
contributing-agents: [performance-engineer]
---

> **読み取り専用リファレンス。** このファイルは ECC Base Template に同梱された実装例であり、実際のプロジェクトの多くのセッションを経て積み上がったナレッジファイルがどのような姿になるかを示しています。これはあなた自身のナレッジファイルでは**ありません**。あなた自身のナレッジファイルは `.claude/learn/knowledge/performance-intuition.md` にあり、実際の作業においてエージェントが内容を拡充するまでは空の状態です。エージェントは `.claude/meta/references/examples/` 配下のファイルを読み込んだり、引用したり、書き込んだりすることは一切ありません。このツリーは人間の読者専用です。設計の背景については [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) を参照してください。

---

<a id="how-to-read-this-file"></a>
## このファイルの読み方

各セクションのレベルマーカーは想定読者を示しています。
- `[JUNIOR]` — 第一原理からの説明。事前知識を前提としません。
- `[MID]` — このスタックにおける、一見しただけでは気づきにくい慣用的な応用。
- `[SENIOR]` — デフォルト以外のトレードオフの評価。何を諦めるかを明示します。

---

<a id="latency-budgets-for-get-v1-tasks"></a>
## `GET /v1/tasks` のレイテンシバジェット  [JUNIOR]

<a id="first-principles-explanation--junior-"></a>
### 第一原理からの説明  [JUNIOR]

「`GET /v1/tasks` の p99 を 200ms 以内に収める」というレイテンシ目標は、データベース層だけで追いかける単一の数値ではありません。それはリクエストが通過するすべてのステップに分散された**バジェット**です。各ステップがスライスを消費し、スライスの合計がばらつきのヘッドルームを持った上で目標値に収まらなければなりません。あるスライスが増えれば、別のスライスを縮めるか、目標値を変更する必要があります。

明示的なバジェットは、漠然とした「高速化しよう」という目標では答えられない 2 つの問いに答えます。最適化に値するステップはどれか、そして次の退行が目標値を超えるまでにどれだけのヘッドルームが残っているか。すでに 8ms しかかかっていないクエリから 5ms 削減したエンジニアは、誰もプロファイルしていない JSON ステップから 30ms 削減したエンジニアより少ない成果しか上げていません。

<a id="idiomatic-variation--mid-"></a>
### 慣用的なバリエーション  [MID]

最も高トラフィックな読み取りエンドポイントである `GET /v1/workspaces/{wid}/tasks?limit=20` に対する Meridian のバジェットは、p99 で合計 200ms となり、おおよそ以下のように分解されます。

| ステージ | バジェット | 典型的な p99 |
|---------|--------|-------------|
| TLS + リバースプロキシ（ingress → Pod） | 30ms | ~20ms |
| 認証ミドルウェア（JWT 検証 + Redis `GET` によるワークスペースチェック） | 10ms | ~6ms |
| ルーティング + バインディング（Gin） | 2ms | <1ms |
| クエリ（レプリカ、カーソルページネーション、20 行、インデックス済み） | 50ms | ~30ms |
| アサイニーの一括フェッチ（2026 年 Q1 に N+1 を置き換えた追加クエリ 1 件） | 25ms | ~18ms |
| JSON マーシャル（20 タスク + ページネーション、`sync.Pool` バッファ） | 15ms | ~10ms |
| レスポンス書き込み + ミドルウェアアンワインド + 構造化ログ出力 | 8ms | ~5ms |
| Slack：ばらつき、GC 一時停止、スケジューラジッター | 60ms | — |
| **p99 の合計** | **200ms** | **~90ms** |

バジェットは均等には分割されていません。`tasks` テーブルが大きいため、クエリステージが最大の固定スライスを得ています。エンドポイントがリストを返すため、マーシャリングは無視できないスライスを持ちます。60ms のスラックは意図的なヘッドルームです。他のすべてのスライスが同時に上限に達しても、リクエストはまだ目標値を満たします。スラックが 30ms 未満に低下したとき、チームは p99 アラートを待つのではなくバジェットを見直す必要があるという先行指標として扱います。

<a id="trade-offs-and-constraints--senior-"></a>
### トレードオフと制約  [SENIOR]

バジェットを（公開ハイパースケーラーのエンドポイントが目指す 100ms ではなく）200ms に設定したことは、Meridian の顧客層を反映しています。B2B のタスクリストは、ユーザーがワークスペースに入るときにロードされるものであり、タイトなループ内ではありません。100ms 未満の体感改善は、エンジニアリングコストに対して小さなものです。チームはそのバジェットをより厳しい数字の追求ではなく、より豊富なレスポンス（アサイニーサマリーの埋め込み、直近のアクティビティ数）に費やすことを選びました。設計時に p99 が 200ms を超えると予測される機能は却下されます。バジェット内に収まる機能は、負荷テスト以外のパフォーマンスレビューなしにリリースされます。

このバジェットは**計測しないもの**も意味します。React クライアントが JSON の解析やリストのレンダリングに費やす時間はフロントエンドのバジェットであり、別々に管理されます。境界はレスポンス書き込みです。フロントエンドを助けるために JSON の形状を最適化するバックエンドエンジニアは、バジェット境界をまたいでいることになり、まず連携すべきです。

### 関連セクション

- [persistence-strategy → Indexing Strategy on the Tasks Table](./persistence-strategy.md#indexing-strategy-on-the-tasks-table) を参照してください。50ms クエリスライスを支えるインデックスについて説明しています。
- [operational-awareness → Logging for Ops](./operational-awareness.md#logging-for-ops) を参照してください。このバジェットをランタイムで検証可能にするステージごとのタイミングフィールドについて説明しています。
- [api-design → Cursor-Based Pagination on Task Lists](./api-design.md#cursor-based-pagination-on-task-lists) を参照してください。テーブルが成長してもクエリスライスを限定するページネーションパターンについて説明しています。

---

<a id="n1-on-the-task-list-assignee-lookup"></a>
## タスクリストのアサイニー検索における N+1  [MID]

<a id="first-principles-explanation--junior--1"></a>
### 第一原理からの説明  [JUNIOR]

**N+1 クエリ**は、リクエストが N 件の親行をフェッチするクエリを 1 件発行し、さらに親ごとに関連行をフェッチする N 件の追加クエリを発行するときに発生します。合計クエリ数は結果セットサイズとともに線形に増加し、レイテンシは各クエリが実行する作業ではなく、クエリごとのラウンドトリップコストに支配されるようになります。

修正はほぼ常に**バッチ処理**です。親ごとの N 件のクエリを、すべての親の関連行を一括でロードする単一クエリに置き換え、アプリケーションコードで親子関係を再構成します。単一のラウンドトリップは、同じデータベースへの N 回のラウンドトリップより劇的に安価です。

<a id="idiomatic-variation--mid--1"></a>
### 慣用的なバリエーション  [MID]

Meridian の `GET /v1/workspaces/{wid}/tasks?limit=20` は、各タスクにフラット化された `assignee` オブジェクト（名前、アバター、メール）を付けて返していました。最初の実装は単独では正しく見えましたが、シリアルなループで 1 タスクごとに 1 件のユーザークエリを発行していました。

```go
// service/task.go — 元の実装（N+1）
for _, t := range tasks {
    if t.AssigneeID != nil {
        user, err := s.users.Get(ctx, *t.AssigneeID) // タスクごとに 1 ラウンドトリップ
        if err != nil { return nil, err }
        view.Assignee = &user
    }
    out = append(out, view)
}
```

インメモリモックに対するユニットテストはマイクロ秒で実行されました。200 行のレスポンス（ページネーションが絞られる前のワークスペースの全バックログ）でのステージング負荷テストでは、p99 が 1.4 秒に達しました。当時のバジェットは 250ms でした。1+200 のパターンは、クロス AZ ごとに約 6ms かかる読み取りレプリカへの 201 回のシリアルなラウンドトリップを発行し、何もオーバーラップしませんでした。

修正は、リストクエリが返した後に実行される単一のバッチクエリで、タスクごとの検索を置き換えました。

```go
// service/task.go — 修正後（バッチ処理）
ids := uniqueAssigneeIDs(tasks)
users, err := s.users.GetMany(ctx, ids) // SELECT ... WHERE id = ANY($1)
if err != nil { return nil, err }
byID := indexByID(users)
for _, t := range tasks {
    view := TaskView{Task: t}
    if t.AssigneeID != nil {
        if u, ok := byID[*t.AssigneeID]; ok { view.Assignee = &u }
    }
    out = append(out, view)
}
```

結果セットサイズに関係なく 2 クエリ。バッチクエリは最大 N 人の別々のユーザーを返します（よくあるのは、1 人のアサイニーが複数のタスクを持つため、それより少ない数です）。変更後、p99 は 95ms に低下し、残りのレイテンシは元のリストクエリに支配されるようになりました。

<a id="trade-offs-and-constraints--senior--1"></a>
### トレードオフと制約  [SENIOR]

バッチ修正は、呼び出しコードが後でフィルタリングする場合でも、すべてのアサイニー行をロードします。Meridian のワークロードでは、返されたすべてのタスクはアサイニーとともにレンダリングされるため、過剰フェッチはゼロです。しかし、このパターンは 10,000 タスクを返すエンドポイントにはそのままではスケールしません。ルール：ファンイン数が限られたバッチロード（ページサイズ 20〜100）はシリアルループよりも推奨されます。ファンインが無制限の場合はページネーションまたはチャンクを使用する必要があります。

2 番目のトレードオフ：1 クエリではなく 2 クエリです。`tasks` と `users` の SQL `JOIN` なら 1 ラウンドトリップで全データを返しますが、各ユーザー行が N 回重複します。Meridian のレスポンスサイズでは、無駄な帯域幅コストが 2 番目のラウンドトリップの節約（p99 テストで 2〜3ms）より大きくなります。

検出：すべての新しいエンドポイントは、50 行と 500 行の合成ワークスペースに対する負荷テストを通過します。CI は構造化ログからリクエストごとのクエリ数を抽出し、手動調整されたしきい値（`2 + ceil(rows/100)`）を超えるとビルドを失敗させます。上記のシリアルループのバグは、課金テナントに到達する前にステージングで検出されました。

### 関連セクション

- [persistence-strategy → Postgres + Redis Split](./persistence-strategy.md#postgres--redis-split-what-lives-where) を参照してください。このリストクエリを読み取りレプリカに送るルーティングルールについて説明しています。
- [architecture → Repository Pattern](./architecture.md#repository-pattern) を参照してください。修正がユーザーリポジトリに必要とした `GetMany` メソッドの追加について説明しています。
- [concurrency-and-async → Bounded Parallelism](./concurrency-and-async.md#bounded-parallelism) を参照してください。却下された代替案（タスクごとの検索への並列ゴルーチン）について説明しています。負荷下でプール枯渇を引き起こすコストでレイテンシを修正します。

---

<a id="p50-vs-p99-per-workspace-latency-histograms"></a>
## p50 vs p99：ワークスペースごとのレイテンシヒストグラム  [MID]

<a id="first-principles-explanation--junior--2"></a>
### 第一原理からの説明  [JUNIOR]

「API の平均応答時間は 80ms」という単一の平均レイテンシ数値は分布を隠します。中央値が 50ms だが最悪の 1% が 4 秒かかるサービスと、中央値が 200ms で最悪の 1% が 250ms かかるサービスは同じ平均です。前者は中央値ユーザーは幸せですが非常に不幸なロングテールがあり、後者は一様に凡庸なユーザーがいます。平均はこれを区別できません。

**パーセンタイル**は分布を位置で記述します。p50（中央値）は半分のリクエストが下回るレイテンシです。p99 は 99% のリクエストが下回るレイテンシです。p50、p95、p99 を別々に追跡することで、遅いリクエストがうるさい少数派なのか（p50 が平坦で p99 が上昇）、システム全体の退行なのか（すべてのパーセンタイルが同時に上昇）を見分けられます。

<a id="idiomatic-variation--mid--2"></a>
### 慣用的なバリエーション  [MID]

Meridian はすべての HTTP リクエストを `http_request_duration_seconds` に関する Prometheus ヒストグラムで計測し、ルートとステータスクラスでラベル付けしています。デフォルトのバケットは 5ms から 10s をカバーし、ダッシュボードはルートごとに 5 分間のローリングウィンドウで p50、p95、p99 を表示します。

非自明な計測は、2026 年 Q2 に追加された**ワークスペースごとのディメンション**です。200 席の 1 顧客の `GET /v1/tasks` が 5〜8 秒でタイムアウトし始めていたのに、グローバルダッシュボードは正常な 180ms p99 を示していました。そのワークスペースのトラフィックは全体のごく一部であり、そのテールはグローバルヒストグラムを動かしませんでした。`workspace_id` でバケット化されたヒストグラムを追加する（カーディナリティの関係でデフォルトダッシュボードには表示せず、オンデマンドでクエリ可能）と、そのテナントの p99 が 6.2 秒であることが分かり、バックログサイズが引き起こし始めた特定のテーブルスキャンクエリに原因があることが判明しました。

```go
// observability/metrics.go — バケット同一、ラベルコスト異なる 2 つのヒストグラム
var httpDuration = prometheus.NewHistogramVec(
    prometheus.HistogramOpts{Name: "http_request_duration_seconds", Buckets: prometheus.DefBuckets},
    []string{"route", "status_class"}, // 合計約 80 系列
)
// フラグゲート済み。インシデント対応中のみ有効化。
var httpDurationByWorkspace = prometheus.NewHistogramVec(
    prometheus.HistogramOpts{Name: "http_request_duration_by_workspace_seconds", Buckets: prometheus.DefBuckets},
    []string{"route", "workspace_id"}, // 約 80 × ワークスペース数
)
```

ワークスペースごとのヒストグラムは `obs.per_workspace_latency` の背後にゲートされ、デフォルトではオフです。インシデント中に有効化することでテナントごとの即時内訳が得られ、無効化することでカーディナリティが管理可能な状態に保たれます。カーディナリティのコストは必要なときだけ支払われます。

<a id="trade-offs-and-constraints--senior--2"></a>
### トレードオフと制約  [SENIOR]

パーセンタイルヒストグラムは、バケットごとのコストにすべてのラベルの組み合わせを掛けたものを持ちます。`route × status_class` で約 80 系列になります。同じメトリクスに `workspace_id` を追加すると 80 × 1500 = 120,000 系列となり、チームの Prometheus キャパシティを超えます。フラグゲートされた別メトリクスは、すべての系列にワークスペースラベルを付けることなく、テナント属性ビューに対してパーセンタイルの忠実性を保持します。

受け入れたトレードオフ：ワークスペースごとのメトリクスは常時オンではないため、テナント固有のインシデントの最初の 5〜10 分間は過去データがありません。ランブック手順（フラグを有効化し、バケットが埋まるまで 2 分待つ）が診断クエリの前に置かれています。常時オンの代替案は毎年見直されます。

2 番目の制約：Prometheus のパーセンタイルはバケット境界の近似であり、この範囲での `DefBuckets` でバケット幅（約 10ms）以内の精度です。200ms バジェットの決定においてこれは許容範囲内です。ミリ秒未満の目標にはカスタムの細かいバケットが必要です。

### 関連セクション

- [operational-awareness → Logging for Ops](./operational-awareness.md#logging-for-ops) を参照してください。インシデント対応中にこれらのメトリクスを補完する構造化ログフィールドについて説明しています。
- [architecture → Hexagonal Split](./architecture.md#hexagonal-split) を参照してください。ヒストグラム観測が記録されるミドルウェア層について説明しています。

---

<a id="allocation-discipline-syncpool-for-json-marshal-buffers"></a>
## アロケーション規律：JSON マーシャルバッファへの `sync.Pool`  [SENIOR]

<a id="first-principles-explanation--junior--3"></a>
### 第一原理からの説明  [JUNIOR]

Go のガベージコレクターは並行動作しますが、無料ではありません。各アロケーションはアロケーション時に CPU コストがかかり、将来の GC サイクルへの作業を増やします。ホットパス（Pod あたり毎秒何千回も実行される）では、短命なアロケーションが蓄積して、スパイクとしてではなく一様なオフセットとしてテールレイテンシへの定常的な税金になります。

`sync.Pool` は、リクエストをまたいで短命なオブジェクトを**再利用**するための Go の標準的な仕組みです。ワーカーはプールからオブジェクトを取り出し、使用して、返します。GC はメモリプレッシャー下でプールされたオブジェクトを回収することがありますが、定常状態では同じバッファが何度も再利用されます。このパターンは、大きく、頻繁にアロケーションされ、ゴルーチン境界をまたいで共有されないオブジェクトに適しています。

<a id="idiomatic-variation--mid--3"></a>
### 慣用的なバリエーション  [MID]

Meridian はコードベース全体でただ 1 箇所にのみ `sync.Pool` を使用しています。`GET /v1/tasks` レスポンスライターの JSON マーシャリングバッファです。このエンドポイントはシステムで最も高い QPS を持ちます。各レスポンスはレスポンスライターにフラッシュする前に JSON を組み立てるために `bytes.Buffer` をアロケートします。プロファイリングにより、これらのアロケーションがピークトラフィック中に合計 CPU の約 4% と GC ポーズへの計測可能な寄与をしていることが分かりました。

```go
// handler/encoding.go — レビュー済みの単一プール配置
var jsonBufferPool = sync.Pool{
    New: func() any { return bytes.NewBuffer(make([]byte, 0, 8*1024)) }, // 典型的な ~6KB に合わせて事前サイズ設定
}

func writeJSONList(c *gin.Context, status int, payload any) {
    buf := jsonBufferPool.Get().(*bytes.Buffer)
    buf.Reset()
    defer jsonBufferPool.Put(buf)
    if err := json.NewEncoder(buf).Encode(payload); err != nil {
        c.AbortWithStatus(http.StatusInternalServerError)
        return
    }
    c.Data(status, "application/json", buf.Bytes())
}
```

変更後、マーシャリングステップの GC への寄与は約 0.6% に低下し、エンドポイントの p99 はバジェット内の 15ms マーシャルスライスに対して有意な約 7ms 改善しました。事前サイズ設定された 8KB バッキング配列は、99 パーセンタイルのレスポンスを再拡張なしに収められます。

<a id="trade-offs-and-constraints--senior--3"></a>
### トレードオフと制約  [SENIOR]

`sync.Pool` は、似たようなアロケーション形状を持つ他のエンドポイントがあるにもかかわらず、他のどこでも意図的に**使用されていません**。理由はすべてしきい値に関するものです。

1. **コールドパスでは恩恵がありません。** 5 RPS のエンドポイントはプロファイリングに記録されるほどのアロケーションをしません。ルール：pprof のアロケーションプロファイルにそのサイトがトップ 50 に表示されなければ、プーリングは時期尚早です。
2. **プール再利用のバグは微妙です。** リセットなしに再利用されたプール値はリクエストをまたいでデータをリークします。これはパフォーマンスの退行ではなく、セキュリティ上の発見です。`sync.Pool` を 1 箇所のレビュー済みの場所に限定することで、監査サーフェスが小さく保たれます。
3. **エンドポイントがホットであることを確認しなければなりません。** チームはこのハンドラーが GC の最大寄与者であることを 4 週間の観測ウィンドウで確認して初めて `sync.Pool` を採用しました。ホットに**なるかもしれない**エンドポイントへの予防的なプーリングは却下されました。

受け入れたトレードオフ：新しいエンジニアが理解しなければならない、エンコーディング層の 1 つの珍しいパターン。エンコーディングヘルパーが唯一のコンシューマーです。`encoding.go` に触れないエンジニアはこれに出会いません。

### 関連セクション

- [concurrency-and-async → Goroutine Lifetimes](./concurrency-and-async.md#goroutine-lifetimes) を参照してください。この層で `sync.Pool` を安全にするリクエストごとのゴルーチンモデルについて説明しています（バッファはリクエスト境界をまたぎません）。
- [operational-awareness → Logging for Ops](./operational-awareness.md#logging-for-ops) を参照してください。この最適化が効果を上げ始めた時期を知らせたレイテンシメトリクスとともに公開される GC ポーズヒストグラムについて説明しています。

---

<a id="cache-hit-rate-on-the-workspace-metadata-lookup"></a>
## ワークスペースメタデータ検索のキャッシュヒット率  [MID]

<a id="first-principles-explanation--junior--4"></a>
### 第一原理からの説明  [JUNIOR]

**キャッシュ**は、計算コストの高いデータのコピーを保持し、繰り返しのリクエストが作業をやり直すことなくそれを返せるようにします。ヘッドラインメトリクスは**ヒット率**です。キャッシュから提供されるリクエストの割合です。ヒット率は 2 つの力によって制限されます。ワーキングセットの分布（すべてのリクエストが異なる質問をする場合、キャッシュは役に立ちません）と、無効化ポリシー（エビクトを拒否するとステールデータを提供し、積極的にエビクトするとヒット率が低下します）。どちらもキャッシュキャパシティを追加することでは解決できません。

<a id="idiomatic-variation--mid--4"></a>
### 慣用的なバリエーション  [MID]

Meridian は**ワークスペースメタデータ**（名前、プランティア、メンバー数、フィーチャーフラグ）を 5 分の TTL で Redis にキャッシュしています。このデータはほぼすべてのリクエストで読み込まれます。認証ミドルウェアはプランティアを必要とします。また、めったに変更されません。3 ヶ月の本番稼働後、定常状態のヒット率はチームが当初期待していた 99% ではなく**89%**でした。このギャップは情報を与えてくれます。

11% のミス率の内訳：
- **TTL 期限切れ（約 7%）。** 5 分ごとにすべてのキャッシュエントリが期限切れになり、再ウォームされます。
- **Pod のコールドスタート（約 2%）。** K8s オートスケーリングによる新しい Pod は空のローカルルーティングで開始します。ミスは新しい Pod の最初の 60 秒に集中します。
- **ロングテールのワークスペース（約 2%）。** 1 時間に 1 リクエストしかないワークスペースは、ウォームなキャッシュにヒットすることがありません。訪問の間に TTL が常に期限切れになります。

チームはより高い数値を追い求めて TTL を 1 時間に増やしませんでした。5 分のウィンドウは、管理者がフィーチャーフラグを変更するときに許容できる最長の遅延と一致しています。TTL を延長すると、コストが「Postgres への余分な読み取り」から「ユーザーが 1 時間ステールなフラグを報告する」に移ります。これはより悪いトレードオフです。

```go
// repository/workspace.go — リードスルーキャッシュ、ベストエフォート書き込み
func (r *postgresWorkspaceRepository) GetMetadata(ctx context.Context, id uuid.UUID) (domain.WorkspaceMetadata, error) {
    cacheKey := "ws:meta:" + id.String()
    if cached, err := r.redis.Get(ctx, cacheKey).Bytes(); err == nil {
        var meta domain.WorkspaceMetadata
        if err := json.Unmarshal(cached, &meta); err == nil {
            return meta, nil
        }
        // キャッシュされたバイトのデコード失敗はログに記録され、ミスとして扱われる。
    }
    meta, err := r.loadMetadataFromDB(ctx, id)
    if err != nil { return domain.WorkspaceMetadata{}, err }
    if encoded, err := json.Marshal(meta); err == nil {
        _ = r.redis.Set(ctx, cacheKey, encoded, 5*time.Minute).Err() // ベストエフォート
    }
    return meta, nil
}
```

書き込み時のターゲット無効化（メタデータ更新後に `DEL ws:meta:{id}`）により、既知の変更に対するステールネスウィンドウを 1 キャッシュミスに減らしますが、TTL 駆動の大半のミスに対しては何もしません。ほとんどのミスは単純に、設定されたサイズでキャッシュが本来の仕事をしているだけです。

<a id="trade-offs-and-constraints--senior--4"></a>
### トレードオフと制約  [SENIOR]

チームは良い候補に見えるいくつかの読み取りパスを**キャッシュしません**。

- **タスクリストレスポンス。** キーは workspace_id、カーソル、フィルター、ユーザーごとの権限スコープをエンコードしなければなりません。パーソナライズされたレスポンスはスパースなキースペースを生みます。ほとんどのスロットは期限切れになる前に最大 1 回しかヒットしません。インデックス済みテーブルへのリストクエリは十分に高速であり、キャッシングコストはベネフィットを超えます。
- **個々のタスクのフェッチ。** タスクはスプリント中に頻繁に変更されます。書き込みのたびに無効化すると、読み取りの節約が支配されます。ヒット率は高くなりますが、全体的な負荷は減少しません。

キャッシュを追加する前の基準：読み取りが書き込みより少なくとも 10 倍頻繁であること、レスポンスがキースペースを爆発させる方法でパーソナライズされていないこと、そしてステールネスウィンドウがプロダクトオーナーに受け入れられること。ワークスペースメタデータは 3 つすべてを満たします。タスクコンテンツは 1 つも満たしません。

2 番目の非デフォルト選択：キャッシュはライトスルーではなく**リードスルー**です。書き込み時、アプリケーションは新しい値を Redis に書き込む代わりに、キーを無効化します（`DEL`）。ライトスルーは新しい障害モード（Postgres は成功したが Redis が失敗した場合どうするか）を導入します。無効化を伴うリードスルーは、書き込みごとに 1 回の低速な読み取りを受け入れる代わりに、その問いに答えることを避けます。ベネフィット：書き込みパスに 2 ストアの整合性推論がありません。

### 関連セクション

- [persistence-strategy → Postgres + Redis Split](./persistence-strategy.md#postgres--redis-split-what-lives-where) を参照してください。Redis に置ける状態を管理するルールについて説明しています。
- [operational-awareness → Logging for Ops](./operational-awareness.md#logging-for-ops) を参照してください。メタデータ読み取りレイテンシとともに公開されるキャッシュヒット/ミスカウンターについて説明しています。

---

<a id="prior-understanding-optimize-sql-by-intuition"></a>
## Prior Understanding：直感による SQL の最適化  [MID]

<a id="prior-understanding-revised-2025-11-12"></a>
### Prior Understanding (revised 2025-11-12)

SQL パフォーマンス作業に対する元のガイダンスは次のとおりでした。

> 「クエリが遅いと感じたら、書き直す。よくある書き直し：`IN (...)` を `EXISTS` に変更する、WHERE 句の列にインデックスを追加する、OR 句を UNION に置き換える。」

これは、直感による書き直しが繰り返し退行を引き起こしたために改訂されました。2025 年 11 月のインシデント：エンジニアが上記のルールに従って `IN` サブクエリを `EXISTS` に置き換えました。プランナーは元のものにハッシュセミジョインを使用していましたが、書き直しにより選択性の推定が変わったためにネストループジョインが強制されました。p99 は 70ms から 1.1 秒に退行しました。修正はリバートでした。

**修正後の理解：**

ルールは今や**クエリを変更する前に常に EXPLAIN し、本番相当のデータに対して変更後に常に EXPLAIN ANALYZE する**です。プランナーが選択した実行パスが答えです。どの SQL 形式が速いかについての直感はそうではありません。具体的には：

1. **現在のプランを取得する。** 本番の行数と統計を反映したスナップショットに対して `EXPLAIN (ANALYZE, BUFFERS)` を使用します。1,000 行のローカルデータベースは 5,000 万行のテーブルに対するプランを予測しません。
2. **コストドライバーを特定する。** `actual time` が高いか `loops` が高いノードが最適化のターゲットです。プランツリーの高い位置にある低コストのノードはそうではありません。
3. **1 つの変更を行う。** クエリまたはスキーマのどちらかに変更を加え、再度 EXPLAIN します。複数の同時変更はどれが効いたかを隠します。
4. **本番相当のデータでマージ前に再計測する。**

元の書き直しは時に正しいですが、それはルールではなく戦術です。プランナーが実行パスを決定します。エンジニアの仕事はプランナーが正しい選択をするのに十分な情報を与え、EXPLAIN で検証することです。

### 関連セクション

- [persistence-strategy → Indexing Strategy on the Tasks Table](./persistence-strategy.md#indexing-strategy-on-the-tasks-table) を参照してください。どのインデックスをリリースするかを決定するために使用される EXPLAIN 駆動のプロセスについて説明しています。
- [review-taste → Reviewing Performance Claims](./review-taste.md#reviewing-performance-claims) を参照してください。`tasks` または `task_assignments` テーブルに対するあらゆるクエリ変更について PR 説明に EXPLAIN 出力を要求するコードレビュアーのルールについて説明しています。

---

<a id="coach-illustration-default-vs-hints"></a>
## コーチイラストレーション（default vs. hints）

> **例示のみ。** 2 つのコーチングスタイルの違いを示した実例です。ライブエージェントのコントラクトの一部ではありません。実際のエージェントの動作は `.claude/skills/learn/coach-styles/` のスタイルファイルによって管理されます。

**シナリオ：** 学習者がステージングで `GET /v1/workspaces/{wid}/tasks` の p99 レイテンシが 850ms を示していることを報告します。Meridian の 200ms バジェットを大きく超えており、エージェントに調査と修正を依頼します。

**`default` スタイル** — エージェントはバジェット分解を説明し、スロークエリログと `pgxpool` 統計を要求し、アサイニー検索に新たに再導入された N+1 を特定し、バッチ修正（1 件の `GetMany` 呼び出し）を実装し、負荷テストのクエリ数しきい値を更新して、退行が解消されたことを確認するためにテストを実行します。レイテンシバジェットフレームワーク、N+1 検出、バッチ修正パターンを説明する `## Learning:` トレーラーを追記します。

**`hints` スタイル** — エージェントは拡大したバジェットスライス（アサイニー検索）を特定し、パターンに名前を付け（N+1 クエリ）、バッチ検索が属する場所をコメントでマークしたサービスメソッドのスキャフォールドを書きます。それから以下を出力します。

```
## Coach: hint
Step: Replace the per-task assignee lookup in TaskService.ListWithAssignees with a
single batched query.
Pattern: N+1 query → batch SELECT (collect distinct IDs, one query, index by ID).
Rationale: With limit=20, the current code issues 21 serial round trips; cross-AZ
round trips dominate latency. SELECT ... WHERE id = ANY($1) replaces 20 trips with
one. EXPLAIN the batch query against production-shaped data before merging.
```

`<!-- coach:hints stop -->`

学習者が `GetMany` 呼び出し、重複排除ヘルパー、ID によるインデックスループを書きます。次のターンで、エージェントはスキャフォールドを再書き込みせずにフォローアップの質問（リストクエリとバッチフェッチの間に削除されたアサイニーなど）に応答します。
