> このドキュメントは `docs/en/adr/001-developer-growth-mode.md` の日本語訳です。英語版が原文（Source of Truth）です。

# ADR-001: Developer Growth Mode — ドメイン別に構成された生きたノートブック

## ステータス

提案（安定化済み）。2026-04-22 に記録されたオーナーの判断に基づき、この ADR の以前のドラフトを置き換える。

## メタデータ

- 日付: 2026-04-22
- 改訂: 2026-04-22 — トグルを Skill に移行、ノートをデフォルトで gitignore 扱いに変更、分類体系を 19 の公式ドメインとして確定。ui-ux-designer を `api-design` に無理に割り当てるのではなく、その職掌に合った主担当ドメインを持てるよう `ui-ux-craft` を追加。長さ上限に関する文言はすべて削除し、すべてのエージェントに少なくとも 1 つの主担当ドメインを割り当てた。
- 決定者: エージェントチーム。オーナーの判断はコンテキストに記載。
- 関連: [docs/en/prd/developer-growth-mode.md](../prd/developer-growth-mode.md)、[docs/en/growth/domain-taxonomy.md](../growth/domain-taxonomy.md) — 正典となる分類体系であり、ドメイン一覧と担当対応表についてはこちらが最終的な根拠となる。
- この ADR の以前のドラフトでは、Growth Mode は 3 通りの形で構想されていた。長さを制限したアノテーション層、追記のみのジャーナル、カスタムスラッシュコマンドによるトグル、の 3 つである。これらはすべて、以下の判断によって置き換えられる。

## コンテキスト

本テンプレートは 15 エージェントからなるチームを備え、PRD、アーキテクチャ、コード、テスト、レビュー、デプロイ計画といった完成度の高い成果物を生み出す。しかし、各成果物の背後にある思考は読み手には見えない。テンプレートを使って実プロジェクトを組み立てる学習者は、出力こそ目にするものの、そこに至るまでの思考の流れは目にしない。Growth Mode は、その思考を、既定の体験を損なうことなくオプトインの層として可視化するために存在する。

2026-04-22 に 3 つのオーナー判断が確定し、それに伴ってアーキテクチャを組み直すこととなった。以下はそれらの判断を忠実に引き写したもので、以降のすべての節はこの判断を起点として展開される。

### 判断 1 — 15 エージェント全員がリリース時点で Growth に対応する

`.claude/agents/` 配下のすべてのエージェントを、Growth のコントラクトを備え、少なくとも 1 つの主担当ドメインを割り当てられた状態で出荷する。一部のエージェントだけを先行して対応させるような構成や、「後回しリスト」のような扱いはしない。`growth_domains: []` のまま出荷されるエージェントも存在しない。15 エージェント全員を分類体系に接続した状態で出荷するか、あるいはこの機能そのものを出荷しないかのどちらかである。

### 判断 2 — 長さの上限を設けず、深さを優先する

貢献の深さは、説明すべき概念が要求するだけ踏み込んだものとする。具体性の度合いは、目の前にあるコードに合わせる。長さに上限はない。トークン予算も、ノート数の制限も、文数の制限も設けない。唯一の制約は関連性であり、ノートは理解を助けるうえで本質的な内容でなければならない。長さは、予算によってではなく、概念によって自然に決まる。エージェントは品質ルール（非破壊的な編集を守ること、重大性を意図的に和らげないこと）にはこれまでどおり従うが、長さの下限や上限には縛られない。

### 判断 3 — ノートは体系的に整理された、生きた知識ベースとする

エージェントが呼び出されるたびに、そのセッションで必要となる知識が提示され、何を教えたか、学習者が何を学んだかが記録される。ノートはセッションの末尾に無造作に追記されるのではなく、体系的に整理されながら肉付けされていく。複数のセッションを重ねることで、ドメインごとに整理されたリファレンスへと結実する。

この判断の帰結として、単一の `journal.md` は、ドメインごとのノートファイルからなるディレクトリへと置き換わる。セッションでは、時系列に沿ってエントリを追記していくのではなく、該当するドメインのファイルを開き、新しい節を追加する／既存の節を深める／成熟したエントリを洗練する／本当に新しい領域であれば新しいドメインを切る、のいずれかを行う。多くのセッションを重ねたのちに手元に残るのは、実プロジェクトの機能開発を通じて学習者自身が築き上げた個人向けの教科書であり、日付ではなくドメインをたどって読めるものである。

### 判断 4 — ノートはデフォルトで gitignore 扱いとし、共有はオプトインにする

`.claude/growth/notes/` と `.claude/growth/config.json` は、どちらもデフォルトで gitignore の対象とする。学習者がチーム内でノートを共有したい場合にのみオプトインする形とし、個人の学びの記録を既定で外部に出すことはしない。根拠は「決定」の節を参照。

### 判断 5 — トグルはカスタムコマンドではなく Skill にする

現在の Claude Code では Skills と Commands が統合され、新しい用途には Skills が正典の選択肢となっている。`/growth` トグルは `.claude/skills/growth/SKILL.md` に置かれた Skill として出荷し、`disable-model-invocation: true` を指定する。これによって、Growth Mode をいつ有効化するかを決めるのはモデルではなくユーザー本人に限定される。根拠は「決定」の節を参照。

### これらの判断がアーキテクチャを組み直す理由

判断 3 は構造を決定づけるものである。ジャーナルは書き込み一回限りの時系列ログだが、生きたノートブックは読み込み・編集・書き戻しのサイクルであり、体系的に整理されている。エージェントの呼び出しはどれも、単発のアノテーションを吐き出すのではなく、共有ファイルに対する編集サイクルに参加することになる。判断 1 によって、このサイクルが 15 エージェント分に拡張される。だからこそ編集プロトコルは、同じセッションのなかで複数のエージェントがそれぞれ担当ドメインのファイルに手を入れても、互いの作業を踏みつぶさずに安全に変更できる程度に堅牢でなければならない。判断 2 により、個々の編集はその概念が要求するだけ踏み込んだものになる。エージェントの貢献は 1 行の注釈ではなく、相応の段落や具体例となる。判断 4 はノートブックをデフォルトで非公開に保ち、オーナーが表明した方針（「ユーザー獲得を最適化しているわけではない。自分のために作ったものだ」）と整合する。素材の性質とも整合する。ノートには誤り、以前の理解、修正の履歴が含まれており、これは私的な学習素材だからである。判断 5 はトグルを、モデルが呼び出せるアクションではなく、第一級のユーザー操作として位置づける。Growth Mode は、それ以降すべてのターンでエージェントの振る舞いを変えるものだからこそ、その切り替えは学習者が明示的に選び取った行為でなければならない。これらの判断が組み合わさることで、Growth Mode は単なるアノテーション層から、作者の境界が明確な知識工学の層へと組み直される。

## 決定

Developer Growth Mode は、デフォルト OFF の機能として、次の 5 つの要素を組み合わせて出荷する。(1) ドメイン別に整理されたノートディレクトリ、(2) 15 エージェントで共同所有する 19 ドメインの正典となる分類体系、(3) すべての Growth 対応エージェントが非破壊的な編集のために従う拡充操作プロトコル、(4) 有効化・無効化とドメイン別フォーカスの切り替えをユーザーの明示的な操作下に置く Skill 形式のトグル、(5) ノートブックをデフォルトで非公開としつつ、オプトインで共有できる経路を残す gitignore 方針、の 5 つである。この設計はデフォルト OFF の不変条件を保つ。`/growth on` を実行しないユーザーは、エージェントの振る舞いの変化も、余分なファイル読み込みも、追加の作業も目にしない。

### ノートの構造: `.claude/growth/notes/`

学習者の知識ベースは `.claude/growth/notes/` に置かれ、ドメインごとに 1 つの Markdown ファイルを持つ。各ドメインファイルは、日付ではなく概念を単位として節を立てた体系的なリファレンスドキュメントであり、節のタイトルはそれが扱う概念そのものに由来する。たとえば `## リポジトリパターン` や `## 読み取りモデルと書き込みモデル` といった形である。節は複数のセッションを経てその場で育ち、時系列で分割されることはない。

