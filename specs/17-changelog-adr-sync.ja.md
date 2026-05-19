> このドキュメントは `specs/17-changelog-adr-sync.md` の日本語訳です。英語版が原文 (Source of Truth) です。

# CHANGELOG↔ADR 承認同期および ADR-001–005 バックフィル

## Status

Approved

**Owner:** product-manager
**Target release:** implementer がバックフィル編集を完了した後の次のパッチリリース

## Problem

リポジトリのドキュメントコーパスには、関連する 2 つの整合性ギャップが存在します。

**ギャップ 1 — ADR-002/003/004 のステータス形式の逸脱。** ADR テンプレート (`adr-template.md`) は、正規のステータス形式を `Accepted — YYYY-MM-DD` (U+2014 em-dash) と定義しています。Roadmap #16 は ADR-001 を修正し、em-dash 形式をテンプレート標準として確立しました。ADR-005 はすでに em-dash 形式を使用しています。しかし ADR-002、ADR-003、ADR-004 は EN sibling と JA sibling の両方で、ピリオド区切りの形式 (`Accepted. YYYY-MM-DD.`) を使用しています — 合計 6 行です。これにより、ADR-002 から ADR-004 のステータス行を解析しようとするあらゆる読者やツールは、テンプレートや ADR-001・ADR-005 と整合しない形式に遭遇することになります。現時点では全 ADR のステータス行に形式の統一を強制する CI ゲートが存在しないため、この不一致はサイレントに継続しています。

