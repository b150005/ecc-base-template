# ADR-007: CLAUDE.md authoring Skill — 不変則インライン + 変動則の実行時 Docs 検証ハイブリッド

> 英語版: [007-claude-md-authoring-skill.md](./007-claude-md-authoring-skill.md)(原文・Source of Truth)

## ステータス

Accepted — 2026-05-06

## 背景

本テンプレートが提供する 8 体の特化 agent は、プロジェクトコンテキスト
ドキュメント — `CLAUDE.md`、`README.md`、`.claude/agents/*.md` — を日常的に
作成・編集します。Anthropic の公式ガイドは Claude Code のリリースごとに進
化していますが、ecc-base-template の adopter には、自分たちの執筆を最新の
Anthropic 推奨に合わせる仕組みが組み込まれていません。これにより 2 つの失
敗モードが生じます。

1. **肥大化**: チェックリストがないと agent はコードから推論可能な事実
   (ファイルパス、フレームワーク名) を文章化し、200 行ガードを見過ごし
   ます。結果として `CLAUDE.md` は context トークンを消費するが Claude
   に何の情報も与えない状態になります。
2. **ドリフト**: Anthropic のガイダンスは変化します — ドメイン移転
   (`docs.anthropic.com` → `code.claude.com`)、新 frontmatter フィールド、
   閾値の改訂など。agent prompt に焼き付けた静的チェックリストは静かに
   陳腐化します。

素朴な 2 つの設計はいずれも失敗します:

- **全文インライン Skill**: 決定論性は最大だが、書いた日付で Anthropic
  ガイダンスが凍結される。数ヶ月で Skill が現行 Docs と矛盾し、adopter は
  どちらを信じるべきか判断できなくなる。
- **全部実行時 fetch**: 常に最新だが、authoring セッションごとに Context7
  / WebFetch のレイテンシとトークンを同じ事実のために支払う。さらに Docs
  が到達不能 (404、ネットワーク障害、ミラー drift) になると authoring が
  停止する。

agent team レビューで合意された方針は **ハイブリッド**: 構造的に不変なルー
ルはインライン化し、変動値は graceful degradation を伴う規約化された手順
で実行時取得する。

## 決定

`.claude/skills/claude-md-authoring/` に Skill を新設し、内容を不変則 / 変
動則の軸で分割し、Anthropic 公式の skill authoring パターン (Progressive
Disclosure) を用いてエントリポイントを小さく保ちつつ詳細レファレンスをオ
ンデマンドで利用可能にします。

### 原則

1. **構造的不変則はインライン化**: hierarchy の存在、root vs subdir の
   compaction survival 差、code-is-not-prose、`@path` import 構文の存在 —
   この 4 項目は Anthropic が Claude Code のメモリモデル自体を再設計しな
   い限り無効化できません。これらは Skill の契約です。
2. **変動値は実行時プロトコルに委譲**: 数値閾値 (200 行ガード、再帰深度
   5)、UI 表面 (`#` ショートカット、`/memory`)、バージョン依存の
   frontmatter 挙動 (`disable-model-invocation` の意味論) は、規約化され
   た Context7 → URL → `llms.txt` チェーンで参照します。
3. **Graceful degradation**: 上記 3 経路すべてが失敗しても、Skill は **失
   敗しません**。インラインされた不変則のみで agent は作業を継続し、変動
   セクションが今回のセッションでは検証できなかった旨をユーザーに伝えま
   す。
4. **Progressive Disclosure** (Anthropic 推奨パターン): Skill ディレクト
   リは `SKILL.md` (エントリポイント、約 200 行) と `invariants.md`、
   `docs-protocol.md`、`examples.md` をオンデマンド読み込みで構成。
   adopter が Skill を読むときに 4 ファイル全てを同時に見ることはなく、
   agent は現在のタスクが必要とするものだけを読み込みます。
5. **手動 invoke のみ**: frontmatter で `disable-model-invocation: true`
   を宣言。Skill はリファレンス資料であり、model が自動 invoke すべき振る
   舞いではありません。これにより、明示的に invoke されない限り context
   コストはゼロになります (検証済み Anthropic ガイダンス —
   "context cost to zero for skills you only trigger yourself")。
6. **Override Protocol**: adopter は自身の `CLAUDE.md` で個別の不変則を
   opt-out できますが、明示的かつ日付付きの宣言が必須です。Invariant
   Core 自体の構造は adopter が再定義できません。
