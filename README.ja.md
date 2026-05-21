# ecc-base-template

Claude Code との高品質・高精度な協働を支える、フレームワーク非依存の
GitHub テンプレート。14 のエージェントによる開発チームを標準装備して
います。

[English README](README.md)

---

## 前提条件

このテンプレートは、**ECC (Everything Claude Code)** をユーザーレベル
(`~/.claude/`) に既にインストール済みの開発者を想定して設計されています。
本テンプレートのエージェントは、ECC 提供のルールや Skill を実行時に参照
します — 言語別レビュアー、フレームワーク別パターン、共通の検証ワーク
フローは、本リポジトリではなくお手元の ECC インストールに置かれます。

ECC なしでもテンプレートは動作しますが、エージェント品質は劣化します:
ルール参照は何もないところを指し、Skill 呼び出しは no-op になり、
言語特化のコードレビュー経路 (
[`code-reviewer`](.claude/agents/code-reviewer.md) を参照) は汎用レビュー
にフォールバックし、判定にもそう明記します。

> **ECC をお持ちでないですか?** まずユーザーレベルに ECC をインストール
> してから、このテンプレートを使ってご自身のリポジトリを作成してください。

---

## 提供物

- **14 個の専門エージェント** が製品ライフサイクル全体を担当します —
  orchestrator、product-manager、architect、implementer、test-runner、
  code-reviewer、security-reviewer、performance-engineer、
  devops-engineer、technical-writer など。すべてエコシステム非依存:
  エージェントは実行時に言語とフレームワークを検出します。
- **Plan Mode デフォルト。** 新しいセッションは Plan Mode で起動します
  (`.claude/settings.json` の `permissions.defaultMode: "plan"` 設定) —
  Claude はまずプランを提示し、書き込みやシェル実行の前に明示的な承認を
  待ちます。
- **クリーンなルートディレクトリ。** fork 後はリポジトリのルートはあなた
  のものです — テンプレートは `docs/`、`scripts/`、ADR/spec 番号などを
  予約しません。
- **ドキュメントテンプレート** が `.claude/templates/` に配置されています。
  ADR と製品 Spec の英語版 `*.md` と日本語版 `*.ja.md` の両方を用意。
  プロジェクトの決定記録をどこに置きたいかに応じて、自由にコピーして
  ください。
- **空の CI スカフォールド** (`.github/workflows/.gitkeep`) があり、
  CI を追加する準備が整っています。

---

## クイックスタート

### 1. リポジトリの作成

