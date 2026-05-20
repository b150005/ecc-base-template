# CI 免除許可リストの有効期限/レビュー機構

## Status

Approved

**Owner:** product-manager
**Target release:** Roadmap row #18

## Problem

このテンプレートは、CI 検出器とテストスイートが偽陽性を抑制するための 6 種類の免除機構を提供しています。これらの機構は正当な目的を持っています。まだ作成されていないファイルへの前方参照、オプトイン語彙の構造的に計算されたカットアウト、不在主張の規約、および既存成果物のgrandfather ルールなどです。しかし、これらの機構はいずれも有効期限、レビュー頻度、担当オーナー、または再評価トリガーの概念を持っていません。マイルストーンの実装期間中に正当な前方参照を抑制するために追加された `<!-- ref-allow: <reason> -->` マーカーは、参照先の成果物が作成された後も長期間静かに残り続け、同じ行の背後に新しい dangling reference を隠す過剰抑制となります。Roadmap マイルストーン #16 と #17 はいずれも、対象ファイルが実体化した後に over-suppression となった ref-allow マーカーを削除するために、technical-writer による行ごとの個別判定が必要でした。このパターンは偶発的なものではなく、構造的なものです。今日追加されたすべての ref-allow マーカーは、明日再評価を促す機構を持っていません。このテンプレートには、免除コーパスが検出器の目的を損なう古い抑制を静かに蓄積しないよう、免除のライフサイクル機構が必要です。

## Goals

