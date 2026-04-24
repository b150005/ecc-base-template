# ECC Base Template

> **v2.0.0 — 破壊的変更:** Developer Growth Mode は **Developer Learning Mode** に改名され、機能ディレクトリが `.claude/growth/` から `learn/` に移動しました。この機能を有効化しておりかつナレッジファイルをコミット済みの場合は、アップグレード前に移行ガイド [`docs/en/migration/v1-to-v2.md`](docs/en/migration/v1-to-v2.md) をご確認ください。

15 エージェントの開発チームと、**Developer Learning Mode** というオプトイン式の学習レイヤーを備えたフレームワーク非依存の GitHub テンプレートです。

[English README is here](README.md)

---

## このテンプレートが提供するもの

- **15 体の AI エージェント**: プロダクトライフサイクル全体を担当する。orchestrator、product-manager、architect、implementer、test-runner、code-reviewer、security-reviewer、performance-engineer、devops-engineer、technical-writer など。エコシステム非依存で、実行時にプロジェクトの言語とフレームワークを検出する。
- **Developer Learning Mode**（任意、デフォルト **OFF**）: 有効化すると、各エージェントが応答の末尾に 2 つのトレーラー節を追加し、判断の根拠を説明するとともに、`learn/knowledge/` 配下のドメイン別知識ベースを更新する。セッションを重ねるほど、知識ベースは実機能を実装することで築き上げた個人用のリファレンスに育つ。
- **CI 上の品質不変条件**: `scripts/check-learn-invariants.sh` が「デフォルト OFF 不変条件」を強制し、Learning Mode が本番成果物に滲み出さないことを保証する。

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

オーケストレーターに実際のタスクを与えます。スペシャリストはオーケストレーター経由でも直接でも呼び出せます。Learning Mode はあなたがオプトインするまで OFF のままです。

### 5.（任意）Learning Mode を有効化

```
/learn on [junior|mid|senior]       指定レベルで有効化
/learn off                          無効化
/learn status                       現在の状態を表示
/learn focus <domain>[,<domain>]    教示効果を特定ドメインに集中
/learn unfocus                      focus を解除
/learn level <junior|mid|senior>    有効/無効を切り替えずにレベルだけ変更
/learn domain new <key>             カスタムドメインを作成（要確認）
```

`/quiet` は、直後 1 回の応答の Learning Mode トレーラーだけを抑止するコンパニオン Skill です（ナレッジファイルは通常どおり更新されます）。

**レベル・知識ベース・設計思想の詳細および side-by-side 例**は [docs/ja/learning-mode-explained.md](docs/ja/learning-mode-explained.md) にあります。**正典の設計判断**は [ADR-001](docs/ja/adr/001-developer-growth-mode.md) を、**改名・移動の経緯**は [ADR-003](docs/ja/adr/003-learning-mode-relocate-and-rename.md) を参照してください。

---

## 15 エージェントのチーム

すべてのエージェントはエコシステムに依存しません。`.claude/CLAUDE.md` とプロジェクトのマニフェストファイル（`package.json`、`pubspec.yaml`、`go.mod`、`Cargo.toml` など）を読み込んで、実行時に言語とフレームワークを判別します。オーケストレーターがチーム全体を調整し、スペシャリストはオーケストレーター経由または開発者からの直接呼び出しで起動します。

| エージェント | フェーズ | 役割 | 主担当 Learning ドメイン |
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

各エージェントのドメイン担当は、プロンプト本文冒頭の `## Learning Domains` セクションで宣言しています。フロントマターではなく本文に宣言を置いている理由は [ADR-002](docs/ja/adr/002-growth-domains-location.md) を参照してください。副担当ドメインと完全な分類体系は [docs/ja/learn/domain-taxonomy.md](docs/ja/learn/domain-taxonomy.md) にあります。

### モデル選定

