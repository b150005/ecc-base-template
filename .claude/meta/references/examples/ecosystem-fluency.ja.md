---
domain: ecosystem-fluency
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: implementer
contributing-agents: [implementer, code-reviewer]
---

> このドキュメントは `.claude/meta/references/examples/ecosystem-fluency.md` の日本語訳です。英語版が原文（Source of Truth）です。

> **読み取り専用リファレンス。** このファイルは ECC Base Template に同梱された作業事例であり、実際のプロジェクトで多くのセッションを重ねた後の knowledge ファイルがどのような状態になるかを示すためのものです。これはあなた自身の knowledge ファイルでは**ありません**。あなた自身の knowledge ファイルは `.claude/learn/knowledge/ecosystem-fluency.md` に置かれ、エージェントが実際の作業を通じて拡充するまでは空の状態です。エージェントは `.claude/meta/references/examples/` 配下を読んだり参照したり書き込んだりしません — このツリーは人間の読者専用です。設計の意図については [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) を参照してください。
>
> **このドメインの knowledge ファイル:** `.claude/learn/knowledge/ecosystem-fluency.md`

---

## このファイルの読み方

レベルマーカーは、各節の対象読者を示します。
- `[JUNIOR]` — 第一原理からの説明。事前知識を前提としない
- `[MID]` — このスタックにおける非自明な慣用的応用
- `[SENIOR]` — 非デフォルトのトレードオフ評価。何を手放したかを明示する

---

## Go 標準ライブラリ vs. サードパーティ: Meridian のポリシー  [JUNIOR]

### 第一原理からの説明  [JUNIOR]

Go は大規模で安定した標準ライブラリを備えています。他のエコシステムではサードパーティパッケージが必要な多くの操作 — HTTP サーバー、JSON エンコーディング、ソート、暗号 — に対して、Go には慣用的な標準ライブラリの答えがあります。これにより、すべての Go プロジェクトが早期に直面する判断が生まれます: ある問題に対して `net/http` を使うか、フレームワークを使うか?

この違いが重要なのは、標準ライブラリの選択とサードパーティの選択ではコストが異なるからです。標準ライブラリのパッケージは Go ツールチェーンとともにバージョン管理され、メンテナンスが停止することがなく、`go.mod` へのインポートオーバーヘッドがゼロです。サードパーティパッケージは依存関係を追加し、推移的グラフをもたらし、メンテナンスの健全性と API の安定性を評価する必要があります。

「シンプルさのために常に標準ライブラリを使う」という素朴な答えは、そうでなくなるまでは正しいです。標準の `net/http` は本番トラフィックをさばけますが、ルーティングパラメータ（`/tasks/:id`）もミドルウェアチェーンも JSON バインディングも提供しません。20 以上のルートを持つプロジェクトで `net/http` の上にそれらを書くことは、フレームワークを再構築することになります — 時間の無駄でありバグの温床です。逆に、5 つのルートしかない内部ツールのためにフレームワークをインポートすることは、利益なしに複雑さを追加します。

### 慣用的な応用  [MID]

Meridian のポリシーは簡潔な判断記録に文書化され、コードレビューで強制されています。

**標準ライブラリを使う場合:**
- 操作が自己完結しており、そのユースケースに対して標準ライブラリの API が完結している場合。`encoding/json` によるシンプルなドメイン構造体の API レスポンスへのマーシャリングはこれを満たします: `json.Marshal(task)` は設定不要です。
- プロジェクトが抽象的な価値を追加しない薄いラッパーを標準ライブラリの上に書くだけになる場合。`context.WithTimeout` はラッパーを必要としません。
- パッケージが単一の呼び出しサイトでのみ呼ばれる場合。一度きりの使用ではフレームワーク依存関係がほとんど正当化されません。

