# ecc-base-template

Claude Code との高品質・高精度な協働を支える、フレームワーク非依存の GitHub
テンプレート。18 のエージェントによる開発チームを標準装備しています。

[English README](README.md)

---

## 前提条件

このテンプレートは、ユーザーレベル (`~/.claude/`) に **ECC
(Everything Claude Code)** を導入済みの開発者を対象としています。
本テンプレートのエージェントは、実行時に ECC が提供するルールおよび
Skill を参照します。言語別レビュアー、フレームワーク固有のパターン、
共有の検証ワークフローはあなたの ECC インストール側に存在し、本リポジトリ
には含まれません。

ECC が無くてもテンプレートは起動しますが、エージェントの品質は低下します。
ルール参照は何も解決せず、Skill 呼び出しは no-op となり、言語別コード
レビュー経路 ([`code-reviewer`](.claude/agents/code-reviewer.md)
を参照) は汎用レビューにフォールバックし、verdict 内で明示します。

> **ECC をまだ導入していない場合は、**先にユーザーレベルでインストールして
> から、本テンプレートでプロジェクトリポジトリを作成してください。

---

## 提供物

- **18 の専門エージェント** で製品ライフサイクル全体をカバー — orchestrator、
  product-manager、architect、implementer、test-runner、code-reviewer、
  security-reviewer、performance-engineer、devops-engineer、technical-writer
  ほか。全エージェントはエコシステム非依存で、言語・フレームワークを実行時に
  検出します。
- **クリーンなルートディレクトリ。** fork 後はあなたがリポジトリルートを
  完全に所有します — テンプレートは `docs/`、`scripts/`、`learn/`、ADR/Spec
  番号などを予約しません。
- **ADR / プロダクト Spec 用ドキュメントテンプレート** が `.claude/templates/`
  に同梱。英語版 `*.md` と日本語版 `*.ja.md` の両方を提供します。プロジェクト
  の意思決定記録を置きたい場所にコピーして使用してください。