機能インストール時のディレクトリ形状:

```
.claude/growth/
├── config.json                 # 状態: enabled、level、focus_domains、updatedAt(gitignored)
├── preamble.md                 # すべての Growth 対応エージェントが読む拡充操作契約
└── notes/                      # gitignored ディレクトリ。.gitignore.example を参照
    ├── architecture.md
    ├── api-design.md
    ├── data-modeling.md
    ├── persistence-strategy.md
    ├── error-handling.md
    ├── testing-discipline.md
    ├── concurrency-and-async.md
    ├── ecosystem-fluency.md
    ├── dependency-management.md
    ├── implementation-patterns.md
    ├── review-taste.md
    ├── security-mindset.md
    ├── performance-intuition.md
    ├── operational-awareness.md
    ├── release-and-deployment.md
    ├── market-reasoning.md
    ├── business-modeling.md
    ├── documentation-craft.md
    └── ui-ux-craft.md
```

補足: 本 ADR が出荷するのは、[分類体系ドキュメント](../growth/domain-taxonomy.md) で定義された 19 の正典ドメインである。学習者は実行時に `/growth domain new <key>` を用いて、追加のカスタムドメインを開くこともできる。カスタムドメインも同じディレクトリに配置され、同じ形式に従う。

各シードファイルは、YAML のフロントマターブロック（タイトル、ドメインキー、担当エージェント、最終更新タイムスタンプ）と、1 つのプレースホルダ節から構成される。エージェントが初めてそのファイルに触れたときに、期待される形をすぐに把握できるようにするためである。

#### Flutter プロジェクトで 10 セッションを経たあとの現実的なツリー

Flutter 固有のエントリは独立したファイルに置かれるのではなく、エコシステムに依存しないファイルのなかに現れる。新しいカスタムドメインは、学習者が正典の分類体系に収まりにくいトピックを持ち込んだときにのみ新設される。

```
.claude/growth/notes/
├── architecture.md             # + Riverpod providers as DI seams、+ clean architecture boundaries in Dart
├── api-design.md               # + Dio interceptors vs plain http、+ freezed for DTOs
├── data-modeling.md            # + immutable value classes with freezed、+ union types for state
├── persistence-strategy.md     # + Drift vs Isar trade-offs、+ local-first sync conflicts
├── error-handling.md           # + Result types in Dart、+ sealed classes for failure modeling
├── testing-discipline.md       # + widget tests vs integration tests、+ pump/pumpAndSettle semantics
├── concurrency-and-async.md    # + Future vs Stream、+ isolate communication model
├── ecosystem-fluency.md        # + null safety idioms、+ build_runner conventions、+ pub.dev workflow
├── dependency-management.md    # + pubspec version constraints、+ workspace refs in a monorepo
├── implementation-patterns.md  # + early-return guards in build methods、+ StateNotifier patterns
├── review-taste.md             # + rebuild-cost heuristics、+ const constructor discipline
├── security-mindset.md         # + secure storage plugin trade-offs、+ platform channel surface risks
├── performance-intuition.md    # + frame budget、+ shader warm-up、+ RepaintBoundary placement
├── operational-awareness.md    # + Firebase console signals、+ crashlytics triage
├── release-and-deployment.md   # + flavors、+ Fastlane lanes、+ Play/App Store review heuristics
├── market-reasoning.md         # + mobile app-store discovery signals、+ category positioning
├── business-modeling.md        # + subscription vs one-off IAP trade-offs、+ platform fee math
├── documentation-craft.md      # + dartdoc conventions、+ worked-example pattern for widget APIs
├── ui-ux-craft.md              # + Material 3 spacing scale、+ Cupertino vs Material decision notes、+ reduce-motion handling
└── state-management.md         # custom domain opened by the learner in session 4
```

#### Go バックエンドプロジェクトで 10 セッションを経たあとの現実的なツリー

```
.claude/growth/notes/
├── architecture.md             # + hexagonal ports and adapters in Go、+ wire for DI
├── api-design.md               # + chi router vs net/http、+ request validation layer
├── data-modeling.md            # + aggregate boundaries、+ repository seam placement
├── persistence-strategy.md     # + sqlc vs gorm trade-offs、+ indexing for common queries
├── error-handling.md           # + errors.Is/As、+ sentinel errors vs wrapped errors
├── testing-discipline.md       # + table-driven tests、+ subtests、+ httptest patterns
├── concurrency-and-async.md    # + goroutine lifecycle、+ errgroup、+ channels as signals vs queues
├── ecosystem-fluency.md        # + interfaces accepted small、+ return concrete types、+ idiomatic error wrapping
├── dependency-management.md    # + go mod vendor、+ replace directives during migration
├── implementation-patterns.md  # + functional options、+ named return values、+ early return over nesting
├── review-taste.md             # + error wrapping cadence、+ context propagation
├── security-mindset.md         # + sql.NullString vs pointers、+ context cancellation leaking secrets
├── performance-intuition.md    # + allocation profiling、+ sync.Pool when justified
├── operational-awareness.md    # + structured logs with slog、+ liveness vs readiness semantics
├── release-and-deployment.md   # + multi-stage Dockerfiles、+ distroless base images、+ graceful shutdown
├── market-reasoning.md         # + B2B backend buyer signals、+ infra-vendor landscape notes
├── business-modeling.md        # + usage-based pricing math、+ cost-to-serve vs contract value
├── documentation-craft.md      # + godoc examples as tests、+ README-driven endpoint docs
├── ui-ux-craft.md              # placeholder — this Go backend has no user-facing UI、so the file stays near-empty
└── observability.md            # custom domain opened by the learner when tracing was introduced
```

ドメインファイルの名前はエコシステムをまたいで同一である一方、各ファイルの中身はエコシステムごとに固有となる。ここが要点で、学習者はどのスタックに移っても同じ概念的な足がかりを持ち続けられ、ノートブックは、同じドメインがいま扱っている言語やフレームワークのなかでどのように立ち現れるのかを教えてくれる。

### ドメインの分類体系

出荷するドメインは 19 個である。名前はエコシステムに依存しないが、意図は具体的に定まっている。結果として、Flutter アプリにも、Go サービスにも、Rails のモノリスにも、Python のデータパイプラインにも、同じドメイン名を等しく適用できる。

| ドメインキー | ここで扱う内容 |
|------------|---|
| `architecture` | システム構造、モジュール境界、階層化、差し替え可能な継ぎ目、依存性逆転、集約設計 |
| `api-design` | リソースモデリング、バージョニング、エラーエンベロープ、冪等性、ページネーション、契約 |
| `data-modeling` | エンティティ設計、関連、正規化のトレードオフ、時間軸を持つデータ、ステートマシン、集約の境界 |
| `persistence-strategy` | データベース技術の選定、スキーマ設計、インデックス、クエリパターン、トランザクション、整合性モデル |
| `error-handling` | エラーの伝播、境界のまたぎ、利用者向けメッセージとログのみのメッセージ、リトライ、リカバリ戦略 |
| `testing-discipline` | テストピラミッド、フィクスチャの衛生、AAA パターン、モックと統合の使い分け、カバレッジのトレードオフ、不安定なテストの原因究明 |
| `concurrency-and-async` | 競合状態、バックプレッシャー、キャンセル、再入可能性、並行単位のライフサイクル |
| `ecosystem-fluency` | 言語の慣用表現、ツールチェーンのワークフロー、フレームワークのパターン、スタック固有の自明でない規約。`dependency-management` とは別物であり、本ドメインは言語とツールチェーンの慣用表現を扱う。`dependency-management` はパッケージのバージョン固定、ロックファイル戦略、サプライチェーンの衛生を扱う。 |
| `dependency-management` | パッケージのバージョン固定、ロックファイル、サプライチェーンの衛生、アップグレードの頻度、推移的依存のリスク |
| `implementation-patterns` | モジュール内のコード構成、ヘルパーの抽出、制御フロー、命名、リファクタリングの勘どころ、コードスメル |
| `review-taste` | シニアは差分から気づくがジュニアは見落としがちなこと、スタイルと不変条件、コードスメルの検出 |
| `security-mindset` | 境界における入力バリデーション、シークレットの扱い、認可の設計、脅威モデリング、OWASP に沿った勘どころ |
| `performance-intuition` | ボトルネックの見立て、プロファイリングの規律、アルゴリズム的な勝ち筋とシステム的な勝ち筋、キャッシュのトレードオフ |
| `operational-awareness` | ランタイムの挙動、ログ、メトリクス、ヘルスチェック、段階的な劣化、インシデント対応 |
| `release-and-deployment` | ビルドパイプライン、デプロイ戦略、ロールバック、フィーチャーフラグ、環境の等価性 |
| `market-reasoning` | 競合状況の読み解き、ユーザーセグメントのモデリング、需要のシグナル、ポジショニング上のトレードオフ |
| `business-modeling` | 価格設計、ユニットエコノミクス、収益認識のパターン、収益化におけるトレードオフ |
| `documentation-craft` | リファレンス／チュートリアル／解説の書き分け、具体例の扱い方、想定読者、変更履歴の衛生 |
| `ui-ux-craft` | 視覚的階層、タイポグラフィ、アクセシビリティ、インタラクションパターン |