**サードパーティを正当化する場合:**
- 標準ライブラリのギャップが実在し、ギャップを埋めるコードを自分たちでメンテナンスしなければならない場合。Meridian はパスパラメータ、ミドルウェアグループ、`ShouldBindJSON` による JSON バインディングがなければ各サービスで約 200 行のボイラープレートが必要になるため、HTTP ルーティングに `github.com/gin-gonic/gin` を使用しています。
- サードパーティパッケージが、誤りやすいことで知られるエッジケースを持つ問題クラスを解決している場合。Meridian は `database/sql` + `lib/pq` の組み合わせではなく `github.com/jackc/pgx/v5`（pgx）を使用しています。pgx は `database/sql` が必要とする追加のスキャンアダプタレイヤーなしに、PostgreSQL 固有の型（配列、UUID、JSONB）をネイティブで扱えるためです。
- パッケージが Go コミュニティにおけるデファクトスタンダードで、メンテナンスの健全性が実証されている場合。`go.uber.org/zap` による構造化ロギングは、手作りの `log/slog` ラッパーよりも、高スループットの書き込みにおけるパフォーマンス特性がよく文書化されているため選択されました。

### トレードオフと制約  [SENIOR]

標準ライブラリ優先ポリシーでは、エルゴノミクスをいくらか犠牲にします。`encoding/json` はフィールドレベルのバリデーション、`json:"-"` や `omitempty` 以外の構造体タグ、Postgres からの JSONB ストリーミングをサポートしていません。これらが必要になった場合、プロジェクトはライブラリを追加します（バリデーションには `github.com/go-playground/validator/v10`）が、標準ライブラリ優先のデフォルトを放棄するわけではありません。各追加は自動的なものではなく、意図的なものです。

このポリシーは Meridian が「何でも入り」のフレームワークを明示的に避けることも意味します。ルーティング、ORM、マイグレーションツール、CLI ジェネレータ、テストハーネスをすべて 1 つのインポートで提供するフレームワークは最初は便利ですが、バージョン結合を生み出します: ルータのアップグレードが他のすべてのフレームワークコンポーネントの同時アップグレードを強制します。Meridian は代わりに、それぞれが独立してバージョン管理される専門化されたパッケージで懸念事項を分離しています: ルーティングに gin、データベースに pgx、ロギングに zap。

バックエンドの具体的な `go.mod` エントリはこのポリシーを反映しています:

```
require (
    github.com/gin-gonic/gin      v1.9.1
    github.com/jackc/pgx/v5       v5.5.2
    github.com/redis/go-redis/v9  v9.4.0
    go.uber.org/zap               v1.27.0
    github.com/google/uuid        v1.6.0
)
```

ORM なし。ランタイムバイナリにマイグレーションライブラリなし（マイグレーションは別の `cmd/migrate/` コマンドで `github.com/golang-migrate/migrate/v4` を使って実行され、CI およびローカルセットアップ時にのみ呼び出されます — API サーバーにはインポートされません）。

### 関連節

