# ecc-base-template

Claude Code との高品質・高精度な協働を支える、フレームワーク非依存の GitHub
テンプレート。16 のエージェントによる開発チームと、オプトインの学習レイヤーを
標準装備しています。

[English README](README.md)

---

## 何が入っているか

- **専門化された 16 エージェント** が製品ライフサイクル全体をカバー
  — orchestrator、product-manager、architect、implementer、test-runner、
  code-reviewer、security-reviewer、performance-engineer、devops-engineer、
  technical-writer など。エコシステム非依存で、利用言語とフレームワークを
  ランタイムに検出します。
- **クリーンなルートディレクトリ。** フォーク後のリポジトリルートはあなたのもので、
  テンプレートが `docs/`、`scripts/`、`learn/`、ADR/spec の番号空間を予約しません。
- **ドキュメントテンプレート**が `.claude/templates/` にあり、英語ベースの `*.md` と
  日本語訳の `*.ja.md` を用意しています。プロジェクトが望む場所にコピーして使えます。
- **Developer Learning Mode**(デフォルト **オフ**)
  — 日常のコーディングセッションを、ドメイン別に整理されたパーソナル知識ベースへ
  変換するオプトインの学習レイヤー。5 つの名前付き決定論的コーチングスタイル
  (`hints` / `socratic` / `pair` / `review-only` / `silent`)に加え `default`
  (コーチング無し)を持つコーチング柱を含みます。

---

## クイックスタート

### 1. 自分のリポジトリを作る

