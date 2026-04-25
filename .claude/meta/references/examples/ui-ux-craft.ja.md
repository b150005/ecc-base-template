> このドキュメントは `.claude/meta/references/examples/ui-ux-craft.md` の日本語訳です。英語版が原文（Source of Truth）です。

---
domain: ui-ux-craft
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: ui-ux-designer
contributing-agents: [ui-ux-designer]
---

> **読み取り専用リファレンス。** このファイルは ECC Base Template に同梱された作業例であり、実際のプロジェクトで多くのセッションを経た後のナレッジファイルがどのような状態になるかを示しています。これはあなた自身のナレッジファイルではありません。あなた自身のナレッジファイルは `.claude/learn/knowledge/ui-ux-craft.md` に置かれており、エージェントが実際の作業中にエンリッチするまでは空の状態です。エージェントは `.claude/meta/references/examples/` 以下を読んだり、参照したり、書き込んだりすることはありません。このツリーは人間の読者のみを対象としています。設計の根拠については [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) を参照してください。

---

<a id="how-to-read-this-file"></a>
## このファイルの読み方

レベルマーカーは各セクションの対象読者を示しています。
- `[JUNIOR]` — ファースト・プリンシプルによる説明。事前の知識を前提としません
- `[MID]` — このスタックにおける非自明なイディオマティックな適用
- `[SENIOR]` — デフォルトではないトレードオフの評価。何を諦めるかを明示します

---

<a id="information-density-on-the-task-list"></a>
## タスクリストの情報密度  [JUNIOR] [MID] [SENIOR]

<a id="first-principles-explanation"></a>
### ファースト・プリンシプルによる説明  [JUNIOR]

リストビューはスキャンするための画面であり、読むための画面ではありません。ユーザーはタスクリストを縦に流し見しながら、特定のタスクや注意が必要なタスクを探します。リスト行の各フィールドに対して問うべき重要な問いは「このフィールドはユーザーがスキャンを止めるかどうかを判断する助けになるか」です。答えが否であれば、そのフィールドは横幅を消費し視線を引きつけるというコストを持ちながら、メリットをもたらしません。

**情報密度**とは、画面上の単位面積あたりに表示されるデータの量を指します。密度が高いほど少ないピクセルに多くのデータを収められます。密度が低いほど各データポイントに余白が生まれます。どちらの極端も正解ではなく、適切な密度はユーザーがやろうとしていることと扱うデータ量によって異なります。

タスク管理製品において、タスクタイトルは常に表示する価値があります。アサイニーのアバターは、タスクが異なる担当者に割り当てられており、誰が何を担当しているかを把握する必要がある場合に表示する価値があります。優先度チップは、優先度がソートのシグナルであって装飾ではない場合に表示する価値があります。期日は、時間的プレッシャーが実際に存在する場合に表示する価値があります。

よくある間違いは、フィールドがスキャンの助けになるからではなく、単に存在するからという理由で追加してしまうことです。タスクタイトル、アサイニー、優先度、期日、プロジェクト、ラベル、最後のコメントプレビュー、作成日をすべて表示する行は、技術的には高密度ですが、実用的には読みにくくなります。視線がどこに落ち着けばよいかわからなくなるため、ユーザーはスキャンできません。

<a id="idiomatic-variation"></a>
### イディオマティックな適用  [MID]

Meridian のタスクリストは、エンタープライズ顧客のフィードバックを受けて追加された「Comfortable」と「Compact」の 2 つのモードで提供されています。デフォルトの Comfortable モードでは、各行に次の情報が表示されます。

- タイトル（プライマリ、大きく、1 行で切り捨て）
- アサイニーのアバター（24 px、フルネームのツールチップ付き）
- 優先度チップ（カラーラベル: Urgent / High / Normal / Low）
- 期日（相対表示: "due tomorrow"、"2 days overdue"）

