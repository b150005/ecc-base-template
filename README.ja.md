# ECC Base Template

15エージェントの開発チームと、Developer Growth Mode というオプトイン式の学習レイヤーを備えたフレームワーク非依存のリポジトリテンプレートです。

[English README is here](README.md)

---

## このテンプレートが存在する理由

このテンプレートは、自分のプロジェクトに必要だったから作ったものです。新しいリポジトリを始めるたびに、オーケストレーター、アーキテクト、実装者、テストランナー、コードレビュアーといったエージェントチームを、構造化されたワークフローと合わせてゼロから組み直していました。このテンプレートは、その作業を一度だけ行った結果です。他の方にとっても役立つとすれば、それは公開したことによる自然な副次効果であって、設計上の目標ではありません。

背景にある考え方はシンプルです。エージェントが作業を担い、Developer Growth Mode を有効化することで、開発者はエージェントとともに実機能を実装しながら専門知識を深めていきます。エージェントは講師ではなく、このテンプレートも講座ではありません。成長は、判断の根拠を説明してくれるエージェントと一緒に本物の作業を進めることの副産物として、自然と立ち上がってきます。

---

## Developer Growth Mode

Developer Growth Mode はこのテンプレートの中核機能で、15 エージェントのチームの上に乗るオプトイン方式のアノテーション層です。オフ（これが既定）のときには、エージェントはこの機能が存在しない場合とまったく同じ出力を生成します。「おおむね同じ」ではなく、実質的な内容についてはバイト単位で同一です。オンにすると、タスクを完了した各エージェントが、宣言された経験レベルに合わせた 2 つのトレーラー節を応答の末尾に付け加えます。

2 つの節はそれぞれ `## Growth: taught this session` と `## Growth: notebook diff` です。前者は、その応答で何を伝えたか（判断の根拠、トレードオフ、検討した代替案とそれが選ばれなかった理由、その推論がプロジェクトの ADR や信頼できる外部ドキュメントのどこに裏づけられているか）を記録します。後者は、知識ベースに対して行った保守操作を記録します。`.claude/growth/notes/` 配下のどのドメインファイルに手を入れたか、そのファイルのどの節か、どの種類の操作を適用したか（追加／深化／洗練／修正／新規ドメイン）を示します。ノートは「引用」するのであって、「説教」はしません。ノートの深さは、恣意的な予算ではなく、説明すべき概念そのものによって決まります。基礎的なパターンについての junior レベルの説明は、第一原理から足場を組み上げるため数段落になることもあります。senior レベルのトレードオフに関するメモは、判断が求めるのが 1 段落であれば、それで十分です。文字数の上限は設けません。トークン予算も、ノートの件数制限も、文数の制限もありません。成果物（コード、アーキテクチャドキュメント、テストファイル、セキュリティレポートなど）は常に先頭に置かれ、Growth のトレーラー節は常にそのあとに続きます。

### Growth Mode が ON のときに何が変わるのか

Growth Mode が有効なとき、チーム内の各エージェントは、応答を確定する前に `.claude/growth/config.json` を読み込みます。`enabled` が `true` であれば、エージェントは主たる出力のあとに 2 つのトレーラー節を追加します。生成される成果物そのものは変更されません。本番コードに教育目的のインラインコメントが足されることもありません。`docs/` や `.claude/growth/` の外には、いかなるファイルも書き込まれません。トレーラー節はチャット応答のなかに現れ、各エージェントは `.claude/growth/preamble.md` に定められた非破壊的な拡充操作に従って、対応するドメインファイル（`.claude/growth/notes/<domain>.md`）も併せて更新します。知識ベースは時系列のログではなく、ドメイン別に整理されています。セッションを重ねるたびに、実プロジェクトでの判断の蓄積に応じて、既存の節が深まっていくか、新しい節が追加されていきます。

実務上、何が変わるかというと、開発者は適用されているパターンの名前、このプロジェクトが一般的な代替案ではなくその選択を採った理由、そしてその判断を記録した ADR や外部参照を、その場で学べるようになります。多くのセッションを重ねることで、断片的なヒント以上のものが積み上がり、プロジェクトのさまざまな判断がどのように組み合わさっているのかについての心的モデルが形作られていきます。