- `<!-- ref-allow: <reason> -->` マーカーに有効期限の概念を導入し、時間的に限定された免除を永続的な構造的免除と区別できるようにする。
- CI が期限切れの ref-allow マーカーを検出して WARN シグナル (ハードな FAIL ではない) を生成し、既存のパイプラインを壊さずに人間による再評価を促す。
- 期限切れおよび長期存在する ref-allow マーカーのレビュー頻度オーナーシップを定義する (テンプレート内部マーカーにはテンプレートメンテナー、派生リポジトリのマーカーにはフォークメンテナー)。
- このマイルストーンが出荷される時点でリポジトリに存在するすべての ref-allow マーカーを新しい有効期限要件から免除する grandfather ルールを確立する — 既存の抑制への破壊的変更なし。
- このマイルストーン (#18) と成果物自己キー型の免除機構 (skill-invariants grandfather、ADR-017 不在主張、ADR-014 Reservation-rule carve-out) 間の MECE 境界を明確にする。これらは明示的にスコープ外。

## Non-goals

- **パスの許可リストなし。** このマイルストーンは、除外パスの一元化された許可リストファイルを作成しません。ADR-015 の amendment は、パス許可リストを陳腐化と構造キー化との不整合に陥りやすいアンチパターンとして明示的に分類しています。ref-allow 機構は行レベルのままです。
- **成果物自己キー型免除のライフサイクル変更なし。** 3 つの構造的に計算された免除 — `check-skill-invariants.sh` の skill-invariants `is_exempt()` grandfather、`check-roadmap-drift.sh` の ADR-017 不在主張免除、`check-dangling-refs.sh` の ADR-014 Reservation-rule carve-out — は、人間が作成した理由文字列ではなく成果物自身の構造にキーが設定されています。これらの陳腐化リスクは ref-allow マーカーとは質的に異なります。これら 3 つのライフサイクル変更は別の将来のマイルストーンです。
- **`workaround-tracker.yml` の有効期限機構への変更なし。** `.github/workaround-tracker.yml` の既存の `expires_on` および `expiry_warning_days` フィールドは、CI 免除マーカーではなく upstream-workaround レジストリエントリを管理します。このマイルストーンはその機構を変更しません。先行事例の参照としてのみ機能します。
- **ADR-015 amendment の語彙 carve-out への変更なし。** `check-dangling-refs.sh` の `absent` / `default-off` / `opt-in` 語彙キーおよび `.example` 兄弟構造シグナルは構造的に計算されており、ref-allow 文字列ではありません。スコープ外です。
- **期限切れマーカーによるハードな FAIL なし。** 期限切れマーカーは WARN シグナルを生成し、パイプラインをブロックする FAIL は生成しません。これは ADR-015 amendment が導入した猶予期間の哲学 (語彙 carve-out エッジケースに対する WARN-not-FAIL) を反映し、まだアップグレードしていない派生リポジトリの破壊を回避します。
- **この Spec で新しい CI 検出器は作成しない。** 具体的な実装機構 (既存検出器への amendment、新しい 7 番目の検出器、または別個のチェック) はアーキテクトに委ねられます。この Spec は検出可能でなければならないものを定義します。ADR はその方法を定義します。
- **#16 および #17 との MECE。** Roadmap #16 は ADR-001 Status 語彙の修正を担当しました。#17 は ADR-002/003/004 Status フォーマットの正規化と CHANGELOG 同期を担当しました。#18 は CI 免除ライフサイクル機構を担当します。これら 3 つのマイルストーンは重複しません。
- **Spec 作成時の CHANGELOG 編集なし。** technical-writer は、Spec 作成中ではなく開発ワークフローの step 7 で CHANGELOG エントリを追加します。
- **この Spec で JA sibling は作成しない。** `specs/18-ci-exemption-allowlist-expiry.ja.md` は technical-writer が step 7 で作成します。その heading-tree parity は Roadmap #06 のオーナーシップによって管理されます。

## User stories

| 対象者                                       | やりたいこと                                                                     | 目的                                                                                     |
|---------------------------------------------|---------------------------------------------------------------------------------|------------------------------------------------------------------------------------------|
| テンプレートメンテナー                        | 有効期限付きの時間限定 ref-allow マーカーを追加したい                           | CI が参照先の成果物が存在するはずの時期になったら抑制の再評価を促してくれるようにしたい   |
| フォークメンテナー                            | リポジトリの ref-allow マーカーが期限切れになったとき WARN (FAIL ではない) を見たい | パイプラインを突然壊すことなく、どの抑制をレビューすべきかを把握したい               |
| Spec を作成する実装者                         | grandfather ケースの既存構文を使って ref-allow マーカーを書きたい               | 既存のマーカーが新しい機構によって無効化されないようにしたい                           |
| マイルストーンを検証するコードレビュアー     | すべての新しい ref-allow マーカーが有効期限を持つか、明示的に grandfather 化されていることを確認したい | 免除コーパスが説明責任なしに増加しないようにしたい |

## Acceptance criteria

- **AC-1 — 有効期限の日付フォーマット定義:**
  有効期限付きの ref-allow マーカーが与えられ、CI がその行を処理するとき、
  日付は ISO 8601 (`YYYY-MM-DD`) に準拠しなければなりません。他のフォーマットは
  存在しないとして扱われます (有効期限なし)。

- **AC-2 — 拡張 ref-allow 構文:**
  既存の `<!-- ref-allow: <reason> -->` 構文が与えられ、このマイルストーンが
  出荷されるとき、`<!-- ref-allow: <reason> | expires: YYYY-MM-DD -->` の形式で
  オプションの有効期限節がサポートされます。`<reason>` テキストと `expires:` 節は
  ` | ` で区切られます。`<reason>` 部分は必須であり、人間が読める形式です。
  `expires:` 節はオプションです。

- **AC-3 — 期限切れマーカー検出 (WARN、FAIL ではない):**
  `expires: YYYY-MM-DD` の日付が CI 実行日より前の ref-allow マーカーが与えられ、
  関連する検出器がその行を処理するとき、検出器はファイル、行番号、有効期限、
  および理由文字列を識別する WARN レベルのメッセージを出力します。検出器は
  期限切れマーカーだけを理由にゼロ以外のコードで終了しません。有効期限の警告は
  勧告的なものです。

- **AC-4 — 期限切れでないマーカーの動作変更なし:**
  `expires: YYYY-MM-DD` の日付が今日以降の ref-allow マーカーが与えられ、
  関連する検出器がその行を処理するとき、その行はこのマイルストーン以前と
  まったく同じように抑制されます。WARN なし、FAIL なし、出力変更なし。

- **AC-5 — 有効期限なしマーカーの動作変更なし (grandfather):**
  `expires:` 節を持たない ref-allow マーカー (#18 以前のフォーマット) が
  与えられ、関連する検出器がその行を処理するとき、その行は以前と同様に抑制されます。
  WARN なし、FAIL なし、出力変更なし。これは出荷時点のリポジトリ内にある
  すべての既存マーカーをカバーする grandfather ルールです。

- **AC-6 — 5 つの検出器の一貫性:**
  今日 `<!-- ref-allow: -->` を使用している 5 つの検出器
  (`check-bilingual-parity.sh`、`check-dangling-refs.sh`、
  `check-ecc-delegation-consistency.sh`、`check-roadmap-drift.sh`、
  `check-research-tier-auth.sh`) が与えられ、このマイルストーンが出荷されるとき、
  5 つすべてが有効期限検出ロジックを一貫して適用します。同じ WARN フォーマット、
  同じ ISO 8601 日付解析、有効期限なしマーカーに対する同じ grandfather 動作。

- **AC-7 — 既存の検出器とテストスイートでのリグレッションなし:**
  6 つの標準検出器 (`check-bilingual-parity.sh`、`check-dangling-refs.sh`、
  `check-ecc-delegation-consistency.sh`、`check-roadmap-drift.sh`、
  `check-research-tier-auth.sh`、`check-skill-invariants.sh`) と 7 つのテスト
  スイート (`test-check-bilingual-parity.sh`、`test-check-dangling-refs.sh`、
  `test-check-ecc-delegation-consistency.sh`、`test-check-roadmap-drift.sh`、
  `test-check-research-tier-auth.sh`、`test-check-skill-invariants.sh`、
  および CI ベースランナー) が与えられ、このマイルストーンの実装が適用されるとき、
  すべての既存テストが変更なしで合格します。リポジトリ内の既存の ref-allow
  マーカーで新しい WARN や FAIL を生成するものはありません。

- **AC-8 — grandfather スコープの定義:**
  このマイルストーンが出荷される時点でリポジトリに存在するすべての
  `<!-- ref-allow: ... -->` マーカー (テンプレート内部マーカー: `specs/`、
  `.claude/meta/adr/`、`.claude/CLAUDE.md`、`.claude/agents/`、
  `.claude/meta/scripts/`) が与えられ、このマイルストーン後に CI が実行されるとき、
  これらのマーカーは `expires:` 節の不在により WARN を生成しません。
  grandfather ルールは有効期限なしマーカーに無条件に適用され、時間的な制限はありません。

- **AC-9 — WARN メッセージフォーマットの仕様:**
  期限切れの ref-allow マーカーが与えられ、検出器が WARN を出力するとき、
  メッセージには `[WARN]` 文字列、リポジトリルートからの相対ファイルパス、
  行番号、有効期限、および理由テキストが含まれます。例のフォーマット:
  `[WARN] specs/18-ci-exemption-allowlist-expiry.md:42 ref-allow expired 2026-06-01: <reason>`。 <!-- ref-allow: illustrative WARN message example referencing a fictional line 42 inside this Spec file, not a real path lookup -->

- **AC-10 — レビュー頻度オーナーシップの文書化:**
  この機構の実装が与えられ、アーキテクトと technical-writer がそれぞれのステップを
  完了するとき、CLAUDE.md または関連するエージェント指示ファイルに以下が文書化されます:
  (a) テンプレートメンテナーはテンプレート内部ファイル (`specs/`、
  `.claude/meta/adr/`、`.claude/CLAUDE.md`、`.claude/agents/`) の
  期限切れ ref-allow マーカーのレビューを担当する。(b) フォークメンテナーは
  派生リポジトリ内のマーカーのレビューを担当する。(c) `technical-writer` は
  各マイルストーンの step-7 ドキュメント作業の一環として over-suppression と
  なったマーカー (参照先の成果物がディスク上に存在するもの) を削除する責任を負う。

- **AC-11 — 省略された有効期限のデフォルト:**
  `expires:` 節を持たない新しい ref-allow マーカーが与えられ、CI が実行されるとき、
  WARN は出力されません (有効期限なしの形式は grandfather ルールの下で有効かつ
  永続的です)。アーキテクチャ決定 (ADR) は有効期限を含めるタイミングの規約を
  推奨することがありますが、CI は新しいマーカーに `expires:` 節の存在を強制しません。

- **AC-12 — 実装機構はアーキテクトに委ねる:**
  この Spec が検出可能でなければならないもの (AC-1 から AC-11) を定義していることが
  与えられ、アーキテクトがこのマイルストーンの ADR を作成するとき、ADR は
  有効期限ロジックを: (a) 5 つの既存 ref-allow 使用検出器それぞれへの amendment
  として追加するか、(b) それらの検出器がソースする共有シェル関数に抽出するか、
  (c) 別個の 6 番目以降の検出器スクリプトとして実装するかを決定します。
  Spec は機構を強制しません。観察可能な動作を強制します。

- **AC-13 — 実装時にテンプレート内の既存 ref-allow マーカーを列挙しカタログ化:**
  実装者がこのマイルストーンの作業を開始することが与えられ、実装ステップを
  開始するとき、実装者はテンプレートリポジトリ内のすべての既存の有効期限なし
  ref-allow マーカー (grandfather 対象母集団) を列挙し、その数を実装コミット
  メッセージまたはコードコメントに記録します。これによりレビューのベースラインが
  追跡可能になります。

## Key interactions

- **product-manager:** この Spec を作成します (現在のステップ)。Spec 作成と同時に
  Roadmap #18 を `☐ todo` から `◐ in-progress` に原子的に切り替えます。
- **architect:** ADR-018 Alternative-B トライアド (新しい契約境界 + 新しいキー/機構 +
  新しい構造成果物) を適用して、新しい ADR (ADR-022) が必要かどうかを判断します。
  有効期限検出ロジックが新しい構造的な規約 (検出器ファミリーの新しい MECE パーティション)
  を構成する場合、ADR-022 が `.claude/meta/adr/` に作成されます。
  有効期限検出ロジックが既存の ref-allow escape-hatch 設計 (ADR-015 amendment) の
  結果明確化である場合は、ADR-015 への amendment で十分かもしれません。
  アーキテクトの判断がどちらのパスをとるかを決定します。
- **implementer:** 各 AC を逐語的な契約として扱います。5 つの検出器全体で
  有効期限検出を一貫して実装します (AC-6)。`check-skill-invariants.sh` や
  3 つの成果物自己キー型 carve-out は変更しません (Non-goals)。
  grandfather 母集団を列挙・記録します (AC-13)。
  既存の 7 つのテストスイートをすべて実行して AC-7 を検証します。
- **code-reviewer:** AC-6 (5 検出器の一貫性)、AC-7 (リグレッションなし)、
  AC-8 (grandfather スコープ)、および AC-9 (WARN メッセージフォーマット) を
  diff だけでなく実際のファイルと CI 出力に対して独立して検証します。
- **technical-writer:** step 7 において — (a) 有効期限機構を記録する 1 つの
  CHANGELOG エントリを `## [Unreleased]` の `### Added` または `### Changed`
  サブセクションに追加します。(b) `specs/18-ci-exemption-allowlist-expiry.ja.md` を作成します
  (JA sibling、Roadmap #06 オーナーシップによる heading-tree parity 検証)。
  (c) この Spec ファイル内のすべての ref-allow マーカーをレビューし、
  参照先の成果物がディスク上に存在するようになった over-suppression を削除します。

## Metrics

- **Leading:** 出荷時点でリポジトリに存在する grandfather ルール (AC-8) でカバーされる
  既存 ref-allow マーカーの数。初期ベースラインの予想: `specs/`、
  `.claude/meta/adr/`、`.claude/agents/`、`.claude/meta/scripts/` 全体で
  おおよそ 20〜40 個のマーカー。実装コミットメッセージで追跡します (AC-13)。
- **Leading:** 既存の 7 つのテストスイートがすべて変更なしで合格します (AC-7)。
  実装時に CI 実行によって即座に測定可能です。
- **Lagging:** 出荷後 12 ヶ月間における over-suppression インシデント (マイルストーン
  ごとの technical-writer による個別判定、#16 と #17 で見られたもの) の減少。
  定性的観察。CI で強制されません。
- **Lagging:** #18 以降のテンプレートマイルストーンで追加された新しい永続的な
  有効期限なし ref-allow マーカーのうち、後から個別判定が必要になったものがゼロ。
  定性的。アーキテクトまたはオーケストレーターが振り返りレビューで監視します。

## Risks and open questions

- **派生リポジトリの grandfather スコープ曖昧性。** grandfather ルール (AC-8) は
  出荷時点のテンプレートリポジトリに対して定義されています。#18 出荷後にテンプレートを
  フォークする派生リポジトリは更新された検出器を引き継ぎます。それらの既存
  ref-allow マーカーも有効期限なし grandfather (AC-5) でカバーされるため、
  破壊的変更はありません。ただし、フォーク日と更新日の間に追加された ref-allow
  マーカーを持つ派生リポジトリが、新しい検出器を取り込むために更新する場合があります。
  これらも AC-5 (有効期限なし = 永続 grandfather) でカバーされます。
  リスクは低く、WARN は勧告的なものです (AC-3)。
- **WARN シグナルの視認性。** CI が WARN メッセージを目立つ形で表示しない場合
  (例: verbose 出力に埋もれる)、期限切れマーカーが気づかれない可能性があります。
  アーキテクトの ADR は、期限切れマーカーの WARN が各検出器の実行終了時に
  集約されるかどうか、および CI ジョブサマリーセクションが更新されるかどうかを
  指定する必要があります。これはこの Spec の AC を変更しない ADR の実装詳細です。
- **有効期限の日付選択規約。** Spec は `expires: YYYY-MM-DD` 構文を強制しますが
  (AC-2)、著者がいつ日付を設定すべきかは強制しません。2099-01-01 の有効期限を
  設定する著者は技術的に準拠していますが、目的を損ないます。アーキテクトの ADR は
  規約を推奨する必要があります (例: 有効期限 = マイルストーンの目標日 + 90 日)。
  CI ゲートにはなりません。
- **5 つの検出器 amendment のスコープ。** 有効期限ロジックを共有するために
  5 つの別個の検出器スクリプトを変更することは、将来の検出器が追加され、
  共有ロジックが抽出されない場合に不整合のリスクがあります。アーキテクトの ADR は、
  共有シェルライブラリ (例: すべての検出器がソースする `ref-allow-lib.sh`) が
  必要かどうか、または現在の 6 つの検出器のスケールではテスト付きコピーペーストが
  許容されるかどうかを検討する必要があります。
- **`check-bilingual-parity.sh` のデュアルモードスキャンとの相互作用。**
  bilingual parity 検出器は `ref-allow` を 2 つの別個のスキャンパス
  (heading-key 抽出とコンテンツ行スキャン) で使用します。有効期限検出ロジックは
  両方のパスで一貫して適用される必要があります。アーキテクトの ADR はこれを
  検証する必要があります。

## Out of scope

- 成果物自己キー型免除: `check-skill-invariants.sh` の `is_exempt()`、
  ADR-017 不在主張免除、ADR-014 Reservation-rule carve-out。
  これらは成果物構造から計算されており、人間が作成した文字列ではありません。
  そのライフサイクルは質的に異なります (Non-goals 参照)。
- `workaround-tracker.yml` の `expires_on` / `expiry_warning_days` フィールドの
  変更 (upstream-workaround レジストリエントリ、別個の機構、Non-goals 参照)。
- ADR-015 amendment の語彙 carve-out (`absent` / `default-off` / `opt-in`
  構造キー化) — 構造的に計算されており、スコープ外。
- あらゆる種類のパス許可リストの作成 (ADR-015 amendment のアンチパターン)。
- 有効期限検出ロジックの具体的な実装 (アーキテクト/実装者、この Spec ではない —
  AC-12 参照)。
- CHANGELOG 編集 (step 7 での technical-writer の作業)。
- JA sibling の作成 (step 7 での technical-writer の作業)。
- 期限切れマーカーのハードな FAIL (WARN のみ — Non-goals 参照)。
- `<!-- ref-allow: <reason> -->` 有効期限なし形式のセマンティクスへの変更
  (永続 grandfather、動作変更なし — AC-5)。

## References

- Roadmap row: #18
- `specs/04-dangling-reference-detector.md` — 元の ref-allow escape-hatch 構文と
  セマンティクスを定義します。escape hatch の意味の信頼できる情報源です。
- `.claude/meta/adr/015-dangling-reference-detector.md` — ADR-015 amendment は
  パス許可リストを明示的にアンチパターンとして分類します。語彙 carve-out
  (WARN-not-FAIL 哲学) を定義します。
- `.claude/meta/adr/017-roadmap-drift-detector.md` — 不在主張免除の先行事例。
  構造キー化の参照。
- `.claude/meta/adr/006-upstream-workaround-tracking.md` — 時間限定ライフサイクル
  追跡の先行事例としての `expires_on` (異なる機構、同じ意図)。
- `.github/workaround-tracker.yml` — WARN-not-FAIL 有効期限シグナリングの既存
  `expiry_warning_days: 14` 参照実装。
- `.claude/meta/scripts/check-dangling-refs.sh` — 標準的な ref-allow コンシューマー。
  ADR-015 amendment の語彙 carve-out と ADR-014 Reservation-rule carve-out が
  ここに存在します。
- `.claude/meta/scripts/check-bilingual-parity.sh` — デュアルパススキャンを持つ
  ref-allow コンシューマー。
- `.claude/meta/scripts/check-ecc-delegation-consistency.sh` — ref-allow コンシューマー。
- `.claude/meta/scripts/check-roadmap-drift.sh` — ref-allow コンシューマー。
  ADR-017 不在主張キー化がここに存在します。
- `.claude/meta/scripts/check-research-tier-auth.sh` — 5 番目の ref-allow コンシューマー。
- `.claude/meta/adr/022-ci-exemption-expiry.md`
  — このマイルストーンの見込み ADR (番号は次の未使用番号。アーキテクトが
  作成するかどうかを決定します)。