学習者はいつでも `/growth domain new <key>` によってカスタムドメインを開くことができる。カスタムドメインは `.claude/growth/notes/<key>.md` として、ほかと同じ形式で保存される。

### 拡充操作プロトコル

Growth 対応エージェントは、学びを伝えるべき場面に出会うたびに、対象となるドメインファイルに対して次の 5 ステップを実行する。この手順は `.claude/growth/preamble.md` に一度だけ定義され、15 エージェント全員が同じ定義を参照する。

1. **対象のドメインを特定する。** エージェントは、その学びの機会を、自身の担当ドメインのうちいずれかのキーへと対応づける。エージェント別の担当対応表は後述する。話題が 2 つのドメインにまたがる場合は、より基礎的な位置づけの概念に該当するドメインを選び、もう一方には 1 行の相互参照のみを残す。既存のどのドメインにも収まらず、本当に新しい領域だと判断される場合には、エージェントは根拠を添えて新規ドメインの追加を提案する。ファイルが実際に作成されるのは、学習者が `/growth domain new <key>` によって確認したあとに限られる。エージェントが確認なしにドメインファイルを勝手に新設することはない。
2. **対象のドメインファイルを読み込む。** エージェントは、どのように貢献するかを決める前に、必ず既存のファイル内容を読む。これは交渉の余地のない手順である。現状を把握しないまま書き加えてしまうと、知識ベースの整合性が崩れてしまう。読み込んでおくことで、既存の節と重複したり、過去に supersede（置き換え）されたエントリと矛盾したりすることを避けられる。
3. **操作を決める。** 次の 5 種類のうちから 1 つを選ぶ。
   - **add**: このドメインにまだ存在しない概念のために、新しい最上位の節を立てる。
   - **deepen**: 既存の節に対して、新しい例、但し書き、エッジケース、相互参照などを追記する。
   - **refine**: 主張は変えずに、既存エントリの表現を引き締める、あるいは例の出来をより良くする。
   - **correct**: 以前のエントリが supersede されたことを明示し、正しい理解をその下に書き加える。supersede された記述は決して削除せず、理由付きのマーカー（`> Superseded YYYY-MM-DD: <reason>`）とともに残す。こうすることで、学習者は自分の理解がどう変わってきたかをたどれる。
   - **new-domain**: ステップ 1 で根拠を示して提案し、学習者の確認を得たあとにのみ実行する。
4. **変更を非破壊的に適用する。** エージェントは、変更を取り込んだ形でファイルを書き出す。変更範囲の外にある見出し・例・コードブロックは、バイト単位でそのまま保たれる。エントリが削除されることはない。supersede されたエントリも、マーカー付きのまま見える状態で残す。ファイルが分割すべき閾値を超えて育ってしまった場合は、エージェントが勝手に再編成するのではなく、「再編成が必要である」という旨を差分レポートとして報告する。閾値の扱いについてはオープンクエスチョンの節を参照してほしい。
5. **差分をレポートする。** レスポンスの末尾で、エージェントはドメインキー、編集した節の見出し、操作名、変更内容の一文要約をまとめて報告する。これは、学びの機会の由来を記録するためのものであり、学習者はこれを手がかりにノートブックの変遷を追跡できる。

この手順を貫く原則は、ファイルを日付ではなく概念で構成するということにある。セッション専用の節は設けない。セッションの貢献は、既存の概念の節に取り込まれるか、新しい概念の節を開く形で加わる。いつ変更が入ったかを追跡する手がかりは、ファイルの構造ではなく、Git の履歴と各応答の差分レポートに残る。

### エージェント別の Growth に関する責務

エージェントはそれぞれ、1 つ以上のドメインを自身の担当として宣言する。担当は排他的ではなく、複数のエージェントが同じドメインに書き込むこともある。ただし、各エージェントは、主担当として挙げられたドメインにおいては主要な貢献者であることが期待される。担当は各エージェントの YAML フロントマターの `growth_domains:` フィールドとしてエンコードされ、主担当のドメインを先に記述する。

15 エージェントはいずれも少なくとも 1 つの主担当ドメインを持ち、`growth_domains: []` のまま出荷されるエージェントは存在しない。以下の担当対応表は本 ADR における確定版であり、[分類体系ドキュメント](../growth/domain-taxonomy.md) と照合される。両者の内容が食い違った場合には、分類体系側を真とする。

| エージェント | 主担当ドメイン | 副担当ドメイン |
|-------|-----------------|---|
| orchestrator | `release-and-deployment` — 委譲をリリース経路の規律として扱う | `architecture`、`api-design` |
| product-manager | `api-design` — プロダクト要件の観点から、要件が契約の形をどう決めるのかを扱う | `architecture`、`data-modeling`、`review-taste`、`release-and-deployment`、`market-reasoning` |
| market-analyst | `market-reasoning` | `business-modeling` |
| monetization-strategist | `business-modeling` | — |
| ui-ux-designer | `ui-ux-craft` | `api-design`、`architecture`、`implementation-patterns`、`performance-intuition` |
| docs-researcher | `ecosystem-fluency` | `dependency-management` |
| architect | `architecture`、`api-design`、`data-modeling` | `persistence-strategy`、`error-handling`、`ecosystem-fluency`、`dependency-management`、`security-mindset` |
| implementer | `error-handling`、`concurrency-and-async`、`ecosystem-fluency`、`implementation-patterns` | `architecture`、`api-design`、`data-modeling`、`persistence-strategy`、`testing-discipline`、`review-taste`、`security-mindset`、`performance-intuition`、`operational-awareness` |
| code-reviewer | `testing-discipline`、`implementation-patterns`、`review-taste`、`security-mindset` | `architecture`、`api-design`、`data-modeling`、`persistence-strategy`、`error-handling`、`concurrency-and-async`、`ecosystem-fluency`、`performance-intuition` |
| test-runner | `testing-discipline`、`performance-intuition` | `error-handling`、`implementation-patterns`、`review-taste`、`security-mindset` |
| linter | `implementation-patterns` | `testing-discipline`、`ecosystem-fluency`、`review-taste`、`security-mindset` |
| security-reviewer | `security-mindset` | `architecture`、`api-design`、`persistence-strategy`、`error-handling`、`testing-discipline`、`dependency-management`、`implementation-patterns` |
| performance-engineer | `concurrency-and-async`、`performance-intuition` | `persistence-strategy`、`testing-discipline`、`implementation-patterns`、`review-taste`、`operational-awareness` |
| devops-engineer | `operational-awareness`、`release-and-deployment` | `persistence-strategy`、`dependency-management`、`security-mindset` |
| technical-writer | `documentation-craft` | — 加えて、ノートディレクトリのキュレーターとしての責務も担う。再編成、分割、節のリネームなど。詳細は実装ノートを参照。 |