### 3 つのレベル

**junior**: 妥当な代替案が存在するすべての応答に、完全な Growth Note を付けます。ノートではパターンに名前を与え、素朴な代替案よりもそれが選ばれた理由を説明し、関連コードのどこに注目すべきかを示します。読者はそのパターンに初めて触れる前提で書きます。応答あたりのノートは最大 3 件までとします。

**mid**: 自明でない判断（フレームワーク固有の慣用表現、横断的な関心事、コード自体には現れないトレードオフ）にのみ Growth Note を付けます。この層の開発者が当然知っているとみなせる、十分に確立された規約についてはノートを省きます。応答あたりのノートは最大 3 件までとします。

**senior**: エージェントが既定以外の選択をとった場合にのみ、トレードオフに関するノートを付けます。ノートでは既定を名指し、それがなぜ見送られたかを説明します。説明的な散文は入れません。応答あたりのノートが 0 件となることもよくあります。このレベルの主な用途は、手軽なセカンドオピニオンや、レビューで同僚に渡すメモ書きです。

レベルは「どの観察をノートとして書き残す価値があるか」を決めるフィルタであり、冗長さを調整するつまみではありません。既定以外の判断を含まない `senior` レベルの応答では、ノートは 0 件となりますが、それが正しい挙動です。

### ノートディレクトリ

`.claude/growth/notes/` 配下のノートディレクトリは、時系列のログではなく、ドメイン別に整理された「生きたリファレンス」です。エージェントは、セッションをまたいで関連する判断が積み重なるにつれて、同じドメインファイルを拡充し、深め、洗練させていきます。各セッションでは、日付付きのエントリを追記するのではなく、関連するドメインのファイルを開き、新しい節を追加するか、既存の節を深めるか、理解が成熟するにつれて古いエントリを洗練していきます。

19 の正典ドメインファイルは、機能のインストール時にプレシードされます。実プロジェクトで多くのセッションを重ねると、その一部が大きく育っていきます。開発者側のディレクトリは、たとえば次のような姿になり得ます。

```
.claude/growth/notes/
├── architecture.md             # 階層型アーキテクチャ、イベントソーシング、ACL配置、ADR参照
├── business-modeling.md        # 価格モデルのトレードオフ、ユニットエコノミクス、収益化パターン
├── persistence-strategy.md     # リポジトリパターン、option vs null、ADR-007、クエリ境界
├── error-handling.md           # Result<T,E>、鉄道指向プログラミング、境界コントラクト
├── security-mindset.md         # OWASPノート、認証パターン、入力バリデーション規約
├── testing-discipline.md       # AAAパターン、フィクスチャ分離、カバレッジ目標、TDDサイクル
└── performance-intuition.md    # プロファイリング方法論、DBクエリコスト、キャッシングトレードオフ
```

各ファイルは、セッションの日付ではなく概念の単位で整理されています。セッション 1 で導入され、セッション 12 で深められたリポジトリパターンに関するノートは、`persistence-strategy.md` の 1 つの一貫した節にまとまって存在します。時系列ログ上の 2 つのエントリに分かれることはありません。アーキテクトが以前の理解を洗練させる判断を下した場合にも、エージェントは元の段落の下に別の段落を足し加えるのではなく、そのエントリを更新したり深めたりします。

ここが、「AI の判断を説明する」と主張する他の多くのツールとの主な違いです。生成のたびにその場で判断を説明してくれる AI も有用ですが、本機能が提供するのは、実際の判断から抽出された累積的な理解を、ドメイン別に整理し、プロジェクト自身の ADR に紐づけ、時間をかけて洗練させていく一連のファイル、すなわち「実機能を実装することで築き上げていく個人用の教科書」です。

### ノートはデフォルトで非公開