GitHub で [b150005/ecc-base-template](https://github.com/b150005/ecc-base-template)
を開き、**Use this template** をクリック。

### 2. クローンして開く

```sh
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>
```

### 3. 初期化スクリプトを走らせる

```sh
.claude/meta/scripts/init.sh
```

プロジェクト名・1 行説明・技術スタックを聞かれます。`.claude/CLAUDE.md` の
`## About This Project` プレースホルダを置換し、`.env.example` を `.env` に
コピーします。再実行は安全です。

非対話モード:

```sh
.claude/meta/scripts/init.sh \
  --project-name "TaskFlow" \
  --description "チームのタスク管理 API" \
  --stack "Go / Gin / PostgreSQL"
```

### 4. 作業を始める

リポジトリルートで Claude Code を開き(`claude`)、orchestrator に具体的な
タスクを投げます。例:

> `POST /tasks` の REST エンドポイントを設計・実装してください。入力検証、
> PostgreSQL への永続化、作成リソースの返却を行ってください。TDD で進めます。

orchestrator が product-manager に受け入れ基準を、architect にモジュール
境界を、implementer にコードを、品質エージェント群にレビューを、それぞれ
委譲します。引き継ぎはあなたが舵を取ります。

### 5.(任意)Developer Learning Mode を有効化

```
/learn on [junior|mid|senior]     有効化(レベルを選択)
/learn off                        無効化
/learn status                     現在の状態を表示
/learn focus <domain>[,<domain>]  教育の焦点ドメインを設定
/learn coach <style>              コーチングスタイル設定 (hints|socratic|pair|review-only|silent|default)
/learn coach list                 利用可能なスタイル一覧
```

`/quiet` は連動 Skill で、1 ターンだけ Learning トレーラー(チャット末尾の付録)を
抑制します。ただし、知識ベースのファイル(`.claude/learn/knowledge/`)への書き込みは
通常通り続行されます。

完全な解説は
[.claude/meta/references/learning-mode-explained.ja.md](.claude/meta/references/learning-mode-explained.ja.md)
にあります。Learning Mode を使う予定がない場合は、ステップ 3 のあとに
`.claude/meta/` と `.github/workflows/learn-invariants.yml` を削除してください
— この機構はオプトインで、利用者が完全に外せるよう設計されています。

---

## 16 エージェントチーム

全エージェントはエコシステム非依存です。`.claude/CLAUDE.md` とプロジェクトの
マニフェストファイル(`package.json`、`pubspec.yaml`、`go.mod`、`Cargo.toml`
など)を読み、ランタイムに言語とフレームワークを検出します。orchestrator が
チームを統括し、各専門家は orchestrator 経由か直接呼び出しで動きます。

| エージェント | フェーズ | 役割 |
|-------------|---------|------|
| **orchestrator** | 全般 | 課題分析、計画立案、専門家への委譲、セッション統括 |
| **product-manager** | 企画 | 仕様書執筆、ユーザーストーリー、受け入れ基準、バックログ優先順位付け |
| **market-analyst** | 企画 | 市場調査、競合分析、ユーザーセグメント特定 |
| **monetization-strategist** | 企画 | ビジネスモデル設計、価格戦略、収益分析 |
| **ui-ux-designer** | 設計 | UI/UX デザイン、ユーザビリティレビュー、アクセシビリティ準拠 |
| **docs-researcher** | 調査 | 一次資料に対する API 検証、フレームワーク挙動、バージョン差分確認(research-verification の Generator) |
| **research-critic** | 調査 | 外部調査結果を primary source 限定で敵対的レビュー(research-verification の Critic) |
| **architect** | 設計 | システムアーキテクチャ、技術選定、ADR 作成 |
| **implementer** | 実装 | アーキテクチャと TDD に沿ったコード実装 |
| **code-reviewer** | 品質 | コード品質、保守性、規約準拠のレビュー |
| **test-runner** | 品質 | テスト実行、カバレッジ報告、TDD サポート |
| **linter** | 品質 | 静的解析とコードスタイル強制 |
| **security-reviewer** | 品質 | 脆弱性検出、シークレットスキャン、OWASP Top 10 |
| **performance-engineer** | 品質 | プロファイリング、ボトルネック特定、最適化 |
| **devops-engineer** | リリース | CI/CD、デプロイ戦略、リリース管理 |
| **technical-writer** | リリース | ドキュメンテーション、変更履歴、二言語ドキュメント保守 |

### モデル階層

各エージェントは frontmatter で Claude Code エイリアス(`opus` / `sonnet` /
`haiku` / `inherit`)を宣言し、各ファミリの最新バージョンに解決されます。
テンプレートはミックス編成です(単一モデルではなく、仕事に合うモデルを選ぶ)。
現状の割り当ては **Opus** が深い推論を要する判断系(architect、
security-reviewer、performance-engineer、monetization-strategist)、
**Sonnet** が一次出力エージェントの大半、**Haiku** が決定論的オラクルを
持つツールラッパー(linter、test-runner)、**inherit** が orchestrator。

最新のバージョン番号は
[Anthropic model overview](https://docs.claude.com/en/docs/about-claude/models/overview)
を参照してください。

---

## ディレクトリ構造(フォーク後)

```
your-repo/
├── README.md                  ← あなたのプロジェクトの README(置き換える)
├── README.ja.md               ← 任意の二言語 README
├── CHANGELOG.md               ← [Unreleased] から始まり、リリースごとに更新
├── LICENSE
├── .env.example               ← 環境変数のテンプレート
├── .env                       ← initializer が作成、コミット禁止
├── .gitignore
├── .gitignore.example
├── .gitattributes
├── .claude/                   ← Claude Code 機構
│   ├── CLAUDE.md              ← プロジェクト指示(About セクションを最初に編集)
│   ├── agents/                ← 16 エージェント定義
│   ├── skills/                ← /learn と /quiet
│   ├── templates/             ← コピー&記入用 ADR/spec テンプレート
│   ├── meta/                  ← テンプレ自身の ADR、参考資料、init スクリプト
│   ├── settings.json
│   └── settings.local.json    ← gitignored、利用者固有
├── .devcontainer/             ← VS Code Dev Containers 雛形
└── .github/                   ← CI、dependabot、Issue/PR テンプレート
```

ルート直下の可視ファイルはすべてあなたのものです。テンプレートが `docs/`、
`src/`、`scripts/` などの上位ディレクトリ名を予約することはありません。

### ADR や仕様書の置き場所

`.claude/templates/adr-template.md` を ADR を置きたい場所にコピーしてください。
よくある例:

- 単一言語: リポジトリ直下の `adr/001-use-postgresql.md`
- 二言語: `adr/en/001-use-postgresql.md` と `adr/ja/001-use-postgresql.md`
- docs 配下: 既存の `docs/` ツリーがあれば `docs/adr/001-use-postgresql.md`

`spec-template.md` も同じです。場所は強制しません。

### CLAUDE.md authoring Skill

`CLAUDE.md`、`README.md`、`.claude/agents/*.md` を短く、最新の Anthropic
ガイダンスに沿った構造で保つための Skill を同梱しています。

- `.claude/skills/claude-md-authoring/SKILL.md` — エントリポイント。
  Pre/Post チェックリストと Override Protocol を含む
- `.claude/skills/claude-md-authoring/invariants.md` — 4 つの不変則
  (`code.claude.com/docs/en/{memory,best-practices,skills}` で検証済)
- `.claude/skills/claude-md-authoring/docs-protocol.md` — 実行時検証
  チェーン (Context7 → URL → `llms.txt`)
- `.claude/skills/claude-md-authoring/examples.md` — 具体的な
  Bad/Good 例
- `.claude/meta/adr/007-claude-md-authoring-skill.ja.md` — 設計の根拠

Skill は **手動 invoke 専用** (`disable-model-invocation: true`) で、
明示的に呼ばない限り context コストはゼロです。コンテキストドキュメ
ントを新規作成・大幅に再構成するときに invoke してください。typo や
単一行追加など軽微な編集では呼び出し不要です。CI が Skill の構造的
不変条件を検証します (`.github/workflows/skill-invariants.yml`)。
Anthropic Docs の月次 freshness diff もオプションで提供 (default-off、
`.github/workflows/docs-freshness.yml`)。

### Research verification(外部調査の敵対的レビュー)

本テンプレートは `research-verification` Skill と新 agent
`research-critic` を提供し、外部調査結果が下流 agent に消費される前
に敵対的レビューを行います。確証エコー、二次情報ドリフト、API ハル
シネーションを「ビルド/テスト時」ではなく「調査ステップ」で捕まえ
る設計です。

- `.claude/skills/research-verification/SKILL.md` — protocol、Tier
  表、Pre/Post チェックリスト
- `.claude/skills/research-verification/checklist.md` — Critic
  チェックリスト 10 項目と primary source allowlist
- `.claude/skills/research-verification/failure-modes.md` — 典型的
  な調査誤りパターン 5 種
- `.claude/agents/research-critic.md` — Critic agent 定義
- `.claude/templates/research-review-template.md` — Generator と
  Critic が共有する出力フォーマット
- `.claude/research-verification.yml.example` — opt-out config
- `.claude/meta/adr/008-research-verification-layer.ja.md` — 設計の
  根拠

仕組み: `docs-researcher` (Generator) は外部調査出力ごとに Tier
(T1/T2/T3) を宣言します。T1 (破壊的変更、認証、セキュリティ)、T2
(API 引数、戻り値、版数別機能) は `research-critic` (Critic) が
レビュー — Generator とは異なるツールファミリを使い、Generator が
引いていない **primary source** を最低 1 つ引用する必要があります。
二次情報 (ブログ、Q&A サイト、AI 要約、primary source の翻訳) は
Critic の独立引用としては明示的に不可です。primary docs から遅れる
情報源を許せば、その遅れを捕まえる Critic の存在意義が消えるためで
す。GAN 反復は最大 2 周。合意に至らなければ orchestrator が
`SKILL.md` の escalation contract に従ってエスカレーションします。
T3 (スタイル、慣用) は Generator self-check のみで Critic は呼ば
れません。

opt-out するには `.claude/research-verification.yml.example` を
`.claude/research-verification.yml` にコピーし、`enabled: false` を
設定します。ファイルがなければデフォルトが適用されます
(`enabled: true`、`max_iterations: 2`、`default_tier: T2`)。
`enabled: false` 時は層全体が不活化され、agent は単一パス調査に戻り
ます。エラーは出ません。

### upstream Issue の追跡(default-off)

不具合の原因が自リポではなくサードパーティのライブラリやフレームワーク
にある場合、本テンプレートはそのライフサイクル(切り分け → 記録 → 追跡
→ upstream パッチ適用後の Workaround 削除)を提供します。

- `.claude/templates/workaround-template.md` — Workaround ごとに
  `workarounds/NNN-*.md`(`registry_dir` の既定値。`docs/` ツリーがあれ
  ば `docs/workarounds/NNN-*.md`)にコピー
- `.github/workflows/workaround-check.yml` — CI 足場 (config でゲート、
  外すべき `if: false` はなし)
- `.github/workaround-tracker.yml` — オプトイン設定
- `.claude/meta/adr/006-upstream-workaround-tracking.md` — 設計の全体像
- `.claude/meta/references/upstream-workaround-tracking.md` — 使い方詳細

「自リポ vs upstream」の 3 ステップ切り分けプロトコルは **orchestrator**
と **docs-researcher** が実行し、**implementer** がソースコード内に
`WORKAROUND-UPSTREAM(<owner>/<repo>#<issue>, fixed=>=<version>)` マー
カーを配置します。CI 足場はマーカーとレジストリの整合を比較し、追跡対
象パッケージを bump する Dependabot PR にコメントを付与します。

**有効化はシングルスイッチ**: `.github/workaround-tracker.yml` で
`enabled: true` にするだけです。ワークフロー側に外すべき第 2 のトグル
はなく、各ジョブが config を読んで無効時は短絡終了します。Workaround
ゼロのプロジェクトは CI ノイズもゼロです。

---

## テンプレート自身を保守する場合

**ecc-base-template**(このリポジトリ、フォーク先ではない)で作業する場合、
テンプレ自身の内部ドキュメントは `.claude/meta/` 配下にあります:

- `.claude/meta/adr/` — テンプレ自身のアーキテクチャ決定
- `.claude/meta/prd/` — テンプレ機能の PRD
- `.claude/meta/references/` — 長尺解説とワークドエグザンプル
- `.claude/meta/scripts/` — initializer と不変条件チェッカ
- `.claude/meta/CHANGELOG.md` — テンプレ自身のリリース履歴
- `.claude/meta/CHANGELOG.legacy.md` — v2.2.0 までの完全な履歴

CI は `.claude/meta/scripts/check-learn-invariants.sh` で Learning Mode の
不変条件を検証しており、`.github/workflows/learn-invariants.yml` から実行されます。

---

## ライセンス

[MIT](LICENSE)
