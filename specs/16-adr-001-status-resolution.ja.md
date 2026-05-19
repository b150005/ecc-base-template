> このドキュメントは `specs/16-adr-001-status-resolution.md` の日本語訳です。英語版が原文 (Source of Truth) です。

# ADR-001 「Proposed (stabilized)」ステータス解決

## Status

Approved

**Owner:** product-manager
**Target release:** architect の決定後の次のパッチリリース

## Problem

ADR-001 (`001-developer-growth-mode.md`) のステータス行には `Proposed (stabilized). Supersedes earlier drafts...` という値が記載されています。この値は 2 つの点で非標準です。第一に、`Proposed (stabilized)` は `.claude/templates/adr-template.md` に定義された語彙の外にあります。テンプレートは `Proposed | Accepted | Deprecated | Superseded by ADR-NNN` の 4 値のみを許可しています。第二に、`Proposed` は現在の状態を誤って表しています: ADR-001 のアーキテクチャ上の決定は v1.1.0 で出荷され、v1.2.1 まで安定化されました (ADR-003 Consequences/Neutral に記録)。リポジトリ内の他のすべての ADR (ADR-002 から ADR-021) は `Accepted` を使用しています。`(stabilized)` の括弧書きは安定化に関する歴史的メモですが、認識されたステータストークンではありません。この不一致により、自動化された語彙チェックと人間によるレビューが困難になり、`Proposed` を額面通りに受け取った読者を誤解させます。このマイルストーンの対象は他のファイルに影響しません — ADR-001 の本文、根拠、代替案、および既存の部分的に置き換えられた blockquote はすべて正規のものとして保持され、スコープ外です。

## Goals

- ADR-001 のステータス行 (`001-developer-growth-mode.md`) を ADR テンプレートの語彙に準拠させる。
- JA sibling (`001-developer-growth-mode.ja.md`) の対応するステータス行を同じ準拠に揃え、EN の変更を行単位でミラーリングする。
- ADR-001 の完全な歴史的ナラティブを保持する: 本文、根拠、代替案、メタデータ、および既存の「Partially superseded by ADR-003」blockquote は変更なし。
- 訂正後のステータス行に記録された承認日は、ADR-001 自身のメタデータ (`Date: 2026-04-22`) に記録されたオーナー決定と一致しなければならない。

## Non-goals

- **CHANGELOG 同期** — CHANGELOG エントリを ADR 承認日に同期すること、または ADR-002 から ADR-005 の承認日メタデータをバックフィルすることは、Roadmap #17 (`specs/17-changelog-adr-sync.md`) のスコープです。<!-- ref-allow: Roadmap #17 reserved, not yet authored — intentional MECE-boundary forward-ref --> Roadmap #16 は CHANGELOG を変更しません。
- **リポジトリ全体の ADR ステータス形式の正規化** — ADR-002 から ADR-004 は `Accepted. YYYY-MM-DD.` (ピリオド区切り) を使用し、ADR-005 から ADR-021 は `Accepted — YYYY-MM-DD` (em-dash) を使用しています。この 2 フォーマットの不一致は ADR セット全体に存在しており、このマイルストーンのスコープ外です。ここで変更されるのは ADR-001 のステータス行のみです。
- **ADR 語彙の新しい CI 検出器** — すべての ADR に対して ADR テンプレートの語彙を強制する CI チェックの追加は、このマイルストーンの受け入れ基準を満たすために必要ではありません。アーキテクトが CI ガードを構造的決定として必要と判断した場合、新しい ADR がそれを導入することができますが、この Spec の受け入れ基準には含まれません。
- **ADR-001 本文の書き直し** — ADR-001 の v1.x パス参照、設計根拠、代替案、および「Partially superseded by ADR-003」blockquote は、ADR-003 Consequences/Neutral に従って意図的に保持された歴史的記録です。スコープ外です。
- **JA 見出しツリーパリティの強制** — `001-developer-growth-mode.ja.md` の見出しツリーと EN sibling のパリティは Roadmap #06 が所有します。このマイルストーンは JA ファイルのステータス行の内容のみを変更します。

