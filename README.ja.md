# ecc-base-template

Claude Code との高品質・高精度な協働を支える、フレームワーク非依存の GitHub
テンプレート。15 のエージェントによる開発チームと、オプトインの学習レイヤーを
標準装備しています。

[English README](README.md)

---

## 何が入っているか

- **専門化された 15 エージェント** が製品ライフサイクル全体をカバー
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

## 15 エージェントチーム

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
| **docs-researcher** | 調査 | 一次資料に対する API 検証、フレームワーク挙動、バージョン差分確認 |
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
│   ├── agents/                ← 15 エージェント定義
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