各エージェントは frontmatter で Claude Code のエイリアス（`opus` / `sonnet` / `haiku` / `inherit`）を用いてモデルを宣言しています。エイリアスは常にそのファミリの最新バージョンに解決されるため、Anthropic が新しいバージョンをリリースしても以下の割り当てはドリフトしません。各ファミリの現在のバージョン番号は [Anthropic のモデル一覧](https://docs.claude.com/en/docs/about-claude/models/overview) を参照してください。

テンプレートは単一フロアを採らず、**職務に応じた混成チーム**として出荷されます。基本則は「出力が直接消費される（権威ある散文、引用、翻訳など）エージェントは Sonnet / Opus、linter やテストランナーのように決定論的なツールをラップするエージェントは Haiku で十分（ツール自身の出力が正解として機能するため）」。

**Opus** — 下流への影響が最も大きい判断のための最深推論:
architect、security-reviewer、performance-engineer、monetization-strategist

**Sonnet** — 権威ある出力に対する既定。総合的なコーディングとライティングで最適:
product-manager、market-analyst、ui-ux-designer、docs-researcher、implementer、code-reviewer、devops-engineer、technical-writer

**Haiku** — 下流に決定論的オラクルを持つツールラップエージェント向けの軽量モデル:
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
│   │   ├── learn/SKILL.md                 # /learn トグル Skill
│   │   └── quiet/SKILL.md                 # /quiet トレーラー抑止 Skill
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
│   │   ├── learn/                         # Learning ドメイン分類体系とサンプル
│   │   ├── migration/                     # アップグレードガイド（例: v1-to-v2.md）
│   │   ├── learning-mode-explained.md     # Learning Mode のロングフォーム解説
│   │   └── (template-usage.md など)
│   └── ja/                                # 日本語訳（英語ソースへのリンクを冒頭に持つ）
├── learn/
│   ├── preamble.md                        # 同梱 — 拡充コントラクト
│   ├── config.json                        # 最初の /learn on で作成（gitignore）
│   └── knowledge/                         # 遅延生成 — 初回の教示瞬間にドメインごとに作成（gitignore）
├── scripts/
│   └── check-learn-invariants.sh          # デフォルト OFF 不変条件を強制する CI チェック
├── .env.example
├── .gitignore
├── .gitignore.example                     # ナレッジファイルを共有したい場合のオプトイン反転の例
├── LICENSE
├── README.md                              # 英語
└── README.ja.md                           # このファイル（日本語）
```

補足: `learn/preamble.md` はテンプレートに同梱されています。`learn/knowledge/` は遅延生成であり、ドメインごとにコンテンツが獲得された初回の教示瞬間に作成されます。実行時に作成されるのは `learn/config.json` のみで、最初の `/learn on` 呼び出し時に作られます。`config.json` と `learn/knowledge/` はいずれも既定で gitignore されており、個人の状態や私的な学習素材がコミットに紛れ込まないようになっています。共有したい場合のオプトイン手順は [learning-mode-explained.md の「ナレッジファイルはデフォルトで非公開」](docs/ja/learning-mode-explained.md#ナレッジファイルはデフォルトで非公開) を参照してください。

---

## テンプレート自体を育てる

重要な判断は `docs/en/adr/` の ADR として記録しています。現時点の ADR 一覧:

- [`000-template.md`](docs/ja/adr/000-template.md) — ADR のフォーマットテンプレート
- [`001-developer-growth-mode.md`](docs/ja/adr/001-developer-growth-mode.md) — Learning Mode の設計判断（旧名 Growth Mode; ADR-003 により一部更新）
- [`002-growth-domains-location.md`](docs/ja/adr/002-growth-domains-location.md) — Learning Domains をプロンプト本文に置く理由
- [`003-learning-mode-relocate-and-rename.md`](docs/ja/adr/003-learning-mode-relocate-and-rename.md) — Learning Mode への改名と `learn/` への移動

プロダクト要件は [`docs/ja/prd/`](docs/ja/prd/) にあります。Developer Learning Mode の PRD は本機能に関する正典の機能仕様です。

テンプレート自体に手を入れる場合も同じエージェントワークフローが適用されます。オーケストレーターが作業を調整し、アーキテクトが判断を ADR として記録し、implementer が PRD の受け入れ基準に対して実装を進めます。

---

## ライセンス

[MIT](LICENSE)