`.claude/growth/notes/` はデフォルトで gitignore されており、`.claude/growth/config.json` も同様です。これには意図があります。ノートには、学習者の誤り、以前の誤った理解、そして心的モデルの変遷が含まれます。これは私的な学習素材であり、チームの共有リポジトリに公開することを想定したドキュメントではありません。蓄積されたドメイン知識をコミットしておき、すべての貢献者が参照できる共有教科書として扱いたいチームは、gitignore のパターンを反転させることでオプトインできます。リポジトリの `.gitignore.example` ファイルに、追加すべきパターンが明示されています。

### 両者の比較例

以下の例では、エコシステムに依存しない TypeScript で書いた、小さなページネーションユーティリティを題材にします。お題: `paginate` 関数を実装する。合計アイテム数、ページサイズ、現在のページ番号を受け取り、現在のページのメタデータを返します。

---

**Growth Mode OFF — implementer の応答:**

```typescript
export interface PageMeta {
  currentPage: number;
  pageSize: number;
  totalItems: number;
  totalPages: number;
  hasPrevious: boolean;
  hasNext: boolean;
}

export function paginate(
  totalItems: number,
  pageSize: number,
  currentPage: number
): PageMeta {
  if (pageSize <= 0) throw new RangeError("pageSize must be positive");
  if (currentPage < 1) throw new RangeError("currentPage must be >= 1");

  const totalPages = Math.ceil(totalItems / pageSize);
  const clampedPage = Math.min(currentPage, Math.max(totalPages, 1));

  return {
    currentPage: clampedPage,
    pageSize,
    totalItems,
    totalPages,
    hasPrevious: clampedPage > 1,
    hasNext: clampedPage < totalPages,
  };
}
```

implementer は、関数、インターフェース、そして境界条件の扱いを提供します。これが応答のすべてです。

---

**Growth Mode ON、レベル junior — implementer の応答:**

まず同じ関数がそのまま（完全に同一の形で）提示されます。コードブロックのあとに、次の節が続きます。

```
## Growth: taught this session

- Value Object パターン: `PageMeta` の返り値型は、クラスではなく素のデータオブジェクトです。
  この関数はモジュール境界をまたぐため、呼び出し側はクラス階層に依存することなく、結果を
  シリアライズしたり、ログに出したり、分割代入で取り出したりできるべきです。これは
  ドメイン駆動設計における Value Object パターンであり、正典の説明は Martin Fowler の
  *Patterns of Enterprise Application Architecture* にあります。

- 例外を投げずにクランプする判断: `currentPage` は範囲外の入力に対して例外を投げるのではなく、
  `[1, totalPages]` の範囲にクランプします。ページネーションの呼び出し側は、ブラウザ履歴や
  キャッシュされたクエリパラメータなど、ユーザー側の状態から古いページ番号を渡してくることが
  多いため、UI 境界で捕捉されずに突き抜ける例外を出すよりも、静かに補正するほうが安全です。
  別の呼び出し箇所で厳密なバリデーションが必要となった場合のプロジェクトの境界契約の規約は、
  今後の ADR で扱う予定です（ADR-005 のスロットをプレースホルダとして確保しています）。

- 空のコレクションの扱い: `Math.ceil(totalItems / pageSize)` は、特別な分岐を書かなくても
  アイテム数が 0 のケース（結果として 0 を返す）を正しく扱えるため、余りをチェックする
  整数除算よりもこちらを推奨します。空のコレクションのケースは `paginate.test.ts` で
  明示的にカバーされています。

## Growth: notebook diff

- notes/architecture.md → `## Value Object` に add: Value Object の定義、使用すべき場面と
  そうでない場面のガイド、プロジェクト内の模範的な実例としての `lib/pagination.ts` への
  ポインタ、Martin Fowler のカタログエントリへの参照を含む節を新設
```

**`.claude/growth/notes/architecture.md` に書き込まれる内容:**

エージェントは Value Object エントリを追加または更新します:

```markdown
## Value Object