同一ワークフローのなかで、2 つのエージェントが同じドメインの同じ節に関わる学びの機会をそれぞれ抱えている場合、拡充プロトコルは直列化される。最初のエージェントが読み込み・編集・書き戻しのサイクルを終えてから、2 番目のエージェントは更新後のファイルを読むところから作業を始める。実運用では、オーケストレーター（あるいはハーネス）が、同じドメインを対象とする複数の Growth 対応エージェントを並列に動かさず、直列に並べる。並列タスク実行との関係については「結果」の節を参照してほしい。

### レベルの意味づけ — junior / mid / senior

レベルが制御するのは、貢献の切り口と密度（エージェントが学習者に対してどの程度の前提知識を仮定するか）であって、長さそのものではない。指針となる言い回しは「概念が要求する範囲まで具体的に、目の前のコードが示す範囲まで詳細に」である。

- **junior**: エージェントは第一原理から説明する。語彙を使う前にその語彙を定義する。選んだアプローチを、初めて触れる開発者が直感的に取りがちな素朴な選択肢と対比させる。具体例は丁寧に展開し、トレードオフは明示的に名前を付けて示す。前提となる概念はその場で説明するか、それを扱うドメインファイルへの相互参照を置く。junior レベルの貢献は、基礎の足場を組み上げる必要があるため、複数のサブ節を持つまとまった節になることが多い。
- **mid**: 説明するのは自明ではない判断だけに絞る。具体的には、このスタックを経験した開発者であっても自力では気づきにくい点に焦点を当てる。トレードオフには名前を付けて触れるが、代替案を網羅的に比較することはしない。mid レベルの貢献では基礎の足場の説明は省くが、なぜその選択をしたのかという根拠は残す。
- **senior**: 既定ではない選択をしたときにだけ貢献する。ノートでは、既定の選択肢を名指し、実際に採った選択肢を名指し、この文脈でそちらが選ばれた理由を説明する。senior の貢献が捉えるのは、別の道もあり得たなかで、なぜこちらを選んだのかという判断の軌跡である。senior レベルのセッションですべての判断が既定どおりだった場合には、何も書き加えないこともある。

重要なのは、3 つのレベルのすべてが同じドメインファイルに書き込む、という点である。ノートブックがレベルごとに分岐することはない。ある概念を導入した junior の貢献と、あとから同じ概念に加わった senior の貢献は、同じ節のなかに共存する。senior のエントリは、その下に `Trade-off refinement` サブ節として配置される。時間が経つにつれて、節は層状の教科書のような姿になっていく。上に基礎、中に慣用表現、下にトレードオフが積み重なる。

動作の細部として、後のセッションで同じ概念に別のレベルで再び出会った場合、エージェントは既存の節を複製するのではなく、深める方向で加筆する。たとえば、junior レベルのセッションですでにリポジトリパターンが説明されている場合、senior レベルのセッションで再び同じ概念に触れたときの貢献は、「リポジトリとは何か」の別解ではなく、トレードオフに関するサブ節となる。

### トグルの置き場所 — カスタムコマンドではなく Skill

トグルは `.claude/skills/growth/SKILL.md` に置いた Skill として出荷する。現在の Claude Code では Skills と Commands が統合されており、新しい用途には Skills が正典の選択肢となる。ここで重要になる Skill の性質は 3 つある。

1. **`disable-model-invocation: true` であること**: Growth Mode はユーザーだけが切り替え可能であり、モデルが自動で有効化することはない。これはスタイルの選択ではなく、設計上の第一級の不変条件である。モデルが自身の教示的な振る舞いを自分で有効化できてしまうと（つまり学習者の代わりに「このセッションは学びのためのセッションだ」と決めてしまうと）、Growth Mode を Growth Mode たらしめている「作者の境界」が反転してしまう。教わることを選ぶのは学習者であり、モデルではない。
2. **`arguments: [action, level]` を受け取れること**: スラッシュコマンド表現の `/growth on junior` は、素直に `$action=on`、`$level=junior` と対応づけられる。引数の形はすべての呼び出しパターンで共通なので、ハンドラ本体を小さく保てるうえ、発見性も損なわれない。
3. **関連ファイルをディレクトリとして抱え込めること**: Skill は専用のディレクトリを持つ。現時点ではそこに置くのは `SKILL.md` だけだが、将来的には引数パーサのヘルパー、状態の整形処理、再編成用プロンプトなどを、1 つのファイルを肥大化させずに収められる。`.claude/commands/growth.md` に置くカスタムコマンドは、慣習的に単一ファイルで完結させるものなので、こうした拡張の余地が閉ざされる。

4 つ目の理由として、現在の Claude Code が進もうとしている方向との前方互換性がある。新機能は Skills 側に追加されているため、Growth 機能もプラットフォームが向かう先と同じ場所に置いておきたい。

| 置き場所 | 役割 |
|---------|------|
| `/growth` Skill（`.claude/skills/growth/SKILL.md`） | ユーザーの単一の操作で状態を切り替える。以下のすべてのサブコマンドを受け付ける。 |
| `.claude/growth/config.json` | 機械可読な状態ファイル。`enabled`、`level`、`focus_domains`、`updatedAt` を保持する。gitignore 対象。 |
| `CLAUDE.md` のポインタ行 | 機能の発見性を担保するための記述。機能名と Skill 名を記した 1 行。 |

サポートする呼び出しと引数の対応は、次のとおりである。

| 呼び出し | `action` | `level` や追加引数 | 挙動 |
|-----------|----------|---|--------|
| `/growth on [level]` | `on` | 省略可：`junior`／`mid`／`senior` | 指定されたレベルで有効化する。省略時は保存済みのレベル、それもなければ `junior` を使う。 |
| `/growth off` | `off` | — | 無効化する。次回の有効化に備えて `level` と `focus_domains` は保持する。 |
| `/growth status` | `status` | — | 現在の状態、フォーカスドメイン、直近 10 件の差分レポートを報告する。 |
| `/growth focus <domain>[,<domain>]` | `focus` | ドメインのリスト | `focus_domains` を設定する。エージェントはこれらのドメインに該当する学びの機会を優先する。 |
| `/growth focus clear` | `focus` | `clear` | フォーカスを解除する。エージェントはすべてのドメインを等しく扱う。 |
| `/growth domain new <key>` | `domain` | `new <key>` | 学習者の確認を経てからカスタムドメインファイルを作成する。 |
| `/growth level <level>` | `level` | `junior`／`mid`／`senior` | 有効状態はそのままに、レベルだけを切り替える。 |

**`/quiet` の位置づけ**: Growth Mode による書き込み自体は止めずに、応答末尾のトレーラー（教えたことの要約とノートブックの差分）だけを抑制する `/quiet` トグルについては、別途要望が挙がっていた。結論として、これは `/growth` のサブコマンドにはせず、独立した Skill として `.claude/skills/quiet/SKILL.md` に置く。理由は、`/quiet` が `/growth` とは別の「作者の境界」を持つからである。学習者は、教示的な出力を応答に含めたくないときでも、ノートブックの拡充自体は静かに継続してほしい、という状況があり得る。これは Growth Mode の ON／OFF とは直交する関心事である。両者を分けておけば、`/quiet` は Growth Mode の外側でも、将来的に他のトレーラーを抑制する用途にも転用できるうえ、`/growth` が雑多なサブコマンドの寄せ集めになることを防げる。

`config.json` スキーマ:

```json
{
  "enabled": false,
  "level": "junior",
  "focus_domains": [],
  "updatedAt": "2026-04-22T00:00:00Z"
}
```

`focus_domains` が空でないとき、フォーカス外のドメインで学びの機会に遭遇したエージェントは、その話題が理解の根幹に関わるのであれば引き続き貢献する。そうでない場合は、浅い貢献を無理に残すのではなく、その機会は見送り、フォーカスドメインへの貢献を優先する。これにより学習者は、「今月は並行性を重点的に学ぶ」と宣言しつつ、他ドメインからの学びが完全に途絶えることなく、全体の注力点をフォーカスドメインに寄せられる。

### CLAUDE.md との統合