## User stories

| As a...                            | I want to...                                                       | So that...                                                       |
|------------------------------------|--------------------------------------------------------------------|------------------------------------------------------------------|
| ADR-001 を読むコントリビューター   | 実際に出荷された状態と一致するステータスを確認する                 | 決定がまだオープンだと誤解しない                                 |
| ADR を解析するエージェントやツール | ADR-001 に標準語彙のステータストークンを見つける                   | 語彙チェックが ADR-001 で偽陽性を出さない                        |
| JA を管理する technical-writer     | 追加調査なしに JA sibling にステータス修正をミラーリングする       | バイリンガルパリティが二重推測なしに維持される                   |

## Acceptance criteria

- **AC-1 — EN ステータス行がテンプレート語彙に準拠している:**
  `.claude/meta/adr/001-developer-growth-mode.md` を読んだとき、
  `## Status` セクションを検査すると、
  `## Status` 配下の最初の空白でない行が
  `Accepted — 2026-04-22` (em-dash 形式、ADR-005 から ADR-021 のパターンに一致、日付は ADR-001 メタデータの `Date:` フィールドから) であり、
  `(stabilized)` などの括弧付き修飾子を含まない。

- **AC-2 — EN ステータス行が ADR-001 EN における唯一の変更である:**
  `001-developer-growth-mode.md` の以前のコミット版との差分を調べると、
  ステータス行 (現在のファイルの line 5) のみが変更されており、
  他の行は追加・削除・変更されていない。

- **AC-3 — JA sibling のステータス行がテンプレート語彙に準拠している:**
  `.claude/meta/adr/001-developer-growth-mode.ja.md` を読んだとき、
  `## ステータス` (または `## Status`) セクションを検査すると、
  その見出し配下の最初の空白でない行が JA 相当の標準トークン
  (`承認済み — 2026-04-22` またはリポジトリ内の他の JA ADR sibling で
  一貫して使用されている等価なローカライズ形式) であり、
  括弧付き修飾子を含まない。

- **AC-4 — JA sibling のステータス行が ADR-001 JA における唯一の変更である:**
  `001-developer-growth-mode.ja.md` の以前のコミット版との差分を調べると、
  JA ステータス行のみが変更されており、他の行は追加・削除・変更されていない。

- **AC-5 — 既存の blockquote が保持されている:**
  変更後の `.claude/meta/adr/001-developer-growth-mode.md` を読んだとき、
  「Partially superseded 2026-04-24 by ADR-003」blockquote
  (現在の lines 7-9) が逐語的に変更なく存在する。

- **AC-6 — 他の ADR ファイルは変更されていない:**
  `.claude/meta/adr/` ディレクトリ全体の差分を調べると、
  `001-developer-growth-mode.md` と
  `001-developer-growth-mode.ja.md` のみが変更ファイルとして現れる。

- **AC-7 — テンプレート語彙準拠:**
  `.claude/templates/adr-template.md` の ADR テンプレートを参照し、
  許可されたステータス値 (`Proposed | Accepted | Deprecated |
  Superseded by ADR-NNN`) を ADR-001 の新しいステータス行と比較すると、
  `Accepted` が先頭トークンとして存在し、テンプレート制約を満たしている。

## Key interactions

実装者が編集するファイルはちょうど 2 つです:
`001-developer-growth-mode.md` (line 5) と
`001-developer-growth-mode.ja.md` (対応するステータス行)。
アーキテクトは実装前に、この変更が新しい ADR を必要とするか、
ADR なしの直接修正として適用できるかを判断します。新しい ADR が作成される場合、
アーキテクトがそのリンクを Roadmap #16 行の `adr:` 列に追加します。
この Spec はその判断を規定しません。

