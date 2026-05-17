# Orchestrator Analyze ロウガード

## ステータス

Approved

**オーナー:** product-manager / implementer
**対象リリース:** template v3.9.0

## 問題

ADR-014 は Roadmap を単一エントリポイントとしている: すべてのマイルストーンは行であり、リンクされた `spec:` ファイルがコンテンツの Source of Truth である。orchestrator の Analyze ステップ (orchestrator.md Workflow ステップ 1) はこの不変条件に基づいて構築されている ── Roadmap を読み、対象行を見つけ、サブエージェントをディスパッチする前にリンクされた設計ソースを開く。

現在の設計には、Analyze ステップが明示的に検出または表面化しない 3 つの障害モードが存在する:

1. **受信タスクに対応する Roadmap 行が存在しない。** まだ Roadmap 行として追加されていない新しい作業が届く。orchestrator には見つけるべき行がなく、開くべき `spec:` もなく、Roadmap に基づいた開始点がない。現在の散文では、未登録のマイルストーンに対してサブエージェントをディスパッチする ── アンカーなしで進む ── か、診断メッセージなしに静かに止まる可能性がある。

2. **行の `spec:` リンクが予約済みだがファイルがディスク上に存在しない。** ADR-014 の Spec 予約ルールは、`product-manager` が行作成時に `specs/NN-slug.md` パスを Roadmap に予約することを明示的に許可している (ファイルはファイル作成時ではなくピックアップ時に作成される)。したがって、☐ todo 行の予約された `spec:` リンクは有効に不在である。orchestrator がその不在を検出せずにこのような行を解決して `implementer` にルーティングすると、implementer は実装する Spec を持たない ── これが主要な ADR-014 ドリフトベクターである。

3. **`◐ in-progress` 行に `specs/NN-progress.md` が欠けている。** orchestrator.md Workflow ステップ 1 にはすでに散文のフォールバックが含まれている: 「そのファイルが不在の場合、進捗レコードが存在しないことを明示的に述べ、`git log` から状態を再導出するフォールバックを使う; ステップをサイレントに仮定しない。」この散文は正しいが非公式であり、最初にファイルを読む新しい orchestrator インスタンスにとって Analyze ステップでは見えない。現在の文言はステップの説明の中に埋め込まれており、他の 2 つと同等の独立したガード条件として名付けられていない。マイルストーン #08 はこれを形式化し、名前付きガードに強化する可能性がある。

合わさったギャップ: Analyze ステップには、作業をディスパッチする前にこれら 3 つの前提条件を確認する名前付きの自己完結したガードがない。orchestrator.md を忠実に遵守するエージェントには、行を作成したり Spec 作成のために `product-manager` にルーティングしたりするために停止する明示的なシグナルがない。すべての orchestrator インスタンスは、宣言されたルールからではなくコンテキストの読み取りから正しい動作を再導出しなければならない。

## ゴール

- サブエージェントをディスパッチする前に Analyze ステップが保証しなければならないことを定義する: Roadmap 行が受信タスクに対して存在しなければならない; 行の `spec:` ファイルが行が `◐ in-progress` または `implementer`/`test-runner` にルーティングされる場合はディスク上に存在しなければならない; `◐ in-progress` 行の欠けた進捗ファイルはサイレントな仮定ではなく名前付き条件として表面化しなければならない。
- 各障害モードのルーティング結果を指定する: 行なし検出 → ユーザーに表面化し行を作成するために `product-manager` にルーティングして進む前に; 非 ☐ 行または実装ディスパッチに対して予約済みだが不在の `spec:` 検出 → 進む前に Spec を作成するために `product-manager` にルーティング; ◐ 行に対する `specs/NN-progress.md` 欠如 → 明示的に述べて `git log` 再導出にフォールバック、サイレントな仮定なし。
- ガードが名前付きで独立しており、将来の orchestrator インスタンスがルールを読むときにコンテキスト推論ではなく独立したディスパッチ前チェックとして遭遇するようにする。
- #04 (ダングリング参照ディテクター)、#05 (Roadmap drift-detection CI)、#07 (グリフ遷移オーナーシップ) に対する MECE 境界を述べ、将来のマイルストーン作成者が関連する懸念を誤ってルーティングしないようにする。