`.claude/CLAUDE.md` には「Growth Mode」の見出しの下に、ポインタブロックを配置する。このブロックは以下の役割を担う。(1) ノートディレクトリのパスを記し、エージェントがどこに読み書きすればよいかを示す。(2) 設定ファイルのパスを記し、エージェントが状態を確認できるようにする。(3) `/growth` Skill の名称を記し、学習者がどこで機能を切り替えればよいかを示す。このブロックは条件分岐なしで常に配置され、CLAUDE.md に必ず存在する。とはいえ 1 段落に収まる分量にとどめているため、デフォルト OFF のセッションに対して意味のあるオーバーヘッドを足すことはない。Growth Mode を一度も有効にしないユーザーも、このブロックを一度読めば十分である。

セッション開始時、Growth 対応エージェントは次の手順を踏む。

1. `.claude/growth/config.json` を読む。ファイルが存在しないか `enabled: false` の場合は、Growth に関するステップをすべてスキップする。
2. `.claude/growth/preamble.md` を読む。拡充操作プロトコルを再確認するためである。
3. 分類体系を参照し、現在のタスクをドメインキーに対応づけて、関連するドメインファイルを洗い出す。
4. 既存の内容を知らないまま重複した記述を書いてしまうのを避けるため、洗い出したドメインファイルを読み込む。
5. 通常どおりタスクを進める。学びの機会が生じたときには、拡充操作プロトコルに従う。

### プライバシーの方針 — デフォルトで gitignore

`.claude/growth/notes/` と `.claude/growth/config.json` は、どちらもデフォルトで gitignore の対象とする。テンプレートには `.gitignore.example` が同梱されており、追加すべき行と、チーム共有へ切り替えたい場合の反転パターンがコメント付きで示されている。

```gitignore
# .gitignore.example — Growth Mode のデフォルト
.claude/growth/notes/
.claude/growth/config.json

# オプトイン: ノートを ignore 対象から外し、チーム共有の教科書として扱う場合。
# 以下 2 行のコメントを外したうえで、.claude/growth/notes/ をコミットする。
# !.claude/growth/notes/
# !.claude/growth/notes/*.md
```

**根拠**: ノートには学習者の誤りや以前の理解、supersede マーカー付きで保持された修正の履歴が含まれる。これは私的な学習素材であって、チームの共有リポジトリに載せることを前提とした資料ではない。学習者が共有用の教科書を必要としたときにのみオプトインで共有する設計とし、個人の学びの記録を既定で外部に出すことはしない。オーナーが表明している方針（「ユーザー獲得を最適化しているわけではない。自分のために作ったものだ」）とも整合するし、supersede と履歴を残す設計自体が、この素材の扱い方と嚙み合う。supersede された説明はすべて永続的に見える形で残るため、パブリックリポジトリには置きたくない類の記述こそが、ここに積み上がっていく。チームがノートブックを共有成果物として扱いたくなったときには、`.gitignore.example` の反転パターンを 1 つ有効にすれば済む。コメント付きの例がその道筋を用意しており、チーム共有をデフォルトとして押し付けることなく、選択肢として提示できる。

`config.json` は別の理由から gitignore の対象とする。レベルやフォーカスドメインは開発者ごとに異なる個人設定であり、バージョン管理に載せる性質のものではないためである。

### セッションごとの約束事

すべての Growth 対応エージェントは、Growth Mode が ON の状態で動作する際、応答の末尾に 2 つのトレーラー節を出力する。「何を教えたか」の要約と、「ノートブックの差分」のレポートの 2 つである。これらはあくまで応答内で学習者が目にする形で提示されるものであり、どこかのファイルに書き込まれるわけではない。