ADR-001 の部分的に置き換えられた blockquote (lines 7-9) は変更なく保持されます。
ステータス修正は blockquote と競合しません。なぜなら blockquote は
ADR-001 自体の承認ステータスではなく、ADR-003 の置き換えスコープを説明しているためです。

## Metrics

- **Leading:** `001-developer-growth-mode.md` の差分が AC-1 のパターンに一致する
  ちょうど 1 行の変更を示す。
- **Lagging:** 修正がマージされた後、いかなるツールもコントリビューターも
  ADR-001 のステータスを非標準と報告しない。

## Risks and open questions

- **日付の選択:** ADR-001 メタデータには `Date: 2026-04-22` が記録されています。
  これはオーナー決定日であり、AC-1 の承認日として使用されます。
  アーキテクトのレビューで別の日付が適切と判断される場合 (例: 別のコンテキストで
  最後の安定化決定が記録された日)、アーキテクトはマージ前の実装コミットまたは
  新しい ADR に根拠を文書化すべきです。
- **JA ローカライズトークン:** JA の `Accepted` に相当するトークンは、
  編集時に実装者が他の JA ADR sibling を確認して検証すべきです。
  ローカライズされたステータストークンを使用する JA ADR sibling がまだ存在しない場合、
  将来の JA スタイル決定を待ちながら JA ファイルでも `Accepted — 2026-04-22` (EN)
  を使用して EN ファイルとの一貫性を維持できます。
  **解決:** アーキテクトが 3 つの収束する根拠に基づき JA ステータス行に
  `Accepted — 2026-04-22` (EN em-dash 形式) を確認しました:
  (1) 主要なコーパスパターン — 20 件の JA ADR sibling のうち 17 件
  (ADR-005.ja から ADR-021.ja) がすでに `Accepted — YYYY-MM-DD`
  (EN トークン、em-dash) を使用しています。ローカライズされた日本語トークン `採択済み。`
  は 2 件のファイル (ADR-003.ja と ADR-004.ja) のみに現れており一貫して使用されていないため、
  実際には「一貫して使用されているローカライズ相当形式」は存在しません;
  (2) 行単位 EN ミラーリング — EN line 5 が `Accepted — 2026-04-22` (AC-1) であり、
  JA の値をバイト同一にすることで ADR-018 に基づく EN/JA 構造パリティが最大化され、
  二重推測が排除されます; (3) Spec の承認 — AC-3 は「他の JA ADR sibling で一貫して
  使用されている等価なローカライズ形式」として EN 形式を明示的に許可しており、
  コーパスの証拠はそれが EN em-dash 形式であることを確認しています;
  `承認済み — 2026-04-22` を採用すると 4 番目のスタイル変種が追加されることになり、
  一貫したコーパスパターンに一致せず、リポジトリ全体の ADR ステータス正規化という
  Non-goal に反します。
- **新しい ADR が必要か:** アーキテクトが判断します。既存の ADR の単一ステータス行を
  変更することは機械的な訂正です。新しい構造的決定 ADR の閾値を満たさない可能性があります。
  この Spec はその選択について中立です。

## Out of scope

- CHANGELOG の更新 (Roadmap #17)
- ADR-002 から ADR-021 のステータス形式の正規化
- ADR ステータスフィールドの新しい CI 語彙ゲート
- ADR-001 本文、根拠、または代替案への変更

## References

- Roadmap 行: #16
- ADR-001: `.claude/meta/adr/001-developer-growth-mode.md`
- ADR-003: `.claude/meta/adr/003-learning-mode-relocate-and-rename.md` (部分的置き換えスコープ)
- ADR テンプレート: `.claude/templates/adr-template.md` (ステータス語彙)
- Roadmap #17: `specs/17-changelog-adr-sync.md` (CHANGELOG 同期 — #16 のスコープ外) <!-- ref-allow: Roadmap #17 reserved, not yet authored — intentional MECE-boundary forward-ref -->
