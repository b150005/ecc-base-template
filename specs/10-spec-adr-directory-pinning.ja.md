# CLAUDE.md における Spec/ADR ディレクトリ場所のピン

## ステータス

Approved

**オーナー:** product-manager / implementer
**対象リリース:** template v3.11.0

## 問題

CLAUDE.md の `## Document Templates` セクションは現在こう述べている: "You decide where to place the resulting documents. Single-language projects can write directly under a top-level directory of your choice (e.g. `adr/001-foo.md`); bilingual projects can split by language (e.g. `adr/en/001-foo.md`, `adr/ja/001-foo.md`). The template does not impose a layout — only the templates." このガイダンスは、自分自身の規約を選択する派生プロジェクトに対しては正確である。しかしテンプレート自体にはギャップが残る。

実際には、このリポジトリは 2 つの場所を規約として名付けることなくピンしている: Spec ファイルは `specs/` 配下に置かれ (ADR-014 の予約ルールと #09 のファイル名規約によってすでに標準化されている)、ADR ファイルは `.claude/meta/adr/` 配下に置かれる (現在までに作成されたすべての ADR ファイルで確認済み)。Roadmap の `## Rules` ブロックは両ディレクトリを参照しているが、それらを権威あるディレクトリ規約として宣言したことはない。テンプレート内のどのドキュメントも、この 2 つのディレクトリを作成ステップでエージェントと貢献者が出会う名前付き・ピン済み規約として述べていない。

結果として、`## Document Templates` の "you decide" ガイダンス (フォーク向けには正確) とこのリポジトリで実際に運用されている規約 (ピン済み) の間に分断が生じている。マイルストーン #10 は、このリポジトリのドッグフーディング姿勢に対してピン済みディレクトリの場所を明示的・名前付き・規範的なものにすることでこれを解決する。既存のフリー配置ガイダンスとの緊張関係を明らかにし、調整を architect に委ねる。

## ゴール

- このリポジトリの Spec ファイルの標準ディレクトリとして `specs/` を、明示的・名前付き規約として宣言する。
- このリポジトリの ADR ファイルの標準ディレクトリとして `.claude/meta/adr/` を、明示的・名前付き規約として宣言する。
- このリポジトリにおける Spec ファイルの EN/JA 二言語規約を述べる: EN と JA の兄弟ファイルは `specs/NN-slug.md` と `specs/NN-slug.ja.md` として**同じ** `specs/` ディレクトリに共存する。`specs/en/` と `specs/ja/` に分割しない。`## Document Templates` の `adr/en/` / `adr/ja/` の例はフォーク向けの例示であり、このリポジトリの規約ではないことを明確にする。 <!-- ref-allow: specs/en/ and specs/ja/ are non-existing illustrative paths documenting what this convention does NOT use; their non-existence is the point -->
- `## Document Templates` の "you decide where to place" ガイダンスと de-facto ピン済みディレクトリの間の緊張関係を表面化し、調整を architect への名前付きオープンクエスチョンとして委ねる (リスク R-01 参照)。
- 遡及的な適合性を確認する: 既存のすべての Spec ファイル (`specs/01-*.md` から `specs/09-*.md` および `.ja.md` 兄弟) と既存のすべての ADR ファイル (`.claude/meta/adr/001-*.md` から `.claude/meta/adr/018-*.md` および `.ja.md` 兄弟) はすでにピン済みディレクトリに適合している。これは規約宣言マイルストーンであり、一括移動マイルストーンではない。
- #09 と組み合わせて完全な標準パスを指定する: `specs/NN-slug.md` = `specs/` (#10 のスコープ) + `NN-slug.md` (#09 のスコープ)。2 つは MECE である。

## ゴール対象外

- 既存の Spec または ADR ファイルの名前変更または移動。すべての既存ファイルはすでにピン済みディレクトリに存在する; 一括移動作業は不要であり、スコープ外である。
- Spec ファイルのファイル名規約の変更。`NN-slug.md` のファイル名形式は #09 のスコープ。#10 はディレクトリについてであり、ファイル名についてではない。
- 新しい CI ディレクトリ適合性チェックの追加。そのようなチェックを追加するかどうかは architect に委ねた構造的決定である (リスク R-01 参照)。#10 はドキュメント/規約宣言マイルストーンであり; CI 強制はオプションの帰結であってこのマイルストーンの成果物ではない。
- 二言語対応パリティルールの変更。EN と JA ファイル間の見出しツリーパリティは #06 (ADR-018) が所有する。#10 はそのルールを再定義または拡張しない。
- ADR ファイル名規約の再定義 (3 桁プレフィックス、`.claude/meta/adr/NNN-slug.md`)。その規約は ADR 作成慣行によって管理される; #10 はディレクトリのみをピンする。
- architect の決定なしに `## Document Templates` の "you decide where to place" ガイダンスを変更すること。そのセクションをどのように、いつ修正するかはリスク R-01 に委ねた構造的問いである。
- 派生プロジェクト向けのディレクトリ規約の指定。フォークは自身のレイアウトを選択する; この規約はこのリポジトリのドッグフーディング姿勢に適用される。

## 対象ユーザー

| ペルソナ | 説明 | 主なニーズ |
|---------|-------------|--------------|
| product-manager (エージェント) | マイルストーンピックアップ時に Spec ファイルを作成する | 追加ファイルを参照せずに使用する正確なディレクトリ (`specs/`) を知る |
| architect (エージェント) | 構造的決定の後に ADR ファイルを作成する | 追加ファイルを参照せずに使用する正確なディレクトリ (`.claude/meta/adr/`) を知る |
| テンプレートメンテナー (人間) | Roadmap と Spec/ADR インベントリを管理する | コードレビューで引用できる単一の宣言された場所にディレクトリ規約を見つける |
| テンプレート採用者 | テンプレートを派生プロジェクトにフォークする | このリポジトリのピン済み選択とフォーク向けの自由選択ガイダンスを区別する |

## ユーザーストーリー

| 〜として | 〜したい | 〜ために |
|---------|--------------|------------|
| product-manager | マイルストーンをピックアップした瞬間に新しい Spec の標準ディレクトリを知る | 過去の Spec パスのディレクトリヒントを確認せずに最初から正しい場所にファイルを置く |
| architect | 構造的決定の後に新しい ADR の標準ディレクトリを知る | 過去の ADR パスのディレクトリヒントを確認せずに最初から正しい場所にファイルを置く |
| テンプレートメンテナー | 規範的な場所に両ディレクトリ規約が明示的に記述されているのを見つける | 貢献された Spec または ADR が非標準ディレクトリに置かれているときにコードレビューでルールを引用できる |
| テンプレート採用者 | レイアウトのどの部分がこのリポジトリのピン済み選択かを知る | フォークで上書きできる自由選択ガイダンスとテンプレートのドッグフーディング規約を区別できる |

## 受け入れ基準

- **Given** Roadmap のいずれかの行に対して新しい Spec が作成される **when** `product-manager` がディレクトリを選択する **then** 標準ディレクトリはリポジトリルートの `specs/` であり、ADR-014 と #09 がすでに確立した予約 `spec:` パス形式に一致する。
- **Given** 構造的決定の後に新しい ADR が作成される **when** `architect` がディレクトリを選択する **then** 標準ディレクトリはリポジトリルートの `.claude/meta/adr/` であり、既存のすべての ADR と一致する 3 桁ゼロ埋めプレフィックスを使用する。
- **Given** JA パリティが必要な二言語プロジェクト要件 **when** EN Spec とその JA 兄弟が配置される **then** 両方とも `specs/NN-slug.md` と `specs/NN-slug.ja.md` として**同じ** `specs/` ディレクトリに存在する。ディレクトリは言語で分割しない (このリポジトリの規約では `specs/en/` や `specs/ja/` サブディレクトリを使用しない)。 <!-- ref-allow: specs/en/ and specs/ja/ are non-existing illustrative paths documenting what this convention does NOT use; their non-existence is the point -->
- **Given** `## Document Templates` セクションの `adr/en/` と `adr/ja/` の例 **when** テンプレート採用者がそれを読む **then** フォーク向けの例示として明確に位置付けられており、このリポジトリのピン済み規約ではない (正確なフレーミングは architect に委ねる; リスク R-01 参照)。 <!-- ref-allow: forthcoming architect decision for #10; authored when #10 moves to implementation -->
- **Given** 述べられたディレクトリ規約 **when** architect の決定によって決定された場所に文書化される **then** Spec 作成または ADR 作成ステップを実行するエージェントはそれらのステップがすでに必要とするファイル以外のファイルを読まずに両ディレクトリ規約に出会う (正確な場所は architect に委ねる; リスク R-01 参照)。 <!-- ref-allow: forthcoming architect decision for #10; authored when #10 moves to implementation -->
- **Given** 既存のすべての Spec ファイル (`specs/01-*.md` から `specs/09-*.md` および `.ja.md` 兄弟) **when** 述べられたディレクトリ規約を遡及的に適用する **then** すべてが適合している。これが一括移動マイルストーンではなく規約宣言マイルストーンであることを確認する。
- **Given** 既存のすべての ADR ファイル (`.claude/meta/adr/001-*.md` から `.claude/meta/adr/018-*.md` および `.ja.md` 兄弟) **when** 述べられたディレクトリ規約を遡及的に適用する **then** すべてが適合している。
- **Given** 本 Spec に述べられた MECE 境界 **when** 将来のマイルストーン作成者が新しい懸念が #10、#09、#04、#05、または #11 に属するかを評価する **then** 境界は明確である: #04 はコミット時に散文のパス参照を検証する; #05 はコミット時に Roadmap グリフ値と双方向 ADR リンクコントラクトを検証する; #09 は Spec ファイルの **ファイル名** 規約を管理する (`NN-slug.md`); #10 は Spec と ADR ファイルが置かれる **ディレクトリの場所** を管理する (`specs/`、`.claude/meta/adr/`); #11 は検証ドメインのオプトイントリガーガイダンスを管理する。 <!-- ref-allow: #11 is a reserved-but-absent Roadmap row (ADR-014 reservation rule); the MECE boundary must name it before its Spec is authored at pickup -->

## 主なインタラクション

1. **マイルストーン #09 (Spec ファイル名規約) とのインタラクション。** #09 はファイル名形式 (`NN-slug.md`) をピンする。#10 はディレクトリ (`specs/`) をピンする。2 つは MECE である: 合わせて完全な標準パス `specs/NN-slug.md` を指定する。ファイル名形式について不確かな将来の作成者は #09 を読む; ディレクトリについて不確かな将来の作成者は #10 を読む。どちらも他方を包含しない。
2. **ADR-014 (Roadmap インデックスを単一エントリポイントとする) とのインタラクション。** ADR-014 の Spec 予約ルールは、各 Roadmap 行の `spec: specs/NN-slug.md` パスを通じてすでに `specs/` ディレクトリを暗に含んでいる。マイルストーン #10 はその予約パスのディレクトリコンポーネントを、明示的な規約として宣言することで規範的にする。予約ルールは変更されない; #10 は予約パスのディレクトリがすでに満たしている名前付きルールを追加する。
3. **マイルストーン #04 (ダングリング参照ディテクター) とのインタラクション。** #04 ディテクターはコミット時にドキュメントの散文のパス参照が既存のファイルに解決することを検証する。architect の #10 決定が CI ディレクトリ適合性チェックを導入する場合、それはトリガーとスコープの両方で #04 とは別のチェックである: #04 は参照パスが存在するかどうかを確認し; #10 CI チェックは既存のファイルが標準ディレクトリに置かれているかどうかを確認する。2 つは重複しない。
4. **マイルストーン #05 (Roadmap drift-detection CI) とのインタラクション。** #05 ディテクターはコミット時に Roadmap グリフの整形性と双方向 ADR リンクコントラクトを検証する。#10 CI チェックは `specs/` と `.claude/meta/adr/` ディレクトリの内容を検証し、#05 のスコープとは別である。2 つは重複しない。
5. **マイルストーン #06 (二言語対応パリティディテクター、ADR-018) とのインタラクション。** #06 CI は EN と JA Spec ファイル間の見出しツリーパリティを強制する。#10 のディレクトリ規約 (EN と JA の兄弟が `specs/` に共存し、`specs/en/` / `specs/ja/` に分割しない) は、#06 のファイルペア単位のキーイングが正しく機能するための前提条件である: #06 は `<stem>.ja.md` をキーにし、同じディレクトリから `<stem>.md` を導出する。ファイルが言語サブディレクトリをまたいで分割されていれば、#06 のキーイングは壊れる。#10 は #06 が依存する同一ディレクトリ規約を確認する。 <!-- ref-allow: specs/en/ and specs/ja/ are non-existing illustrative paths documenting what this convention does NOT use; their non-existence is the point -->
6. **`## Document Templates` ガイダンスとのインタラクション。** CLAUDE.md の `## Document Templates` セクションは現在「結果となるドキュメントをどこに置くかはあなたが決める」と述べ、例示的な二言語例として `adr/en/` / `adr/ja/` 分割を提示している。このガイダンスはフォークに対して正確である。#10 のこのリポジトリ向けピン済みディレクトリ規約との緊張関係は architect の決定によって解決されなければならない (リスク R-01 参照): "you decide" ガイダンスをフォーク向けに明示的にスコープするか、このリポジトリのピン済み規約の別記述を追加するか、またはその両方か。調整戦略は委ねられている; 緊張関係を名付けることが #10 の貢献である。
7. **マイルストーン #11 (検証ドメインのオプトイントリガーガイダンス) とのインタラクション。** #11 は予約済みだが不在の Roadmap 行である。#10 と #11 の MECE 境界: #10 は Spec/ADR ファイルのディレクトリ場所を管理し; #11 は検証ドメインのオプトイントリガー動作のガイダンスを管理する。これらは重複しない懸念事項である。 <!-- ref-allow: #11 is a reserved-but-absent Roadmap row (ADR-014 reservation rule); the MECE boundary must name it before its Spec is authored at pickup -->
8. **構造的な HOW は architect に委ねる。** ディレクトリ規約が CLAUDE.md (`## Document Templates` の修正、`## Roadmap` Rules ブロックの新しい箇条書き、またはその両方) に述べられるかどうか; CI ディレクトリ適合性チェックが必要かどうか (新しいディテクター + 新しい MECE 境界 + 新しいキーイング => 新しい ADR-019; ADR-014 の予約ルール決定の帰結明確化/拡張 => ADR-014 amendment ── architect は ADR-018 Alternative-B の判別子を適用する; ADR-018 が最後に使用された番号、ADR-019 は未使用); エージェントプロンプト (product-manager.md、architect.md) または spec/adr テンプレートが編集を必要とするかどうか; 正確な MECE 境界ドキュメント ── すべて architect の forthcoming decision に委ねる。 <!-- ref-allow: forthcoming architect decision for #10; authored when #10 moves to implementation -->

## メトリクス

- **先行指標:** 本マイルストーン出荷後、`product-manager` が作成するすべての新しい Spec が過去のファイルパスを参照せずに `specs/` に置かれ、`architect` が作成するすべての新しい ADR が過去のファイルパスを参照せずに `.claude/meta/adr/` に置かれる。セッショントランスクリプトで検証可能。
- **先行指標:** Roadmap 行 #10 以降の `specs/` または `.claude/meta/adr/` でのゼロのディレクトリ配置逸脱、git 履歴で観察可能。
- **遅行指標:** 規約が継承された規範的な場所に明示的に述べられることで、派生リポジトリでの「この Spec/ADR をどこに置くべきか?」という質問の削減。

## リスクとオープンクエスチョン

### リスク R-01: architect に委ねられた構造的決定 ── 規約配置、`## Document Templates` の緊張関係、CI チェック、ADR 戦略 <!-- ref-allow: forthcoming architect decision for #10; authored when #10 moves to implementation -->

**説明。** 本 Spec は規約がカバーしなければならない *こと* (Spec の標準ディレクトリ、ADR の標準ディレクトリ、同一ディレクトリ二言語規約、遡及的な適合性) と適合した宣言の受け入れ基準を述べる。構造的な *どのように* を明示的に委ねる: 作成ステップで追加ファイル読み取りなしにエージェントが出会えるようにディレクトリ規約が文書化される場所; `## Document Templates` の "you decide" ガイダンスとの緊張関係をどのように調整するか (フォーク向けにスコープするか? 別のピン済み規約記述を追加するか?); CI ディレクトリ適合性チェックが必要かどうか、そしてそうであれば新しい ADR-019 か ADR-014 amendment か (architect は ADR-018 Alternative-B の判別子を適用する: 新しいディテクター + 新しい MECE 境界 + 新しいキーイング => 新しい ADR-019; ADR-014 の既存予約ルール決定の帰結明確化/拡張 => ADR-014 amendment; ADR-018 が最後に使用された番号、ADR-019 は未使用); <!-- ref-allow: ADR-019 is a forthcoming reserved number cited as a possible outcome of the architect's decision; it does not yet exist by design --> エージェントプロンプト (product-manager.md、architect.md) または spec/adr テンプレートが編集を必要とするかどうか。これは `specs/09-spec-filename-convention.md`、`specs/08-orchestrator-row-guard.md`、`specs/07-roadmap-status-transitions.md`、`specs/06-bilingual-parity-detector.md`、`specs/05-roadmap-drift-detection-ci.md` が使用した R-01 パターンを踏襲する。

**architect に渡す緩和制約。** architect の forthcoming decision は以下を指定しなければならない: (a) Spec 作成と ADR 作成ステップで追加ファイル読み取りなしに `product-manager` と `architect` が出会えるようにディレクトリ規約が文書化される場所 (CLAUDE.md `## Document Templates` 修正 vs `## Roadmap` Rules ブロック箇条書き vs 両方 vs エージェントプロンプト)、(b) "you decide where to place" ガイダンスとピン済み規約の緊張関係をどのように解決するか。`## Document Templates` の例示的な `adr/en/` / `adr/ja/` 分割の例がフォークに適用されこのリポジトリのピン済み規約ではないことを明確にするスコープ注記が必要かどうかを含む、(c) CI ディレクトリ適合性チェックが含まれるかどうか、そしてそうであれば ADR-014 amendment か新しい ADR-019 か (Alternative-B 判別子を適用)、(d) #10 のディレクトリスコープを #09 のファイル名スコープ、#04 のパス存在スコープ、#05 の Roadmap 構造スコープ、および将来の #11 スコープから区別する明示的な MECE 境界記述。 <!-- ref-allow: forthcoming architect decision for #10; authored when #10 moves to implementation --> その決定が存在するまで、暗黙の規約 (27 の既存の適合した Spec および ADR ファイルと ADR-014 予約ルールから推測される) がプロセスガイダンスとして本 Spec の宣言された規約によって拡張されながら運用慣行として残る。

**注意:** forthcoming architect decision を参照する行の `<!-- ref-allow: -->` 抑制は本 Spec ファイル (`specs/10-spec-adr-directory-pinning.md`) のみに存在し、`specs/09-spec-filename-convention.md` がその architect decision に対して設定した先例に従っている。抑制は `CLAUDE.md` に現れない。

### リスク R-02: #09 (ファイル名規約) へのスコープクリープ

**説明。** マイルストーン #09 はファイル名形式 (`NN-slug.md`) をピンする。将来の作成者またはレビュアーが「ファイルがどのように名前付けられるか」(#09) と「ファイルがどこに置かれるか」(#10) を混同する可能性がある。隣接性は実在する: 完全な標準パスは `specs/NN-slug.md` であり、ディレクトリ (#10 のスコープ) とファイル名 (#09 のスコープ) を組み合わせる。

**緩和策。** MECE 境界は本 Spec の非ゴール、ゴール、主なインタラクションセクションに述べられている。受け入れ基準はディレクトリコンポーネントに厳密にスコープされている。将来の作成者が #10 にファイル名ルールを追加することを提案した場合、正しい応答は #09 にルーティングすることである。

### リスク R-03: `## Document Templates` ガイダンスの緊張関係

**説明。** 既存の `## Document Templates` セクションの "you decide where to place" ガイダンスは、フォークに対して意図的に許容的である。同じまたは隣接する場所でこのリポジトリのピン済み規約を宣言すると、独自のレイアウトを選択することを期待するテンプレート採用者を混乱させる可能性がある。

**緩和策。** architect の決定 (リスク R-01、サブポイント b) はスコープを明示的に扱わなければならない: ピン済み規約が明示的な「このリポジトリのドッグフーディング姿勢のために」修飾子と共に述べられるか、`## Document Templates` がフォークガイダンスとこのリポジトリガイダンスを分離するよう修正されるか、またはその両方か。緊張関係はここで名付けられており、静かに解決されることはできない。

## スコープ対象外

- 既存の Spec ファイル (`specs/01-*.md` から `specs/09-*.md`) の名前変更または移動 ── すべてすでに標準ディレクトリに存在する。
- 既存の ADR ファイル (`.claude/meta/adr/001-*.md` から `.claude/meta/adr/018-*.md`) の名前変更または移動 ── すべてすでに標準ディレクトリに存在する。
- Spec ファイルのファイル名規約の変更 ── それはマイルストーン #09 である。
- CI ディレクトリ適合性チェックの追加 ── architect に委ねた構造的決定。
- 派生プロジェクット向けのディレクトリ規約の定義 ── フォークは `## Document Templates` ガイダンスに従って独自のレイアウトを選択する。
- 二言語対応パリティルールの変更 ── #06 (ADR-018) がそのチェックを所有する。
- ADR の 3 桁プレフィックス規約の変更 ── それは ADR 作成慣行であり、このマイルストーンのスコープではない。

## 参照

- ADR-014 (Roadmap インデックスを単一エントリポイントとする) ── §決定「マイルストーン (1:1) で Spec は必須」と §Amendment (Spec 予約ルール): `spec: specs/NN-slug.md` パスは `specs/` ディレクトリを暗に含んでいる; #10 はそれを名前付き規約として規範的にする
- ADR-018 (二言語対応パリティディテクター) ── EN と JA Spec ファイル間の見出しツリーパリティを強制する CI; そのファイルペア単位のキーイングは EN と JA の兄弟が同じディレクトリに共存することを前提としており、#10 はそれを規約として確認する
- `specs/09-spec-filename-convention.md` ── 隣接するマイルストーン: #09 はファイル名 (`NN-slug.md`) をピンし; #10 はディレクトリ (`specs/`) をピンする; 合わせて完全な標準パスを構成する
- `specs/08-orchestrator-row-guard.md` ── 構造的兄弟; その R-01 が本 Spec がミラーする ADR-018 Alternative-B 判別子の指示を確立する <!-- ref-allow: forthcoming architect decision for #10; authored when #10 moves to implementation -->
- `specs/07-roadmap-status-transitions.md` ── 構造的兄弟; その R-01 が本 Spec が従う 2 セッション決定と実装の分割を確立する <!-- ref-allow: forthcoming architect decision for #10; authored when #10 moves to implementation -->
- `specs/05-roadmap-drift-detection-ci.md` ── MECE 境界の補完: #05 はコミット時に Roadmap 構造的整合性を検証する; #10 はディレクトリ規約を述べる
- `specs/04-dangling-reference-detector.md` ── MECE 境界の補完: #04 はコミット時に散文のパス参照の存在を検証する; #10 はパスの存在ではなくディレクトリの場所を述べる
- `specs/11-verification-domain-opt-in-guidance.md` (予約済み) ── 隣接するマイルストーン: #11 は検証ドメインのオプトイントリガーガイダンスを管理し; #10 は Spec/ADR ファイルのディレクトリ場所を管理する; 2 つは重複しない <!-- ref-allow: #11 is a reserved-but-absent Roadmap row (ADR-014 reservation rule); the MECE boundary must name it before its Spec is authored at pickup -->
- Roadmap row: #10