Value Object は、フィールドによって完全に記述され、アイデンティティを持たないデータ構造です。
慣例として不変（immutable）であり、クラス階層への依存を持ち込むことなく、モジュールや
プロセスの境界をまたいでシリアライズ・等値比較・受け渡しを安全に行えます。

**使うべき場面**: モジュールやプロセスの境界をまたぐ純粋計算関数の返り値の型。
たとえばページネーションのメタデータ、検索結果のサマリー、バリデーションレポートなど。

**使うべきでない場面**: その構造がカプセル化すべき振る舞いを持つ場合、あるいは
アイデンティティの追跡が必要な場合（その場合は Entity を使うのが望ましい）。

**このプロジェクトでの実例**: `lib/pagination.ts` の `PageMeta` が代表的な例です。
新しい Value Object を正式に記録する価値があるかどうかの判断基準については、
`docs/en/adr/` の ADR の規約も参照してください。

**参考**: Martin Fowler, *Patterns of Enterprise Application Architecture*, Value Object
パターン, https://martinfowler.com/eaaCatalog/valueObject.html
```

このエントリは、このセッションより前には存在していませんでした。次のセッションで
Value Object が再び話題になったとき、エージェントが追加すべき新しい文脈があれば
（たとえば、ネストした Value Object を含むより複雑なケースが後のセッションで持ち込まれた場合）、
そのケースは新しい日付見出しの下に別ファイルとして追加されるのではなく、同じエントリの
サブ節として追記されます。

---

## 15 エージェントのチーム

すべてのエージェントはエコシステムに依存しません。`.claude/CLAUDE.md` とプロジェクトのマニフェストファイル（`package.json`、`pubspec.yaml`、`go.mod`、`Cargo.toml` など）を読み込み、実行時に言語とフレームワークを判別します。チーム全体の調整はオーケストレーターが担い、各スペシャリストはオーケストレーターから呼び出されるか、開発者から直接呼び出されます。

Growth Mode が有効なとき、各エージェントは、下表に示したドメインにしたがって `.claude/growth/notes/` 配下のドメインノートに貢献します。完全なドメインの分類体系は [`docs/en/growth/domain-taxonomy.md`](docs/en/growth/domain-taxonomy.md) で定義しています。

以下の表の「主担当 Growth ドメイン」の列は、そのエージェントが主として貢献するドメインを示します。副担当ドメインは [ADR-001](docs/en/adr/001-developer-growth-mode.md) と分類体系のドキュメントで定義しています。

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

以前の README では 14 エージェント構成と記載していましたが、現在のチームは 15 エージェント構成です。新たに `docs-researcher` を追加しました。これは、陳腐化している可能性のある学習データに頼るのではなく、コードを書く前の段階で、一次ドキュメントに対して API の挙動、フレームワークの変更、マイグレーションパスを検証する専任の調査担当スペシャリストです。

> **実装上の注記**: 各エージェントのドメイン担当は、そのエージェントファイルの frontmatter 内の `growth_domains:` キーで宣言し、エージェントプロンプト本文から参照しています。Claude Code 公式の sub-agent frontmatter スキーマは `name` / `description` / `tools` / `model` で、`growth_domains:` はテンプレート内の慣例です。エージェントプロンプトが自ファイルをテキストとして読むことで成立しています。将来 Anthropic が frontmatter スキーマを厳格に閉じた場合、このキーはエージェント本文へ移します。いずれにしても、デフォルト OFF の不変条件は `scripts/check-growth-invariants.sh` が決定論的に強制するため、frontmatter の扱いには依存しません。

---

## はじめ方

### 1. テンプレートからリポジトリを作成する

GitHub で [b150005/ecc-base-template](https://github.com/b150005/ecc-base-template) を開き、**Use this template** をクリックしてください。リポジトリ名と公開設定を選択します。テンプレートから、完全な `.claude/` 構造、ドキュメント、CI/CD パイプライン、コミュニティヘルス関連ファイルがあらかじめ配置された新しいリポジトリが作られます。

### 2. クローンしてリポジトリを開く

```sh
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>
```

お好みのエディタで開くか、Claude Code で直接開いてください（リポジトリルートで `claude` を実行）。

### 3. CLAUDE.md をカスタマイズする

`.claude/CLAUDE.md` はエージェントチーム向けの中心的な指示ファイルです。テンプレートにはプレースホルダの「About This Project」の節が含まれています。ここをプロジェクト固有のコンテキスト（何を作るプロジェクトか、使用するフレームワーク、ドメイン固有の規約など）で置き換えてください。それ以外の節（エージェント一覧、開発ワークフロー、テスト要件、ドキュメント規約など）は、そのまま、あるいは必要に応じた軽微な追記で引き継げるように設計しています。

テンプレートには、フレームワーク固有のマニフェストファイル（`package.json`、`go.mod` など）は含まれていません。エージェントは実行時にエコシステムを判別するので、選択したフレームワークのマニフェストを作成すれば、エージェントは自動的にそれに合わせて振る舞います。

### 4. 既定の体験

Growth Mode を OFF にした状態（既定）では、エージェントは成果物のみを生成します。オーケストレーターが Issue を分析して作業を委任し、アーキテクトが設計を行って判断を `docs/en/adr/` の ADR として記録します。implementer は TDD にしたがってコードを書き、品質担当のエージェント群（code-reviewer、test-runner、linter、security-reviewer、performance-engineer）が作業を検証します。technical-writer がドキュメントを最新の状態に保ちます。

ワークフローは `.claude/CLAUDE.md` の「Development Workflow」に定義されています。エージェントは追加の指示なしにこれに従います。基本的にはオーケストレーターとやり取りすることになりますが、必要に応じてスペシャリストを直接呼び出すこともできます。

### 5. Growth Mode を有効化する

関係する入口は 3 つあり、それぞれ異なる役割を持ちます。

**Skill** は操作の入口です。`/growth` は Claude Code の Skill（`.claude/skills/growth/SKILL.md` で定義）で、現在のセッションの状態を即座に切り替えます。この Skill は `disable-model-invocation: true` を用いているため、Growth Mode を切り替えられるのはユーザーだけで、モデルが自動で呼び出すことはできません。これは緩い慣習ではなく、設計上の保証です。

```
/growth on [junior|mid|senior]       指定レベル（または直近の保存レベル）で有効化
/growth off                          無効化。次回有効化のために level と focus を保持
/growth status                       現在の状態と直近のノートブック diff を表示
/growth focus <domain>[,<domain>]    エージェントの教示効果を指定ドメインに集中させる
/growth unfocus                      focus を解除し、全ドメインを同等に扱う
/growth level <junior|mid|senior>    enabled を切り替えずにレベルだけ変更
/growth domain new <key>             カスタムドメインファイルを作成（確認プロンプトあり）
```

`/quiet` は独立したコンパニオン Skill で `.claude/skills/quiet/SKILL.md` にあります。**直後 1 回の**エージェント応答に限って `## Growth: taught this session` と `## Growth: notebook diff` のトレーラー節を抑止します。ドメインノートへの書き込みは通常どおり行われ、チャット上のトレーラー表示だけが隠されます。状態は変更されず、次のユーザーターンで通常のトレーラー表示に自動復帰します。

