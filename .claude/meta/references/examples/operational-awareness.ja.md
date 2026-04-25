> このドキュメントは `.claude/meta/references/examples/operational-awareness.md` の日本語訳です。英語版が原文（Source of Truth）です。

---
domain: operational-awareness
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: devops-engineer
contributing-agents: [devops-engineer]
---

> **読み取り専用リファレンス。** このファイルは ECC Base Template に同梱された実装例であり、実際のプロジェクトの多くのセッションを経て積み上がったナレッジファイルがどのような姿になるかを示しています。これはあなた自身のナレッジファイルでは**ありません**。あなた自身のナレッジファイルは `.claude/learn/knowledge/operational-awareness.md` にあり、実際の作業においてエージェントが内容を拡充するまでは空の状態です。エージェントは `.claude/meta/references/examples/` 配下のファイルを読み込んだり、引用したり、書き込んだりすることは一切ありません。このツリーは人間の読者専用です。設計の背景については [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) を参照してください。

> **ナレッジドメイン**: `.claude/learn/knowledge/operational-awareness.md`

---

<a id="how-to-read-this-file"></a>
## このファイルの読み方

各セクションのレベルマーカーは想定読者を示しています。
- `[JUNIOR]` — 第一原理からの説明。事前知識を前提としません。
- `[MID]` — このスタックにおける、一見しただけでは気づきにくい慣用的な応用。
- `[SENIOR]` — デフォルト以外のトレードオフの評価。何を諦めるかを明示します。

---

<a id="three-pillar-observability-logs-metrics-and-traces"></a>
## 3 本柱のオブザーバビリティ：ログ、メトリクス、トレース  [JUNIOR]

<a id="first-principles-explanation--junior-"></a>
### 第一原理からの説明  [JUNIOR]

本番稼働中のサービスはブラックボックスです。エンジニアが常時監視することはありません。サービスが何をしているか、インシデント中に何をしていたかを知る唯一の方法は、サービスが出力するシグナルを通じてです。3 種類のシグナルタイプが存在し、それぞれが異なる問いに答えます。

**ログ**は個別のイベントを記録します。リクエストが受信された。エラーが返された。バックグラウンドジョブが完了した。ログは「何が起きたか、どの順序で？」に答えます。ログエントリは、エンジニアが含めることを選択したコンテキストとともに、何かが起きた瞬間を捉えます。ログの弱点は、大量になるとストレージと検索に費用がかかることと、集計（「直近 5 分間で 500ms 以上かかったリクエストは何件？」）に弱いことです。

**メトリクス**は時間の経過に伴う数値的な計測を記録します。リクエストレート、レイテンシのパーセンタイル、エラーレート、キューの深さ、メモリ使用量。メトリクスは「システムは今どのように動作していて、それはどう変化したか？」に答えます。メトリクスは効率的なストレージ（時系列データベースは繰り返しの数値サンプルをうまく圧縮する）と効率的なクエリ（事前集計済み）を持ちます。メトリクスの弱点は、個々のイベントコンテキストを失うことです。p99 レイテンシのスパイクはエンジニアに何かが遅いことを告げますが、どのリクエストが遅いかや理由は教えてくれません。

**トレース**は、複数のサービスやコンポーネントを通じた単一リクエストのパスを記録します。各ステップは**スパン**です。名前、開始時刻、終了時刻、キーバリュー属性を持つ名前付き操作です。トレースはスパンのツリーです。トレースは「この特定のリクエストはどこで時間を費やし、システムをどのように流れたか？」に答えます。トレースの弱点は、すべてのリクエストをキャプチャするのが高コストすぎることです。実際には、リクエストのサンプルだけがトレースされます。

3 つの柱のどれも他を置き換えられません。レイテンシスパイク（メトリクス）はエンジニアがトレースを見てどのリクエストパスが遅いかを見つけるように促します。トレースはリポジトリクエリを指します。ログはクエリがロックにヒットしていることを示します。3 本柱は相関させるときに最も役立ちます。トレース ID がログ行に現れ、ログ行が最初に異常を浮かび上がらせたメトリクスを指し示す場合です。

<a id="idiomatic-variation--mid-"></a>
### 慣用的なバリエーション  [MID]

Meridian のオブザーバビリティスタックは各柱を特定の技術にマッピングしています。

| 柱 | 技術 | シグナルの送信先 |
|--------|-----------|-----------------|
| 構造化ログ | `uber-go/zap` | Loki（各 K8s ノードの Promtail 経由） |
| メトリクス | Prometheus クライアント（`prometheus/client_golang`） | Prometheus（15 秒間隔でスクレイプ） |
| トレース | OpenTelemetry SDK → Jaeger | Jaeger（OTLP エクスポーター経由） |

**zap によるログ。** Meridian は `zap.Logger` を構造化モードで使用します。すべてのログ呼び出しは人間が読める文字列ではなく JSON オブジェクトを出力します。フィールドはキーバリューペアであり、補間されたテキストではありません。これが構造化ログと `fmt.Println` を分けるものです。ログはマシン読み取り可能であるため、Loki はメッセージテキスト全体をスキャンすることなく任意のフィールドでフィルタリングや集計ができます。

```go
// internal/middleware/logger.go — リクエストロギングミドルウェア
func RequestLogger(log *zap.Logger) gin.HandlerFunc {
    return func(c *gin.Context) {
        start := time.Now()
        c.Next()
        log.Info("request completed",
            zap.String("method", c.Request.Method),
            zap.String("path", c.FullPath()),
            zap.String("trace_id", traceIDFromContext(c.Request.Context())),
            zap.Int("status", c.Writer.Status()),
            zap.Duration("latency", time.Since(start)),
            zap.String("workspace_id", workspaceIDFromContext(c.Request.Context())),
        )
    }
}
```

