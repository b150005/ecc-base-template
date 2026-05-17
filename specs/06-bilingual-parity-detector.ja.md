# EN/JA 二言語パリティディテクター

## ステータス

Approved

**オーナー:** product-manager / implementer
**対象リリース:** template v3.7.0

## 問題

テンプレートは二言語ペアの成果物を出荷する — ADR、Spec、エージェントファイル、テンプレートは英語 (`<name>.md`) と日本語 (`<name>.ja.md`) の両方で存在する。人間とエージェントはこれらのペアが構造的に一貫していることに依存する: 正規 EN ファイルを読むエージェントは JA 翻訳が同じセクションを同じ順序でカバーしていると信頼できるべきであり、人間のレビュアーは手動で見出しツリーを diff せずにパリティを確認できるべきである。今日、この点を CI で強制するものはない。`.md` とその `.ja.md` 対応ファイルの間で見出しの数や順序がドリフトしても、日本語読者やJA成果物を好むエージェントを静かに誤解させるだけである。JA ファイル内の非 ASCII 括弧 (`(` U+FF08 / `)` U+FF09) はテンプレートの ADR ハウススタイルに違反する — 日本語散文であっても ASCII `(` `)` が必要であり、翻訳者が反射的に全角タイポグラフィを適用すると混入する。スコープ内ツリーで `.ja.md` 対応ファイルのない `.md` (またはその逆) はパリティ破壊であり、一方の言語にカバレッジがない状態になる。#04 と #05 ディテクターは二言語パリティを明示的にスコープ外としている。テンプレート自身の `check-roadmap-drift.sh` はすでに逆方向スキャンから `.ja.md` ファイルを意図的に除外しており — EN/JA バックリンクパリティは #06 の契約オーナーであると明示して — 本マイルストーンが出荷される前に境界が実在し負荷を担っている。

## ゴール