**設定ファイル** は状態の入口です。`.claude/growth/config.json` は、セッションをまたいでレベルと focus を保持します。最初の `/growth on` 呼び出しで作成されるため、クローン直後のリポジトリには存在しません。スキーマは次のとおりです。

```json
{
  "enabled": true,
  "level": "junior",
  "focus_domains": [],
  "updatedAt": "2026-04-22T00:00:00Z"
}
```

- `enabled` — Growth Mode の有効/無効。設定が存在しない、または不正な JSON の場合は無効として扱います。
- `level` — `"junior"` / `"mid"` / `"senior"` のいずれか。`/growth off` 後も保持され、次回の `/growth on` で復元されます。
- `focus_domains` — ドメインキーの配列（例: `["architecture", "testing-discipline"]`）。空でないとき、エージェントは focus 対象ドメインの教示瞬間には完全な拡充エントリを書き、それ以外のドメインの教示瞬間は真に重要なもののみ書き、それ以外は後回しにします。**エージェント単位の on/off スイッチではなく**、重み付けのソフトなシグナルです。15 エージェント全員が引き続き参加します。
- `updatedAt` — `/growth` Skill が状態を変更するたびに書き込む ISO 8601 タイムスタンプ。

**CLAUDE.md のポインタ** は発見性のための入口です。`.claude/CLAUDE.md` の短いポインタ節が、機能の存在、実行時ファイルの所在、有効化方法を伝えます。Growth Mode を利用するために CLAUDE.md を編集する必要はありません。呼び出し方を覚えていなくても、ここから辿れるようにしてあるだけです。