```
## Growth: taught this session
- [concept-name]: [one-sentence summary at the declared level]
- [concept-name]: [one-sentence summary]

## Growth: notebook diff
- notes/<domain>.md → <operation> on `## <section-heading>`: <one-sentence change summary>
- notes/<domain>.md → <operation> on `## <section-heading>`: <one-sentence change summary>
```

これによりノートブックの進化をリアルタイムで追えるようになり、学習者はエージェントが選んだ操作が妥当だったかを都度確認できる。たとえば、本当にそれは `deepen` だったのか、実は `correct` とすべきだったのではないか、といった判断を学習者自身が下せる。これは将来のツール連携の足がかりにもなる。学習者はチャット履歴をたどれば、任意のドメインファイルの変遷を再現できる。

## 検討した代替案

| 代替案 | 採用しなかった理由 |
|--------|---|
| 追記のみのジャーナル（当初の案） | 却下。体系化を伴わないため、知識が断片化する。学びの機会の時系列ログでは、人間がログを読み直して頭のなかで統合しない限り「並行性について自分は何を知っているのか」に答えられない。 |
| 単一の一枚岩な `notes.md` | 却下。スケールに耐えない。19 ドメインを 1 ファイルに詰め込むと、数週間のうちに節の構造が崩れていく。 |
| セッションごとの時系列ノート | 却下。ドメイン別に整理するという目的に反する。学習者が手にするのは「セッション 17 で何があったか」であって、「テスト規律について自分は何を知っているか」ではない。 |
| セッションごとに LLM で再要約するノート | 魅力的ではあるが却下。セッション末に LLM に要約させると一見手軽だが、その都度以前の素材が失われていく。セッション 2 でジュニアレベル向けに書かれた基礎的な説明は、3 ヶ月後に基礎を復習したいシニアレベルの学習者にとって、そのまま手を付けずに残しておきたい内容そのものである。要約によるアプローチでは supersede-with-history も機能しなくなる。要約器には、どのテキストが理由付きで supersede されたもので、どれが現時点で正しい説明なのかを区別する手段がないからである。失われる文脈のコストは、ファイルが短くなる利益を上回る。採用した方針は、書き直しではなく `deepen` と `supersede` によって層を重ねていくものであり、元の素材をすべて保持する。そこに本質がある。 |
| カスタムコマンド `.claude/commands/growth.md` | 却下。現在の Claude Code では Skills と Commands が統合されており、新しい用途では Skills が正典の選択肢である。カスタムコマンドには `disable-model-invocation` に相当する仕組みがないため、モデルが学習者の代わりに `/growth on` を自動起動してしまう可能性がある。これは「作者の境界」を反転させてしまう動きである。カスタムコマンドは慣習的に単一ファイルで完結するものなので、Skill のディレクトリが将来的に抱え込めるような支援ファイル（ステータス整形器、再編成用プロンプト、ヘルパー類）を置く余地も塞いでしまう。呼び出し制御、引数のマッピング、前方互換性のいずれの観点から見ても、Skill に軍配が上がる。 |
| ノートをデフォルトで Git にコミットする | 却下。ノートには誤りや以前の理解、supersede された履歴が含まれる。これは私的な学習素材であって、チームの共有リポジトリに公開するドキュメントではない。デフォルトでコミットしてしまうと、学習者のつまずきがリポジトリの履歴に流れ続けることになる。デフォルトを gitignore とし、`.gitignore.example` の反転パターンでオプトイン共有を用意するこの方針であれば、共有教科書を望むチームに道筋を提供しつつ、共有を既定として押し付けずに済む。 |

### 追記のみのジャーナル - 詳細

セッションログ機能の多くは、日付付きのエントリを持つ単一の `journal.md` から始まる。実装は容易で、エージェントはただ追記していくだけで、読み返すこともない。しかし 1 ヶ月もすれば、学習者が「エラー処理について自分は何を知っているか」と問うたとき、ジャーナル全体を grep で洗い、17 件のエントリを手作業でつなぎ合わせ、互いに矛盾がないことを祈るしかない、という状態になる。ジャーナルは学びの機会を捉えはするが、それを体系化はしない。これは、オーナー判断 3 が求めるものの対極にある。

### 単一の一枚岩な `notes.md` - 詳細

原理的には、見出しの規約を揃えれば、1 つの大きなファイルをドメイン別に整理することも可能である。しかし実際には、19 のドメインを 1 ファイルに同居させると、特定のドメインを読みたいだけでも、他の 18 ドメインをスクロールで通過しなければならない。アーキテクチャの節を編集しようとするエージェントは、他の部分の構造を壊さないために毎回ファイル全体をコンテキストに読み込む必要に迫られる。ドメインごとにファイルを分けるのは、そうした摩擦を避けるための自然な境界線である。

### セッションごとの時系列ノート - 詳細

ジャーナルのバリエーションで、追記していく代わりに、セッションごとに独立したファイル（例: `2026-04-22-session.md`）を作る方式である。個々のセッションを振り返るには便利だが、ドメイン別に整理されたリファレンスは得られない。「リポジトリパターン」を探す学習者は、それを含んでいそうなセッションファイルを 1 つずつ開いて確認することになる。

### セッションごとに LLM で再要約するノート - 詳細

各セッションの後に、エージェントがドメインファイル全体を読み込んで、より引き締まった版に書き直してコミットする方式である。確かに文章は短くなり、見た目も整う。しかし書き換えを行う側は「何を残すか」の取捨選択を強いられ、どのような書き直しも、以前のエントリの正確な文面を失わせる。具体的には 2 つの害が生じる。(1) `Superseded YYYY-MM-DD: <reason>` マーカー付きで残された supersede 済みエントリは、学習者に自分の理解がどう変化してきたかを教えてくれるが、書き直しはその歴史を押しつぶしてしまう。(2) ジュニアレベルの基礎となるエントリこそ、学習者が基礎を組み直すために読み返したい素材である。簡潔さを優先するよう調教された要約処理は、よりによってその基礎の部分を圧縮してしまう。オーナー判断 2 の「説明の深さは機能であってバグではない」が、この案を退ける。

## 結果

### ポジティブな帰結

- **ノートブックは学習者自身が築き上げた教科書になる**: 数十回のセッションを重ねると、学習者の手元にはドメイン別に整理された個人向けのリファレンスが残る。これは単なるログではなく、真に教育的な成果物であり、概念をたどっていつでも読み返せる。
- **ドメインをキーとした構造は、スタックの変更を越えて生き延びる**: 同じ 19 のドメイン名が Flutter プロジェクトにも Go プロジェクトにも適用できる。スタックを行き来する学習者は安定した概念的な足がかりを持ち続けられ、各ドメインファイルの中身は、いま使っているエコシステムでそのドメインがどのように立ち現れるかを教えてくれる。
- **`supersede` と履歴が、理解の変化を刻む**: 1 月に書かれた junior レベルのエントリと、6 月に書かれた senior レベルの洗練が、同じ節のなかに共存する。学習者は上から下へ読むだけで、自分の進歩の跡をたどれる。
- **いつでも自己レビューができる**: レビューのセッションの前に `review-taste.md` を開けば、これまで積み上げてきた勘どころを読み返せる。デプロイ前であれば `release-and-deployment.md` を開けばよい。ノートブックはセッションの成果物であるだけでなく、学習のためのツールとしても機能する。
- **エージェント別の担当範囲が明示される**: `growth_domains:` フロントマターにより、どのエージェントがどのドメインに貢献することになっているかを監査できる。エージェントの Growth 関連の責務を追加・削除するのは、1 行の変更で済む。
- **「作者の境界」をプラットフォーム層で強制できる**: Growth Skill の `disable-model-invocation: true` により、モデル側のターンが学習者を黙って教授モードに切り替えることはできない。この不変条件は、プロンプトの規律ではなく Claude Code そのものによって強制される。
- **デフォルト非公開という方針が、導入の心理的障壁を下げる**: 学習者はパブリックリポジトリで Growth Mode を動かしても、ノートがコードと一緒に公開されてしまう心配をせずに済む。チーム共有の教科書を望むチームは、`.gitignore.example` の反転パターンを 1 箇所有効にするだけでよい。
- **デフォルト OFF の不変条件が守られる**: `/growth on` を一度も実行しないユーザーは、ノートを目にすることもなく、読み込みや書き込み、エージェントの振る舞いの変化のいずれも発生しない。

### ネガティブな帰結／トレードオフ

- **Growth 対応エージェントの呼び出しは、いずれも I/O 重めになる**: 各ターンで、応答の生成前に `config.json`、`preamble.md`、そして 1 つ以上のドメインファイルを読み込むことになる。5 エージェントが 4 ドメインに触れるセッションでは、読み込みが 10 件規模、書き込みが複数回発生しうる。オプトインである限り許容できるコストだが、デフォルト有効であれば受け入れられない。だからこそ、デフォルト OFF の不変条件がこれまで以上に重要になる。
- **ON のときのコンテキストコストは、長さ上限を設けた場合よりも高くなる**: 貢献の深さは概念が要求するところまで踏み込むため、junior レベルの 1 セッションでリポジトリパターンを導入するだけでも、複数段落の節と具体例が生成されうる。これは意図した挙動であり、現実のコンテキスト消費であり、この設計が成立させようとしているものそのものである。
- **再編成の工程は簡単ではなく、誤りも起こりうる**: `refine` 操作を行うエージェントが、隣接する節をうっかり書き換えてしまう可能性がある。拡充操作プロトコルは、変更範囲外のバイト単位での保持を求めるが、その強制は規律の問題である。軽減策として、セッションの約束事に含まれる差分レポートが、そのセッション内で意図しない変更を可視化する。また、エージェントプロンプトやプリアンブルに変更が加わる PR では、レビュー時にこの性質が保たれていることを確認する。エージェント出力に対するバイト単位の自動アサーションは、LLM の非決定性ゆえに信頼できないため、採用しない。
- **セッション内でのマージコンフリクト**: 同一セッションのなかで、たとえば architect と implementer の 2 つのエージェントが連続して実行され、どちらも `architecture.md` の `Dependency Inversion` 節を拡充しようとする場合、2 番目のエージェントは 1 番目の書き込み後のファイルを読み込む必要がある。オーケストレーターが両者を並列実行し、どちらも編集前のファイルから処理を始めた場合、2 番目の書き込みが 1 番目を上書きしてしまう。軽減策として、オーケストレーターは同じドメインを対象とする Growth 対応エージェントを直列化する（実装ノート参照）。直列化が失敗して衝突が発生した場合でも、セッションの約束事に含まれる差分レポートに失われた操作が現れるため、学習者はエージェントに再実行を依頼できる。
- **プレッシャー下での非破壊的編集**: 古くなったエントリを「直してほしい」と頼まれたエージェントは、削除ではなく `correct` 操作を選び、supersede マーカーを付けたうえで修正版を追記しなければならない。プリアンブルは書き直しを明示的に禁じており、プリアンブルやエージェントプロンプトに変更が加わる PR のレビュー時に、この性質が保たれていることを確認する。

### 中立な帰結／今後のフォローアップ

- **チームはノート共有をオプトインで選べる**: 共有教科書を望むチームは、`.gitignore.example` の反転パターンを有効化し、`.claude/growth/notes/` をコミットする。明示的なエクスポート機能は設計しない。gitignore の経路がそのままエクスポートの経路を兼ねる。
- **時間が経つと、分割が必要になるほど大きく育つドメインファイルも現れる**: 詳細はオープンクエスチョンの節を参照。
- **technical-writer は主要な書き手であると同時にキュレーターでもある**: `documentation-craft` の主担当は、technical-writer がドキュメントの形や規律に関する教育内容を自ら生み出すことを意味する。加えて、ファイルが漂流し始めたときに、全ドメインを横断して分割の提案・統合・節のリネームなどを行うキュレーターとしての役割も副次的な責務として負う。
- **ノートの日本語訳は本 ADR の範囲外**: ノートディレクトリは出荷時点では英語のみである。`docs/ja/growth/notes/` のミラーを持つかどうかは、今後の判断に委ねる。

## 実装ノート

以下は、実装担当エージェントに向けた具体的なチェックリストである。`.claude/` と `docs/en/adr/` の既存の配置を前提とする。

### ディレクトリとシードファイル

以下の構成で `.claude/growth/` を作成する。

```
.claude/growth/
├── config.json
├── preamble.md
└── notes/
    ├── architecture.md
    ├── api-design.md
    ├── data-modeling.md
    ├── persistence-strategy.md
    ├── error-handling.md
    ├── testing-discipline.md
    ├── concurrency-and-async.md
    ├── ecosystem-fluency.md
    ├── dependency-management.md
    ├── implementation-patterns.md
    ├── review-taste.md
    ├── security-mindset.md
    ├── performance-intuition.md
    ├── operational-awareness.md
    ├── release-and-deployment.md
    ├── market-reasoning.md
    ├── business-modeling.md
    ├── documentation-craft.md
    └── ui-ux-craft.md
