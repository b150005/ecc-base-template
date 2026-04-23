# ECC Base Template

15 エージェントの開発チームと、**Developer Growth Mode** というオプトイン式の学習レイヤーを備えたフレームワーク非依存の GitHub テンプレートです。

[English README is here](README.md)

---

## このテンプレートが提供するもの

- **15 体の AI エージェント**: プロダクトライフサイクル全体を担当する。orchestrator、product-manager、architect、implementer、test-runner、code-reviewer、security-reviewer、performance-engineer、devops-engineer、technical-writer など。エコシステム非依存で、実行時にプロジェクトの言語とフレームワークを検出する。
- **Developer Growth Mode**（任意、デフォルト **OFF**）: 有効化すると、各エージェントが応答の末尾に 2 つのトレーラー節を追加し、判断の根拠を説明するとともに、`.claude/growth/notes/` 配下のドメイン別知識ベースを更新する。セッションを重ねるほど、ノートブックは実機能を実装することで築き上げた個人用のリファレンスに育つ。
- **CI 上の品質不変条件**: `scripts/check-growth-invariants.sh` が「デフォルト OFF 不変条件」を強制し、Growth Mode が本番成果物に滲み出さないことを保証する。

---

## クイックスタート

### 1. テンプレートからリポジトリを作成

