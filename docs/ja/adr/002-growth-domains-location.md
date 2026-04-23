# ADR-002: `growth_domains` を sub-agent フロントマターから外す

> English source: [docs/en/adr/002-growth-domains-location.md](../../en/adr/002-growth-domains-location.md)

## Status

Accepted. 2026-04-23.

## Metadata

- 日付: 2026-04-23
- 決定者: エージェントチーム（architect が主導、docs-researcher がスキーマ検証）
- 置き換え対象: [ADR-001](001-developer-growth-mode.md) が導入した `growth_domains:` フロントマター宣言パターン
- 関連: [ADR-001](001-developer-growth-mode.md)、[docs/ja/growth/domain-taxonomy.md](../growth/domain-taxonomy.md)、[scripts/check-growth-invariants.sh](../../../scripts/check-growth-invariants.sh)

## Context

ADR-001 では、15 エージェントの各定義ファイル（`.claude/agents/*.md`）に対し、以下のようなカスタムフロントマターキーで Growth Mode ドメインの担当を宣言する方針を採用していた。

```yaml
---
name: implementer
description: ...
model: sonnet
growth_domains:
  primary: [error-handling, concurrency-and-async, ecosystem-fluency, implementation-patterns]
  secondary: [architecture, api-design, data-modeling, ...]
---
```

v1.1.1 の仕様整合性レビューにおいて、Claude Code 公式の sub-agent フロントマタースキーマを `docs.claude.com`（Context7 MCP 経由）で検証した。公式スキーマは `name` / `description` / `tools` / `model` に**閉じている**。`growth_domains:` はスキーマ上サポートされているキーではない。

このパターンが現状動作している理由は 1 点のみ — LLM がエージェントファイル全体（自身のフロントマターを含む）をテキストとして読み、プロンプト本文に「`as listed in the frontmatter above` のように自然言語でフロントマターを参照する」ガード文が書かれているためである。LLM はフロントマターブロックを「可読なコンテキスト」として処理しており、Claude Code ランタイムが構造化データとして扱っているわけではない。

これは 2 つのリスクを生む。

1. **Silent regression**: 将来 Anthropic が閉じたスキーマを強制し、プロンプト組み立て前に未知のキーを除去する変更を入れた場合、ガード分岐は動作するがドメインリストが参照できず、教育的貢献が静かに劣化する。
2. **Hard failure**: より厳格な強制モードでは、ファイル読み込み自体が拒否される可能性があり、Growth 対応エージェントすべてがロード失敗となり得る。静かな劣化ではないが、その変更がリリースされた瞬間に全 fork でテンプレートが壊れる。

`scripts/check-growth-invariants.sh` のガード分岐チェックは、現状 `growth_domains:` という文字列の存在を「Growth 対応エージェントである」というマーカーとして grep しているに過ぎず、フロントマターのパースには依存していない。テキスト上の存在に依存している。

本 ADR は、いずれかの退行モードが fork に到達する前に、非公式フロントマター意味論への依存を除去する判断を記録する。

## Decision

各エージェントの Growth Mode ドメイン宣言を、フロントマターキーから、**フロントマター直後・エージェントプロンプト本文の冒頭にある専用の `## Growth Domains` セクション**へ移動する。

正典シェイプ:

```markdown
---
name: implementer
description: ...
model: sonnet
---

## Growth Domains

- Primary: error-handling, concurrency-and-async, ecosystem-fluency, implementation-patterns
- Secondary: architecture, api-design, data-modeling, persistence-strategy, testing-discipline, review-taste, security-mindset, performance-intuition, operational-awareness

# Implementer Agent
...
```

すべての Growth 対応エージェントが完全に同一のシェイプを持つ。`Primary` / `Secondary` の 2 階層は `.claude/growth/preamble.md` の拡充プロトコルが 2 階層を前提にしているため維持する（主担当を「第一責任ゾーン」、副担当を「相互参照領域」として扱う）。フラットリストへの潰し込みは意味論を失うため採らない。

`scripts/check-growth-invariants.sh` のガード分岐アンカーは `growth_domains:` の grep から `## Growth Domains` の grep へ変更する。デフォルト OFF 不変条件は維持される — 依然として (a) Skill の `disable-model-invocation: true`、(b) 各エージェントプロンプト内の `.claude/growth/config.json` 参照、(c) gitignore 体制の 3 つに依存する。変わるのはマーカー文字列のみである。

`.claude/growth/preamble.md` の表記を「`growth_domains` フロントマターで宣言された」から「`## Growth Domains` セクションで宣言された」へ更新する。

v1.1.1 で README に追加した `growth_domains:` に関する「実装上の注記」段落は、新しい宣言場所を反映する内容に更新する（Issue #3 で README 再構成する場合は、その際にさらに整形 or 削除する）。

## Alternatives Considered

| 代替案 | 長所 | 短所 | 採用可否 |
|---|---|---|---|
| **A. プロンプト本文のインラインセクション**（採用） | エージェントと同じ場所に置ける／セッション開始時の I/O 追加ゼロ／invariant スクリプトのアンカー再設定が自明／スキーマに準拠する | ドメイン一覧が専用 CI なしには機械的に監査しづらい | 採用。同じ実行時コストで最高のレジリエンス。 |
| **B. 集約マニフェストファイル**（`.claude/growth/agent-domains.yaml`） | 監査用に単一ビューがある／分類体系と CI で照合可能／フロントマター依存なし | Growth 対応エージェントが毎セッション開始時にマニフェストを読む必要がある（I/O 増）／「エージェント ↔ マニフェスト」の新しい drift モードが発生／ドメイン一覧がエージェント定義から離れる | 15 エージェントが単一ディレクトリに並んでおり CI でスキャン可能な現状、マニフェストの I/O コストは正当化できない。 |
| **C. 現状維持**（`growth_domains:` フロントマター + README の注意書き） | 移行コストゼロ／現在動作している | 未文書化のスキーマ寛容さに機能を賭けている／Anthropic がスキーマを強制した場合、silent regression が最も起こりやすい故障モード | 採用しない。同コストで Alt A のほうがレジリエンスで厳密に優位。 |

