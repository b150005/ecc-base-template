# Roadmap セクションテンプレート

> 英語版: [roadmap-section.md](./roadmap-section.md)(原文・Source of Truth)

## このテンプレートの使い方

1. 下記の `---` 区切り線以降のセクションを `.claude/CLAUDE.md` の
   `## Development Workflow` の直前に貼り付けます。
2. 2 つのプレースホルダー行を、計画を始めた最初の実際のマイルストーンに
   置き換えます。
3. コミット前にこの「このテンプレートの使い方」ブロックを削除します。
4. 行番号は安定しており、再利用しません。`01` から始めて増分します。
   分割されたマイルストーンは新しい行と古い行へのメモになります。

**ルール:**
- 1 マイルストーン 1 行。行番号は安定し、再利用しない
  (ADR 番号の規約に準拠)。分割 = 新しい行 + 古い行へのメモ。
- `Design source` はタイプを明示する: `spec:` および/または `adr:` リンク。
- マイルストーン ↔ Spec は 1:1 かつ必須。マイルストーン → ADR は 0:1 または
  1:N (構造的決定が生じた場合のみ。ADR の `## References` は行番号への
  逆参照を持つ)。
- ステータス = 実装状態: ☐ todo / ◐ in-progress / ☑ done / ✗ dropped。
  dropped の行は残す (履歴を書き換えない)。
- インデックスのみ ── 受け入れ基準や根拠は重複させない。
  リンク先の Spec/ADR が Source of Truth。
- 書き込みオーナーシップ: `product-manager` が行と `spec:` リンクを
  作成/更新する。`architect` が `adr:` リンクを追加する。
  `orchestrator` は読むだけ。
- 100 以上のマイルストーンになった場合は `## Roadmap` 見出しの下に
  `### Phase N` のサブテーブルに分割する。

---

## Roadmap

Single entry point mapping each milestone to its authoritative design source. Each row is one milestone; the linked Spec/ADR is the source of truth for content — this table is an index only, never duplicating acceptance criteria or rationale.

| # | Milestone | Status | Design source |
|---|-----------|--------|---------------|
| 01 | [replace with one-line milestone description] | ☐ todo | spec: `specs/01-example.md` |
| 02 | [replace with one-line milestone description] | ☑ done | spec: `specs/02-example.md` + adr: `adr/002-example.md` |

> **These rows are placeholders.** Replace them with real milestones as you plan. Row numbers are stable and never reused.

**Rules:**
- One row per milestone; row number stable, never reused (follows ADR-number convention). A split = new row + note on old row.
- `Design source` names the type explicitly: `spec:` and/or `adr:` links.
- Milestone ↔ Spec is 1:1 mandatory; Milestone → ADR is 0:1 or 1:N (only when a structural decision occurred; the ADR's `## References` back-links the row number).
- Status = implementation state: ☐ todo / ◐ in-progress / ☑ done / ✗ dropped. Dropped rows stay (history not rewritten).
- Index only — never duplicate acceptance criteria or rationale; the linked Spec/ADR is the source of truth.
- Write-ownership: `product-manager` creates/updates the row + `spec:` link; `architect` adds the `adr:` link; `orchestrator` only reads.
- At 100+ milestones, split into `### Phase N` sub-tables under `## Roadmap`.