7. **英語専用**: `.claude/meta/references/upstream-workaround-tracking.md`
   や `.claude/meta/references/domain-taxonomy.md` と同じ規約。読者層は英
   語の upstream コンテンツを既に直接読むエンジニア / agent。

### 不変 / 変動の分類

分類は `docs-researcher` の鮮度監査から導出し、2026-05-06 に 2 経路
(Context7 MCP + URL 直 fetch) で検証済みです。

| 項目 | 分類 | 理由 |
|---|---|---|
| 階層 (global / project / subdir) | 不変 | メモリモデルを再設計しないと撤廃不可。Anthropic は新規場所を追加するだけで撤廃したことがない。 |
| root vs subdir の compaction survival 差 | 不変 | 階層が存在する構造的理由そのもの。撤廃すれば階層を持つ意味がなくなる。 |
| code-is-not-prose 原則 | 不変 | Anthropic が公式に表明する `CLAUDE.md` の用途哲学。数値の調整値ではない。 |
| `@path` import 構文の存在 | 不変 | 撤廃は世界中の既存 CLAUDE.md に対する破壊的変更。 |
| 200 行 CLAUDE.md 閾値 | 変動 | 数値であり、モデルや context 窓の改善で動きうる。 |
| `@path` 再帰深度 (5) | 変動 | 数値の調整値。 |
| `#` ショートカットと `/memory` UI | 変動 | UI 表面は最も再設計されやすい。 |
| `disable-model-invocation` の正確な効果 | 変動 | frontmatter の意味論は拡張されうる。"context cost zero" は最近のリリースで追加された。 |

### ファイルサイズ予算 (検証済みガイダンス)

`SKILL.md` の目標は約 200 行、上限は Anthropic 推奨の **500 行**
(`code.claude.com/docs/en/skills` で 2026-05-06 検証)。CLAUDE.md の 200 行
ガードは Skill ファイルには **適用されません** — これは CLAUDE.md 固有の
推奨で、同じソースで検証済みです。詳細レファレンスは sibling `.md` ファイ
ルに置き、オンデマンドでのみロードされます。

### 提供成果物

| パス | 役割 |
|---|---|
| `.claude/skills/claude-md-authoring/SKILL.md` | エントリポイント、約 200 行、Pre/Post チェックリスト、Override Protocol、ナビゲーション |
| `.claude/skills/claude-md-authoring/invariants.md` | 4 不変則の本文、引用、再検証プロトコル |
| `.claude/skills/claude-md-authoring/docs-protocol.md` | Context7 → URL → `llms.txt` 実行時検証チェーンと fallback 意味論 |
| `.claude/skills/claude-md-authoring/examples.md` | 各不変則の実適用を示す Bad/Good 抜粋 |
| `.claude/meta/scripts/check-skill-invariants.sh` | Skill の構造的不変条件 (行数上限、frontmatter フィールド、相互参照解決) を強制する CI スクリプト |
| `.github/workflows/skill-invariants.yml` | default-on。Skill 変更時に上記スクリプトを実行するワークフロー |
| `.github/workflows/docs-freshness.yml` | default-off、月次。`code.claude.com/docs/llms.txt` の前回との diff をサマリで通知するワークフロー |
| `.github/docs-freshness.yml` | freshness ワークフローの設定 (`enabled: false` 既定) |

### Grandfather された Skill

既存の `learn` Skill (ADR-001 / ADR-003 / ADR-004) は本契約より先に
存在し、現在 721 行で 500 行上限を上回っています。これを Progressive
Disclosure 形式に再構成することは ADR-007 のスコープ外です — それは
Learning Mode の設計に踏み込む別意思決定になります。
`check-skill-invariants.sh` は明示的な allowlist で
`.claude/skills/learn/SKILL.md` を除外します。新規 skill は除外され
ません。`learn` を後日再構成する際は、同じ変更で allowlist エントリ
も削除してください。

### 範囲外 (意図的に)

- README 専用の 2 つ目の Skill (構造ルールは同じため、本 Skill が
  `README.md` も対象とする)。
- code-derivable content を自動検出する linter。判断ベースの不変則であり
  CI で強制できない。
- Anthropic Docs との双方向同期 (そのための API は存在しない)。
- `llms.txt` diff からの Skill 自動更新。人手レビューを残す。

## 帰結

### ポジティブ

- adopter は初日から動作する CLAUDE.md authoring 契約を得る。Anthropic の
  Docs を先に読まなくてよい。