```

あわせて、リポジトリ直下に `.gitignore.example` を配置する。その中身は「決定」の節で定義した Growth Mode のプライバシーブロックであり、実際の `.gitignore` にはデフォルトでこれらの行が含まれる。`.gitignore.example` は、共有に切り替えたいチーム向けに、オプトイン用の反転パターンを文書化する役割を担う。

各シードファイルには、フロントマターと最初のプレースホルダ節を含める。エージェントが初めてファイルに触れたときに、どこに何を書けばよいのかがすぐに分かるようにするためである。

```markdown
---
domain: testing-discipline
owners: [test-runner, implementer, code-reviewer]
updated: 2026-04-22
---

# Testing Discipline

This domain covers how tests are structured, when each test type earns its keep,
fixture hygiene, and how test failures are triaged. Agents contribute entries
as teaching moments arise during real sessions; the file grows section by section.

## Placeholder

This section is seeded empty. The first agent with a teaching moment in this
domain will replace this placeholder with a real section following the
enrichment protocol in `.claude/growth/preamble.md`.
```

### `.claude/growth/preamble.md`

プリアンブルは、拡充操作プロトコルの唯一の参照元である。このファイルは次の事項を定める。

- 5 ステップの手順（特定／読み込み／操作の決定／非破壊的な適用／差分の報告）の定義。
- 5 種類の操作（`add`／`deepen`／`refine`／`correct`／`new-domain`）の列挙と、それぞれの具体例。
- supersede マーカーの書式の定義（`> Superseded YYYY-MM-DD: <reason>`）。
- 応答の末尾にエージェントが出力する差分レポートの書式の定義。
- junior／mid／senior の各レベルの意味づけ。これは貢献の切り口と密度を決めるものであって、長さの上限ではない。
- 19 の正典ドメインの列挙と、各ドメインが扱う内容の説明。
- 非破壊的な編集のルールと、新規ドメインを勝手に作らないというルール。
- 同じドメインを対象とする並列編集を直列化するルール。

Growth 対応エージェントはすべて、Growth Mode が ON の状態でセッションを開始した時点でこのファイルを読み込む。エージェントのプロンプトからはパスで参照するにとどめ、中身をインラインに展開することはしない。

### エージェント別のフロントマター追記

`.claude/agents/` 配下のすべてのファイルに対し、YAML フロントマターに新しい `growth_domains:` フィールドを加える。15 エージェント全員が少なくとも 1 つの主担当ドメインを持った状態で出荷され、例外リストも、`growth_domains: []` のまま出荷されるエージェントも存在しない。値はドメインキーの順序付きリストとし、主担当のドメインを先に、副担当のドメインを後ろに並べる。以下は architect の例である。

```yaml
---
name: architect
description: ...
model: opus
growth_domains: [architecture, api-design, data-modeling, persistence-strategy, error-handling, ecosystem-fluency, dependency-management, security-mindset]
---
```

各エージェントのプロンプト本体には、短い条件分岐を 1 つ追加する。意味としては次のようなものである。「`.claude/growth/config.json` が `enabled: true` を含むならば、`.claude/growth/preamble.md` と、`growth_domains` に列挙されたドメインのファイルを読み込んだうえで、拡充操作プロトコルに従う。応答の末尾には、教えたことの要約と、ノートブックの差分レポートを出力する」。エージェントのプロンプトに Growth 固有の内容として含めるのはこれだけで十分であり、ポリシーそのものは `preamble.md` に集約する。

### `.claude/skills/growth/SKILL.md` に配置する Growth Skill

次の YAML フロントマターを持つ `.claude/skills/growth/SKILL.md` を作成する。

```yaml
---
name: growth
description: Toggle Developer Growth Mode and manage per-domain focus for the notebook at .claude/growth/notes/.
disable-model-invocation: true
arguments:
  - name: action
    description: on | off | status | focus | domain | level
  - name: level
    description: Optional level (junior|mid|senior) for `on`, or subargument for other actions.
---
```

**`disable-model-invocation: true` を動かしようのないものとする理由**: Growth Mode は、それ以降すべてのエージェントターンの振る舞いを変える。教わる形を選び取るのは学習者自身でなければならない。モデルに `/growth on` を自動で呼び出させてしまうと、「作者の境界」が反転してしまう。この根拠は Skill 本体にも明記しておき、将来の保守担当者が「親切のつもり」でこのフラグを外すことがないようにする。

**各呼び出しの引数マッピング**

- `/growth on` もしくは `/growth on junior` → `$action=on`、`$level=junior`。省略時は保存済みのレベル、それもなければ既定の `junior`。
- `/growth off` → `$action=off`。
- `/growth status` → `$action=status`。
- `/growth focus concurrency-and-async,security-mindset` → `$action=focus`、`$level=<CSV>`。第 2 引数にドメインのリストを格納する。
- `/growth focus clear` → `$action=focus`、`$level=clear`。
- `/growth domain new <key>` → `$action=domain`、`$level=new <key>`。Skill 側でサブ引数をパースし、ファイル作成前に学習者の確認を必ず取る。
- `/growth level mid` → `$action=level`、`$level=mid`。

Skill 本体は `$action` をパースし、対応する処理にディスパッチする。状態は `.claude/growth/config.json` に書き出す。`domain new` の場合、Skill は明示的な確認を取ったうえで、`preamble.md` で定義された形に沿ってシードファイルを作成する。`config.json.focus_domains` は、学習者がオプトインした場合にのみ更新する。

### `/quiet` Skill — 独立した Skill として

`.claude/skills/quiet/SKILL.md` を独立した Skill として出荷し、`/growth` のサブコマンドにはしない。役割は、応答末尾のトレーラー（教えたことの要約とノートブック差分の節）を抑制することであり、Growth Mode 側の書き込みそのものは止めない。両者は「作者の境界」が異なる。`/growth` はノートブックを維持するかどうかを制御するもので、`/quiet` はトレーラーを描画するかどうかを制御するものである。両者を分けておけば、`/quiet` は Growth Mode の有無にかかわらず有用であり、将来は他のトレーラーを抑制する用途にも転用できる。

### CLAUDE.md のポインタ

`.claude/CLAUDE.md` に新しい見出し `## Developer Growth Mode` を立て、その下に短いブロックを追記する。

```markdown
## Developer Growth Mode

Growth Mode is a default-off learning layer. When enabled via the `/growth` Skill
(`/growth on [junior|mid|senior]`), every agent contributes to a domain-organized
notebook at `.claude/growth/notes/`. The notebook grows and is refined over many
sessions into a personalized reference the learner built by shipping real features.
Notes and `config.json` are gitignored by default; see `.gitignore.example` to opt
in to team sharing. The enrichment protocol every agent follows is defined in
`.claude/growth/preamble.md`. Run `/growth status` to see current state.
```

CLAUDE.md に置く Growth Mode 関連の記述はこれだけにとどめ、エージェントプロンプトの中身をここに書き写すことはしない。

### オーケストレーターの直列化ルール

オーケストレーターエージェントのプロンプトに、次のルールを追加する。Growth Mode が ON で、委任先のエージェント 2 つ以上のあいだで `growth_domains` が重なる場合、並列ではなく直列で実行する。`growth_domains` が重ならない場合は、並列実行で構わない。これにより、ノートブックに関わる並列化を完全に諦めずに済みつつ、「読み込み→変更→書き戻し」の不変条件を守れる。

### 強制: デフォルト OFF の不変条件