- **空の CI スカフォールド** (`.github/workflows/.gitkeep`) を保持。CI を
  追加する判断をした時のために枠は確保されています — [CI](#ci) セクションを
  参照。

---

## Forking について

本リポジトリは **2 ブランチモデル** を採用しています:

- **`main`** — fork ペイロード。「Use this template」で新しいリポジトリに
  コピーされる対象です: agent 定義、ドキュメントテンプレート、fork 向け設定、
  初期化スクリプトのみ。テンプレート内部成果物は含まれません。
- **`develop`** — テンプレート開発ブランチ。Spec、ADR、PRD、内部 CI
  ワークフロー、テンプレート自身の Roadmap を保持。**fork 向けではありません。**

fork (「Use this template」または `git clone`) すると `main` で作業を開始し、
fork ペイロードのみを受け取ります。テンプレート内部成果物を手動で削除する
必要はありません。

---

## クイックスタート

### 1. リポジトリを作成

GitHub で
[b150005/ecc-base-template](https://github.com/b150005/ecc-base-template)
を開き、**Use this template** をクリック。(`main` ブランチを使用 — それが
fork-clean のデフォルトです。)

### 2. クローンして開く

```sh
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>
```

### 3. 初期化スクリプトを実行

```sh
.claude/meta/scripts/init.sh
```

プロジェクト名、1 行説明、技術スタックを尋ねた後、`.claude/CLAUDE.md` の
`## About This Project` プレースホルダを置換し、`.env.example` を `.env`
にコピーします。テンプレート内部の `payload-manifest-check.yml`
ワークフローの削除も対話的に提案されます(デフォルトは残す。どちらでも
安全 — このワークフローは upstream テンプレートリポジトリでのみ動くよう
ガードされています)。再実行は安全です。

非対話形式:

```sh
.claude/meta/scripts/init.sh \
  --project-name "TaskFlow" \
  --description "Team task management API" \
  --stack "Go / Gin / PostgreSQL"
```

### 4. 作業開始

Claude Code を repo root で開き (`claude`)、orchestrator に具体的なタスク
を渡します。例:

> Design and implement a REST endpoint `POST /tasks` that validates input,
> persists to PostgreSQL, and returns the created resource. Use TDD.

orchestrator が product-manager (受け入れ基準) / architect (モジュール境界)
/ implementer (コード) / 品質エージェント (レビュー) に委任します — ハンド
オフはユーザーが舵を取ります。

---

## CI

本テンプレートは **`main` 上に fork 向け GitHub Actions ワークフローを
含めません** (設計上の意図的判断)。`.github/workflows/` フォルダは
`.gitkeep` で保持されており、ここに CI を追加できることを忘れないため
の仕組みです。

GitHub ワークフローは fork ごとの選択です — プロジェクトによって必要な
CI 構成は異なります (lint、test、coverage gate、security scan、依存更新
トリアージなど)。万人向けのセットを同梱して不要分を削除させる代わりに、
枠だけ空のまま提供し、`develop` ブランチの参考ワークフローを紹介します:

```sh
git remote add template https://github.com/b150005/ecc-base-template.git
git fetch template develop
git checkout template/develop -- .github/workflows/<workflow>.yml
```

プロジェクトに合うワークフロー (例: `ci-base.yml`、`security.yml`、
`coverage-gate.yml`、`workaround-check.yml`) を選ぶか、独自に作成してくだ
さい。

### `main` に同梱される唯一のワークフロー

`.github/workflows/payload-manifest-check.yml` は、上流テンプレートが
自身の `main` 宛 PR を `.claude/payload-manifest.txt` (develop 上に存在)
に対して gate するためのテンプレート内部 boundary-enforcement
ワークフローです。fork ではこの workflow は無害に動作します — `develop`
ブランチの checkout を試み、存在しない場合は静かに SUCCESS で skip
します。完全に空の `.github/workflows/` を望む fork はこの 1 ファイル
を `git rm` で削除して問題ありません。残したままにすれば、PR ごとに
no-op success が報告されるだけです。

---

## 18 のエージェントチーム

全エージェントはエコシステム非依存。`.claude/CLAUDE.md` とプロジェクトの
マニフェストファイル (`package.json`、`pubspec.yaml`、`go.mod`、
`Cargo.toml` など) を実行時に読み、言語・フレームワークを検出します。
orchestrator がチームを調整し、専門エージェントは orchestrator または
直接的に呼び出されます。

| Agent | フェーズ | 役割 |
|-------|---------|------|
| **orchestrator** | 全般 | 課題分析、計画立案、専門家への委任 |
| **product-manager** | 計画 | Spec 起草、ユーザーストーリー、受け入れ基準 |
| **market-analyst** | 計画 | 市場調査、競合分析 |
| **monetization-strategist** | 計画 | ビジネスモデル、価格戦略、収益分析 |
| **ui-ux-designer** | 設計 | UI/UX 設計、ユーザビリティレビュー、アクセシビリティ |
| **docs-researcher** | 調査 | API 検証、フレームワーク挙動の primary docs 照合 |
| **research-critic** | 調査 | 調査出力の対立的レビュー (primary-source-only) |
| **adversarial-implementer** | 構築 | 並列実装 Critic (opt-in) |
| **architecture-critic** | 設計 | ADR への対案 Critic (opt-in) |
| **architect** | 設計 | システムアーキテクチャ、技術判断、ADR 作成 |
| **implementer** | 構築 | アーキテクチャ仕様と TDD に従う実装 |
| **code-reviewer** | 品質 | コード品質、保守性、規約遵守 |
| **test-runner** | 品質 | テスト実行、カバレッジ報告、TDD 支援 |
| **linter** | 品質 | 静的解析、コードスタイル強制 |
| **security-reviewer** | 品質 | 脆弱性検出、シークレット走査、OWASP Top 10 |
| **performance-engineer** | 品質 | プロファイリング、ボトルネック特定、最適化 |
| **devops-engineer** | リリース | CI/CD、デプロイ戦略、リリース管理 |
| **technical-writer** | リリース | ドキュメント、CHANGELOG、バイリンガル文書 |

### モデルティア

各 agent は frontmatter で Claude Code エイリアス (`opus` / `sonnet` /
`haiku` / `inherit`) を宣言。最新版に解決されます。テンプレートは混成
編成 — 一律ではなく仕事に合うモデルを選定。

現在のバージョン番号は
[Anthropic model overview](https://docs.claude.com/en/docs/about-claude/models/overview)
を参照。

---

## fork 後のプロジェクト構造

```
your-repo/
├── README.md                  ← プロジェクトの README に置換
├── README.ja.md               ← バイリンガル README (任意)
├── CHANGELOG.md               ← [Unreleased] から開始
├── LICENSE
├── .env.example
├── .gitignore                ← Learning Mode の opt-in 反転をインラインで文書化 (ADR-027 参照)
├── .gitattributes
├── .claude/
│   ├── CLAUDE.md              ← プロジェクト指示 (About セクションをまず編集)
│   ├── agents/                ← 18 個の agent 定義ファイル
│   ├── templates/             ← コピーして使う ADR / Spec テンプレート
│   ├── meta/scripts/init.sh   ← 対話型初期化スクリプト
│   └── settings.json          ← Claude Code 設定
└── .github/
    ├── workflows/.gitkeep     ← 設計上空 — CI はここに追加
    ├── CODEOWNERS
    ├── ISSUE_TEMPLATE/
    ├── PULL_REQUEST_TEMPLATE.md
    └── dependabot.yml
```

すべての可視ルートファイルはあなたが所有します。テンプレートは `docs/`、
`src/`、`scripts/` などのトップディレクトリ名を予約しません。

### 独自の ADR / Spec の配置

`.claude/templates/adr-template.md` をコピーして、ADR を置きたい場所に
配置します。よくある選択肢:

- `adr/001-use-postgresql.md` (repo root 直下)
- `adr/en/001-use-postgresql.md` + `adr/ja/001-use-postgresql.md`
  (バイリンガルプロジェクト)
- `docs/adr/001-use-postgresql.md` (既に `docs/` ツリーがあれば)

`spec-template.md` も同様。場所の強制はありません。

---

## テンプレート本体への貢献

このセクションは **ecc-base-template 本体** で作業する人向けで、fork
ユーザー向けではありません。

- Issue と PR は `develop` ブランチに対して開いてください。
- `main` はテンプレート maintainer が維持する payload-only ブランチで、
  直接 PR は受け付けません。
- `develop → main` のマージは develop 上の `payload-manifest-check` CI
  でゲートされ、fork payload のクリーン性を担保します。

テンプレート開発基盤一式 (Spec、ADR、内部 CI ワークフロー、Roadmap
index) は `develop` 上にあります。テンプレート自身の設計と保守を確認
するには `develop` ブランチを参照してください。

---

## ライセンス

[MIT](LICENSE)