A/B/C それぞれを 6 つの評価軸（保守性、LLM 読み込みコスト、invariant 強制、Single Source of Truth、退行リスク、分類体系の drift 耐性）で 1〜5 で採点した比較表を判断過程で実施している。Alt A が 28 点、Alt B と C が 21 点で並ぶ。

## Consequences

### Positive

- **スキーマ準拠**: 未文書化のフロントマターキーに依存しない。Anthropic が厳格に閉じてもテンプレートはそのまま動作する。
- **I/O 追加ゼロ**: ドメインリストはすでにエージェントプロンプト本文にある。LLM は毎回上から下まで読んでいるため、新しいファイル読み込みは発生しない。
- **認知コストが下がる**: 新しい貢献者がエージェントファイルを読むとき、YAML の中ではなく散文の中にドメイン宣言が見える。
- **Invariant の強制は維持される**: CI チェックはリテラルマーカーの grep を継続する（`growth_domains:` から `## Growth Domains` へ変更）。既存 3 チェックはすべて有効なまま。

### Negative

- **1 回限りの移行コスト**: 15 エージェントファイルすべてを単一コミットで編集する。invariant スクリプトも同じコミットで更新する。両方のマーカーを受け付ける移行期間は設けず、アトミックに切り替える。
- **機械可読な構造体ではない**: ドメインリストは Markdown であって YAML ではない。将来「各ドメイン名が `docs/en/growth/domain-taxonomy.md` に存在する」ことを検証する CI を追加する場合、新しい regex またはパーサが必要となる。これは別 issue へ繰り延べる。

### Neutral

- **README の注意書き段落**: v1.1.1 で追加した「`growth_domains:` はテンプレート固有のフロントマター慣例」旨の段落は、移行中に新しい宣言場所の説明に書き換える。Issue #3（README 再構成）の進行状況次第でさらに整形または削除される可能性がある。
- **ADR-001 の参照**: ADR-001 内の「`growth_domains:` フロントマターキーとして」記述している箇所は、本 ADR と新しい宣言場所を指す文言に更新する。ADR-001 のアーキテクチャ的本質は不変。
- **日本語訳**: 本ファイル `docs/ja/adr/002-growth-domains-location.md` は英語版と同時に作成される同期翻訳。

## Implementation Notes

### 移行範囲（単一コミット）

1. `.claude/agents/*.md` の 15 ファイルから `growth_domains:` フロントマターキーを除去し、フロントマター直後に `## Growth Domains` セクションを追加する。2 行のラベル付きリスト（Primary / Secondary）で正典シェイプに従う。
2. `scripts/check-growth-invariants.sh` のチェック 2 をアンカーし直す。既存の `grep -Eq '^growth_domains:'` を `grep -Eq '^## Growth Domains$'` に変更する。「そのようなエージェントがすべて `.claude/growth/config.json` を参照する」というガード分岐チェックは不変。
3. `.claude/growth/preamble.md` の表記を更新: 「`growth_domains` フロントマター」への参照は「エージェントプロンプト本文冒頭の Growth Domains セクション」に変える。プロトコルの意味論は変更しない。
4. 各エージェントの "Developer Growth Mode contract" 節のクロスリファレンスを「as listed in the frontmatter above」から「as listed in the Growth Domains section above」に変更する。
5. `README.md` / `README.ja.md` の注意書き段落を、新しい宣言場所を反映する内容に更新する（または Issue #3 が先行して再構成する場合はそちらに合わせる）。
6. 同じコミットで `docs/ja/adr/002-growth-domains-location.md` を翻訳として作成する。

### Curator フラグ

`technical-writer.md` は現状 `growth_domains:` と並んで `curator: true` をフロントマターで宣言している。これはクロスドメイン整理（重複ノートの統合、安定した節の正典ドメインアンカーへの昇格など）を担うエージェントであることを示すフラグである。このフラグは同じ `## Growth Domains` セクションに 3 番目のラベル付き行として移行する:

```markdown
## Growth Domains

- Primary: documentation-craft
- Secondary: (none)
- Curator: true
```

クロスドメインの整理操作を行うエージェントだけが `Curator` 行を持つ。既定は「行が存在しない」であり、存在すればそのエージェントは主担当／副担当リストに限定されず、整理目的で任意のドメインファイルを編集できる。`.claude/growth/preamble.md` は同じセクション内でこの行を探すように更新する。

### ADR-002 のスコープ外

- 列挙された各ドメイン名が `docs/en/growth/domain-taxonomy.md` に存在するかを検査する CI の追加。有用だが分離可能。v1.2.x フォローアップとして追跡する。
- 分類体系そのものや、`preamble.md` の primary/secondary 意味論に対する構造的変更。これらは ADR-001 の支配下にある。
- エージェントの実行時挙動の変更。本移行は散文のみの変更である。