デフォルト OFF の不変条件は、本機能全体の屋台骨である。この不変条件は、エージェント応答をゴールデンファイルと突き合わせる形ではなく、3 つの決定論的な前提条件によって強制する。LLM の出力は、実行ごと・モデルバージョン・プロンプト圧縮イベントを通じて非決定的であり、エージェント応答に対するハッシュベースの回帰テストハーネスは遅かれ早かれ不安定テストに劣化して無効化されるため、テストが無い状態よりも有害となる。

不変条件を実際に強制する 3 つの前提条件は次のとおりである。

1. **`.claude/skills/growth/SKILL.md` の `disable-model-invocation: true` フラグ**: これは「壁」である。モデルは自分で Growth Mode を ON に切り替えられない。切り替えられるのはユーザーだけである。CI では 1 行の grep で検証する。
2. **すべての Growth 対応エージェントプロンプトのガード分岐**: すべてのエージェントは次のように指示されている。セッション開始時に `.claude/growth/config.json` を読み、ファイルが存在しないか `enabled: false` であれば、Growth 関連のステップをすべてスキップする。これは「床」であり、挙動そのものがここに実装されている。`.claude/agents/` 配下で `growth_domains:` を宣言しているすべてのファイルに対して、ガード分岐のマーカー文字列を grep することで検証する。
3. **gitignore の方針**: `.claude/growth/notes/` と `.claude/growth/config.json` が出荷時点の `.gitignore` によって無視されている。grep で検証する。

CI では、単一のシェルスクリプト（`scripts/check-growth-invariants.sh`）がこの 3 つの grep チェックを実行する。3 つとも決定論的で、モデルのバージョンに依存せず、LLM を介在させない。

### PR レビューで確認する設計目標

本システムの以下の 3 つの性質は、自動テスト対象ではなく設計目標として扱う。エージェント出力に対して自動テストを行おうとすると、同じ非決定性の問題に突き当たるためである。これらの性質は、`.claude/growth/preamble.md` やエージェントプロンプトに変更が加わった際に、PR レビューで確認することで担保する。

- **非破壊的な編集**: `deepen` を適用するエージェントは、対象節の既存内容をバイト単位で保持し、途中への差し込みではなく末尾への追記を行うこと。`refine` を適用するエージェントは、元の版を supersede ブロックとして可視状態で残すこと。`correct` を適用するエージェントは、`> Superseded YYYY-MM-DD: <reason>` マーカーの下に、supersede されたテキストをそのまま残すこと。
- **supersede の履歴**: 同じ節に対して `correct` 操作を複数回適用しても、過去のすべての版がマーカー付きでファイルに残り、どの版も黙って削除されないこと。
- **ドメイン境界の規律**: エージェントは主担当ドメインに書き込み、副担当ドメインには相互参照を残すだけで、内容を重複させないこと。

これらの性質は `.claude/growth/preamble.md` に明記されており、エージェントプロンプトやプリアンブルを変更する PR のレビュー時に検証される。

### gitignore の方針チェック

4 つ目のチェックで、これも grep であり、同じ `scripts/check-growth-invariants.sh` に含める。クリーンなクローンに対して、`.gitignore` が `.claude/growth/notes/` と `.claude/growth/config.json` を無視するエントリを含んでいることをアサートし、`.gitignore.example` にオプトイン反転のコメントブロックが含まれていることもアサートする。これにより、テンプレートを編集する過程でプライバシーのデフォルトが誤って崩れることを防ぐ。

## オープンクエスチョン

以下の立場はいずれも暫定的なものである。オーナー判断によって確定した項目（gitignore の方針、ドメイン数、Skill と Command の選択、長さの上限、全エージェントの Growth 対応）は「決定」の節に移したため、このリストからは除いてある。

1. **ドメインファイルはどのサイズで分割すべきか**
   暫定的な立場としては、およそ 1200 行、もしくは最上位の節が 8 個を超えたところのうち、いずれか早いほうで分割を検討する。分割のきっかけを作るのは、キュレーターとしての technical-writer エージェントであり、内容を寄稿するエージェントではない。分割後は、派生キーを持つ兄弟ファイル（たとえば `architecture.md` から `architecture-layering.md` と `architecture-boundaries.md` を派生させる）を作成し、元のファイルには参照先ポインタとなる節を残す。根拠は、1200 行程度までであればファイルはリファレンスとして読めるが、それを超えると概念検索の効率が落ちる、という経験則に基づく。この閾値そのものは、実際のノートブックが現場でどう育つかを見ながら動かしていく余地がある。

2. **オーケストレーターは、同じドメインファイルへの並行書き込みをどう直列化すべきか**
   暫定的な立場としては、オーケストレーターは現在のターンで呼び出そうとしているすべてのエージェントの `growth_domains` を事前に検査する。2 つ以上のエージェントが同じドメインに重なっていれば直列で実行し、それ以外は並列実行でかまわない。未決の部分として、ハーネス自体がオーケストレーターの制御外でエージェントを並列化する場合に、正しい契約がどうあるべきかという問題が残る。Skill のフレームワーク側でファイルレベルのロックを露出すべきか、それともオーケストレーター層での直列化だけに頼るかは、Growth 対応エージェントをオーケストレーター以外のハーネスで動かす段になると、途端に重要になる。

3. **複数のドメインにまたがる学びの機会はどう扱うべきか**
   暫定的な立場としては、エージェントは主担当のドメインに書き込み、副担当のドメインには相互参照の行を 1 つ生成して、主担当側のエントリを指し示す。相互参照は相対 Markdown リンク（例: `See [Dependency Inversion](./architecture.md#dependency-inversion)`）で表現する。完璧ではないが、ノートブックをたどれる状態に保つうえで最も安価な方法である。未決の部分として、この相互参照自体を 1 つの操作として差分レポートで追跡すべきかどうかが残る。

4. **学習者がプロジェクトの途中でレベルを切り替えたとき、何が起きるか**
   暫定的な立場としては、新しい貢献は新しいレベルに従い、既存のエントリは書き直さない。junior から mid に移った学習者の、基礎となる足場を消してしまいたくはない。その素材は、以降のより高いレベルのセッションで読み返すための資源として価値を持ち続けるし、その上に慣用表現やトレードオフに関する素材が層として積み重なっていく。

5. **technical-writer はノートブックを定期的にレビューすべきか**
   暫定的な立場としては、はい、ただし自動ではなく、明示的な呼び出し（Skill 経由で発火する `/growth review`）によってオンデマンドで行う。自動再編成は編集のロスを招くリスクが高く、学習者を起点としたレビューのほうが、より明確な監査の跡を残せる、というのが根拠である。

## 参考

- PRD: [docs/en/prd/developer-growth-mode.md](../prd/developer-growth-mode.md) — プロダクトレベルの要件、レベルの意味づけ、受け入れ基準、および同じ機能のロールアウト計画。
- 分類体系: [docs/en/growth/domain-taxonomy.md](../growth/domain-taxonomy.md) — 正典となる 19 ドメインの定義、隣接ドメイン同士の境界の担当分担（特に `ecosystem-fluency` と `dependency-management`、および `data-modeling` と `persistence-strategy`）、エージェント別の確定版の担当対応表。本 ADR の担当表はこちらと照合され、内容が食い違った場合には分類体系側を真とする。
- ADR テンプレート: [docs/en/adr/000-template.md](./000-template.md) — 本 ADR は最小テンプレートを、メタデータ、検討した代替案（表と本文の両方）、オープンクエスチョン、実装ノートの節で拡張している。
- Claude Code の Skills: https://docs.claude.com/en/docs/claude-code/skills — `disable-model-invocation`、`arguments`、支援ファイル用ディレクトリに関する一次情報。
- Claude Code のエージェントフロントマター: https://docs.claude.com/en/docs/claude-code/sub-agents — `growth_domains:` フィールドの規約の出所。
- プロジェクトの CLAUDE.md: [.claude/CLAUDE.md](../../../.claude/CLAUDE.md) — 本機能が拡張する 15 エージェントのチームの一覧。

スタイル上の補足: 本 ADR の構造は、メタデータ、コンテキスト、決定、検討した代替案、結果、実装ノート、オープンクエスチョン、参考、の順とする。同程度の重みを持つ意思決定を今後記録する際にも、この形式を踏襲する。