`trace_id` フィールドは相関アンカーです。Loki クエリは `trace_id` でフィルタリングして特定のリクエストの完全なログシーケンスを返せます。同じ ID を Jaeger に貼り付ければ、同じリクエストのトレースツリーを表示できます。

**Prometheus によるメトリクス。** Meridian は Prometheus の Go クライアントを通じて `/metrics` エンドポイントを公開しており、クラスタ内の Prometheus インスタンスがスクレイプします。Gin の HTTP メトリクス（リクエスト数、期間ヒストグラム、アクティブコネクション）は `internal/metrics/http.go` に登録されています。ドメイン固有のゲージ（プールコネクション数、Redis パイプラインキューの深さ）も同様に登録されています。Prometheus は 15 秒ごとにスクレイプし、アラートは Prometheus が計算するメトリクスで発火します。ログ由来のクエリでは発火しません。これは重要です。ログベースのアラート（ログクエリからのアラート）は低速でコストが高く、メトリクスベースのアラートは高速で安価です。

**OpenTelemetry によるトレース。** Meridian は起動時に OTel Go SDK を初期化し、Jaeger OTLP エクスポーターを登録します。トレースコンテキストは、受信 HTTP リクエストの W3C `traceparent` ヘッダーを経由して Go の `context.Context` を通じて伝播します。ミドルウェアは到着時に `traceparent` を抽出してトレースを作成または継続します。

```go
// cmd/server/main.go — OTel 初期化（簡略版）
func initTracer(cfg config.Telemetry) (func(context.Context) error, error) {
    exp, err := otlptracehttp.New(context.Background(),
        otlptracehttp.WithEndpoint(cfg.JaegerEndpoint),
        otlptracehttp.WithInsecure(),
    )
    if err != nil {
        return nil, err
    }
    tp := trace.NewTracerProvider(
        trace.WithBatcher(exp),
        trace.WithSampler(trace.TraceIDRatioBased(cfg.SampleRate)), // 本番では 0.1
    )
    otel.SetTracerProvider(tp)
    otel.SetTextMapPropagator(propagation.TraceContext{})
    return tp.Shutdown, nil
}
```

0.1（10%）のサンプルレートは意図的なトレードオフです。Meridian のボリュームですべてのリクエストをトレースすると、月間約 2 TB のトレースデータが生成されます。10% サンプリングにより、ほとんどのリクエストパスタイプの統計的カバレッジを維持しながら、管理可能な 200 GB に削減されます。トレースサンプリングについては、以下のトレードオフセクションで詳しく説明します。

<a id="trade-offs-and-constraints--senior-"></a>
### トレードオフと制約  [SENIOR]

**ログからメトリクスを導出するという罠。** よくある誤りは、ログのボリュームから運用メトリクスを導出することです。「ERROR」を含むログ行を数え、その数がしきい値を超えるとアラートを発します。このパターンは高コスト（同じデータレートでログストレージはメトリクスストレージの 5〜10 倍）で低速（ログクエリは事前集計された数値時系列ではなく生テキストをスキャンする）で不正確（ログレベルは一貫性なく適用される。単一の誤分類されたログレベルがアラートを歪める）です。Meridian のルール：**アラートは Prometheus メトリクスで発火し、ログクエリでは発火しません。** ログはドリルダウンツールであって、検出サーフェスではありません。アーキテクチャ上の強制：alertmanager の設定にある Loki ベースのアラートは、メトリクスとして表現することが構造的に不可能なもの（メトリクスカウンターに関連付けられていない特定のエラーメッセージテキストへのアラートなど）のみです。

**サンプリングによってレアなリクエストがトレースレコードから削除されます。** 10% サンプリングでは、90% のリクエストはトレースを生成しません。これは一般的なリクエストパスには許容できます（`GET /v1/tasks` のサンプルは多くある）が、レアまたは断続的なエラーパスがトレースに表現されない可能性があります。Meridian はこれを**優先サンプリング**で軽減しています。2xx 以外のレスポンスを返すリクエストは、基本サンプルレートに関係なく常にトレースされます。これは OTel プロバイダーのカスタムサンプラーを通じて設定されており、リクエストが完了した後のスパンステータスをチェックします。

```go
// internal/telemetry/sampler.go
type errorForcedSampler struct {
    base trace.Sampler
}

func (s *errorForcedSampler) ShouldSample(p trace.SamplingParameters) trace.SamplingResult {
    // ハンドラーが設定したエラー属性を持つスパンを常に収集する
    if _, ok := p.Attributes.Value(attribute.Key("http.status_code")); ok {
        // スパン終了時に評価。5xx レスポンスを強制サンプル
        // （実際の実装は Sampler ではなく SpanProcessor にフックする）
    }
    return s.base.ShouldSample(p)
}
```

実質的な効果：通常トラフィックは 10% でサンプリングされ、エラートラフィックは 100% でサンプリングされます。インシデントを調査するエンジニアは、すべての障害パスの完全なトレースレコードを持ちます。

### 関連セクション