- 見出しツリーパリティの破壊を検出する: EN 正規ファイルのすべての見出し (`#` / `##` / `###` / `####`) は JA ファイルに 1:1 の位置対応を持たなければならず、その逆も同様 (同じカウント、同じ順序)。個々の見出しの翻訳が正しくても、数や順序が一致しない場合はパリティ失敗である。
- JA ファイル内の全角括弧を検出する: `.ja.md` ファイルのいずれかの場所に `(` U+FF08 または `)` U+FF09 が現れることはスタイル違反であり、ファイルパスと行番号とともに報告しなければならない。
- 存在パリティの破壊を検出する: スコープ内ツリーで `.ja.md` 対応ファイルのない `.md` ファイル (または `.md` 対応ファイルのない `.ja.md`) はパリティ破壊である。
- フォークごとの設定ステップなしに、`main` へのすべての push と pull request で自動的に実行する — ADR-015 の subject-matter-presence ルール (#06 を明示的に指名) から継承した always-on ポスチャーに一致する。
- 本マイルストーンが出荷される時点で、テンプレートリポジトリ自身の成果物がチェックを通過している (自己ベースライン / green-by-construction)。

## ゴール対象外

- JA 翻訳の自動生成や自動修正 — ディテクターは報告するのみ。人間と `technical-writer` が修正する。
- JA 翻訳の*意味的コンテンツ*を EN オリジナルと照合する — 機械翻訳品質、翻訳の事実正確性、意味的等価性は機械的チェックではなく人間の判断に関わる。
- カーブアウトツリーで意図的に EN のみに設計されたファイルの二言語パリティチェック。アーキテクトが ADR-018 でどのツリーが EN のみかを決定し免除ルールを成文化する。EN のみのカーブアウトは存在パリティチェックで失敗しない。スコープ内ツリーとカーブアウトツリーセットの正確な定義は ADR-018 に委ねられたアーキテクト決定である。 <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->
- JA ファイル内のクロスリファレンス整合性や Roadmap リンク有効性の確認 — それは #04 と #05 のスコープ。境界はすでに強制されている: `check-roadmap-drift.sh` は逆方向スキャンから `.ja.md` を除外しており、EN/JA バックリンクパリティが本マイルストーンの契約であることを明示している。
- EN または JA ファイル内の外部 URL の検証。
- `workarounds/` レジストリファイル内のパリティチェック。
- GitHub Actions 以外の CI プロバイダーへのチェックの移植。

## 対象ユーザー

| ペルソナ | 説明 | 主なニーズ |
|---------|-------------|--------------|
| テンプレートメンテナー | 二言語設計成果物を作成または更新する開発者 | テンプレートが構造的に一貫しない二言語ペアを出荷する前に見出しドリフトや JA 対応ファイルの欠落を検出する |
| テクニカルライター | JA 翻訳を担当する `technical-writer` エージェント | 人間レビューで発見するのではなく、全角括弧や見出し不一致が導入された時点で即座に知る |
| エージェント (orchestrator) | CLAUDE.md を読み成果物リンクを辿る | どこかで参照される JA 成果物が EN 正規と同じ構造セクションをカバーしていると信頼し、どちらを読んでも十分であること |
| テンプレート採用者 | テンプレートをフォークして CI を継承する | 設定ステップなしに構造的に一貫していることが検証された二言語ベースラインから始める |

## ユーザーストーリー

| 〜として | 〜したい | 〜ために |
|---------|--------------|------------|
| テンプレートメンテナー | JA 翻訳が EN 正規より少ないか多い見出しを持つとき CI 失敗を得る | エージェントや読者が構造的に不完全な翻訳に誤解される前に見出しドリフトを検出する |
| テクニカルライター | `.ja.md` ファイルに全角括弧 (`(` または `)`) が現れるときファイルと行を示す CI 失敗を得る | JA ファイルのタイポグラフィ負債を蓄積するのではなくスタイル違反を即座に修正する |
| テンプレートメンテナー | スコープ内ツリーに `.ja.md` 対応ファイルなしで `.md` が追加されるとき CI 失敗を得る | 単一言語成果物が main に達する前に存在パリティの破壊を検出する |
| テンプレート採用者 | すべてのスコープ内二言語ペアがフォーク時点で構造的に検証されたことを知りながらフォークする | 自身の翻訳が分岐した後に見出しドリフトを発見するのではなく、健全な二言語ベースラインを継承する |

## 受け入れ基準

- **Given** スコープ内ツリーの `.ja.md` ファイルが EN `.md` 正規より少ない見出し (`#`/`##`/`###`/`####`) を持つ **when** ディテクターが実行される **then** ファイルペアとカウント不一致 (EN カウント対 JA カウント) を示すメッセージとともに失敗する。
- **Given** スコープ内ツリーの `.ja.md` ファイルが EN `.md` 正規より多い見出しを持つ **when** ディテクターが実行される **then** ファイルペアとカウント不一致を示すメッセージとともに失敗する。
- **Given** `.ja.md` ファイルが EN 正規と同じ見出しカウントを持つが順序が異なる (位置不一致) **when** ディテクターが実行される **then** 最初に不一致した見出し位置を示して失敗する。
- **Given** `.ja.md` ファイルのいずれかの行に `(` (U+FF08) または `)` (U+FF09) の文字が含まれる **when** ディテクターが実行される **then** 各出現箇所のファイルパスと行番号を示して失敗する。
- **Given** スコープ内ツリーの `.md` ファイルに対応する `.ja.md` 対応ファイルがない **when** ディテクターが実行される **then** ペアのない `.md` ファイルを示して失敗する。
- **Given** スコープ内ツリーの `.ja.md` ファイルに対応する `.md` 対応ファイルがない **when** ディテクターが実行される **then** 孤立した `.ja.md` ファイルを示して失敗する。
- **Given** `.md` ファイルがアーキテクトによって ADR-018 で EN のみのカーブアウトとして指定されたツリーに存在する **when** ディテクターが実行される **then** `.ja.md` 対応ファイルの欠如で失敗しない — 意図的に EN のみのファイルは存在パリティから免除される。 <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->
- **Given** スキャン対象のいずれかのファイルの行に `<!-- ref-allow: -->` コメントがある **when** ディテクターが実行される **then** その行のバリデーションをスキップする — #04/#05 のエスケープハッチをこのディテクターが変更なしに再利用する。
- **Given** 本マイルストーンが出荷される時点のテンプレートリポジトリ自身の成果物 **when** ディテクターが実行される **then** すべてのチェックが通過する — テンプレートを自身のベースラインとして確立する (green-by-construction)。
- **Given** フォークごとの設定変数や設定ファイルなしにワークフローファイルが存在する **when** 派生リポジトリの CI が実行される **then** 追加のセットアップなしにチェックが自動的に実行される (ADR-015 から継承した always-on デフォルト)。
- **Given** `.md` とその `.ja.md` の間に見出しカウント不一致を導入する `main` への push または pull request **when** ワークフローが実行される **then** `bilingual-parity-check` という名前の CI ジョブが失敗し、サマリー出力にファイルペアと失敗したパリティ次元が示される。

**注 (ADR-018 amendment — 2026-05-17):** AC#5 および AC#7 の「スコープ内ツリー」という表現は、ADR-018 (`.claude/meta/adr/018-bilingual-parity-detector.md`) の `## Amendment — 2026-05-17 (in-scope granularity — per-pair, not per-directory)` セクションによってファイルペア単位の粒度に権威ある形で精緻化されている。その精緻化の下では、対応する `<stem>.ja.md` を持たない単独の `<stem>.md` は認可された EN のみの補完ファイルであり、存在パリティの失敗とはならない。存在パリティが失敗するのは、対応する `<stem>.md` を持たない孤立した `<stem>.ja.md` (AC#6) の場合のみである。これが、慣例を持つツリーに EN のみの `.md` ファイルが存在するにもかかわらず、テンプレートが green-by-construction (AC#9) である理由である: それらのファイルは認可された EN のみの補完ファイルであり、パリティ失敗ではない。AC#7 の ADR-018 への明示的な委任が AC#5 をスコープ付けており、amendment は歴史的な契約の上に重ねられた権威ある精緻化である。

## 主なインタラクション

1. `implementer` が `.claude/meta/scripts/check-dangling-refs.sh` と `.claude/meta/scripts/check-roadmap-drift.sh` (#04/#05 から確立された再利用可能なパターン) の構造に従って `.claude/meta/scripts/check-bilingual-parity.sh` を作成する: `set -euo pipefail`、`git rev-parse` によるリポジトリルート解決、`pass`/`warn`/`fail_check` ヘルパー、`fail=0` アキュムレーター、`exit "$fail"`。スクリプトは 3 つのチェックを順番に実装する: (1) スコープ内ツリー全体の存在パリティスキャン、(2) 見つかった各 EN/JA ペアの見出しツリーパリティ、(3) スコープ内のすべての `.ja.md` の全角括弧スキャン。 <!-- ref-allow: .claude/meta/scripts/check-bilingual-parity.sh is the deliverable artifact this milestone authorizes; it does not exist yet at Spec authoring time -->
2. `implementer` が `.github/workflows/dangling-ref-check.yml` と `.github/workflows/roadmap-drift-check.yml` の構造に従って `.github/workflows/bilingual-parity-check.yml` を作成する: スコープ内ツリーとスクリプト/ワークフロー自体にパス指定した `main` への `on: push/pull_request`、`bash .claude/meta/scripts/check-bilingual-parity.sh` を実行する単一 `check` ジョブ、`permissions: contents: read`、`timeout-minutes: 5`、ジョブ名 `bilingual-parity-check`。 <!-- ref-allow: .claude/meta/scripts/check-bilingual-parity.sh is the deliverable artifact this milestone authorizes; it does not exist yet at Spec authoring time -->
3. #04 と #05 との MECE 境界はスクリプトヘッダーに明示的に述べなければならない: #04 はクロスリファレンス整合性 (ADR-NNN テキスト参照と `.claude/` ルートパス言及) を所有する。#05 は Roadmap 双方向リンクとステータスグリフ一貫性を所有する。#06 は EN/JA 翻訳パリティ (見出しツリー、全角括弧、存在) を所有する。境界が負荷を担っていることの具体的な証拠: `check-roadmap-drift.sh` はすでに逆方向スキャンループから `.ja.md` を意図的に除外しており (#06 を契約オーナーとして明示)、このスクリプトが出荷される前にパーティションが有効になっている。
4. TDD スイートが `implementer` によって #04 と #05 で使用された `test-check-*.sh` 規則に従って作成され、少なくとも以下をカバーする: 見出しカウント不一致 (EN が少ない、EN が多い)、位置的見出し不一致 (同じカウント、異なる順序)、JA ファイルの全角括弧、欠落した JA 対応ファイル、孤立した JA ファイル、green-by-construction ベースライン (すべてのテンプレート成果物がパス)。
5. 正確なファイルセットキーイング (どのツリーがスコープ内か EN のみカーブアウトか)、見出し正規化戦略 (例: 番号付きプレフィックスや ローカライズされた見出しテキストが特別な処理を必要とするかどうか)、見出し抽出のパース手法は明示的に ADR-018 (architect) に委ねられており、specs/05 の R-01 が構造的キーイングを ADR-017 に委ねたのと同様である。Spec は *何を* (3 つのパリティ次元とその受け入れ基準) を述べ、ADR は構造的な *どのように* を記録する。 <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->
6. 本マイルストーンではエージェントプロンプトの変更は不要。ディテクターは CI レイヤーのみである。

## メトリクス

- **先行指標:** テンプレート自身の `main` ブランチで、マイルストーン出荷直後に CI ジョブ `bilingual-parity-check` が通過する。
- **先行指標:** テンプレート自身の成果物に出荷時点で `<!-- ref-allow: -->` 抑制がゼロ (テンプレートの二言語ペアはベースラインとして構造的にクリーンであるべきであり、エスケープハッチは派生リポジトリの先行参照用に存在する)。
- **遅行指標:** 「エージェントまたは読者が EN 対応より構造的に少ないセクションを持つ JA 成果物に遭遇する」インシデントの減少 (チームが追跡する場合はセッションのトランスクリプトで観察可能。本マイルストーンのハードなメトリックゲートではない)。

## リスクとオープンクエスチョン

### リスク R-01: ADR-018 に委ねられたファイルセットキーイングと EN のみカーブアウト定義 <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->

**説明。** 本 Spec は 3 つのパリティ次元 (見出しツリー、全角括弧、存在) を定義するが、どのディレクトリツリーがスコープ内でどれが EN のみによる設計かという問いを明示的に ADR-018 に委ねる。specs/05 の R-01 が構造的キーイングを ADR-017 に委ねたのと同じ類型。ADR-018 なしでは、implementer は後のアーキテクチャ意図と矛盾する可能性のあるアドホックなスコープ内判断をしなければならない。 <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->

**architect に渡す緩和制約。** ADR-018 は以下を指定しなければならない: (a) スコープ内ツリーの権威あるリスト (またはスコープ内ツリーの決定ルール)、(b) EN のみのカーブアウトルール (テンプレートが JA ペアを決して必要としないと指定するファイル/ツリーの免除)、(c) 見出しツリー比較のための見出し正規化戦略 (例: 比較前に番号付きプレフィックスを除去するかどうか)。ADR-018 が存在するまで、implementer は保守的なデフォルトを使用する: `.claude/meta/adr/`、`.claude/templates/`、`.claude/agents/`、`specs/` ツリーすべてがスコープ内。アーキテクトが別途決定するまでカーブアウトなし。 <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->

**注意:** リスク R-01 見出し行の `<!-- ref-allow: -->` 抑制は本 Spec ファイル (`specs/06-bilingual-parity-detector.md`) のみに存在し、ADR-017 に対する `specs/05-roadmap-drift-detection-ci.md` と ADR-016 に対する `specs/03-cross-session-progress-persistence.md` が設定した先例に従っている。抑制は `CLAUDE.md` に現れない。

### リスク R-02: 再議論なしに継承されるポスチャー

**説明。** ADR-015 §Decision point 3 は明示的に述べている: 「#05/#06 を default-off として扱うことは subject-matter-presence ルール (Roadmap ドリフトと EN/JA パリティも always-present な構造的契約である) と矛盾するため、ルールはそれらのポスチャーも決定する。」本マイルストーンの always-on ポスチャーは **継承** されたものであり、新しい決定ではない。ここで継承として文書化することで、将来のレビュアーが確立した決定を読まずに再議論することを防ぐ。

**本 Spec の記述:** 本マイルストーンの CI ポスチャーは always-on であり、ADR-015 が確立した subject-matter-presence ルールを継承する。新しいポスチャー決定は不要であり、適切でもない。ルールは拘束力を持つ。ADR-015 は §Decision point 3 で #06 を明示的に指名している。

### リスク R-03: 見出し正規化のエッジケース

**説明。** JA ファイルの見出しテキストは EN 見出しテキストの翻訳であり、位置比較はテキストコンテンツではなくレベルと位置で比較しなければならない。しかし、番号付きプレフィックス (例: EN の `## 1. Context` 対 JA の `## 1. コンテキスト`) や翻訳中に導入された見出しレベルの変更が、正規化戦略が誤っていた場合に偽陽性や偽陰性を生じる可能性がある。

**architect に渡す緩和制約。** ADR-018 は見出し正規化戦略を指定しなければならない (レベル+位置のみ比較、比較前に数値プレフィックスを除去、または別のアプローチ)。Spec の受け入れ基準はカウントと順序の観点で書かれている — アーキテクトが偽陽性なしにそれらを満たす正確な比較形式を決定する。 <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->

### リスク R-04: #04 と #05 ディテクターとのスコープ重複

**説明。** #04 は JA ファイルを含むファイルの壊れたクロスリファレンス (パス言及、ADR-NNN テキスト参照) を検出する。#05 は逆方向スキャンから `.ja.md` を明示的に除外する (負荷を担う境界)。#06 は見出し/パリティ/存在を所有する。重複ゾーン: 見出しテキストに壊れた `ADR-NNN` 参照を持つ JA ファイルは #04 に検出される。これは許容される — 2 つの異なる失敗が 2 つの異なる CI レポートを 2 つの異なるオーナーに生じる。

**緩和策。** スクリプトヘッダーは MECE パーティションを明示的に述べなければならず、将来のメンテナーが間違ったスクリプトにチェックを割り当てないようにする。具体的な境界: `check-roadmap-drift.sh` が逆方向スキャンから `.ja.md` を除外していることが、#06 の出荷前にパーティションが強制されていることの既存の証拠である。

## スコープ対象外

- JA 対応ファイルの自動生成、自動修正、機械翻訳。
- JA コンテンツの意味的翻訳品質や事実正確性の検証。
- `workarounds/` レジストリファイル内のパリティチェック。
- JA ファイル内のクロスリファレンス整合性の確認 — それは #04 のスコープのまま。
- GitHub Actions 以外の CI プロバイダーへのチェックの移植。
- (ADR-018 が決定する) スコープ外ツリーが JA 対応ファイルを持つことの強制。 <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->

## 参照

- ADR-015 (Dangling-reference detector — always-on、subject-matter-keyed CI posture) — §Decision point 3 が #05 と #06 を明示的に指名し、それらの always-on ポスチャーを subject-matter-presence ルールから継承 (新決定ではない) として固定する。§Decision point 1 は本ディテクターが複製せずに補完する #04 スコープ境界を定義する
- `specs/04-dangling-reference-detector.md` — 構造的兄弟。その Non-goals セクションが #06 を二言語パリティの担当ディテクターとして明示的に指名する
- `specs/05-roadmap-drift-detection-ci.md` — 直接の構造的兄弟。その Non-goals セクションが #06 を指名する。そのスコープ外セクションが #06 を指名する。そのリスクセクション (R-04) が本 Spec が ADR-018 に対してミラーする ADR-017 前方参照パターンを記述する。`check-roadmap-drift.sh` はすでに逆方向スキャンから `.ja.md` を除外しており #06 を契約オーナーとして明示 — 本マイルストーンが出荷される前にスコープ境界が負荷を担っていることの具体的な証拠 <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->
- `.claude/meta/scripts/check-dangling-refs.sh` / `.claude/meta/scripts/check-roadmap-drift.sh` — 本マイルストーンのスクリプトが従う再利用可能なスクリプトパターン (#04/#05)
- `.github/workflows/dangling-ref-check.yml` / `.github/workflows/roadmap-drift-check.yml` — 本マイルストーンのワークフローが従う再利用可能なワークフローパターン (#04/#05)
- ADR-018 — 本マイルストーンの構造的キーイングのための forthcoming architect 決定: スコープ内ツリーセット、EN のみカーブアウトルール、見出し正規化戦略、パース手法 (本マイルストーンが実装に移行する際に作成される) <!-- ref-allow: ADR-018 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->
- Roadmap row: #06
