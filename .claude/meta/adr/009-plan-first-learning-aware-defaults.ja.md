# ADR-009: Plan-First かつ学習意識の高いデフォルト

## ステータス

Accepted — 2026-05-07

## 背景

`ecc-base-template` は GitHub テンプレートリポジトリであり、主たるユーザは
**学習者** — フォークして派生プロジェクトを作りつつ、Claude Code との高品質な
協働を実践する人 — である。既存 ADR は構造的成果物 (16-agent team, ADR/spec
テンプレート, Learning Mode, research verification) を積み上げてきたが、
**新規セッションのデフォルトの実行姿勢** は変えてこなかった。観察される
ギャップは 3 つ:

1. **実装前に計画を立てさせる構造的な圧力がない。** Claude Code 公式の Plan
   Mode は存在するが、テンプレートはデフォルト permission mode (allow-list
   ツールの auto-accept) で出荷されており、学習者がトグルを思い出す必要が
   ある。意思決定が実装中に発生してしまう。
2. **agent team は 16 件あるが、各 `description` は「そのエージェントは何か」
   を書いており、「いつ呼ぶか」が薄い。** 公式 sub-agents ドキュメントは
   `description` にトリガー条件を明記すべしと述べており、orchestrator の
   ルーティング精度に直結する。
3. **coaching context が手作業でアタッチされる。** Learning Mode 有効時、
   `coach.style` は `.claude/learn/config.json` にあるが、エージェントが
   気が向いたときに読みに行くだけ。すべてのプロンプトに現在の coaching
   context が必ず付随する保証はない。

research-critic による敵対的レビュー (Tier S、一次情報のみ) を
`code.claude.com/docs` に対して行ったところ、以下 4 つの一次プリミティブが
本番利用可能であることが確認できた (2026-05-07 検証):

- `settings.json` の `permissions.defaultMode: "plan"` — セッションを Plan
  Mode で起動。
- 組み込み Output Style **`Learning`** — `TODO(human)` マーカーを付与し、
  学習者に小さな断片を書かせる。
- `.claude/output-styles/*.md` のカスタム output style とそのフロントマター
  (`name`, `description`, `keep-coding-instructions`, `force-for-plugin`)。
- `UserPromptSubmit` Hook — `additionalContext` 注入と `decision: "block"`、
  Claude のプロンプト処理前に発火。

さらに `SubagentStop` Hook (ブロック可) と Skill 本文の `ultrathink`
キーワード (1 ターン分の Extended Thinking 強制) も確認済み。
**意図的に却下した** プリミティブが 1 つある:
`tools` フロントマターでの `Agent(<agent_type>, …)` 制限構文。Critic は
これが `claude --agent` で起動した main thread にのみ効き、`.claude/agents/`
配下の通常のサブエージェント定義では no-op であることを公式ドキュメントで
確認した。本 ADR では採用しない。

## 決定

このテンプレートからブートしたあらゆるセッションに対し、**plan-first かつ
学習意識の高いデフォルト姿勢** を採用する。具体的には:

1. **Plan Mode をデフォルト化。** `.claude/settings.json` に
   `"permissions": { "defaultMode": "plan" }` を追加し、書き込みやシェル
   副作用の前に計画の確認を学習者に求める。各セッションで Shift+Tab、または
   ローカル設定で opt-out 可。

2. **Output Style ガイダンス (opt-in、ただし発見可能性は確保)。**
   `.claude/output-styles/ecc-learn.md` をカスタム output style として同梱
   (組み込み `Learning` ベース)。CLAUDE.md と README にトレードオフを記述。
   グローバル強制は行わない (`keep-coding-instructions: false` は
   coding-specific system prompts を置換してしまい影響が大きすぎる)。
   選択は 1 行で済むようにする。

3. **agent `description` の規約を成文化する。** 実装前監査の結果、
   `.claude/agents/*.md` の 16 agent は既に公式 sub-agent docs が推奨する
   *"Use when …"* 形式に揃っていた。同一内容を書き換える代わりに、本 ADR
   では規約を **forward に固定** する: `claude-md-authoring` Skill
   (ADR-007) のチェック項目として追加し、今後の agent 編集および新規
   agent ファイルがすべて同じトリガーフレーズ規則で検証されるようにする。
   既存 agent ファイル本文への変更は本 ADR には含まれない。