GitHub で
[b150005/ecc-base-template](https://github.com/b150005/ecc-base-template)
を開き、**Use this template** をクリック。

### 2. クローンして開く

```sh
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>
```

### 3. 初期化スクリプトを実行

```sh
.claude/init.sh
```

プロジェクト名、概要、技術スタックを質問形式で受け取り、
`.claude/CLAUDE.md` の `## About This Project` プレースホルダーを置換し、
`.env.example` を `.env` にコピーします。再実行も安全です。

非対話形式:

```sh
.claude/init.sh \
  --project-name "TaskFlow" \
  --description "Team task management API" \
  --stack "Go / Gin / PostgreSQL"
```

### 4. 作業を開始

リポジトリのルートで Claude Code (`claude`) を開き、orchestrator に実
タスクを渡してください。例:

> POST /tasks REST エンドポイントを設計して実装してください。入力の
> バリデーション、PostgreSQL への永続化、作成済みリソースの返却を
> 行う形で。TDD で。

orchestrator が product-manager に受け入れ基準、architect にモジュール
境界、implementer にコード、品質エージェントにレビューを委譲します —
ハンドオフはあなたが舵を取ります。

---

## 14 のエージェントチーム

すべてのエージェントはエコシステム非依存です。`.claude/CLAUDE.md` と
プロジェクトのマニフェストファイル (`package.json`、`pubspec.yaml`、
`go.mod`、`Cargo.toml` 等) を実行時に読んで、プロジェクトの言語と
フレームワークを検出します。orchestrator がチームを統率し、専門
エージェントは orchestrator または直接呼び出されます。

| Agent | Phase | Role |
|-------|-------|------|
| **orchestrator** | All | Issue 解析、計画立案、専門エージェントへの委譲 |
| **product-manager** | Planning | Spec 作成、ユーザーストーリー、受け入れ基準 |
| **market-analyst** | Planning | 市場調査、競合分析 |
| **monetization-strategist** | Planning | ビジネスモデル、価格戦略、収益分析 |
| **ui-ux-designer** | Design | UI/UX 設計、ユーザビリティレビュー、アクセシビリティ |
| **architect** | Design | システムアーキテクチャ、技術選定、ADR 作成 |
| **implementer** | Build | アーキテクチャ仕様と TDD に従ったコード実装 |
| **code-reviewer** | Quality | コード品質、保守性、規約準拠 |
| **test-runner** | Quality | テスト実行、カバレッジ報告、TDD 支援 |
| **linter** | Quality | 静的解析、コードスタイル強制 |
| **security-reviewer** | Quality | 脆弱性検出、シークレットスキャン、OWASP Top 10 |
| **performance-engineer** | Quality | プロファイリング、ボトルネック特定、最適化 |
| **devops-engineer** | Release | CI/CD、デプロイ戦略、リリース管理 |
| **technical-writer** | Release | ドキュメント、changelog、バイリンガル文書 |

### モデル階層

各エージェントは frontmatter でモデルエイリアス (`opus` / `sonnet` /
`haiku` / `inherit`) を宣言し、Claude Code が各ファミリの最新バージョン
に解決します。テンプレートはミックス艦隊を採用しています — 単一の下限
ではなく、ジョブごとに適切なモデルを選ぶ方針です。

現在のバージョン番号は
[Anthropic モデル概要](https://docs.claude.com/en/docs/about-claude/models/overview)
を参照してください。

---

## fork 後のプロジェクト構造

```
your-repo/
├── README.md                  ← プロジェクトの README (これを置き換えてください)
├── README.ja.md               ← オプションのバイリンガル README
├── CHANGELOG.md               ← [Unreleased] からスタート、リリースで成長
├── LICENSE
├── .env.example
├── .gitignore
├── .gitattributes
├── .claude/
│   ├── CLAUDE.md              ← プロジェクト指示 (About セクションを最初に編集)
│   ├── agents/                ← 14 個のエージェント定義
│   ├── templates/             ← コピーして埋める ADR/spec テンプレート
│   ├── init.sh                ← 対話型初期化スクリプト
│   └── settings.json          ← Claude Code 設定 (Plan Mode デフォルト)
└── .github/
    ├── workflows/.gitkeep     ← 設計上空 — ここに自前の CI を追加
    ├── CODEOWNERS
    ├── ISSUE_TEMPLATE/
    ├── PULL_REQUEST_TEMPLATE.md
    └── dependabot.yml
```

ルート直下の可視ファイルはすべてあなたのものです。テンプレートは
`docs/`、`src/`、`scripts/` などのトップレベルディレクトリ名を予約
しません。

### 独自の ADR と Spec を配置する

`.claude/templates/adr-template.md` を ADR を置きたい場所にコピーして
ください。よくある選択肢:

- リポジトリルートに `adr/001-use-postgresql.md`
- バイリンガルプロジェクトなら `adr/en/001-use-postgresql.md` + `adr/ja/001-use-postgresql.md`
- 既に `docs/` ツリーがあるなら `docs/adr/001-use-postgresql.md`

`spec-template.md` も同様です。配置場所は強制されません。

### CI

`.github/workflows/` は空 (`.gitkeep` のみ) で出荷されます。CI は
fork ごとの選択 — プロジェクトごとに必要な CI スカフォールド (lint、
test、coverage、セキュリティスキャン、依存バンプの triage) は異なる
ためです。必要に応じて、スタックに合わせて自分で書いてください。

---

## テンプレート本体への貢献

このセクションは **ecc-base-template 本体** に取り組む人向けで、
fork 利用者向けではありません。Issue と PR は `main` ブランチに対して
作成してください。

---

## ライセンス

[MIT](LICENSE)