### 6. Growth Mode を有効化した最初のセッション

有効化したら、オーケストレーターに本物のタスクを与えてください。チュートリアルの演習ではなく、プロジェクトの実際の作業です。最初のタスクとして妥当なのは、バックログからの機能実装や、アーキテクトに対するドメインモデルのデータ層の設計依頼などです。

エージェントがタスクを完了すると、貢献した各エージェントは、その応答で下した判断についての観察を記した `## Growth: taught this session` の節と、`.claude/growth/notes/` 配下のどのドメインファイルに手を入れ、どの種類の操作を適用したかを記した `## Growth: notebook diff` の節を出力します。これらの節は成果物の「あと」に表示されるもので、成果物の内部には入り込みません。

セッション終了後、`.claude/growth/notes/` を確認してみてください。作成ないし更新されたドメインファイルが見つかるはずです。ぜひ読んでみてください。そこに並んでいるのは、汎用のチュートリアル的な表現ではなく、あなた自身のコードベースでの具体的な判断の言葉です。

---

## Growth Mode の背後にある考え方

### アノテーションは別層であって、挙動の変更ではない

Growth Note は、生成された成果物のなかには決して現れません。本番ファイルのインラインコメントとしても、テストコードの一部としても、ドキュメントの埋め込みとしても出現しません。Growth Note はあくまで、エージェントのチャット応答の末尾の節です。Growth Mode が ON のときに implementer が書くコードは、OFF のときに書くコードとまったく同じです。これはエージェント出力のハッシュ照合で担保しているのではなく（LLM の出力は非決定的であり、ゴールデンファイルに対する回帰テストは不安定テストに劣化するため）、`scripts/check-growth-invariants.sh` の 3 つの決定論的な CI チェック（`growth` Skill の `disable-model-invocation: true`、すべての Growth 対応エージェントプロンプトのガード分岐、gitignore の方針）によって強制しています。

この厳格さが必要な理由は、本番成果物に滲み出すアノテーション層は「アノテーション層」ではなく「コード品質の劣化」だからです。教育目的で追加されたコメントは、やがて技術的負債として積み重なります。Growth Note はあくまで会話のなかにとどめます。

### ノートはドメイン別に整理し、セッション別には整理しない

時系列ログは「何が起きたか」を記録します。ドメイン別のノートディレクトリは「何が分かっているか」を記録します。Growth Mode は時系列ジャーナルをいっさい保持しません。セッション単位の情報は、応答ごとの「ノートブック diff」とチャット出力に残り、長期的な監査証跡は Git の履歴が担います。ノートディレクトリは、構造化された知識の層です。セッション 3 であるエージェントがリポジトリパターンについてノートを加え、セッション 17 で別のエージェントがリポジトリパターンを再び扱った場合、その知識の正典となる置き場所は `persistence-strategy.md` の該当ノートです。セッション 17 の内容は、その並びに別エントリとして重複して追加されるのではなく、既存のノートを深める形で取り込まれていきます。

これは、実際の熟達の仕方そのものです。同じコードベースで 2 年間働いている開発者は、すべてのセッションを覚えているわけではなく、同じパターンに繰り返し出会うなかで築かれた心的モデルを持っているだけです。ノートディレクトリは、そのモデルを外在化するものです。

### レベルは「教えるかどうか」ではなく、深さを調整する