4. **`UserPromptSubmit` Hook で coaching auto-context。** Learning Mode 有効
   時 (`learn/config.json: enabled: true`) のみ、フックスクリプトが
   `coach.style` を読み、対応する coaching preamble を `additionalContext`
   としてプロンプト毎に注入。「coaching style が本当にロードされたか?」の
   失敗モードを排除。スクリプト自身が条件付きで動作する — Learning Mode
   が無効、もしくはスタイルが `default` の場合は何も出力せず exit 0 する
   ので、opt-in しない派生プロジェクトは登録による実コストをゼロにできる。
   Hook 登録時に `matcher` フィールドを省略するのは、公式 hooks リファレンス
   が `UserPromptSubmit` で matcher を **サポートしない** (毎プロンプト
   発火、フィルタなし) と明記しているため。スクリプトのパスは CWD への
   依存を避けるため `$CLAUDE_PROJECT_DIR` 経由で解決する。スクリプトは
   ファイルを読む前に、設定された style 名を allow-list と realpath-containment
   チェックで厳格に検証するので、改竄された `learn/config.json` から
   無関係な `.md` ファイルをプロンプトにリークさせることはできない。

4 つのサブ決定は相互補強的なので一括で出荷する: Plan Mode が「考えずに
書く」コストを上げ、Learning output style が「読む」を「書く」に変え、
description 改善が計画の各ステップに正しいエージェントをルーティングし、
coaching hook が選択スタイルを常時アクティブに保つ。

## 結果

### ポジティブ

- 実装は意思の力ではなく **明示的な計画承認ステップ** でゲートされる。
  全体的に意思決定の質が上がる。
- `Learning` output style が「完成コードを読む」を「次の小さな断片を書く」
  に置き換え、テンプレートの学習目的と一致する。
- 新規ユーザにとって agent ルーティングが信頼できる: orchestrator は
  `description` だけで適切なスペシャリストを選べる。
- coaching style が「アドバイザリーなドキュメント」ではなくなり、Learning
  Mode 有効時はあらゆるプロンプトに構造的に付随する。

### ネガティブ

- Plan Mode が全セッションに確認ステップを追加する。瑣末な編集ではパワー
  ユーザが摩擦を感じる。緩和策: Shift+Tab で当該セッションは無効化、
  `.claude/settings.local.json` で個別開発者の上書き。
- カスタム output style と Plan Mode のデフォルト化はいずれも「最低限の
  インタラクション量」の床を上げる。学習者にとってはそれが目的だが、
  非学習用途で本テンプレを採用する経験者向けには README で opt-out 経路を
  明示する必要がある。
- 新しい `UserPromptSubmit` hook はプロンプト毎に (軽量だが) シェル呼び出し
  を 1 回追加する。スクリプトは保守的に: 実行時間に上限、ネットワーク禁止、
  エラー時は fail-open (誤動作するフックがユーザを止めない)。

### 中立

- 16 agent の書き換えは不要 (上記監査による)。規約は
  `claude-md-authoring` で forward に固定されるので、次に追加・編集される
  agent ファイルから機械的に検証される。
- 新 output style ファイルは opt-in なので、無視する派生プロジェクトには
  影響しない。

## 検討した代替案

| 代替案 | 利点 | 欠点 | 採用しなかった理由 |
|---|---|---|---|
| Plan Mode と Learning output style をグローバル強制 | 学習圧力が最大 | 非学習フォークが壊れる、README をスキップしたユーザに驚きを与える | デフォルトは*推奨*姿勢であるべきで、強制ではない |
| README で Plan Mode を案内するだけ、設定変更なし | 挙動変更ゼロ | ほとんどのユーザは Quick Start から先を読まない、構造的保証が消える | ドキュメント単独は歴史的に常に失敗モードだった |
| `Agent(<agent_type>)` フロントマターで orchestrator のスポーン先を固定 | 一見ルーティングがクリーン | Critic が一次情報で検証: サブエージェント定義では no-op (`--agent` main thread にのみ効く) — 偽の安心感 | 一次情報による証拠で却下 |
| coaching context を hook ではなく CLAUDE.md に埋め込む | 新ファイル/スクリプトなし | CLAUDE.md は Learning Mode 状態に関係なく毎プロンプトに適用され、coach style が増えると肥大する | hook が正しいスコープ: per-prompt、条件付き、削除可能 |

## 参考

- ADR-001 (Developer Growth/Learning Mode), ADR-004 (Coaching Pillar) —
  本 ADR が構造的に強制するレイヤ。
- ADR-007 (claude-md-authoring Skill) — 「Anthropic 公式 docs に対して
  書く前に検証する」という同じ哲学。
- ADR-008 (Research Verification Layer) — 本 ADR が依拠するプリミティブを
  検証した検証プロトコル。
- Anthropic 一次情報 (2026-05-07 検証, Tier S):
  `code.claude.com/docs/en/settings`, `/hooks`, `/output-styles`,
  `/sub-agents`, `/skills`。コードレビュー時に再検証:
  `permissions.defaultMode` は `"plan"` を有効値として受理する、
  `UserPromptSubmit` は `matcher` を無視する、hook command は
  `$CLAUDE_PROJECT_DIR` 経由で解決され相対パスはサポート明記がない、
  output-style フロントマターの `keep-coding-instructions` 既定値は
  `false`。