- このポリシーが保護するパッケージ境界がレイヤー構造にどうマップされるかについては [architecture → Hexagonal Split](./architecture.md#hexagonal-split) を参照してください。
- インターフェースを受け付けるライブラリが導入された後に適用される命名慣習については [ecosystem-fluency → Go Interface Naming Conventions](#go-interface-naming-conventions) を参照してください。

---

## Go インターフェースの命名規則  [JUNIOR]

### 第一原理からの説明  [JUNIOR]

Go の命名は異例なほど独自のスタイルを持っています。言語の公式スタイルガイド（Effective Go と Go Code Review Comments）は、他の多くの言語の規約とは異なる具体的なルールを定めています。最も目立つ違いは:

- **インターフェースに `I` プレフィックスをつけない。** Java や C# のコードベースでは `IUserRepository` のようなインターフェース名をつけるかもしれません。Go はそのプレフィックスをノイズとして扱います。型はインターフェースです; 名前は型の種類ではなく、型が何をするかを表すべきです。
- **単一メソッドのインターフェースは動詞に由来する名前をつける。** `Read(p []byte) (n int, err error)` というメソッドを 1 つ持つインターフェースは `ReadInterface` や `IReadable` ではなく `Reader` と名付けられます。
- **複数メソッドのインターフェースはその機能を表す名詞にする。** 読み取りとクローズの両方ができる型は `ReadCloser` です。タスクを書き込める型は `TaskRepositoryInterface` や `ITaskRepository` ではなく `TaskRepository` です。

この根拠は、Go のインターフェースが暗黙的に満たされるためです — 型は必要なメソッドを持つだけでインターフェースを満たします。`implements` キーワードがないため、インターフェースの名前がコントラクトの全意味的重みを担います。機能を表す名前（「フェッチするもの」）は、型の種類を表す名前（「IFetcher と呼ばれるインターフェース」）よりも多くを伝えます。

### 慣用的な応用  [MID]

Meridian はコードベース全体で 3 つの命名ルールを一貫して適用しています。2 つは Go の標準で、1 つはプロジェクト固有の決定です。

**ルール 1 — `I` プレフィックスなし。** `domain/`、`service/`、`repository/` のすべてのインターフェースはプレフィックスなしで命名されます。`ITaskRepository` ではなく `TaskRepository`。

**ルール 2 — 単一メソッドのインターフェースは `-er` サフィックスを使用する。** Meridian の `NotificationService` インターフェースは複数のメソッドを持つため名詞として命名されています。しかし、プロジェクトが単一メソッドの Webhook バリデーションインターフェースを導入した際、`WebhookValidator` や `IValidator` ではなく `Validator` と名付けられました。

**ルール 3 — コンストラクタ関数は `New<T>` で、`Make<T>` ではない。** これは Meridian のプロジェクト決定であり、Go の標準ライブラリや人気パッケージの大多数（`http.NewRequest`、`json.NewDecoder`、`zap.NewProduction`）のスタイルに合わせています。チームはあるチームメンバーの Rust バックグラウンドの影響で初期スプリント中に `Make<T>` を使用しましたが、コードレビューで `Make` プレフィックスが Go コミュニティの規約に先例がなく、Go の経験を持つ新しいコントリビューターを混乱させると指摘され `New<T>` に変更しました。

```go
// domain/task.go — 一貫したコンストラクタ命名
func NewTask(workspaceID uuid.UUID, title string) Task {
    return Task{
        ID:          uuid.New(),
        WorkspaceID: workspaceID,
        Title:       title,
        Status:      TaskStatusActive,
        CreatedAt:   time.Now().UTC(),
    }
}
```

**レシーバー名** は厳格なルールに従います: 型名から 1 文字に省略します。`TaskService` は `s`、`postgresTaskRepository` は `r`、`TaskHandler` は `h` を使用します。複数文字のレシーバー（`ts`、`repo`）はコードレビューで却下されます。これは Go Code Review Comments の推奨に沿っており、メソッドのシグネチャをコンパクトに保ちます。

### トレードオフと制約  [SENIOR]

単一メソッドのインターフェースに対する `-er` サフィックス規約は、ときに不自然な名前を生み出します。単一の `Execute(ctx context.Context, cmd Command) error` メソッドを持つインターフェースは慣例的に `Executor` と名付けられます — これはうまくいきます。しかし、単一の `Notify(ctx context.Context, event Event) error` メソッドを持つインターフェースは `Notifier` になり、これも問題ありません; 一方、`CheckAndRecord(ctx context.Context, key string) (bool, error)` を持つインターフェースは `CheckAndRecorder` になり、これは無理があります。その場合、Meridian は不自然な `-er` 名前を強制するのではなく名詞形（`IdempotencyChecker`）を選択します。原則は「規約に従い、結果が代替案より明らかに悪い場合は逸脱する」です。

`New<T>` 規約では、一部の Rust 経験者が便利と感じる区別を手放します: ゼロ引数コンストラクタには `make`、パラメータを取るコンストラクタには `new` という使い分けです。Go はこの区別を標準ライブラリや主要パッケージのどこにも採用しておらず、Go コードベースにこれを持ち込むと、他のプロジェクトで Go を経験してきた新しいコントリビューターに摩擦をもたらします。

### 関連節

- これらの命名ルールが適用されるインターフェース宣言の場所（`domain/` で定義され `service/` で使用されるインターフェース）については [architecture → Hexagonal Split](./architecture.md#hexagonal-split) を参照してください。
- インターフェースでバックされた抽象化が定義する価値があるかを判断するポリシーについては [ecosystem-fluency → Go Stdlib vs. Third-Party](#go-stdlib-vs-third-party-the-meridian-policy) を参照してください。

---

## プロジェクトレイアウト: `pkg/` 論争において Meridian が辿り着いた答え  [MID]

### 第一原理からの説明  [JUNIOR]

Go プロジェクトのレイアウトは、言語の構文よりもコミュニティ内で議論の多いテーマです。[golang-standards/project-layout](https://github.com/golang-standards/project-layout) GitHub リポジトリで使われている `cmd/` + `internal/` + `pkg/` 構造は広く模倣されていますが、Go の公式推奨ではありません。Go チームは Go モジュールに必須のディレクトリ構造はないと明示しています。

3 つのディレクトリの主な区別:

- `cmd/<name>/main.go` — エントリポイント。各 `cmd/` サブディレクトリが 1 つのバイナリを生成します。ここのコードは薄くあるべきです: フラグの解析、依存関係の配線、`Run(ctx)` の呼び出し。
- `internal/` — 同じモジュール内のコードのみがインポートできるパッケージ。Go ツールチェーンがこれを強制します: `go build` は `mymodule` の外からの `mymodule/internal/service` のインポートを拒否します。これが Go における主要なカプセル化メカニズムです。
- `pkg/` — 外部モジュールからのインポートを意図したパッケージ。これはライブラリコードの規約です。プロジェクトが `pkg/` を必要とするかは、再利用可能なパッケージをエクスポートするかどうかによります。

### 慣用的な応用  [MID]

Meridian には `pkg/` ディレクトリがありません。この決定は明示的に行われました: Meridian はライブラリではなくアプリケーションです。外部モジュールが Meridian のパッケージをインポートすることは想定されていません。`pkg/` を追加することは、一部のパッケージが外部での再利用を意図しているというシグナルになりますが、それは事実でなく、新しいコントリビューターに誤解を与える可能性があります。

レイアウトは次の通りです:

```
cmd/
  server/
    main.go          # API サーバーエントリポイント — 依存関係を配線し Gin を起動
  migrate/
    main.go          # マイグレーションランナー — サーバーとは別のバイナリ、インポート不可

internal/
  domain/            # 純粋な型、インターフェース、エラー型 — インフラのインポートなし
  handler/           # Gin ハンドラ構造体
  service/           # ビジネスロジックサービス
  repository/        # PostgreSQL と Redis の実装
  middleware/        # Gin ミドルウェア（認証、リクエスト ID、ロギング）
  config/            # 環境変数からの設定読み込み
```

`config/` パッケージは単純であるにもかかわらず `internal/` にあります。設定はアプリケーション固有であるためエクスポートしません。`middleware/` パッケージは Gin 固有のコードを含み、このアプリケーションの外では価値がありません。

`pkg/` がないことで、Go モノリポにおける一般的な混乱を避けられます: `pkg/` を見たコントリビューターは、そこが共有ユーティリティを置く場所だと思い込みます。Meridian の場合、共有ユーティリティは外部モジュールとではなく同じモジュール内の他のパッケージとのみ共有するため `internal/` に置かれます。

### トレードオフと制約  [SENIOR]

`pkg/` がないことは、Meridian が仮想の第 2 サービス（バックグラウンドジョブランナー、Webhook フォワーダー）とユーティリティを共有したい場合、ユーティリティを複製するか、別モジュールとして抽出するか、第 2 サービスを同じモジュールに追加するかを選ばなければならないことを意味します。レイアウト決定時点では、チームは第 2 サービスを持っておらず、具体的な計画もありませんでした。`pkg/` を先取りして追加することは YAGNI になっていたでしょう。

`internal/` の強制がより大きな恩恵です。Go ツールチェーンは `internal` パッケージがモジュール外からインポートされることを防ぐため、Meridian のデータベースレイヤー、設定、ドメイン型は、同じモノリポを共有していても別チームのサービスから誤ってインポートされることがありません。このカプセル化はコンパイラによって強制されており、規約による強制ではありません。

第 2 サービスが後でリポジトリに追加される場合の判断ポイントは: 真に共有するパッケージのための `pkg/` ディレクトリを作成するか、各サービスのコードを完全に独自の `internal/` に収めるか。Meridian の現在のコンセンサスは、共有の必要性が具体的になり、共有パッケージの API がライブラリコントラクトとして扱えるほど安定するまでは、サービスごとの `internal/` が望ましいというものです。

### 関連節

- これらのディレクトリが六角形レイヤー構造にどうマップされるかについては [architecture → Hexagonal Split](./architecture.md#hexagonal-split) を参照してください。
- パッケージレイアウトがサードパーティ依存ポリシーとどのように関係するかについては [ecosystem-fluency → Go Stdlib vs. Third-Party](#go-stdlib-vs-third-party-the-meridian-policy) を参照してください。

---

## Meridian のデータレイヤーとしての TanStack Query  [MID]

### 第一原理からの説明  [JUNIOR]

サーバーからデータをフェッチする React アプリケーションは、繰り返し発生する問題に直面します: ローディング状態、エラー状態、キャッシング、バックグラウンドリフレッシュ、同一リソースへの並行リクエストの重複排除、楽観的更新です。素朴なアプローチでは `useState` と `useEffect` を使ってコンポーネント内でこれらをインラインで処理します。1 つのコンポーネントが 1 つのリソースをフェッチする場合はこれで機能しますが、アプリケーションが成長するにつれて、すべてのコンポーネントが同じパターンを不一致に実装します: あるコンポーネントはスピナーを表示し、別のコンポーネントは何も表示せず、あるコンポーネントはデータをグローバルストアにキャッシュし、別のコンポーネントはマウントのたびに再フェッチします。

**サーバー状態ライブラリ** はこの関心事を専用レイヤーに引き出します。ライブラリがキャッシュ、ローディング状態、エラー状態、重複排除ロジック、バックグラウンドリフレッシュのスケジューリングを所有します。コンポーネントは必要なデータを宣言し、ライブラリはキャッシュから提供するかフェッチするかを決定します。

サーバー状態とクライアント状態の区別は重要です。サーバー状態はサーバーが所有するデータを表します（タスク、ワークスペース、ユーザー）。非同期であり、既知の鮮度モデルを持ち、コンポーネント間で共有される場合があります。クライアント状態は UI の動作を表します（どのドロワーが開いているか、どのタブが選択されているか）。この 2 種類の状態はライフサイクルが異なるため、同じツールで管理すべきではありません。

### 慣用的な応用  [MID]

Meridian はすべてのサーバー状態に TanStack Query（`@tanstack/react-query`）を使用しています。パターンはすべてのデータフェッチコンポーネントで一貫しています:

```tsx
// hooks/useTaskList.ts
import { useQuery } from '@tanstack/react-query';
import { fetchTasks } from '../api/tasks';

export function useTaskList(workspaceId: string) {
  return useQuery({
    queryKey: ['tasks', workspaceId],
    queryFn: () => fetchTasks(workspaceId),
    staleTime: 30_000,   // データを 30 秒間フレッシュとして扱う
  });
}
```

```tsx
// components/TaskList.tsx
function TaskList({ workspaceId }: { workspaceId: string }) {
  const { data, isLoading, error } = useTaskList(workspaceId);

  if (isLoading) return <Skeleton />;
  if (error) return <ErrorBanner error={error} />;
  return <ul>{data.tasks.map(t => <TaskItem key={t.id} task={t} />)}</ul>;
}
```

`queryKey` 配列はキャッシュの識別子です。`['tasks', workspaceId]` は、異なるワークスペースのタスクリストが独立してキャッシュされることを意味し、タスクの作成や更新後に `['tasks', workspaceId]` を無効化すると、そのワークスペースのみのバックグラウンドリフェッチがトリガーされます。

Meridian のフロントエンドには Redux ストアも Zustand ストアもありません。クライアントのみの状態（どのパネルが展開されているか、どのモーダルが開いているか）は、コンポーネント内または共有コンテキスト内で `useState` か `useReducer` を使って管理します。ルールは: データがサーバーに存在するなら TanStack Query に置く。データが純粋に UI の動作でサーバー表現を持たないなら、ローカルコンポーネント状態に置く。

### トレードオフと制約  [SENIOR]

TanStack Query は React 自身のサーバーフェッチのプリミティブ（`use` + Suspense を使った React Server Components）よりも選択されました。なぜなら、Meridian のフロントエンドは別の Go バックエンドと通信する静的サイトとして Vercel にデプロイされるシングルページアプリケーションだからです。React Server Components は、React ツリーとデータフェッチの両方を制御する Node.js レンダリング環境を必要とします。Meridian のアーキテクチャはそれらの責任を別々のサービスに置いています — Go がデータを担当し、React が UI を担当します — そして RSC は Node.js のバックエンド・フォー・フロントエンドレイヤーまたはホスティングアーキテクチャの変更を必要とします。チームはフロントエンドアーキテクチャフェーズでこれを評価し、Meridian の現在のスケールでは Node.js レイヤーを追加する運用コストが RSC の開発体験上の恩恵を上回ると結論付けました。

TanStack Query は、静的ページのクライアントサイド JavaScript を排除する機能を手放します。認証を必要とし動的データを持つすべてのページで構成されるダッシュボードアプリケーションでは、これは意味のある損失ではありません。

キャッシュの無効化モデルは明示的です: ミューテーションの後、呼び出しコードが `queryClient.invalidateQueries({ queryKey: ['tasks', workspaceId] })` を呼び出します。これは RSC の暗黙的なサーバー再レンダリングよりも若干機械的ですが、より予測可能でもあります: 無効化は呼び出しサイトで可視であり、フレームワークの規約によって暗示されません。

### 関連節

- TanStack Query のエラー処理がバックエンドの返す RFC 9457 エラーフォーマットとどのように相互作用するかについては [api-design → Error Envelope: RFC 9457](./api-design.md#error-envelope-rfc-9457) を参照してください。
- TanStack Query の `useInfiniteQuery` がカーソルベースのページネーションレスポンス形状をどのように消費するかについては [api-design → Cursor-Based Pagination on Task Lists](./api-design.md#cursor-based-pagination-on-task-lists) を参照してください。

---

## これまでの理解: Meridian のルータを gorilla/mux から Gin へ移行  [MID]

### これまでの理解 (改訂 2026-01-14)

元のバックエンドは HTTP ルーティングに `github.com/gorilla/mux` を使用していました。プロジェクトの最初の週に決定されました。`gorilla/mux` はリードエンジニアが以前のプロジェクトから慣れ親しんでおり、`net/http` には不足しているパスパラメータルーティングを提供し、実績があったためです。

これまでの理解は: `gorilla/mux` はこのサイズのプロジェクトに十分であり、大きなフレームワークに比べて表面積が最小限だというものでした。

**何が変わったか:**

Meridian が認証ミドルウェア、リクエスト ID インジェクション、ロギングミドルウェア、Slack Webhook エンドポイントを追加した時点で、チームは `gorilla/mux` の上に約 180 行の手作りミドルウェアインフラを書いていました:

- ミドルウェアチェーンランナー（gorilla/mux にはミドルウェアチェーンが組み込まれていない）
- 認証済みユーザー ID をハンドラに渡すためのコンテキスト伝播ヘルパー
- JSON バインディングヘルパー（各ハンドラで `json.NewDecoder(r.Body).Decode(&req)` を呼び出していた）
- `json.NewEncoder(w).Encode(body)` をラップするレスポンスヘルパー

コードレビューで、このミドルウェアインフラが `gin-gonic/gin` が最初から提供するものを実質的に再構築していることが明らかになりました: `c.ShouldBindJSON`、`c.JSON`、`router.Use()` によるミドルウェア、ルートグループです。チームは Gin に移行し、180 行のインフラを削除し、ミドルウェアグループサポートを獲得しました（これにより認証ミドルウェアをグローバルではなくルートグループごとに適用できるようになりました）。

**修正後の理解:**

原則は「最小限のルーティングライブラリを優先する」ではありません。原則は「プロジェクトが必要とする機能を、使用を意図する抽象レベルで提供するライブラリを優先する」です。`gorilla/mux` はルーティングパラメータだけが必要なプロジェクトには正しい選択です。ミドルウェアグループ、JSON バインディング、レスポンスヘルパーも必要なプロジェクトに対しては、より完全なフレームワークがゼロの手作りコードでそれらを提供します。切り替えコスト（ハンドラのシグネチャを `func(w http.ResponseWriter, r *http.Request)` から `func(c *gin.Context)` に更新すること）は 2 日間の作業でした。振り返れば最初から Gin を使っていれば効率的でしたが、ミドルウェアの表面積が大きくなるまで正しい決定は明らかではありませんでした。

教訓はエコシステム固有です: Go では「ルーティングライブラリ」と「フレームワーク」の差は他のエコシステムより小さいです。Gin は Rails スタイルのフルスタックフレームワークではありません — 専門化された HTTP ツールキットです。「フレームワーク」という言葉が最小限のオプションへの自動的な好みを引き起こすべきではありません; 常に問うべきは「このプロジェクトは最初の 1 年でどのような機能を必要とするか?」です。

### 関連節

- これらの選択が技術的負債として蓄積する前に統制するポリシーについては [ecosystem-fluency → Go Stdlib vs. Third-Party](#go-stdlib-vs-third-party-the-meridian-policy) を参照してください。

---

## コーチイラストレーション（default vs. hints）

> **説明のみ。** 以下は、このドメインのタスクに対して 2 つのコーチングスタイルがどのように異なるかを示す作業事例です。ライブエージェントのコントラクトの一部ではありません。実際のエージェントの動作は `.claude/skills/learn/coach-styles/` のスタイルファイルによって規定されます。

**シナリオ:** 学習者が Meridian に Prometheus メトリクスエンドポイントを追加しており、`github.com/prometheus/client_golang` を使うか、標準ライブラリの `expvar` を使ってシンプルなカウンタを実装するかをエージェントに尋ねます。

**`default` スタイル** — エージェントは標準ライブラリ vs. サードパーティのポリシーを適用します: `expvar` は `GET /debug/vars` で読み取り可能な基本的なカウンタを提供しますが、Meridian の Kubernetes モニタリングスタックが期待するのは Prometheus の公開フォーマット（`/metrics` スクレイプエンドポイント）です。エージェントは `github.com/prometheus/client_golang/prometheus` と `promhttp` をインポートし、`/metrics` にハンドラを登録し、Gin エンジンの既存ルートグループにラップします。`## Learning:` トレーラーが、標準ライブラリが勝つケース（自己完結した操作、外部コンシューマーなし）とサードパーティが正当化されるケース（外部コンシューマー — Prometheus スクレイパー — が特定のフォーマットを要求しており標準ライブラリはそれを再実装なしに生成できない）を説明します。

**`hints` スタイル** — エージェントは決定を示し（`expvar` ではなく `prometheus/client_golang`、なぜならスクレイプコンシューマーがフォーマットを決定するため）、ポリシーに名前を付け（「stdlib vs. サードパーティ: コンシューミングシステムがフォーマットを指定する」）、次のメッセージを出力します:

```
## Coach: hint
Step: Register a Prometheus metrics handler at /metrics using promhttp.Handler().
Pattern: Stdlib vs. third-party — the external consumer (Prometheus scraper) requires
the exposition format; expvar cannot produce it.
Rationale: The policy prefers stdlib unless the gap-filling code would be
non-trivial; reimplementing Prometheus exposition format is non-trivial.
```

`<!-- coach:hints stop -->`

学習者がハンドラを配線してカウンタメトリクスを登録します。次のターンでエージェントはポリシーを再説明することなくフォローアップの質問に答えます。