3 つのレベルは、「開発者にどれだけ教えるか」を表しているのではなく、「どの判断がノートに残す価値があるか」を表しています。junior レベルの開発者にとっては、ほとんどのパターンが初めて出会うものなので、パターンに関する判断すべてについてのノートが役立ちます。senior レベルの開発者にとって、すでに知っているパターンのノートは意味を持ちません。むしろ自明でない選択、つまりエージェントが検討に値する代替案を選び取ったケースについてのノートこそが意味を持ちます。

`senior` レベルで 0 件の Growth Note を出力したエージェントは、失敗しているわけではありません。「その応答には、このレベルでノートとして書き残すだけの判断は含まれていなかった」と正しく判断しただけです。senior レベルにおいてノート 0 件は、有効かつよく起こる結果であり、それこそが本機能の意図です。

### 15 エージェント全員が参加する

「学びに関わるエージェント」だけの部分集合というものはありません。Growth Mode が ON のときは、15 エージェント全員が、それぞれの職能に対応するドメインにしたがってノートディレクトリに貢献します。security-reviewer は `security-mindset.md` に、product-manager は `api-design.md` に、devops-engineer は `operational-awareness.md` と `release-and-deployment.md` に、ui-ux-designer は `ui-ux-craft.md` に、といった具合です。Growth Mode を一部のエージェントに限定すると、開発者は実装パターンについての知識は蓄積できても、セキュリティ上のトレードオフやインフラに関する判断は蓄積できない、という盲点が生まれてしまいます。これはまさに、サイロ化した思考を生み出す、偏った全体像です。

### `docs/en/` が Source of Truth

ドキュメントの正典は `docs/en/`（英語）に置き、日本語訳は `docs/ja/` に配置しています。エージェントはコンテキストウィンドウの使用を抑えるため、`docs/en/` のみを読み込みます。日本語ファイルの冒頭には、対応する英語ソースへのリンクを含むヘッダが付いています。この役割分担は意図的なものです。同じドキュメントを 2 つ同時に「正典」として保守するのは、保守コストを倍増させるうえに、遅かれ早かれ内容のドリフトを招きます。1 つの Source of Truth と、それに追従する翻訳、という構成のほうが信頼性が高まります。

### 基礎的な文脈は保持する

Growth Note 自体は簡潔にまとめますが、ドメインノートのファイルは、必要なだけの紙幅をとります。リポジトリパターンを過不足なく説明したノートエントリ（使うべき場面、使うべきでない場面、このプロジェクトでの具体的な適用のされ方、その判断を記録した ADR）は、「使うべきでない場面」を省いた圧縮された要約よりも有用です。「流し読みしやすくするため」といった理由で削ることはしません。想定読者は、コードベースを理解したい開発者であり、ざっと印象を掴みたいだけの訪問者ではないからです。

---

## プロジェクト構造