- [persistence-strategy → Connection Pooling with pgxpool](./persistence-strategy.md#connection-pooling-with-pgxpool) を参照してください。Prometheus に公開されてプール飽和シグナルとして使用される `pgxpool.Stat()` メトリクスについて説明しています。
- [error-handling → Domain Error Type Hierarchy](./error-handling.md#domain-error-type-hierarchy) を参照してください。ドメインエラータイプがメトリクスラベルにどう接続されるかについて説明しています（各メトリクスデータポイントの HTTP ステータスコードはドメインエラーの `HTTPStatus()` メソッドから導出されます）。
- [operational-awareness → SLO Design and Error Budget Management](#slo-design-and-error-budget-management) を参照してください。ここで生成されるレイテンシメトリクスが SLO バーンレートアラートにどのようにフィードするかについて説明しています。

---

<a id="slo-design-and-error-budget-management"></a>
## SLO 設計とエラーバジェット管理  [MID]

<a id="first-principles-explanation--junior--1"></a>
### 第一原理からの説明  [JUNIOR]

**サービスレベル目標（SLO）**は、サービスの特定の品質ディメンション（可用性、レイテンシ、エラーレート）に対するターゲットであり、ローリングウィンドウの割合として表されます。30 日間の 99.9% 可用性 SLO は、そのウィンドウの最大 0.1%、つまり月あたり約 43 分だけサービスが利用不可であることが許容されることを意味します。

利用不可であることが許容される 0.1% が**エラーバジェット**です。エラーバジェットは最大化すべきターゲットではなく、リスクプールです。バジェットが満杯のとき（今月はインシデントなし）、チームはより積極的にデプロイして多くのリスクを取ることができます。バジェットがほぼ枯渇しているとき、チームはリスクの高い変更を凍結して信頼性向上の作業に投資すべきです。エラーバジェットは速度と信頼性の間の緊張を明示的かつ計測可能にします。

SLO は**サービスレベル指標（SLI）**を必要とします。実際に計測するメトリクスです。可用性 SLI：成功レスポンスの総レスポンスに対する比率。レイテンシ SLI：指定した時間しきい値内に完了するリクエストの割合。

<a id="idiomatic-variation--mid--1"></a>
### 慣用的なバリエーション  [MID]

Meridian はコア API サーフェスに 2 つの SLO を維持しています。

**SLO-1：`GET /v1/tasks` の可用性**
- SLI：`(成功リクエスト数) / (総リクエスト数)`（成功は HTTP 2xx または 3xx）
- ターゲット：30 日ローリングウィンドウで 99.9%
- エラーバジェット：月間合計ダウンタイムの約 43 分

**SLO-2：`POST /v1/tasks` のレイテンシ**
- SLI：1,000ms 以内に完了する書き込みリクエストの割合
- ターゲット：30 日ローリングウィンドウで 99.5%
- エラーバジェット：書き込みリクエストの 0.5% が 1,000ms を超えることが許容される

書き込み SLO は読み取り SLO より緩くなっています（99.5% vs 99.9%）。書き込みはより多くのインフラを経由するからです。pgxpool コネクション、Postgres プライマリ（書き込みはレプリカに行けない）、Redis の冪等性キー、Slack 通知のファンアウト。各ホップがレイテンシのばらつきを増やします。書き込みに読み取りと同じ SLO を設定すると、エラーバジェットは本物の信頼性問題ではなく、想定内の書き込みパスのばらつきによって消費されます。これはシグナルノイズ比の問題です。

SLO は Prometheus のレコーディングルールとアラートマネージャー設定のバーンレートアラートとして表現されています。

```yaml
# prometheus/rules/slo-tasks.yaml
groups:
  - name: slo_tasks_availability
    rules:
      # SLI：リクエスト成功率（アラート用 5 分ローリングウィンドウ）
      - record: meridian:task_read:success_rate5m
        expr: |
          sum(rate(http_requests_total{handler="GET /v1/tasks",code=~"2.."}[5m]))
          /
          sum(rate(http_requests_total{handler="GET /v1/tasks"}[5m]))

      # バーンレートアラート：エラーバジェットが SLO の許容する速度の 14.4 倍で消費されると、
      # 2 時間でバジェットが尽きる。直ちにページング。
      - alert: TaskReadSLOCriticalBurn
        expr: |
          (1 - meridian:task_read:success_rate5m) > (14.4 * 0.001)
        for: 2m
        labels:
          severity: page
          slo: task_read_availability
        annotations:
          summary: "SLO critical burn: task read availability"
          description: >
            Error rate {{ $value | humanizePercentage }} is burning the 30-day error budget
            at 14.4x the sustainable rate. Runbook: https://runbooks.meridian.internal/slo/task-read
          runbook_url: "https://runbooks.meridian.internal/slo/task-read"
```

**14.4x バーンレート**は Google SRE ワークブックのマルチウィンドウ、マルチバーンレートアラートヒューリスティックです。通常のエラーレートの 14.4 倍では、残りの月次エラーバジェットが約 2 時間で枯渇します。これが即時ページングのしきい値です。より遅いバーンレート（1x〜5x）は、エンジニアを起こさないチケット優先度アラートを発火させます。

<a id="trade-offs-and-constraints--senior--1"></a>
### トレードオフと制約  [SENIOR]

**SLO ウィンドウの選択は目標パーセンテージの選択より重要です。** 30 日ローリングウィンドウは、29 日前のインシデントが今日のエラーバジェット残高に影響することを意味します。7 日ウィンドウはより速く回復しますが、短期的なばらつきに対してより敏感です。Meridian が 30 日を使うのは、販売サイクルが月次であり、顧客が請求期間にわたって信頼性を評価するためです。異なるウィンドウは SLO ツールのシグナルと顧客が実際に感じるシグナルの間にミスマッチを生じさせます。

**締め付けすぎた SLO は誤った教訓を教えます。** 実際に 99.9% を達成しているサービスに対して 99.99% の SLO を設定すると、エラーバジェットは常に枯渇していて、あらゆる変更がリスクに見えます。チームの行動はそれに応じて変わります。デプロイが減り、変更への恐れが増します。Meridian の 99.9% ターゲットは 12 ヶ月の過去のアップタイムを分析し、過去のパフォーマンスの 10 パーセンタイルに SLO を設定することで導かれました。本物の品質基準を表すのに十分な締め付けさであり、通常のばらつきがバジェットを消費しないほど緩くなっています。ターゲットは年次で見直されます。

### 関連セクション

- [operational-awareness → Alerting Without On-Call Burnout](#alerting-without-on-call-burnout) を参照してください。これらの SLO バーンレートルールを消費する完全なアラートルーティング設定について説明しています。
- [release-and-deployment → Blast-Radius Reasoning Before Changes](#blast-radius-reasoning-before-changes) を参照してください。エラーバジェット残高がデプロイリスク決定をゲートする方法について説明しています。
- [performance-intuition → Latency Budgets](./performance-intuition.md) を参照してください。1,000ms の書き込みレイテンシ SLO しきい値を導いたホップごとのレイテンシ分析について説明しています。

---

<a id="alerting-without-on-call-burnout"></a>
## オンコールバーンアウトなしのアラート  [MID]

<a id="first-principles-explanation--junior--2"></a>
### 第一原理からの説明  [JUNIOR]

アラートはメトリクスがしきい値を超えるとエンジニアを起こします。エンジニアが何も行動できない場合、つまりメトリクスが情報提供のみ、状態が自己解決する、またはしきい値が低すぎる場合、そのアラートはノイズです。繰り返しのノイズはエンジニアにアラートを無視するよう訓練します。本当のインシデントが同じように見えるアラートを発生させたとき、それも無視されます。アラート疲労が結果です。アラートシステムはシグナル価値を失います。

2 つの原則がアラート疲労を軽減します。

**症状でアラートし、原因でアラートしない。** 症状はユーザーが体験するもの：高レイテンシ、高エラーレート、可用性の低下。原因はシステム内のもの：CPU 使用率、コネクション数、キューの深さ。原因は症状の貧しい予測子であることが多いです。CPU はユーザー体感レイテンシを引き起こすことなくスパイクすることがあり、コネクション数はエラーを引き起こすことなく高くなることがあります。原因でアラートすると偽陽性率が高くなります。症状（SLI の低下）でアラートし、アラートが発火したら原因を調査してください。

**ランブックなしのアラートはありません。** すべてのアラートは、状態を調査して解決するための文書化された手順にリンクする `runbook_url` アノテーションを含まなければなりません。ランブックのないアラートは、オンコールエンジニアにプレッシャー下で即興を強います。これは文書化された手順に従うよりも遅く信頼性が低くなります。アラートがランブックに関連付けられない理由が「待ってみよう」であれば、そのアラートはページでなくチケットであるべきです。

<a id="idiomatic-variation--mid--2"></a>
### 慣用的なバリエーション  [MID]

Meridian のアラート哲学、優先度順：

1. **SLO バーンレートアラート**（上記参照）は主要なページングサーフェスです。症状でアラートします。SLI がエラーバジェットを枯渇させるレートで低下しています。

2. **飽和アラート**は二次的であり、ページでなくチケットを生成します。SLI が低下する前にリソースが枯渇に近づいており、介入が必要なときに発火します。

```yaml
# prometheus/rules/saturation.yaml
groups:
  - name: meridian_saturation
    rules:
      # pgxpool コネクション飽和 — プールが枯渇する前にアラート
      - alert: PgxpoolHighAcquireLatency
        expr: |
          histogram_quantile(0.95,
            rate(pgxpool_acquire_duration_seconds_bucket[5m])
          ) > 0.1
        for: 5m
        labels:
          severity: ticket
          component: postgres
        annotations:
          summary: "pgxpool acquire p95 > 100ms"
          description: >
            The connection pool is slow to hand out connections. Current p95 acquire
            time: {{ $value | humanizeDuration }}. Runbook: /runbooks/postgres/pool-saturation
          runbook_url: "https://runbooks.meridian.internal/postgres/pool-saturation"

      # Redis メモリ飽和
      - alert: RedisMemoryHighWatermark
        expr: |
          redis_memory_used_bytes / redis_memory_max_bytes > 0.85
        for: 10m
        labels:
          severity: ticket
          component: redis
        annotations:
          summary: "Redis memory > 85% of max"
          runbook_url: "https://runbooks.meridian.internal/redis/memory-saturation"
```

3. **不在アラート**はシグナルが沈黙するときを検出します。これは多くの場合、シグナルが不良な値を示すよりも悪い状態です。Prometheus の `absent()` アラートは、Pod がメトリクスの出力を完全に停止したときに発火します。

```yaml
      - alert: NoTaskMetricsReceived
        expr: absent(http_requests_total{handler="GET /v1/tasks"})
        for: 3m
        labels:
          severity: page
        annotations:
          summary: "No metrics from task read endpoint for 3 minutes"
          description: "Either all pods are down or the metrics pipeline has broken."
          runbook_url: "https://runbooks.meridian.internal/metrics/absent"
```

**ランブックコントラクト。** すべてのアラートアノテーションは `runbook_url` を持ちます。その URL のランブックには：(1) アラートが意味することの 1 段落の説明、(2) 最初に実行する 3 つの診断コマンド、(3) 最も一般的な原因とそれぞれの確認方法、(4) 修正手順が含まれます。新しいアラートはランブックなしにマージされません。CI パイプラインは `prometheus/rules/` 内のすべてのアラートルールが `runbook_url` アノテーションを持つことを確認します。

<a id="trade-offs-and-constraints--senior--2"></a>
### トレードオフと制約  [SENIOR]

**CPU とメモリのアラートは Meridian ではページングアラートではありません。** これはレガシーの運用慣行からの意図的な逸脱です。高い CPU は自動的にユーザーへの影響を意味しません。サービスはオートスケールしたか、スパイクが一時的か、またはメトリクスが misleading です（CPU には Go の GC プレッシャーが含まれており、ユーザーレイテンシに線形にはマッピングされません）。Go サービスでの高いメモリは多くの場合、リークではなく GC がまだ実行されていないことを示します。CPU やメモリでエンジニアをページングしても、MTTR を改善せずに疲労を生み出します。正しいシグナルは SLI（レイテンシ、エラーレート）です。飽和メトリクスはページングではなくキャパシティプランニングのために存在します。

この選択のコスト：プール枯渇インシデントの最中で、飽和アラート（ページでなくチケットだった）を見ていないエンジニアは、飽和ダッシュボードを積極的に見る必要があります。SLO バーンレートアラートのランブックは調査シーケンスのステップ 2 として「飽和ダッシュボードを確認する」を含んでいるため、情報は別のページなしに利用可能です。

### 関連セクション

- [operational-awareness → SLO Design and Error Budget Management](#slo-design-and-error-budget-management) を参照してください。これらのルールが補完する SLO バーンレートアラート設定について説明しています。
- [operational-awareness → The pgxpool Exhaustion Incident](#prior-understanding-logging-everything-at-info-level-and-the-pgxpool-exhaustion-incident) を参照してください。飽和アラート（チケット重大度）が SLO バーンレートアラート（ページ重大度）の前に実際に発火したシナリオについて説明しています。

---

<a id="tracing-the-slack-webhook-fanout"></a>
## Slack Webhook ファンアウトのトレース  [MID]

<a id="first-principles-explanation--junior--3"></a>
### 第一原理からの説明  [JUNIOR]

分散トレースは、単一リクエストがコンポーネントを移動する際のパスを記録します。各コンポーネントは**スパン**を作成します。開始時刻、終了時刻、属性を持つ名前付きの作業単位です。スパンはツリーで接続されています。ルートスパンは受信 HTTP リクエストで、子スパンはそのリクエストがトリガーする操作です。トレースツリーによって、単一リクエストについて、各ステップでどのように時間が費やされ、どの順序で行われたかを正確に見ることができます。

ログではこれができません。ログ行は 1 つのコンポーネントの 1 つの瞬間に何が起きたかをエンジニアに伝えます。同じリクエストが 5 つのコンポーネントに触れると、エンジニアはトレース ID で 5 つのログ行を相関させ、頭の中でシーケンスを再構成し、タイムスタンプからデュレーションを推定する必要があります。トレースはこれらすべてを自動的に、構造化されて、視覚的に提供します。

<a id="idiomatic-variation--mid--3"></a>
### 慣用的なバリエーション  [MID]

Meridian の Slack webhook は受信エンドポイントです。Slack はワークスペースインテグレーションがイベントを発火するとき（例：タスクが Slack チャネルでメンションされたとき）に HTTP POST リクエストを送信します。リクエストパスは次のとおりです。

```
Slack → POST /v1/webhooks/slack → handler → 冪等性チェック（Redis） →
イベントサービス → タスクリポジトリ（Postgres） → 通知ファンアウト
                                                    ├── Slack 送信 API コール
                                                    └── アプリ内通知（Postgres 書き込み）
```

各ステップはスパンとして計測されます。Jaeger のトレースツリーは次のようになります。

```
[ROOT] POST /v1/webhooks/slack                        147ms total
  ├── [SPAN] idempotency.CheckAndRecord               3ms
  │     attrs: redis.command=SET, idempotency_key=evt_01HX...
  │     result: first_seen=true
  ├── [SPAN] event.ProcessSlackEvent                  138ms
  │     attrs: event_type=message.mentioned, workspace_id=ws_abc
  │     ├── [SPAN] task.repository.GetByExternalRef   12ms
  │     │     attrs: db.statement=SELECT tasks WHERE..., db.rows_affected=1
  │     ├── [SPAN] notification.fanout                122ms
  │     │     ├── [SPAN] slack.PostMessage            118ms  ← 最も遅い子スパン
  │     │     │     attrs: slack.channel=#ops, http.status_code=200
  │     │     └── [SPAN] notification.repository.Create  4ms
  │     │           attrs: db.statement=INSERT INTO notifications...
  └── [SPAN] response.write                           2ms
```

トレースは、Slack の送信 API コールが合計 147ms のうち 118ms を消費したことを即座に明らかにします。これはタイムスタンプ算術なしにログから見ることはできず、メトリクスからも見えません（メトリクスはすべてのリクエストにわたって集計されます。リクエストごとのメトリクスはありません）。トレースは、ログとメトリクスが答えられない問いに答えます。この特定のリクエストで、時間はどこに行ったか？

Go での計測コードは OTel Go API を直接使用します。

```go
// service/notification.go — スパン付き通知ファンアウト
func (s *notificationService) Fanout(ctx context.Context, event domain.SlackEvent) error {
    ctx, span := otel.Tracer("meridian").Start(ctx, "notification.fanout")
    defer span.End()

    // Slack 送信コール
    slackCtx, slackSpan := otel.Tracer("meridian").Start(ctx, "slack.PostMessage")
    err := s.slackClient.PostMessage(slackCtx, event.Channel, formatMessage(event))
    if err != nil {
        slackSpan.RecordError(err)
        slackSpan.SetStatus(codes.Error, err.Error())
    }
    slackSpan.End()

    // アプリ内通知書き込み
    notifCtx, notifSpan := otel.Tracer("meridian").Start(ctx, "notification.repository.Create")
    if writeErr := s.notifRepo.Create(notifCtx, event); writeErr != nil {
        notifSpan.RecordError(writeErr)
    }
    notifSpan.End()

    return err
}
```

ログだけでは見逃すものをトレースが浮かび上がらせる点：

- **並行処理の可視性**：Slack コールと通知書き込みが並行していた場合、トレースはオーバーラップするスパンを示します。ログは明確な並行構造なしに交互に並んだ行を示すだけです。
- **帰属**：118ms は「webhook ハンドラーが遅かった」のではなく、具体的に `slack.PostMessage` に帰属しています。
- **エラーコンテキスト**：失敗したスパンには、トレースツリーの正確な障害発生地点に関連付けられた完全なエラーメッセージとスタックを含むエラーイベントが添付されます。

<a id="trade-offs-and-constraints--senior--3"></a>
### トレードオフと制約  [SENIOR]

すべてのスパンを `otel.Tracer("meridian").Start(...)` と `defer span.End()` で手動計測すると、すべてのサービスメソッドにボイラープレートが追加されます。代替案（HTTP ハンドラー呼び出し全体をラップする自動計測ミドルウェア）はルートスパンをキャプチャしますが、内部スパンツリーを見逃します。Meridian の選択は、サービスとリポジトリメソッドには明示的な計測を使用し、Gin の HTTP 層と pgx データベースドライバー（OTel フックを持つ）には自動計測を使用することです。pgx OTel インテグレーションによって、リポジトリ内の手動計測なしにすべての SQL クエリがスパンとして現れます。

明示的計測のコスト：新しいコードが書かれるとき、スパンを意識的に追加しなければなりません。計測されていないコードパスは Jaeger では見えません。強制メカニズムはオンコールランブックです。「期待するトレースツリーのステップが欠けている場合は計測する」は、インシデントポストモーテムテンプレートの常設アクションアイテムです。

### 関連セクション

- [error-handling → Idempotent Retry on the Slack Webhook](./error-handling.md#idempotent-retry-on-the-slack-webhook) を参照してください。上記のトレースツリーの最初のスパンを支える Redis `SET NX` 冪等性チェックについて説明しています。
- [architecture → Cross-Cutting Concern: Notifications](./architecture.md#cross-cutting-concern-notifications) を参照してください。通知ファンアウトスパンが存在するサービス層の設計について説明しています。
- [operational-awareness → Three-Pillar Observability](#three-pillar-observability-logs-metrics-and-traces) を参照してください。上記のスパンで使用されるトレーサーを支える OTel 初期化について説明しています。

---

<a id="blast-radius-reasoning-before-changes"></a>
## 変更前のブラストラジウス推論  [SENIOR]

<a id="first-principles-explanation--junior--4"></a>
### 第一原理からの説明  [JUNIOR]

本番システムへのすべての変更はリスクを伴います。変更の**ブラストラジウス**は、変更が失敗した場合の被害の範囲です。どのユーザーが影響を受けるか、どの機能が壊れるか、そしてシステムを既知の良好な状態に戻すためにどれだけ速く回復できるか。ブラストラジウス推論は、変更が適用された後ではなく、変更が適用される前にこのスコープを推定して制限する規律です。

ブラストラジウスが大きい変更はすべてのユーザーに影響し、重要な機能を壊し、ロールバックに何時間もかかります。ブラストラジウスが小さい変更はユーザーのサブセットに影響し、クリティカルでないパスを劣化させ、秒単位でロールバックできます。目標は、ブラストラジウスが大きいすべての変更を排除することではありません（必要な変更の中には本来的に広いものがあります）。変更のスコープを理解し、文書化されたロールバックパスを持った上で進むことを確保することです。

<a id="idiomatic-variation--mid--4"></a>
### 慣用的なバリエーション  [MID]

Meridian のデプロイプロセスは、本番 Kubernetes クラスター、データベーススキーマ、または外部サービス設定に触れるすべての変更について「ブラストラジウスチェックリスト」の完了を要求します。チェックリストは官僚的なゲートではなく、PR の説明に記録された 5 分間の構造化された思考演習です。

**Meridian ブラストラジウスチェックリスト：**

```
## Blast-Radius Assessment

### Scope
- [ ] Which API endpoints or features does this change affect?
- [ ] What fraction of the active tenant population is affected?
      (All tenants / specific plan tier / specific workspace IDs)

### Failure Mode
- [ ] If this change fails silently, what is the user-visible symptom?
- [ ] If this change fails loudly (panic, crash), what is the user-visible symptom?
- [ ] Is the failure mode reversible without data loss?

### Rollback
- [ ] Rollback mechanism: K8s rollout undo / feature flag / migration revert
- [ ] Estimated time to rollback: ___
- [ ] If the rollback fails, what is the manual recovery path?

### Deployment Window
- [ ] Safe to deploy during business hours?
- [ ] Does this change require maintenance mode or a traffic blackout?
- [ ] Who is on-call and aware this is deploying?
```

5,000 万行の tasks テーブルに対するスキーママイグレーションはブラストラジウスが大きい（全テナント）ですが、既知のロールバックパス（[persistence-strategy → Online Migrations](./persistence-strategy.md#online-migrations-on-the-50m-row-tasks-table) からの 2 デプロイ列削除シーケンス）があります。Slack 通知アダプターへの変更はブラストラジウスが小さく（通知配信のみ、タスクアサインフローでは非ブロッキング）、K8s のロールアウト取り消しで即座にロールバックできます。チェックリストはこの違いを明示して記録します。

**Kubernetes 設定のデプロイセーフティネット：**

```yaml
# k8s/deployment.yaml — セーフティネット設定
spec:
  replicas: 6
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2          # ロールアウト中の最大余分な Pod 数
      maxUnavailable: 0    # 交換先が Ready になるまで Pod を削除しない
  minReadySeconds: 30      # 新しい Pod は次のステップの前に 30 秒健全でなければならない
  template:
    spec:
      containers:
        - name: api
          readinessProbe:
            httpGet:
              path: /healthz/ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 3    # 3 回連続失敗後 LB から除外
          lifeycleHooks:
            preStop:
              exec:
                command: ["sleep", "5"]  # SIGTERM 前に進行中リクエストをドレイン
```

`maxUnavailable: 0` は通常のデプロイ中にゼロダウンタイムを確保します。ローリングアップデートは新しい Pod を追加し、30 秒連続でレディネスプローブに合格するのを待ってから、古い Pod を 1 つ削除します。`preStop` スリープは、Kubernetes が SIGTERM を送信する前に進行中のリクエストをドレインします。これらを組み合わせることで、デプロイのブラストラジウスは「Pod のローテーション自体によって導入される追加エラーはゼロ」になります。デプロイ中のすべてのエラーは、デプロイのメカニクスではなくコードの変更から来ます。

<a id="trade-offs-and-constraints--senior--4"></a>
### トレードオフと制約  [SENIOR]

ブラストラジウスチェックリストはデプロイプロセスに摩擦を加えます。その摩擦が目的です。チェックリストを省略して金曜午後に行ったデプロイが午後 5 時に失敗するのは、ブラストラジウス評価によって変更がすべてのテナントに影響し、それを認識しているオンコールエンジニアがいないことが明らかになったため月曜まで保留されたデプロイよりはるかに悪い結果です。

ブラストラジウスが大きい変更に対する Meridian のルール：火曜から木曜にデプロイし、金曜や長い週末前はデプロイしません。これはツールで強制されるプロセスルールではなく、コードレビューで強制されるチームの規範です。スキーママイグレーションのために金曜午後に開かれた PR は、火曜まで待つよう求めるコメントを受けます。SLA エラーバジェットは定量的な正当化を提供します。30 分のアウテージを引き起こす金曜のデプロイは、1 回のインシデントで月次エラーバジェットの 70% を消費します。

### 関連セクション

- [persistence-strategy → Online Migrations on the 50M-Row Tasks Table](./persistence-strategy.md#online-migrations-on-the-50m-row-tasks-table) を参照してください。スキーマ変更のブラストラジウス評価に情報を提供する特定のマイグレーションパターンについて説明しています。
- [operational-awareness → SLO Design and Error Budget Management](#slo-design-and-error-budget-management) を参照してください。ブラストラジウスが大きいインシデントのコストを定量化するエラーバジェットについて説明しています。

---

<a id="prior-understanding-logging-everything-at-info-level-and-the-pgxpool-exhaustion-incident"></a>
## Prior Understanding：すべてを INFO レベルでログすることと pgxpool 枯渇インシデント  [MID]

<a id="prior-understanding-revised-2026-02-14"></a>
### Prior Understanding (revised 2026-02-14)

Meridian の元のロギング戦略は、個々の SQL クエリの完了、Redis の `GET` と `SET` 操作、通知サービスへのすべての呼び出しを含む、すべてのリクエストイベントを `INFO` レベルでログしていました。意図は「インシデント中の最大の可視性」でした。効果は、6 Pod にわたって 1 日あたり約 120 GB のログボリュームでした。

発生した問題：

1. **コスト。** Loki の保持価格では、30 日保持の 120 GB/日は月 1,800 ドルかかっていました。PostgreSQL マネージドインスタンスより高額でした。シグナル対ノイズ比は低く、ログボリュームの 98% はインシデントとは無関係の日常的な成功イベントでした。

2. **検索レイテンシ。** 120 GB/日の 30 日間のログに対する Loki クエリには 45〜90 秒かかりました。インシデント中、ログクエリの 90 秒待ちは永遠のようなものです。エンジニアはインシデント中に Loki を使用するのをやめ、代わりに `kubectl logs` に頼りました。これは現在の Pod の存続時間を超える過去のコンテキストを示しませんでした。

3. **pgxpool 枯渇インシデント。** 金曜午後、大きなワークスペースのエクスポートを実行するバックグラウンドジョブが、実行ごとに 8〜12 分間コネクションを保持しました。6 レプリカで各 25 接続、エクスポートジョブが 4 Pod で同時実行されたため、150 の総コネクションのうち約 100 がエクスポートジョブに保持されました。残りのコネクションは通常の負荷下の API Pod には不十分でした。SLO バーンレートアラートが 16:47 に発火しました。オンコールエンジニアは `pgxpool` イベントを検索するために Loki を開き、クエリが返るまで 80 秒待ちました。その間、アラートは 6 分間発火し続け、エラーバジェットは 18x で燃え続けていました。

   ランブック手順「Prometheus でプール取得レイテンシを確認する」はまだ書かれていませんでした。エンジニアは手動で飽和メトリクスを見つけ、16:54 にプール枯渇を確認し、エクスポートジョブの Pod 数を 1 にスケールしました（コネクション消費を削減）。17:02 までにプールは回復し、SLO アラートはクリアになりました。

   15 分の MTTR は許容できましたが、80 秒の Loki クエリは診断の障害でした。ポストモーテムのアクションアイテム：ログボリュームを削減して Loki クエリが 5 秒以内に返るようにする。

**修正後の理解：**

改訂されたロギング戦略は 3 つのルールに従います。

1. **日常的な成功パスは DEBUG でログし、DEBUG は本番では無効。** 個々の SQL クエリの完了、Redis キャッシュヒット、成功した通知配信はすべて DEBUG レベルのイベントです。本番では、ロガーのレベルは INFO に設定されているため、これらの行は書き込まれません。開発では、`LOG_LEVEL=debug` を設定することで有効になります。

2. **重要な状態遷移は INFO でログする。** リクエストが予期しないステータスで完了した。バックグラウンドジョブが開始または終了した。設定値がロードされた。INFO イベントは運用上のナラティブです。すべてのマイクロステップを追わずに、サービスが何をしたかのストーリーを語ります。

3. **注意が必要だがエラーではない状況は WARN でログする。** 通知配信がリトライされた。キャッシュミスにより低速パスが発生した。単一リクエストでプール取得レイテンシが 50ms を超えた。

4. **ユーザーにエラーレスポンスを返した状況は ERROR でログする。** ドメインエラータイプのカテゴリ（[error-handling → Domain Error Type Hierarchy](./error-handling.md#domain-error-type-hierarchy) 参照）によって、エラーが WARN（期待されるエラー：404、422）または ERROR（予期しないエラー：500、503）でログされるかどうかが決まります。区別：404 はユーザーが存在しないリソースを要求したことを意味します。オペレーターの懸念ではありません。500 はサービスが有効なリクエストを満たせなかったことを意味します。常にオペレーターの懸念です。

改訂後、ログボリュームは 1 日あたり 8 GB に低下しました。30 日ウィンドウの Loki クエリ時間は 2〜4 秒に低下しました。1,800 ドル/月のロギングコストは 120 ドル/月に低下しました。次のインシデント（2026 年 5 月の Redis タイムアウト）での調査中、オンコールエンジニアは `kubectl logs` に頼る代わりに Loki をプライマリ調査ツールとして使用するのに十分なほど高速でした。

ポストモーテムは 2 つの恒久的なランブック追加も生みました。

- pgxpool 飽和ランブック（`/runbooks/postgres/pool-saturation`）は、ログ検索の前にステップ 1 としてプール取得レイテンシ p95 の Prometheus クエリを含むようになりました。
- エクスポートジョブの Kubernetes `Job` スペックは、マルチ Pod コネクション独占を防ぐために `spec.parallelism: 1` を設定するようになりました。

### 関連セクション

- [persistence-strategy → Connection Pooling with pgxpool](./persistence-strategy.md#connection-pooling-with-pgxpool) を参照してください。プールの上限を決定した `MaxConns=25` と 6 レプリカ設定について説明しています。
- [operational-awareness → Three-Pillar Observability](#three-pillar-observability-logs-metrics-and-traces) を参照してください。元の戦略を置き換えた構造化ログレベルと zap 設定について説明しています。
- [operational-awareness → Alerting Without On-Call Burnout](#alerting-without-on-call-burnout) を参照してください。このインシデント後のポストモーテムアクションアイテムとして書かれた `PgxpoolHighAcquireLatency` 飽和アラート（チケット重大度）について説明しています。

---

<a id="coach-illustration-default-vs-hints"></a>
## コーチイラストレーション（default vs. hints）

> **例示のみ。** 以下はこのドメインのタスクにおける 2 つのコーチングスタイルの違いを示した実例です。ライブエージェントのコントラクトの一部ではありません。実際のエージェントの動作は `.claude/skills/learn/coach-styles/` のスタイルファイルによって管理されます。

**シナリオ：** 学習者が Meridian に新しいバックグラウンドジョブを追加しています。スケジュールに従ってワークスペースレベルのタスク統計を再計算するもので、エージェントにオブザーバビリティのための計測を依頼します。

**`default` スタイル** — エージェントは完全な計測を作成します。ジョブ構造体に注入された `zap.Logger` フィールド、ジョブ期間の `prometheus.Histogram`、ジョブのメインループをラップする OTel スパン。ヒストグラムの登録を `internal/metrics/` に追加し、ログ呼び出しを INFO（ジョブ開始、ジョブ完了）と DEBUG（ワークスペースごとのバッチ進捗）で追加します。3 本柱モデル、バッチ進捗が INFO ではなく DEBUG である理由、ログ由来のメトリクスでアラートしないというルールを説明する `## Learning:` トレーラーを追記します。学習者は完成した動作する計測を受け取ります。

**`hints` スタイル** — エージェントはジョブ構造体のロガーとトレーサーフィールド、ヒストグラムの登録スタブ（名前、ヘルプテキスト、バケット。登録コールはまだなし）を書きます。それから以下を出力します。

```
## Coach: hint
Step: Register the job-duration histogram in internal/metrics/ and record observations
      at the end of each workspace batch.
Pattern: Three-pillar observability (metrics pillar) — histogram for duration, not gauge.
Rationale: A histogram captures the full latency distribution (p50, p95, p99) across
batch sizes; a gauge would only show the most recent duration, losing the distribution
shape needed to detect slow outlier workspaces.
```

`<!-- coach:hints stop -->`

学習者が登録と `Observe` コールを実装します。次のターンで、エージェントはメトリクスコードを再書き込みせずに OTel スパンをどこに追加するかのフォローアップに応答します。