Compact モードでは行の高さが 30% 減少し、期日はアイコンとツールチップに変わります。アサイニーは 20 px に縮小されます。タイトルは残りの全幅を引き続き使用します。モードの切り替えはビュー単位ではなく、ユーザーごとに永続化されるワークスペースレベルの設定です。Compact を好むユーザーはどこでも Compact で表示されます。

初回リリースでは Comfortable モードのみが提供されていました。両モードを提供するに至った経緯は [Prior Understanding: Single Density Mode](#prior-understanding-single-density-mode) に記載されています。

リストから意図的に省いているもの: プロジェクト名（タイトルのブレッドクラムにホバーするとアクセス可能）、最終更新タイムスタンプ（詳細ドロワーで確認可能）、作成日（詳細ドロワーで確認可能）、ラベル（デフォルトでは行ではなくフィルターサイドバーに表示）。これらはいずれも意図的な省略です。これらのフィールドは詳細な調査には有用ですが、スキャンには適していません。

<a id="trade-offs-and-constraints"></a>
### トレードオフと制約  [SENIOR]

フィールドがどれほどコンパクトであっても、リスト行に追加するとスキャン性はコストとして失われます。視覚的要素が増えるたびに、それが無関係なときに目が無視しなければならないものが一つ増えます。トレードオフは常に「このフィールドが重要なときにリストの使いやすさが向上するか、また重要でないときにその存在をユーザーが許容できるか」という問いに帰着します。

Meridian における優先度チップはこのトレードオフの最たる例です。すべてのタスクが Normal 優先度の場合、チップは視覚的ノイズになります。すべての行に同じチップが表示されます。デザインチームは Normal 優先度のときはチップを非表示にする（Non-Normal の優先度のみ表示する）案を検討しましたが、アナリティクスによってユーザーがトリアージ中に Normal 優先度のタスクを積極的に探していることが明らかになったため、チップを残す判断をしました。コストはトリアージが不要な状況での視覚的な均一性です。メリットは積極的なトリアージセッション中における一貫したスキャン性です。

Compact モードは妥協の産物ではなく、異なるユーザーのための別製品です。1 日に 200 以上のタスクを管理するデスクトップのパワーユーザーには Compact が適しています。少ないタスクを扱う非頻繁ユーザーには Comfortable の余白が適しています。両モードを提供するにはメンテナンスコストが伴います（2 つの CSS レイアウト、2 セットのスナップショットテスト、2 行の E2E カバレッジ）が、Meridian のエンタープライズ契約を牽引するユーザーセグメントに対応できます。

このリストビューを支える API 設計については [See api-design → Cursor-Based Pagination on Task Lists](./api-design.md#cursor-based-pagination-on-task-lists) を参照してください。特に、アクティブなセッション中にタスクが作成されたときの行スキップアーティファクトを避けるためにカーソルページネーションが選ばれた理由が記載されています。

<a id="prior-understanding-single-density-mode"></a>
### Prior Understanding: Single Density Mode

> Superseded: Meridian shipped v1.0 with a single row density. This was revised after
> enterprise customers with large workspaces reported that the list felt "sluggish to scan"
> compared to competitor tools.

**Prior implementation (single density):** One fixed row height, all four fields always
visible, no user preference.

**Corrected understanding:**

Enterprise users managing 200+ tasks do not have the same scanning needs as small-team
users with 15 tasks. A single density optimized for readability at small scale created
friction at large scale. The Compact mode was added in v1.4, gated behind a workspace
preference. The default remained Comfortable so existing users were not disrupted.

The lesson: density is not a universal preference. Products that cross the threshold
from small-team to enterprise use almost always need to offer multiple densities. The
forcing function is user complaints about scanning speed, not visual design instinct.

---

<a id="interaction-states-as-first-class-design"></a>
## インタラクション状態のファーストクラス設計  [JUNIOR] [MID] [SENIOR]

<a id="first-principles-explanation-1"></a>
### ファースト・プリンシプルによる説明  [JUNIOR]

ユーザーインターフェースのすべてのインタラクティブ要素は複数の状態を持っています。ボタンはデフォルトの見た目だけでなく、ホバー、フォーカス、アクティブ（押下）、無効、ローディングの各状態を持ちます。リスト行にはデフォルト、ホバー、選択中、ドラッグ中の状態があります。フォームフィールドにはデフォルト、フォーカス中、入力済み、無効、非活性の状態があります。

デフォルト状態だけを設計し、残りをブラウザやコンポーネントライブラリに任せると、インターフェースは未完成な印象を与えます。ボタンにホバーしても何も変化しないとき、ユーザーはその要素がインタラクティブかどうかを疑います。送信後にフォームフィールドが赤いボーダーを表示するだけで何が問題かを説明するメッセージがなければ、ユーザーは何を修正すればよいかわかりません。

**ファーストクラスのインタラクション状態**という考え方は、デフォルト以外のすべての状態をデフォルト状態と同じ精度の設計成果物として扱うことを意味します。新しい画面を出荷する前に、デザイナー（またはその画面をレビューするエンジニア）はチェックリストを確認します。ローディング中はどう見えるか？データがない場合は？エラーが発生した場合は？ユーザーが操作できない場合は？

これは完璧主義ではなく、テストでは見えないが実際のユーザーには即座に見えるバグの一群を排除することです。

<a id="idiomatic-variation-1"></a>
### イディオマティックな適用  [MID]

Meridian では、新しいコンポーネントがコードレビューで受け入れられる前に、以下の画面チェックリストをすべて適用します。

| 状態 | 必要なコンポーネント | 定義すべき内容 |
|-------|-------------|----------------|
| Default | すべてのコンポーネント | 静止時の外観 |
| Hover | クリック可能・ドラッグ可能な要素 | カーソル、背景色の変化、または微妙な浮き上がり |
| Focus | すべてのインタラクティブ要素 | 視認できるフォーカスリング（3px、`--color-focus`） |
| Active（押下） | ボタン、クリック可能な行 | 短い縮小（0.97）または暗い塗りつぶし |
| Disabled | フォームコントロール、ボタン | 40% 透明度、`cursor: not-allowed`、理由を説明するツールチップ |
| Loading | データ依存の画面 | スピナーではなくスケルトンローダー |
| Error | フォーム、データ取得 | エラー発生箇所にインラインメッセージ |
| Empty | リスト、ボード、検索結果 | 明確な次のアクション付きのイラスト入り空状態 |

フォーカスリングの要件は交渉の余地がありません。代替フォーカスインジケーターなしの `outline: none` は WCAG 2.1 AA 違反であり、Meridian のコードレビューでのブロッカーです。リングはデザイントークン（`--color-focus: oklch(68% 0.21 250)`）を使用しており、アクセントカラーが変更された場合にグローバルに更新できます。

ローディング状態にはスピナーではなくスケルトンローダー（コンテンツの形を模したグレーのブロック）を使用します。Meridian の主要な画面であるタスクリストは、ロード時点で既知の構造を持っているためです。タスク行の形を模したスケルトンは、何がロード中でどれだけのスペースを占有するかをユーザーに伝えます。スピナーは何かが起きていることしか伝えません。TanStack Query の `isLoading` フラグと `isFetching` フラグがスケルトン表示を駆動する仕組み、および初回ロードとバックグラウンド更新の区別については [See ecosystem-fluency → TanStack Query as Meridian's Data Layer](./ecosystem-fluency.md#tanstack-query-as-meridians-data-layer) を参照してください。

空の状態は最も省略されやすい状態です。Meridian では、すべてのリストビューに設計された空状態があります。イラスト、見出し（"No tasks yet"）、プライマリアクション（"Create your first task"）が含まれます。イラストは画面固有です。タスクリスト、チームボード、通知センターはそれぞれ独自のものを持ちます。空状態はあとから付け足すのではなく、ポピュレート状態と同じパスで設計されます。

<a id="trade-offs-and-constraints-1"></a>
### トレードオフと制約  [SENIOR]

8 つの状態すべてを設計するには時間がかかります。トレードオフは、フロントエンドに集中するコストと、バックエンドに分散する欠陥のどちらを選ぶかです。無効状態の欠落はユニットテストではなく、ユーザーテストやサポートチケットで発見されます。空の状態が欠落していると、その状態に最初に到達したユーザーはガイダンスのない空白ページを見ることになります。これは摩擦の大きい瞬間であり、多くの場合サポートチケットや解約シグナルを引き起こします。

スケルトン対スピナーの選択にはメンテナンスコストが伴います。スケルトンは画面のレイアウトが変更されたときに更新が必要です。スピナーは陳腐化しません。Meridian ではこのコストを許容しています。なぜなら、ユーザー体験上のメリットが大きいからです。タスクリストのスケルトンはポピュレートされたリストと同じ視覚的リズムでレンダリングされ、データが到着する前にユーザーに方向感覚を与えることで知覚される読み込み時間が短縮されます。

無効状態のツールチップは特定の投資です。無効なボタンを説明せずに放置するのではなく、Meridian はホバー時に理由を説明するツールチップを表示します（「Only workspace admins can archive a workspace」）。これはマイクロコピーのコミットメントです。すべての無効状態には理由が必要であり、その理由は文章として書かれなければなりません。コストは作成時間です。メリットは、ユーザーが自分にできないことと理由を理解でき、混乱とサポート負荷が軽減されることです。これらの説明を管理するマイクロコピーの方針については [See documentation-craft.md](./documentation-craft.md) を参照してください。

---

<a id="accessibility-keyboard-navigation-and-contrast"></a>
## アクセシビリティ: キーボードナビゲーションとコントラスト  [MID] [SENIOR]

<a id="idiomatic-variation-2"></a>
### イディオマティックな適用  [MID]

Meridian のかんばんボードは、タスクをステータス列間で移動するためのドラッグ＆ドロップインターフェースを提供しています。ドラッグ＆ドロップは本質的にポインターに依存したインタラクションモデルです。キーボードおよびスクリーンリーダーのユーザーには、明示的な代替手段がなければ完全なブロッカーとなります。

Meridian が提供する代替手段は、すべてのタスクカードに配置されたコンテキストメニューです。キーボードショートカット `Enter` またはスリードットボタン（フォーカス時とホバー時に表示）でアクセスできます。メニューには各列への「Move to...」アクションが含まれます。このアクションはキーボードで操作でき、スクリーンリーダーにアナウンスされ、ドラッグ＆ドロップと同じ結果をもたらします。

ポインターなしでタスクを「Done」に移動するキーボードフロー: タスクカードへの `Tab`、コンテキストメニューを開く `Enter`、「Move to...」→「Done」へのカーソルキー、確定の `Enter`。

ボードは列内のカード間（`Up`/`Down`）および列間（`Left`/`Right`）のカーソルキーナビゲーションもサポートしています。現在のカードには視認できるフォーカスリングが表示されます。タスクが移動されると `aria-live="polite"` が列の変更をアナウンスします。「Task 'Update billing contact' moved to Done.」

<a id="trade-offs-and-constraints-2"></a>
### トレードオフと制約  [SENIOR]

キーボードの代替手段は、ポインターを持つパワーユーザーのドラッグ＆ドロップほど速くはありません。これは期待されるトレードオフです。アクセシビリティの代替手段がポインター版と同じ速度に達することはほとんどありません。目標は同じ速度ではなく、同等の機能です。キーボードユーザーはポインターユーザーが実行できるすべての操作を実行できます。パスは長いですが、完全です。

優先度チップのコントラスト比には特定の設計上の判断が必要でした。初期デザインでは完全に彩度の高いチップ背景を使用していました。Urgent には鮮やかな赤、High には鮮やかなオレンジ、Normal には落ち着いたグリーン、Low にはグレー。WCAG 2.1 AA では、色付き背景上のテキストは小テキスト（18px 太字未満または 24px 通常未満）に対して 4.5:1 のコントラスト比が必要です。鮮やかな赤背景（`oklch(55% 0.21 25)`）の白テキストは 4.8:1 でパスしました。鮮やかなオレンジ背景（`oklch(68% 0.18 55)`）の白テキストは 2.9:1 でフェールしました。

修正されたデザインでは High 優先度により暗いチップ背景を使用しています。`oklch(48% 0.18 55)`（ダークアンバー）は白テキストに対して 4.6:1 でパスします。視覚的なコストは、High チップが「鮮やかなオレンジ」に見えなくなることです。ダークアンバーとして読まれるため、元の色ほど即座に警戒感を与えません。デザインチームはこのトレードオフを許容しました。WCAG AA 準拠は、アクセシビリティ要件が調達契約に含まれる顧客が使用する可能性がある B2B 製品にとって交渉の余地がないからです。

B2B SaaS のエンタープライズ調達では、アクセシビリティ要件が契約条項として含まれることが増えています。WCAG AA 準拠を実証できない製品はベンダー評価段階で失格になる可能性があります。シートあたりのエンタープライズ契約がこのような設計上の判断をどのように牽引するかについては [See business-modeling.md](./business-modeling.md) を参照してください。

---

<a id="microcopy-precision-at-decision-points"></a>
## マイクロコピー: 判断ポイントでの精度  [JUNIOR] [MID] [SENIOR]

<a id="first-principles-explanation-2"></a>
### ファースト・プリンシプルによる説明  [JUNIOR]

**マイクロコピー**はユーザーインターフェース内の短いテキストです。ボタンのラベル、確認メッセージ、エラーの説明、空状態の見出し、プレースホルダーテキスト、ツールチップの内容。「マイクロ」と呼ばれるのは各ピースが小さいからです。数語、まれに 2 文を超えることもありません。ユーザビリティへの累積的な影響は大きいものです。

最も一般的なマイクロコピーの失敗は、判断ポイントでの曖昧さです。次のようなモーダルを考えます。

> Are you sure?
> **Cancel** | **OK**

「OK」をクリックすると何が起きるか」という問いに答えていない 2 つの単語がユーザーの前に置かれています。ユーザーは「OK」が何を意味するかを解釈するために、どのアクションがモーダルを開いたかを思い出さなければなりません。「このタスクをアーカイブする」というアクションだった場合、ユーザーは「OK」が「はい、アーカイブする」を意味することを思い出す必要があります。これは再認ではなく想起であり、Nielsen のユーザビリティヒューリスティックの一つに違反しています。

正確なマイクロコピーは問いに直接答えます。

> Archive "Update billing contact"?
> This task will be moved to the archive. You can restore it later.
> **Keep editing** | **Archive task**

プライマリアクション（「Archive task」）はアクションを名指ししています。セカンダリアクション（「Keep editing」）はキャンセルするものではなく、ユーザーが保つものを名指ししています。ユーザーはコンテキストを思い出す必要がありません。モーダル自体がコンテキストを持っているからです。

<a id="idiomatic-variation-3"></a>
### イディオマティックな適用  [MID]

Meridian はアクションの可逆性に基づいて 2 種類の確認パターンを使用しています。

**可逆的な破壊的アクション**（アーカイブ、クローズ、アサイン解除）: アクションとその結果を説明し、ラベル付きのプライマリボタンとセカンダリボタンを持つモーダル。セカンダリボタンは常に「Cancel」ではなく「Keep [名詞]」です。ユーザーはリクエストをキャンセルしているのではなく、現在の状態を維持することを選んでいます。

Meridian コードベースからの例:
- タスクのアーカイブ: 「Archive task」/ 「Keep editing」
- プロジェクトのクローズ: 「Close project」/ 「Keep open」
- アサイニーの削除: 「Remove [Name]」/ 「Keep assigned」

**不可逆的な破壊的アクション**（削除、完全削除）: 入力確認モーダル。プライマリボタンが有効になる前に、ユーザーはリソース名または「delete」という単語を入力する必要があります。プライマリボタンは赤色で、正確なアクションのラベルが付いています。「Delete workspace」であり、「Delete」や「Confirm」ではありません。

入力確認パターンは不可逆的なアクションにのみ表示されます。Meridian のルール: アクションを元に戻せる場合（アーカイブから復元、再招待、再オープン）は標準の確認モーダルを使用します。元に戻せない場合は入力確認を要求します。この区別は重要です。すべての破壊的アクションに入力確認を要求すると、ユーザーは内容を読まずに素早く入力するよう訓練され、目的が失われます。

「Don't save」のアンチパターン: 未保存の変更があるユーザーが離れようとする場合、モーダルに「Cancel」/「Don't save」と表示すべきではありません。「Don't save」は解釈を遅らせる二重否定です。Meridian では「Keep editing」/「Discard changes」を使用しています。どちらも肯定的で、別のアクションを否定するのではなくボタンが行うことを名指ししています。

<a id="trade-offs-and-constraints-3"></a>
### トレードオフと制約  [SENIOR]

正確なマイクロコピーは、確認時点でリソース名を把握している必要があります。「Archive task」は「Archive item」よりも有用です。ユーザーは何を操作しているかを正確に知れるからです。しかしこのためには、あらゆる画面が呼び出せる汎用確認コンポーネントではなく、モーダルがタスクタイトルをプロップ（またはコンテキスト）から受け取る必要があります。

Meridian ではすべての確認モーダルをリソース認識にするという設計判断をしました。コストは汎用的な `<ConfirmationModal>` コンポーネントが存在しないことです。`<ArchiveTaskModal>` と `<DeleteWorkspaceModal>` のように、それぞれが自分のリソースを知っています。単一の汎用モーダルよりもコードは増えますが、すべての確認における正確でコンテキストを持つ言語というユーザー体験上のメリットが重複に値します。

代替案である汎用モーダルにリソース名プロップを渡す方法も可能ですが脆弱です。ボタンラベルの文字列補間（「Archive [task name]」）は英語では機能しますが、記事と動詞の形が名詞に依存するジェンダー言語では崩れます。Meridian は現時点で英語以外のロケールを提供していないため、これは先送りにしている懸念事項です。ローカライゼーションが追加される場合、リソース固有のモーダルアプローチでは単一の翻訳文字列テンプレートではなく、モーダルごとのローカライゼーションラッパーが必要になります。これは現在のアプローチの既知のコストです。

---

<a id="dark-mode-as-a-design-system-commitment"></a>
## デザインシステムのコミットメントとしてのダークモード  [MID] [SENIOR]

<a id="idiomatic-variation-4"></a>
### イディオマティックな適用  [MID]

Meridian のダークモードは、単一のカラー変数に適用される CSS の `prefers-color-scheme` メディアクエリではありません。デュアルパレットのデザインシステムです。システム内のすべての色にライトモードとダークモードの両方の値があり、それらは単純に反転されたものではありません。

デザイントークンの構造:

```css
:root {
  /* Semantic tokens — always reference these, never raw palette */
  --color-surface-primary: oklch(98% 0 0);
  --color-surface-secondary: oklch(94% 0 0);
  --color-text-primary: oklch(14% 0 0);
  --color-text-secondary: oklch(42% 0 0);
  --color-border: oklch(88% 0 0);
  --color-accent: oklch(55% 0.21 250);
  --color-focus: oklch(68% 0.21 250);
  --color-urgent: oklch(48% 0.21 25);
  --color-high: oklch(48% 0.18 55);
}

[data-theme="dark"] {
  --color-surface-primary: oklch(16% 0 0);
  --color-surface-secondary: oklch(22% 0 0);
  --color-text-primary: oklch(94% 0 0);
  --color-text-secondary: oklch(68% 0 0);
  --color-border: oklch(30% 0 0);
  --color-accent: oklch(70% 0.21 250);   /* lighter in dark mode */
  --color-focus: oklch(78% 0.21 250);    /* lighter in dark mode */
  --color-urgent: oklch(62% 0.21 25);    /* lighter in dark mode */
  --color-high: oklch(62% 0.18 55);      /* lighter in dark mode */
}
```

重要な洞察: セマンティックトークン（surface、text、border）はその機能のために名付けられており、色の値のためではありません。コンポーネントは生の hex や `oklch()` 呼び出しではなく `--color-surface-primary` を参照します。テーマが変更されると、セマンティックトークンを使用するすべてのコンポーネントがコード変更なしに自動的に再着色されます。

ダークモードではアクセント、Urgent、High の色が変化します。コントラスト要件が逆転するからです。ライトモードでは、Urgent カラーは白テキストが 4.5:1 で読めるほど暗い必要があります。ダークモードでは背景が暗いため、Urgent カラーはより明るくできます。チップ上のテキストはチップの明度に応じて白または暗色になります。デュアルパレットアプローチはこれを正しく処理します。単純な CSS 反転（`hue-rotate(180deg)` または明度の反転）では対応できません。

<a id="trade-offs-and-constraints-4"></a>
### トレードオフと制約  [SENIOR]

真のデュアルパレットダークモードのコストは、新しい色を追加するたびにライトの値とダークの値の 2 つの判断が必要になることです。インライン色を一箇所だけ追加するエンジニアはシステムを崩壊させます。Meridian ではトークンファイル外の生の `oklch()`、`rgb()`、hex 値にフラグを立てる stylelint ルールによってこれを強制しています。このルールは完璧ではありません（CSS カスタムプロパティは JavaScript 経由で設定できます）が、最も一般的なドリフトは検出できます。

代替案である CSS `prefers-color-scheme` 反転は、より速く実装でき、継続的な規律も不要です。トレードオフは、反転がほとんどの場合に正しく見えないことです。影が明るい発光に変わり、白背景向けに設計された彩度の高いチップがほぼ黒い背景では不自然に見えます。反転ベースのダークモードを提供するチームは、ダークモードが使用不能だというユーザー報告を一貫して受け取ります。

ダークモードはファーストクラスのデザインシステムコミットメントか、そうでなければ負債です。ほとんどの画面は正しく見えるが一部は明らかにそうでないという部分的なダークモードは、ダークモードなしよりも悪い状況です。ユーザーが有効にしているモードで製品が壊れているというシグナルを送ってしまうからです。Meridian はアクティブユーザーの 34% が OS レベルでダークモードを有効にしていることをアナリティクスが示した後、v1.2 でこのコミットメントをしました。遅延はリソース上の判断でした。一度コミットしたら、それは完全なものでした。

---

<a id="the-assignment-modal-surface-driven-disclosure"></a>
## アサインメントモーダル: 画面駆動の段階的開示  [MID] [SENIOR]

<a id="idiomatic-variation-5"></a>
### イディオマティックな適用  [MID]

タスクアサインメントモーダルは、ユーザーがチームメンバーへのタスク割り当て、期日の設定、優先度の調整を行う画面です。初期デザインでは 3 つのフィールドがすべてモーダル内に同時に表示され、それぞれ完全に編集可能でした。ユーザーテストでは、参加者がモーダルを操作する前に躊躇するという現象が見られました。3 つの編集可能なフィールドを同時に見ることで、アサインメントを保存する前にすべてに入力しなければならないという印象を与えてしまっていました。

修正されたデザインでは**段階的開示**を適用しています。モーダルはアサイニーフィールドにフォーカスした状態で開き、期日と優先度のフィールドは微妙な区切り線の下に配置されています。プライマリアクションボタンには「Save」や「Update」ではなく「Assign」と書かれており、モーダルのプライマリな結果としての目的を伝えています。期日や優先度も調整したいユーザーはそれらのフィールドまでスクロールします。アサインメントのみを行いたいユーザーはチームメンバーを選択した後、ワンクリックでモーダルを完了できます。

これはフィールドを隠しているのではありません。3 つのフィールドはすべて存在しアクセス可能です。強調の順序付けです。アサイニーフィールドはモーダルの主要な関心事であり、UI はそれに最も大きな視覚的ウェイトとオープン時のキーボードフォーカスを与えることでそれを伝えています。

「正しいものが編集可能」の原則: フィールドがアサインメントモーダルで編集可能であるべきは、ユーザーがアサインメント時にそれを変更したいと一般的に思う場合です。期日と優先度はこのテストを通過します。タスクタイトルは通過しません。ユーザーはタスクを割り当てながらタスクの名前を変更することはなく、アサインメントモーダルでタイトルが編集可能だとユーザーテストで誤った編集が発生しました。モーダル内のタイトルフィールドは読み取り専用で、詳細ビューへのリンクが付いています。

<a id="trade-offs-and-constraints-5"></a>
### トレードオフと制約  [SENIOR]

段階的開示は、スクロールしないユーザーが期日や優先度フィールドを発見しない可能性があることを意味します。トレードオフは発見性と認知負荷のどちらを優先するかです。Meridian はこのトレードオフを許容しました。アサインメントモーダルは高頻度で使用されるため（アクティブユーザーにとって 1 ワークセッション中に複数回）、ユーザーはモーダルの構造を素早く習得します。稀にしか使用されないモーダルは即時開示（全フィールドが見える）の恩恵を受けます。頻繁に使用されるモーダルは集中したプライマリアクションの恩恵を受けます。

「Assign」ボタンラベルは特定の選択です。代替案「Save」「Update」「Done」「Confirm」はいずれも汎用的です。「Assign」はアクションを名指ししています。具体的なラベルのコストは、モーダルの目的が変わったとき（たとえば将来のバージョンでモーダルがアサイン解除もサポートするよう転用される場合、「Assign」は曖昧になります）にラベルを更新しなければならないことです。これはメンテナンスのコミットメントです。アクションが変更されるたびにボタンラベルを更新しなければなりません。汎用ラベルは時間の経過とともに劣化しにくいですが、具体的なラベルはその瞬間のコミュニケーションに優れています。

ユーザーが「Assign」をクリックしたときにトリガーされる通知をバックエンドがどのように処理するかについては [See architecture → Cross-Cutting Concern: Notifications](./architecture.md#cross-cutting-concern-notifications) を参照してください。特に、Slack 通知の失敗がアサインメントアクション自体を失敗させないベストエフォートの通知パターンが記載されています。

<a id="coach-illustration"></a>
### Coach Illustration (default vs. hints)

> **Illustrative only.** The following is a worked example of how the two coaching styles
> differ for a task in this domain. It is not part of the live agent contract. Actual
> agent behavior is governed by the style files at
> `.claude/skills/learn/coach-styles/`.

**Scenario:** A learner asks the agent to design the task assignment modal for Meridian —
specifically to determine which fields to show, in what order, and what the primary action
button should say.

**`default` style** — The agent produces the full specification: the component hierarchy
(`<AssignmentModal>` with `<AssigneeField>` in primary position, a divider, and
`<SecondaryFields>` containing `<DueDateField>` and `<PriorityField>`), the interaction
state for each field, the primary button label rationale ("Assign" rather than "Save"),
and the keyboard flow (Tab through fields; Enter to confirm). `## Learning:` trailers
explain the progressive disclosure principle and the microcopy rationale.

**`hints` style** — The agent names the pattern (progressive disclosure), identifies the
primary action (assigning a user), and emits:

```
## Coach: hint
Step: Define the modal's primary concern — which single action does the user open this
      modal to perform?
Pattern: Progressive disclosure — surface the primary action at modal-open; secondary
         fields are accessible but not competing for focus.
Rationale: Showing all fields at equal visual weight creates the impression that all
           fields are required, which increases task completion time and hesitation.
```

`<!-- coach:hints stop -->`

The learner identifies the primary action and field ordering. On the next turn, the agent
helps specify interaction states for each field.