- Anthropic ガイダンスが進化しても Skill は有用であり続ける。不変則は安定、
  変動値はオンデマンド参照、規約化された復旧経路 (`llms.txt`) がドメイン
  移転を吸収する。
- Progressive Disclosure により Skill は 500 行上限を超えない。詳細は
  invoke 時のみロードされる sibling ファイルに置く。
- `disable-model-invocation: true` により、明示的に invoke されないセッ
  ションでは context コストはゼロ。authoring 活動のないセッションでは
  adopter は何も支払わない。

### ネガティブ

- Skill を一度も読まない adopter は影響を受けない。Skill は設計上 opt-in
  (手動 invoke) であり、authoring 中に invoke することを知らない adopter
  はチェックを受けない。緩和策: 関連する agent 定義
  (`technical-writer`、`docs-researcher`、`architect`、`implementer`、
  `code-reviewer`、`devops-engineer`、`orchestrator`) から本 Skill を
  参照する。
- 実行時検証プロトコルは Context7 MCP の設定に依存する。Context7 のない
  adopter は URL 直 fetch にフォールスルーする。動作はするが遅い。
- Skill の検証日付は定期的なリフレッシュが必要。`docs-freshness.yml` ワー
  クフローを有効化していないと日付が静かに drift する。

### 中立

- Skill は英語専用。日本語 authoring ガイドが必要なチームは自前の docs
  で書くこと。Skill の英文がリファレンスドキュメントとなる。
- Skill は `CLAUDE.md` 自体を置き換えない。これは「`CLAUDE.md` の書き方」
  を扱うメタ文書であり、プロジェクトは依然としてプロジェクト固有のコンテ
  キストを記述した自身の `CLAUDE.md` が必要。

## 検討した代替案

| 代替案 | 利点 | 欠点 | 採用しなかった理由 |
|---|---|---|---|
| 全文インライン Skill (実行時 fetch なし) | 最大の決定論性、失敗しない | 書いた時点で Anthropic ガイダンスを凍結。静かに陳腐化 | Claude Code リリースサイクルでの drift が支配的な失敗モード |
| 全実行時 fetch (インライン規則なし) | 常に最新 | Docs 到達不能で authoring 停止。安定部分のトークンを毎セッション再 fetch | 4 不変則は十分に安定しておりインラインで足りる。安定部分への実行時コストは純粋な無駄 |
| 単一ファイル SKILL.md (Progressive Disclosure なし) | 構造が単純 | 総コンテンツが 500 行上限を超える。検索性が下がる | Anthropic はリファレンス詳細を持つ skill には Progressive Disclosure を明示推奨 |
| ADR-006 の特殊ケースとして扱う (Anthropic-as-upstream) | 既存の workaround 機構を再利用 | ADR-006 は semver 管理された依存を追跡する。Anthropic Docs は semver 管理されておらず、marker/registry 契約が適合しない | 独立 ADR で両者の契約を清潔に保つ |
| SKILL.md にも 200 行上限 | CLAUDE.md と対称 | Anthropic は SKILL.md には 500 行を推奨。200 行上限は不自然な圧縮を強い、Skill 品質を損なう | 検証済み Anthropic ガイダンス: 200 は CLAUDE.md 固有、500 が SKILL.md の推奨 |

## 参照

- ADR-005 — テンプレ内部 vs 採用者層の分離。本 ADR は同じ分割原則に従う。
- ADR-006 — upstream workaround tracking。本 ADR はその sibling
  (Anthropic Docs を別カテゴリの upstream として扱う。ただし semver 追跡
  ができないため別契約が必要)。
- `https://code.claude.com/docs/en/skills` — Skill 構造、500 行推奨、
  Progressive Disclosure パターン。2026-05-06 検証。
- `https://code.claude.com/docs/en/memory` — CLAUDE.md 階層、imports、
  200 行推奨。2026-05-06 検証。
- `https://code.claude.com/docs/en/best-practices` — code-is-not-prose
  ガイダンス。2026-05-06 検証。
- `https://code.claude.com/docs/en/features-overview` — Skill ロード意味
  論 ("full content when used"、`disable-model-invocation` →
  "context cost to zero")。2026-05-06 検証。
- 2026-05-06 council 協議 — architect、docs-researcher、technical-writer、
  devops-engineer、code-reviewer が初版提案をレビューし、行数上限とトリガー
  設計の問題を顕在化。findings は §決定 と §検討した代替案 に統合済み。