## ゴール対象外

- 4 つの認可されたグリフ値 (☐ / ◐ / ☑ / ✗) の変更。ADR-014 がそれらを所有する。
- コミット時にガードを機械的に検証する CI チェックの追加。#08 は orchestrator のランタイム Analyze 動作についてであり、静的解析レイヤーではない。ガードロジックは orchestrator.md (または architect が決定するドキュメントルールソース) に存在する; CI 強制は別個の将来のマイルストーンである (存在する場合)。
- ユーザーの代わりに Roadmap 行を自動作成すること。ガードは欠けた行を表面化して `product-manager` にルーティングする; サイレントに行を挿入しない。
- Spec 予約ルールの変更。ADR-014 の予約ルール (`spec:` リンクはファイルが存在する前に予約される可能性がある) は正しい; #08 は ☐ 行に対して合法的に予約されたリンクと実装にディスパッチされる行に対して壊れた不変条件の区別を利用する。
- `product-manager` が Spec を作成する方法の変更。ピックアップフローは #07 (グリフ遷移オーナーシップ) と Roadmap Rules ブロックが所有する; #08 はピックアッププロトコル自体ではなく、ピックアップをトリガーする orchestrator 側の前提条件を追加する。
- エージェントプロンプトの直接変更。orchestrator.md の編集が必要かどうかは architect の判断に委ねる (リスク R-01 参照)。

## 対象ユーザー

| ペルソナ | 説明 | 主なニーズ |
|---------|-------------|--------------|
| orchestrator (エージェント) | すべてのタスクで Analyze ステップを実行する | サブエージェントをディスパッチする前に満たされなければならない独立した前提条件と、各未達成条件に対する明示的なルーティング行動を知る |
| product-manager (エージェント) | マイルストーンピックアップ時に Spec と Roadmap 行を作成する | 行が欠けているか実装開始前に Spec を作成しなければならない場合に orchestrator からの明確なルーティングシグナルを受け取る |
| implementer (エージェント) | Spec に対して実装する | `spec:` ファイルがディスク上に存在しないマイルストーンのディスパッチを受け取ることがない |
| テンプレートメンテナー (人間) | orchestrator.md と Roadmap を管理する | ガードがコードレビューで検証でき派生リポジトリに継承できる単一の名前付き場所に定義されているのを見つける |
| テンプレート採用者 | テンプレートをフォークする | 追加の設定なしに 3 つの主要な障害モードに対してガードされた Analyze ステップを持つ orchestrator を継承する |

## ユーザーストーリー

| 〜として | 〜したい | 〜ために |
|---------|--------------|------------|
| orchestrator | Analyze ステップで受信タスクに Roadmap 行がないことを検出し、進む前に行を作成するために `product-manager` にルーティングする | 未登録のマイルストーン作業に対してサブエージェントをディスパッチしない |
| orchestrator | `implementer` または `test-runner` にディスパッチしようとしているときに Roadmap 行の `spec:` パスがディスク上に存在しないことを検出し、先に Spec 作成のために `product-manager` にルーティングする | Spec なしで実装が開始されない |
| orchestrator | ◐ in-progress 行の `specs/NN-progress.md` 欠如を独立したガード条件として名付け、`git log` 再導出にフォールバックする前に明示的に述べる | フォールバックがサイレントな仮定ではなく見えて監査可能である |
| product-manager | 行が存在しないか Spec を作成しなければならない場合に orchestrator からのルーティングシグナルを受け取る | なぜ委任されているか何を生成しなければならないか、orchestrator が再ディスパッチする前に正確に知る |
| implementer | Spec が不在のマイルストーンのタスクディスパッチを受け取ることがない | 常に実装する Spec を持つ |
| テンプレートメンテナー | ガードが orchestrator のルールソースに名前付きで独立したディスパッチ前チェックとして定義されているのを見つける | コンテキストの読み取りではなくルールを指し示すことでガードをコードレビューで強制できる |