**ギャップ 2 — ADR ステータスバックフィルマイルストーンに対応する CHANGELOG エントリが存在しない。** CHANGELOG はマイルストーンごとに注目すべき変更を記録しています。ADR-001 のステータス修正 (#16) は対応する CHANGELOG エントリなしに出荷されました。ADR-002/003/004 のバックフィルが完了した後も同じギャップが生じます。CHANGELOG には `## [Unreleased]` 配下に、ADR-001–005 のステータス形式正規化のバックフィルを記録する 1 件のエントリが必要です (#16 の修正をすでに完了した背景コンテキストとして扱い、#17 の修正を現在のエントリとして記録します)。どちらのギャップもプロダクトの観点からユーザー向けではありませんが、どちらもコントリビューター向けの正確性の問題であり、統一された解析可能なステータス行に依存する将来のツールの開発を遅らせます。

## Goals

- ADR-002、ADR-003、ADR-004 の EN ファイルのステータス形式を `Accepted — YYYY-MM-DD` (em-dash、#16 で確立されたテンプレート標準に一致) に正規化する。
- ADR-002、ADR-003、ADR-004 の JA sibling のステータス形式を `Accepted — YYYY-MM-DD` (EN em-dash 形式、#16 の §Risks 解決で確認された支配的なコーパスパターンに一致) に正規化する。
- `## [Unreleased]` 配下に 1 件の CHANGELOG エントリを追加し、ADR-002/003/004 のステータス形式正規化を記録する。すでに完了した ADR-001 修正 (#16) を背景コンテキストとして参照する。
- ADR-002/003/004 の EN および JA の本文テキスト、根拠、代替案、Metadata セクションをすべてそのまま保持する。各ファイルのステータス行のみを変更する。

## Non-goals

- **ADR-001 ステータスの変更** — ADR-001 のステータス行は Roadmap #16 によって `Accepted — 2026-04-22` に修正済みであり、すでにテンプレート標準形式になっています。このマイルストーンでは ADR-001 への追加変更は必要なく、許可もされません。
- **ADR-005 ステータスの変更** — ADR-005 はすでに EN と JA の両方で `Accepted — 2026-04-25` (em-dash 形式) を使用しています。すでに準拠しており、変更は行いません。
- **ADR-006 から ADR-021 のステータス形式監査** — 残りの ADR セット全体 (ADR-006 から ADR-021) のスキャンと正規化は明示的にスコープ外です。3 ファイルのバックフィル対象は ADR-002/003/004 のみです。ADR-006 以降のファイルに形式の逸脱がある場合、それは別の将来のマイルストーンです。このマイルストーンは em-dash 標準が確認される前 (#16) に存在していた 5 つの ADR に MECE 境界が設定されています。そのうち ADR-001 と ADR-005 はすでに準拠しており、ADR-002/003/004 のみが残ります。
- **ADR ステータス形式の新しい CI ゲート** — すべての ADR ファイルにステータス形式パターンを強制する CI チェックの追加は、このマイルストーンを満たすために必要ではありません。バックフィルは一度限りの機械的な修正です。CI ゲートはアーキテクトが必要と判断した場合に独自の ADR (ADR-018 トリアド) を必要とする構造的決定であり、別の将来のマイルストーンです。
- **#16 以前のマイルストーンに対する CHANGELOG バックフィル** — ADR-001 から ADR-004 の元の承認日 (2026-04-22 から 2026-04-25) に対する CHANGELOG エントリの追加はスコープ内ではありません。このマイルストーンで追加される CHANGELOG エントリは、ステータス形式正規化イベント (#17) をカバーするものであり、元の ADR 承認イベントではありません。
- **JA CHANGELOG エントリ** — JA CHANGELOG sibling は現時点でリポジトリに存在しません。作成はこのマイルストーンの範囲外です。
- **Spec JA sibling の作成** — `specs/17-changelog-adr-sync.ja.md` は technical-writer が後のステップで作成します。この Spec は EN のみを対象とします。
- **ADR-001 の語彙/概念変更 (#16 が対象)** — #16 は ADR-001 のステータス語彙修正 (`Proposed (stabilized)` の削除と `Accepted — 2026-04-22` への修正) を担当しました。このマイルストーンは ADR-002/003/004 の*形式*正規化 (ピリオド区切り → em-dash) を担当します。2 つのマイルストーンは MECE です: #16 は 1 つのファイルの語彙トークンを変更し、#17 は 3 つのファイルの区切り文字を変更します。

## User stories

| As a...                                    | I want to...                                                        | So that...                                                             |
|--------------------------------------------|---------------------------------------------------------------------|------------------------------------------------------------------------|
| いずれかの ADR を読むコントリビューター    | 一貫した `Accepted — YYYY-MM-DD` のステータス形式を確認する         | 形式のノイズなしに承認日と履歴を比較できる                             |
| ADR ステータスを解析するエージェントやツール | 初期 5 件の ADR すべてに統一された em-dash 形式を見つける           | regex やパターンベースのツールが特別ケースを必要としない               |
| マイルストーンを追跡する CHANGELOG 読者   | ADR-001–005 の正規化を記録する簡潔なエントリを確認する              | マイルストーンがリリース履歴で追跡可能になる                           |

## Acceptance criteria

- **AC-1 — ADR-002 EN ステータス行の正規化:**
  `.claude/meta/adr/002-growth-domains-location.md` を読んだとき、
  `## Status` セクションを検査すると、
  `## Status` 配下の最初の空白でない行が正確に
  `Accepted — 2026-04-23` (U+2014 em-dash、ADR-002 Metadata の `Date:` フィールドからの日付) である。

- **AC-2 — ADR-002 EN ステータス行が唯一の変更:**
  `002-growth-domains-location.md` の以前のコミット版との差分を調べると、
  ステータス行のみが変更されており、他の行は追加・削除・変更されていない。

- **AC-3 — ADR-002 JA ステータス行の正規化:**
  `.claude/meta/adr/002-growth-domains-location.ja.md` を読んだとき、
  `## Status` セクションを検査すると、
  `## Status` 配下の最初の空白でない行が正確に
  `Accepted — 2026-04-23` (EN em-dash 形式、#16 の §Risks 解決で確立された支配的な JA ADR コーパスパターンに一致) である。

- **AC-4 — ADR-002 JA ステータス行が唯一の変更:**
  `002-growth-domains-location.ja.md` の以前のコミット版との差分を調べると、
  JA ステータス行のみが変更されており、他の行は追加・削除・変更されていない。

- **AC-5 — ADR-003 EN ステータス行の正規化:**
  `.claude/meta/adr/003-learning-mode-relocate-and-rename.md` を読んだとき、
  `## Status` セクションを検査すると、
  `## Status` 配下の最初の空白でない行が正確に
  `Accepted — 2026-04-24` である。

- **AC-6 — ADR-003 EN ステータス行が唯一の変更:**
  `003-learning-mode-relocate-and-rename.md` の以前のコミット版との差分を調べると、
  ステータス行のみが変更されており、他の行は追加・削除・変更されていない。

- **AC-7 — ADR-003 JA ステータス行の正規化:**
  `.claude/meta/adr/003-learning-mode-relocate-and-rename.ja.md` を読んだとき、
  `## ステータス` セクションを検査すると、
  `## ステータス` 配下の最初の空白でない行が正確に
  `Accepted — 2026-04-24` (EN em-dash 形式、`採択済み。2026-04-24。` を置き換える) である。

- **AC-8 — ADR-003 JA ステータス行が唯一の変更:**
  `003-learning-mode-relocate-and-rename.ja.md` の以前のコミット版との差分を調べると、
  JA ステータス行のみが変更されており、他の行は追加・削除・変更されていない。

- **AC-9 — ADR-004 EN ステータス行の正規化:**
  `.claude/meta/adr/004-coaching-pillar.md` を読んだとき、
  `## Status` セクションを検査すると、
  `## Status` 配下の最初の空白でない行が正確に
  `Accepted — 2026-04-25` である。

- **AC-10 — ADR-004 EN ステータス行が唯一の変更:**
  `004-coaching-pillar.md` の以前のコミット版との差分を調べると、
  ステータス行のみが変更されており、他の行は追加・削除・変更されていない。

- **AC-11 — ADR-004 JA ステータス行の正規化:**
  `.claude/meta/adr/004-coaching-pillar.ja.md` を読んだとき、
  `## ステータス` セクションを検査すると、
  `## ステータス` 配下の最初の空白でない行が正確に
  `Accepted — 2026-04-25` (EN em-dash 形式、`採択済み。2026-04-25。` を置き換える) である。

- **AC-12 — ADR-004 JA ステータス行が唯一の変更:**
  `004-coaching-pillar.ja.md` の以前のコミット版との差分を調べると、
  JA ステータス行のみが変更されており、他の行は追加・削除・変更されていない。

- **AC-13 — ADR-001 と ADR-005 が変更されていない:**
  `.claude/meta/adr/` ディレクトリ全体の差分を調べると、
  `001-developer-growth-mode.md`、`001-developer-growth-mode.ja.md`、
  `005-template-restructure.md`、`005-template-restructure.ja.md` が
  変更ファイルとして現れない。

- **AC-14 — 他の ADR ファイル (ADR-006 から ADR-021) が変更されていない:**
  `.claude/meta/adr/` の差分を調べると、
  6 つの対象ファイル (ADR-002 EN + JA、ADR-003 EN + JA、ADR-004 EN + JA) のみが
  変更ファイルとして現れる。

- **AC-15 — CHANGELOG エントリの追加:**
  `CHANGELOG.md` を読んだとき、`## [Unreleased]` セクションを検査すると、
  ADR-002、ADR-003、ADR-004 のステータス行 (EN および JA) が em-dash テンプレート標準に
  正規化されたことを記録する新しいエントリが `### Documentation` (または適切な既存サブセクション)
  配下に含まれており、#16 ですでに完了した ADR-001 修正への参照が含まれている。

- **AC-16 — CHANGELOG の既存エントリが逐語的に保持されている:**
  `CHANGELOG.md` の差分を調べると、新しい CHANGELOG エントリ (AC-15) の行のみが追加されており、
  既存の CHANGELOG 行は削除・変更されていない。

- **AC-17 — 歴史的なナラティブが保持されている:**
  正規化後の 6 つの変更済み ADR ファイルそれぞれを読んだとき、
  本文テキスト、根拠、代替案、結果、Metadata、および blockquote がすべて逐語的に変更なく存在しており、
  単一のステータス行を除いて変更前バージョンと同一である。

## Key interactions

実装者は `.claude/meta/adr/` 内のちょうど 6 つのファイルを編集します:
`002-growth-domains-location.md` (line 5)、`002-growth-domains-location.ja.md`
(line 9)、`003-learning-mode-relocate-and-rename.md` (line 5)、
`003-learning-mode-relocate-and-rename.ja.md` (line 7、現在
`採択済み。2026-04-24。`)、`004-coaching-pillar.md` (line 5)、
`004-coaching-pillar.ja.md` (line 7、現在 `採択済み。2026-04-25。`)。

実装者はさらに `CHANGELOG.md` の `## [Unreleased]` 配下に 1 件のエントリを追加します。
エントリは追加のみです (既存の CHANGELOG テキストは変更しません)。他のファイルは変更されません。

technical-writer のステップが担当するのは: (a) `specs/17-changelog-adr-sync.ja.md`
(JA Spec sibling、見出しツリーパリティは #06 が所有) の作成、および (b) `specs/17-changelog-adr-sync.md` が
実際にディスク上のファイルになった現時点で、`specs/16-adr-001-status-resolution.md` (lines 48、200) と
`specs/16-adr-001-status-resolution.ja.md` (lines 25、146) に置かれた 4 件の
`<!-- ref-allow: Roadmap #17 reserved, not yet authored — intentional MECE-boundary forward-ref -->`
抑制が over-suppression になっているかどうかの判断と除去です。technical-writer は有効な解決済み参照を
over-suppression しているすべての ref-allow コメントを除去します。

新しい CI 検出器やテストスイートはこのマイルストーンには導入されません。
バックフィルは一度限りの機械的な修正であり、既存の 6 つの検出器
(`check-research-tier-auth`、`check-dangling-refs`、`check-roadmap-drift`、
`check-skill-invariants`、`check-bilingual-parity`、`check-ecc-delegation-consistency`)
と 7 つのテストスイートが正規化後の成果物を守るのに十分です。ADR ステータス形式の統一のための
将来の CI ゲートは別のマイルストーンおよび ADR です。

## Metrics

- **Leading:** 6 つの対象 ADR ファイルの差分が、`Accepted — YYYY-MM-DD` em-dash パターンに
  一致する正確に 1 行の変更をそれぞれ示している。
- **Leading:** CHANGELOG の差分が、既存行の削除・変更なしに新しい追加エントリのみを示している。
- **Lagging:** この修正が出荷された後、いかなる将来のツールもコントリビューターも ADR-002、
  ADR-003、ADR-004 のステータス行を非標準と報告しない。

## Risks and open questions

- **JA ローカライズトークンの選択:** #16 の §Risks 解決により、EN em-dash 形式
  (`Accepted — YYYY-MM-DD`) が支配的な JA ADR コーパスパターンであることが確認されました
  (20 件の JA ADR sibling のうち 17 件、`採択済み。` は 2 ファイルのみに現れており一貫していません)。
  この Spec は 3 つの JA 対象 (AC-7、AC-11) に確認された先例に基づいて EN em-dash 形式を
  必須とします。実装者は編集時に、#16 から現在までの間に異なるローカライズトークンを持つ新しい
  JA ADR sibling が追加されていないことを確認すべきです。コーパスが大幅に変わっていた場合は、
  コミット前にフラグを立てるべきです。
- **ref-allow の over-suppression:** `specs/17-changelog-adr-sync.md` が実際にディスク上の
  ファイルになった今、#16 の Spec ファイルにある 4 件の `ref-allow` 抑制
  (`specs/16-adr-001-status-resolution.md` の lines 48 と 200、および
  `specs/16-adr-001-status-resolution.ja.md` の lines 25 と 146) が有効な解決済み参照を
  over-suppression している可能性があります。technical-writer のステップがこの判断と除去を
  担当します (§Key interactions を参照)。
- **CHANGELOG エントリのカテゴリ:** CHANGELOG は `### Documentation` サブセクションを、
  コントリビューター向けの構造的変更 (ADR 追加、Spec 追加) に使用しています。
  ADR-002/003/004 のステータス正規化のための新しいエントリは `### Documentation` に適合します。
  実装時に既存の `## [Unreleased]` にすでに `### Documentation` ブロックがある場合、
  新しいエントリはそのブロックに追記され、重複サブセクションは作成されません。

## Out of scope

- ADR-001 のステータス変更 (#16 で完了、§Non-goals を参照)
- ADR-005 のステータス変更 (すでに準拠、§Non-goals を参照)
- ADR-006 から ADR-021 のステータス形式監査 (別の将来のマイルストーン)
- ADR ステータス形式の統一のための新しい CI ゲート (別の将来のマイルストーン)
- JA CHANGELOG sibling の作成
- ADR の本文テキスト、根拠、代替案、Metadata セクションへのいかなる変更

## References

- Roadmap 行: #17
- ADR-002: `.claude/meta/adr/002-growth-domains-location.md`
- ADR-003: `.claude/meta/adr/003-learning-mode-relocate-and-rename.md`
- ADR-004: `.claude/meta/adr/004-coaching-pillar.md`
- ADR-005: `.claude/meta/adr/005-template-restructure.md` (すでに準拠、変更なし)
- ADR テンプレート: `.claude/templates/adr-template.md` (ステータス語彙)
- Roadmap #16: `specs/16-adr-001-status-resolution.md` (ADR-001 ステータス修正 — 完了した前のマイルストーン、このマイルストーンの MECE 境界)
- CHANGELOG: `CHANGELOG.md`