```
.
├── .claude/
│   ├── CLAUDE.md                          # エージェント指示 + Growth Mode ポインター
│   ├── agents/                            # 15 エージェントの定義ファイル
│   │   ├── orchestrator.md
│   │   ├── product-manager.md
│   │   ├── market-analyst.md
│   │   ├── monetization-strategist.md
│   │   ├── ui-ux-designer.md
│   │   ├── docs-researcher.md
│   │   ├── architect.md
│   │   ├── implementer.md
│   │   ├── code-reviewer.md
│   │   ├── test-runner.md
│   │   ├── linter.md
│   │   ├── security-reviewer.md
│   │   ├── performance-engineer.md
│   │   ├── devops-engineer.md
│   │   └── technical-writer.md
│   ├── skills/
│   │   ├── growth/
│   │   │   └── SKILL.md                   # /growth Claude Code Skill のハンドラ
│   │   └── quiet/
│   │       └── SKILL.md                   # /quiet トレーラー抑止 Skill（1 ターン限定）
│   ├── growth/                            # Growth Mode の実行時ファイル + 同梱アセット
│   │   ├── preamble.md                    # 同梱 — 全エージェントが共有する拡充コントラクト
│   │   ├── notes/                         # 同梱 — 19 のドメイン別ノート（既定で gitignore）
│   │   │   ├── architecture.md
│   │   │   ├── api-design.md
│   │   │   ├── data-modeling.md
│   │   │   ├── persistence-strategy.md
│   │   │   ├── error-handling.md
│   │   │   ├── testing-discipline.md
│   │   │   ├── concurrency-and-async.md
│   │   │   ├── ecosystem-fluency.md
│   │   │   ├── dependency-management.md
│   │   │   ├── implementation-patterns.md
│   │   │   ├── review-taste.md
│   │   │   ├── security-mindset.md
│   │   │   ├── performance-intuition.md
│   │   │   ├── operational-awareness.md
│   │   │   ├── release-and-deployment.md
│   │   │   ├── market-reasoning.md
│   │   │   ├── business-modeling.md
│   │   │   ├── documentation-craft.md
│   │   │   └── ui-ux-craft.md
│   │   └── config.json                    # 最初の /growth on で作成（gitignore）
│   ├── settings.json
│   └── settings.local.json
├── .devcontainer/
│   └── devcontainer.json                  # コメント付きのテンプレート。フレームワークに応じて調整する
├── .github/
│   ├── CODEOWNERS
│   ├── ISSUE_TEMPLATE/
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── dependabot.yml
│   └── workflows/
│       ├── ci-base.yml                    # lint、test、build
│       └── security.yml                   # シークレットスキャン、脆弱性チェック
├── docs/
│   ├── en/                                # 英語の Source of Truth
│   │   ├── adr/
│   │   │   ├── 000-template.md
│   │   │   └── 001-developer-growth-mode.md
│   │   ├── growth/
│   │   │   └── domain-taxonomy.md         # 19 の Growth ドメインとその担当を定めた正典
│   │   ├── prd/
│   │   │   └── developer-growth-mode.md
│   │   ├── ci-cd-pipeline.md
│   │   ├── devcontainer.md
│   │   ├── ecc-overview.md
│   │   ├── github-features.md
│   │   ├── template-usage.md
│   │   └── tdd-workflow.md
│   └── ja/                                # 日本語訳（各ファイル先頭に英語ソースへのリンクあり）
├── scripts/
│   └── check-growth-invariants.sh         # CI チェック: Skill フラグ、エージェントのガード分岐、gitignore
├── .env.example
├── .gitattributes
├── .gitignore
├── LICENSE
├── README.md                              # 英語
└── README.ja.md                           # このファイル（日本語）
```

補足: `.claude/growth/` ディレクトリには、`preamble.md`（拡充コントラクト）と `notes/`（19 のプレシード済ドメインファイル）がテンプレートに同梱されています。実行時に作成されるのは `config.json` のみで、最初の `/growth on` 呼び出し時に作られます。`config.json` と `notes/` はいずれも既定で gitignore されており、個人の状態や私的な学習素材がコミットに紛れ込まないようになっています。チームでノートを共有したい場合のオプトイン手順については、上の「ノートはデフォルトで非公開」の節を参照してください。

---

## テンプレート自体を育てる

テンプレートに関する重要な判断は `docs/en/adr/` の ADR として記録していきます。現時点の ADR 一覧は以下のとおりです。

- `000-template.md` — ADR のフォーマットテンプレート
- `001-developer-growth-mode.md` — Growth Mode の設計判断（コンテキスト、決定、検討した代替案、結果）

プロダクト要件は `docs/en/prd/` に置きます。Developer Growth Mode の PRD は本機能に関する正典の仕様であり、受け入れ基準、機能要件、非機能要件、そしてデフォルト OFF の不変条件を記述しています。

テンプレート自体に手を入れる場合も、同じエージェントワークフローに従います。オーケストレーターに変更案の分析を依頼し、アーキテクトが判断を ADR として記録し、implementer が PRD の受け入れ基準に対して実装を進める、という流れです。

---

## ライセンス

[MIT](LICENSE)