GitHub で [b150005/ecc-base-template](https://github.com/b150005/ecc-base-template) を開き、**Use this template** をクリックします。

### 2. クローンして開く

```sh
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>
```

リポジトリのルートで `claude` を実行し、Claude Code で開きます。

### 3. `.claude/CLAUDE.md` をカスタマイズ

`.claude/CLAUDE.md` は各セッションでエージェントが読み込むプロジェクト指示ファイルです。`## About This Project` のプレースホルダをプロジェクト固有のコンテキストに置き換えてください。残りの節（エージェント表、ワークフロー、テスト要件、ドキュメント規約）はそのまま引き継げる設計です。

### 4. 作業を始める

オーケストレーターに実際のタスクを与えます。スペシャリストはオーケストレーター経由でも直接でも呼び出せます。Growth Mode はあなたがオプトインするまで OFF のままです。

### 5.（任意）Growth Mode を有効化

```
/growth on [junior|mid|senior]       指定レベルで有効化
/growth off                          無効化
/growth status                       現在の状態を表示
/growth focus <domain>[,<domain>]    教示効果を特定ドメインに集中
/growth unfocus                      focus を解除
/growth level <junior|mid|senior>    有効/無効を切り替えずにレベルだけ変更
/growth domain new <key>             カスタムドメインを作成（要確認）
```

`/quiet` は、直後 1 回の応答の Growth トレーラーだけを抑止するコンパニオン Skill です（ノートは通常どおり更新されます）。

**レベル・ノートブック・設計思想の詳細および side-by-side 例**は [docs/ja/growth-mode-explained.md](docs/ja/growth-mode-explained.md) にあります。**正典の設計判断**は [ADR-001](docs/ja/adr/001-developer-growth-mode.md) を参照してください。

---

## 15 エージェントのチーム

すべてのエージェントはエコシステムに依存しません。`.claude/CLAUDE.md` とプロジェクトのマニフェストファイル（`package.json`、`pubspec.yaml`、`go.mod`、`Cargo.toml` など）を読み込んで、実行時に言語とフレームワークを判別します。オーケストレーターがチーム全体を調整し、スペシャリストはオーケストレーター経由または開発者からの直接呼び出しで起動します。

| エージェント | フェーズ | 役割 | 主担当 Growth ドメイン |
|-------------|---------|------|----------------|
| **orchestrator** | 全体 | Issue を分析し、作業を計画し、スペシャリストに委任し、セッション全体を調整する | release-and-deployment |
| **product-manager** | 企画 | PRD の作成、ユーザーストーリー、受け入れ基準、バックログの優先順位づけ | api-design |
| **market-analyst** | 企画 | 市場調査、競合分析、ユーザーセグメントの特定 | market-reasoning |
| **monetization-strategist** | 企画 | ビジネスモデルの設計、価格戦略、収益分析 | business-modeling |
| **ui-ux-designer** | 設計 | UI/UX の設計、ユーザビリティレビュー、アクセシビリティ適合 | ui-ux-craft |
| **docs-researcher** | 調査 | 一次ドキュメントに対する API の挙動、フレームワークの挙動、バージョン固有の変更の検証 | ecosystem-fluency |
| **architect** | 設計 | システムアーキテクチャ、技術選定、ADR の作成 | architecture, api-design, data-modeling |
| **implementer** | 実装 | アーキテクチャ仕様と TDD にもとづくコード実装 | ecosystem-fluency, error-handling, concurrency-and-async, implementation-patterns |
| **code-reviewer** | 品質 | コード品質、保守性、規約適合性のレビュー | review-taste, testing-discipline, implementation-patterns, security-mindset |
| **test-runner** | 品質 | テストの実行、カバレッジの報告、TDD のサポート | testing-discipline, performance-intuition |
| **linter** | 品質 | 静的解析とコードスタイルの強制 | implementation-patterns |
| **security-reviewer** | 品質 | 脆弱性検出、シークレットスキャン、OWASP Top 10 | security-mindset |
| **performance-engineer** | 品質 | プロファイリング、ボトルネック特定、最適化 | performance-intuition, concurrency-and-async |
| **devops-engineer** | リリース | CI/CD、デプロイ戦略、リリース管理 | operational-awareness, release-and-deployment |
| **technical-writer** | リリース | ドキュメント、CHANGELOG、バイリンガルドキュメントの管理 | documentation-craft |

各エージェントのドメイン担当は、プロンプト本文冒頭の `## Growth Domains` セクションで宣言しています。フロントマターではなく本文に宣言を置いている理由は [ADR-002](docs/ja/adr/002-growth-domains-location.md) を参照してください。副担当ドメインと完全な分類体系は [docs/ja/growth/domain-taxonomy.md](docs/ja/growth/domain-taxonomy.md) にあります。

### モデル選定

各エージェントは frontmatter でモデルを宣言しています。テンプレートは単一フロアを採らず、**職務に応じた混成チーム**として出荷されます。基本則は「出力が直接消費される（権威ある散文、引用、翻訳など）エージェントは Sonnet / Opus、linter やテストランナーのように決定論的なツールをラップするエージェントは Haiku で十分（ツール自身の出力が正解として機能するため）」。

**Opus 4.5** — 下流への影響が最も大きい判断のための最深推論:
architect、security-reviewer、performance-engineer、monetization-strategist

**Sonnet 4.6** — 権威ある出力に対する既定。総合的なコーディングとライティングで最適:
product-manager、market-analyst、ui-ux-designer、docs-researcher、implementer、code-reviewer、devops-engineer、technical-writer

**Haiku 4.5** — 下流に決定論的オラクルを持つツールラップエージェント向けの軽量モデル:
linter、test-runner

**Inherit** — 呼び出し側セッションのモデルを継承:
orchestrator

---

## プロジェクト構造

```
.
├── .claude/
│   ├── CLAUDE.md                          # エージェントが読み込むプロジェクト指示
│   ├── agents/                            # 15 エージェントの定義ファイル
│   ├── skills/
│   │   ├── growth/SKILL.md                # /growth トグル Skill
│   │   └── quiet/SKILL.md                 # /quiet トレーラー抑止 Skill
│   ├── growth/                            # Growth Mode の実行時ファイル + 同梱アセット
│   │   ├── preamble.md                    # 同梱 — 拡充コントラクト
│   │   ├── notes/                         # 同梱 — 19 の seed 済ドメインファイル（gitignore）
│   │   └── config.json                    # 最初の /growth on で作成（gitignore）
│   ├── settings.json
│   └── settings.local.json
├── .devcontainer/
│   └── devcontainer.json                  # コメント付きテンプレート。フレームワークに応じて調整する
├── .github/
│   ├── CODEOWNERS
│   ├── ISSUE_TEMPLATE/
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── dependabot.yml
│   └── workflows/                         # CI: lint/test/build とセキュリティスキャン
├── docs/
│   ├── en/                                # 英語の Source of Truth
│   │   ├── adr/                           # アーキテクチャ判断
│   │   ├── prd/                           # プロダクト要件
│   │   ├── growth/                        # Growth ドメイン分類体系
│   │   ├── growth-mode-explained.md       # Growth Mode のロングフォーム解説
│   │   └── (template-usage.md など)
│   └── ja/                                # 日本語訳（英語ソースへのリンクを冒頭に持つ）
├── scripts/
│   └── check-growth-invariants.sh         # デフォルト OFF 不変条件を強制する CI チェック
├── .env.example
├── .gitignore
├── .gitignore.example                     # ノートを共有したい場合のオプトイン反転の例
├── LICENSE
├── README.md                              # 英語
└── README.ja.md                           # このファイル（日本語）
```

補足: `.claude/growth/preamble.md` と `.claude/growth/notes/` 配下の 19 の seed 済ノートはテンプレートに同梱されています。実行時に作成されるのは `config.json` のみで、最初の `/growth on` 呼び出し時に作られます。`config.json` と `notes/` はいずれも既定で gitignore されており、個人の状態や私的な学習素材がコミットに紛れ込まないようになっています。共有したい場合のオプトイン手順は [growth-mode-explained.md の「ノートはデフォルトで非公開」](docs/ja/growth-mode-explained.md#ノートはデフォルトで非公開) を参照してください。

---

## テンプレート自体を育てる

重要な判断は `docs/en/adr/` の ADR として記録しています。現時点の ADR 一覧:

- [`000-template.md`](docs/ja/adr/000-template.md) — ADR のフォーマットテンプレート
- [`001-developer-growth-mode.md`](docs/ja/adr/001-developer-growth-mode.md) — Growth Mode の設計判断
- [`002-growth-domains-location.md`](docs/ja/adr/002-growth-domains-location.md) — Growth Domains をプロンプト本文に置く理由

プロダクト要件は [`docs/ja/prd/`](docs/ja/prd/) にあります。Developer Growth Mode の PRD は本機能に関する正典の機能仕様です。

テンプレート自体に手を入れる場合も同じエージェントワークフローが適用されます。オーケストレーターが作業を調整し、アーキテクトが判断を ADR として記録し、implementer が PRD の受け入れ基準に対して実装を進めます。

---

## ライセンス

[MIT](LICENSE)