## 受け入れ基準

- **Given** `.claude/CLAUDE.md` に対応する Roadmap 行がない受信タスク **when** orchestrator が Analyze ステップを実行する **then** orchestrator はマイルストーン実装のためのサブエージェントをディスパッチしない; 代わりにユーザーに欠けた行を表面化し、新しく作成された行で Analyze を再実行する前に行を作成する (および #07 に従ってピックアップ時に Spec を作成する) ために `product-manager` にルーティングする。
- **Given** `spec:` リンクが予約済みだがファイルがディスク上に存在しない ☐ todo の Roadmap 行 **when** orchestrator が行を特定し次のアクションが `implementer` または `test-runner` にディスパッチすることである **then** orchestrator はそのディスパッチを進めない; `implementer` または `test-runner` に再ディスパッチする前に Spec を作成する (および #07 に従って ☐→◐ に変更する) ために `product-manager` にルーティングする。(次のアクションがプロダクトプランニングまたはアーキテクチャである ☐ 行はこのガードをトリガーしない ── ☐ 行に対して不在の Spec は想定内である。)
- **Given** `spec:` リンクがディスク上に存在しないファイルを指す ◐ in-progress の Roadmap 行 **when** orchestrator が Analyze ステップを実行する **then** orchestrator は `implementer` または `test-runner` にディスパッチしない; 実装が進む前に解決しなければならない不完全なピックアップとして、欠けた Spec を作成するために `product-manager` にルーティングする。
- **Given** ◐ in-progress の Roadmap 行と対応する `specs/NN-progress.md` が不在 **when** orchestrator が Analyze ステップを実行する **then** orchestrator は進捗レコードが存在しないことを明示的に述べ、`git log` から状態を再導出するフォールバックを使い、ワークフローステップをサイレントに仮定しない ── この条件は Analyze 出力で名前付きで見える、コンテキストから推測されない。
- **Given** 3 つのガード条件がすべて満たされている (Roadmap 行が存在する; 実装ディスパッチに対して行の `spec:` ファイルがディスク上にある; 欠けた進捗ファイルが明示的に表面化されている) **when** orchestrator が Analyze ステップを完了する **then** 現在 orchestrator.md で定義されているように Assess Feasibility (ステップ 2) と完全なディスパッチフローに進む ── ガードは満たされたパスの動作を変更せずにディスパッチ前ゲートを追加する。
- **Given** 形式化されたガード **when** architect の決定によって決定された場所に文書化される **then** 通常の Analyze ステップの入力のみを読む orchestrator インスタンスは、Analyze ステップがすでに必要とするファイル以外のファイルを読まずにガード条件に遭遇する (正確な場所は architect に委ねる; リスク R-01 参照)。 <!-- ref-allow: forthcoming architect decision for #08; authored when #08 moves to implementation -->
- **Given** 本 Spec に述べられた MECE 境界 **when** 将来のマイルストーン作成者が新しいランタイム orchestrator の懸念が #08 または #04/#05/#07 に属するかを評価する **then** 境界は明確である: #04 はコミット時に散文のパス参照を検証する; #05 はコミット時にグリフ値と双方向 ADR リンクコントラクトを検証する; #07 は誰がグリフをいつ変更できるかを割り当てる; #08 は行または Spec が欠けているか進捗ファイルが不在の場合の orchestrator のランタイム Analyze 動作についてである。

## 主なインタラクション

1. **ADR-014 Spec 予約ルールとのインタラクション。** 予約ルールはファイルが存在する前に `spec:` パスを予約することを許可する。#08 はこのルールを変更しない。代わりに、意味的な区別を利用する: ☐ todo 行に対して予約済みだが不在の `spec:` は有効な中間状態である (Spec はピックアップ時に作成される); `implementer` または `test-runner` にディスパッチされる行に対して予約済みだが不在の `spec:` は、ガードが検出しなければならない無効な中間状態である。
2. **#07 (グリフ遷移オーナーシップ) とのインタラクション。** #07 は誰がグリフをいつ変更するかを割り当てる; #08 は orchestrator が作業をディスパッチする前に検証しなければならないことを定義する。2 つは合成可能である: #08 のガードが Spec を作成するために `product-manager` にルーティングするとき、その作成アクションは #07 に従って ☐→◐ 変更をトリガーする。オーナーシップギャップは存在しない。
3. **ADR-016 (クロスセッション進捗永続化) とのインタラクション。** ADR-016 は ◐ 時の最初のセッション境界で `specs/NN-progress.md` の作成を定義する; #08 のガード条件 3 は orchestrator が ◐ 行を読んでそのファイルが不在のときに何をしなければならないかを形式化する。2 つのルールは合成可能である: ガードの「明示的に述べて git log にフォールバック」動作は ADR-016 の「implementer が更新を所有し、orchestrator は読むだけ」書き込みオーナーシップコントラクトと整合する。
4. **#04 (ダングリング参照ディテクター) とのインタラクション。** #04 ディテクターはコミット時に文書の散文の壊れたパス参照を検出する。予約された `spec:` リンクが実体化されたかどうかの Roadmap 固有のランタイム動作は明示的にチェックしない。#08 は orchestrator のランタイムロジックについてであり、CI チェックではない; 2 つはスコープとトリガーポイントの両方で重複しない。
5. **#05 (Roadmap drift-detection CI) とのインタラクション。** #05 ディテクターはコミット時にグリフ値の整形性と双方向 ADR リンクの一貫性を検証する。#08 は静的構造的有効性ではなく、行/Spec 状態が欠けている場合のランタイム orchestrator 動作についてである。MECE 境界はクリーンである: #05 はコミット時に「Roadmap は構造的に有効か?」と問う; #08 はランタイムに「Analyze の前提条件は満たされているか?」と問う。
6. **構造的な HOW は architect に委ねる。** ガードが orchestrator.md Workflow ステップの散文、CLAUDE.md Roadmap Rules の箇条書き、新しい名前付きガードセクション、またはその組み合わせとして文書化されるかどうか、そしてどこで orchestrator が追加ファイル読み取りなしに Analyze ステップでそれに遭遇するか; 新しい ADR-019 が必要かまたは ADR-014 amendment で十分か; orchestrator.md が直接編集を必要とするか (その場合 claude-md-authoring Skill が適用されるか); および選択された配置における #04/#05/#07 に対する MECE 境界ドキュメント ── すべて architect の forthcoming decision に委ねる。 <!-- ref-allow: forthcoming architect decision for #08; authored when #08 moves to implementation -->

## メトリクス

- **先行指標:** 本マイルストーン出荷後、新しいタスクに対するすべての orchestrator Analyze 出力が 3 つのガード条件それぞれの結果 (行が存在する/不在、実装ディスパッチに対して spec がディスク上にある/不在、◐ 行に対して進捗ファイルが存在する/不在) を明示的に述べる ── セッショントランスクリプトで検証可能。
- **先行指標:** 本マイルストーン以降のテンプレート自身の Roadmap で「Spec がディスク上にないのに implementer がディスパッチされた」インシデントがゼロ。
- **遅行指標:** エージェントが必要な設計成果物なしにサブタスクを受け取る誤ったルーティングディスパッチの削減、orchestrator がアンカーなしで進むのではなくガード条件を表面化するときにセッショントランスクリプトで観察可能。

## リスクとオープンクエスチョン

### リスク R-01: architect に委ねられた構造的決定 ── ガード配置、ADR 戦略、エージェントプロンプトへの影響、Skill の必要性 <!-- ref-allow: forthcoming architect decision for #08; authored when #08 moves to implementation -->

**説明。** 本 Spec はガードが保証しなければならない *こと* (3 つの名前付き前提条件、3 つの名前付きルーティング結果、#04/#05/#07 に対する MECE 境界) と適合する実装の受け入れ基準を述べる。構造的な *どのように* を明示的に委ねる: ガードが orchestrator.md Workflow ステップの散文、CLAUDE.md Roadmap Rules の箇条書き、新しい CI ディテクター、またはその組み合わせとして文書化されるかどうか、そしてどこで orchestrator が追加ファイル読み取りなしに Analyze ステップでそれに遭遇するか; これが新しい ADR-019 か ADR-014 amendment か (architect は ADR-018 Alternative-B の判別子を適用する: 新しいディテクター + 新しい MECE 境界 + 新しいキーイング => 新しい ADR; 既存の Decision の帰結明確化 => amendment; ADR-018 が最新、ADR-019 は未使用); <!-- ref-allow: forthcoming architect decision for #08; authored when #08 moves to implementation --> エージェントプロンプト (主に orchestrator.md) が編集を必要とするかどうか、その場合 claude-md-authoring Skill の Pre/Post チェックリストが適用されるか (orchestrator.md は `.claude/agents/*.md` ファイルであり、「大幅な再構成」に対する Skill のスコープ内だが通常の単一箇条書き編集ではない); および選択された配置における #04/#05/#07 に対する MECE 境界ドキュメント。これは `specs/07-roadmap-status-transitions.md` (構造的 how を architect に委ねた R-01)、`specs/06-bilingual-parity-detector.md`、`specs/05-roadmap-drift-detection-ci.md` が使用した R-01 パターンを踏襲する。

**architect に渡す緩和制約。** architect の forthcoming decision は以下を指定しなければならない: (a) Analyze ステップで追加ファイル読み取りなしに orchestrator がガード条件に遭遇できるよう文書化される場所、(b) これが ADR-014 amendment か新しい ADR-019 か (Alternative-B 判別子を適用)、(c) orchestrator.md が直接編集を必要とするかどうかとどのセクションが影響を受けるか、(d) #08 のランタイム動作スコープを #04/#05/#07 の静的解析スコープから区別する明示的な MECE 境界記述。 <!-- ref-allow: forthcoming architect decision for #08; authored when #08 moves to implementation --> その決定が存在するまで、既存の orchestrator.md 散文 (Workflow ステップ 1、すでに進捗ファイルのフォールバックを含む) がプロセスガイダンスとして本 Spec の名前付きガード条件によって拡張されながら運用ルールとして残る。

**注意:** forthcoming architect decision を参照する行の `<!-- ref-allow: -->` 抑制は本 Spec ファイル (`specs/08-orchestrator-row-guard.md`) のみに存在し、その architect decision に対する `specs/07-roadmap-status-transitions.md`、ADR-017 に対する `specs/05-roadmap-drift-detection-ci.md`、ADR-018 に対する `specs/06-bilingual-parity-detector.md` が設定した先例に従っている。抑制は `CLAUDE.md` に現れない。

### リスク R-02: ☐ 行ディスパッチのガード粒度

**説明。** 2 番目の受け入れ基準は `implementer`/`test-runner` にディスパッチされる ☐ 行 (ガードが発火する) と `product-manager` または `architect` にディスパッチされる ☐ 行 (ガードが発火しない) を区別する。ディスパッチ条件 (「implementer または test-runner にディスパッチしようとしている」) は、ガードを確認する前に意図されたダウンストリームエージェントを評価することを orchestrator に要求する ── 単純な行ステータスチェックよりわずかに複雑な前提条件である。

**緩和策。** architect の配置決定はこのディスパッチターゲット条件を明示的に述べるか、より単純なヒューリスティックに収束させるべきである: 「行が ☐ で Spec が不在の場合、意図されたダウンストリームエージェントに関係なく常に最初に product-manager にルーティングする。」より単純なヒューリスティックは安全であり (product-manager が Spec を作成して ◐ に変更してからディスパッチが進む)、ガード評価時のダウンストリームエージェントイントロスペクションの必要を避ける。本 Spec はこれを意図的に解決しない ── architect の判断に委ねる。

### リスク R-03: MECE 境界での #05 と #04 とのスコープ重複

**説明。** #04 (ダングリング参照ディテクター) と #05 (Roadmap drift-detection CI) は静的なコミット時チェックである。#08 は orchestrator のランタイム動作ガードである。将来のマイルストーン作成者が「orchestrator がランタイムに欠けた Spec を検出した」を「CI がコミット時に壊れたパス参照を検出した」または「CI がコミット時に予約済みだが不在の spec: リンクを検出した」と混同する可能性がある。

**緩和策。** MECE 境界は本 Spec のゴール、受け入れ基準、主なインタラクションセクションに述べられている。architect の決定はガードの配置ドキュメントでこの境界を繰り返すべきである。注意: #05 の非ゴールは予約済みの `spec:` リンクがディスク上のファイルに解決するかどうかの確認を明示的に除外している (予約ルールのカーブアウト) ── それはランタイムの懸念であり構造的整合性の懸念ではなく、#08 に属する。

## スコープ対象外

- 新しい CI ワークフローファイルの追加。#08 は静的解析追加ではなくランタイム orchestrator 動作変更である。
- Spec 予約ルールの変更 (ADR-014 がこれを所有する)。
- `product-manager` がピックアップ時に Spec を作成する方法の変更 (#07 と Roadmap Rules ブロックが所有する)。
- CI でのガードの機械的強制 (将来のマイルストーンの可能性があり、#08 ではない)。
- ガードの派生リポジトリ orchestrator 設定への翻訳 (フォーク時に派生リポジトリで technical-writer が行うタスク)。
- 行が存在しない場合の Roadmap 行の自動挿入 (ガードは条件を表面化する; 人間または `product-manager` が行を作成する)。

## 参照

- ADR-014 (Roadmap インデックスを単一エントリポイントとする) ── §Spec 予約ルール (☐ 行に対して予約済みだが不在の `spec:` パスは明示的に有効); §決定「インデックス更新のオーナーシップ」── ガードがルーティングする行/リンク書き込みオーナーシップ; 本マイルストーンが閉じるギャップは予約ルールの中間状態が実装ディスパッチと衝突するときの orchestrator のランタイム動作である
- ADR-016 (クロスセッション進捗永続化) ── ◐ 行のクロスセッション状態キャリアとして `specs/NN-progress.md` を定義する; #08 ガード条件 3 はこのファイルが不在の場合の orchestrator の名前付き動作を形式化する
- `specs/07-roadmap-status-transitions.md` ── 本 Spec がミラーする前方参照パターンを確立する構造的兄弟; また Spec 作成のために `product-manager` にルーティングするときにガードがトリガーする ☐→◐ 変更のオーナー
- `specs/05-roadmap-drift-detection-ci.md` ── MECE 境界の補完: #05 はコミット時の静的チェック; #08 はランタイム orchestrator チェック; #05 の非ゴールセクションは予約済みだが不在の `spec:` のランタイムケースを明示的に除外する
- `specs/06-bilingual-parity-detector.md` ── 構造的兄弟; R-01 が ADR-018 前方参照パターンを確立する <!-- ref-allow: forthcoming architect decision for #08; authored when #08 moves to implementation -->
- `specs/04-dangling-reference-detector.md` ── コミット時の散文パス参照に対する MECE 境界の補完; Roadmap ランタイム動作はカバーしない
- `.claude/agents/orchestrator.md` Workflow ステップ 1 ── 本 Spec がガードする Analyze ステップ; 28 行目の進捗ファイルフォールバック散文がガード条件 3 の前身である
- Roadmap row: #08
