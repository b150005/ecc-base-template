> このドキュメントは `.claude/meta/references/examples/data-modeling.md` の日本語訳です。英語版が原文（Source of Truth）です。

---
domain: data-modeling
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: architect
contributing-agents: [architect]
---

> **読み取り専用リファレンス。** このファイルは ECC Base Template に同梱されたサンプルです。実際のプロジェクト上で多くのセッションを重ねた後の、ポピュレートされたナレッジファイルの見た目を示すために提供されています。**あなた自身のナレッジファイルではありません。** あなたのナレッジファイルは `.claude/learn/knowledge/data-modeling.md` に置かれ、エージェントが実際の作業の中で拡充するまでは空の状態で始まります。エージェントは `.claude/meta/references/examples/` 配下を読んだり引用したり書き込んだりしません — このツリーは人間の読者専用です。設計根拠については [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) を参照してください。

---

## このファイルの読み方

各セクションのレベルマーカーは、その想定読者を示します。
- `[JUNIOR]` — 第一原理からの説明。事前知識なしを前提とします
- `[MID]` — このスタックにおける自明でない慣用的な適用方法
- `[SENIOR]` — 非デフォルトのトレードオフの評価。何を諦めたかを明示します

---

## Tasks, Assignments, and Workspaces: The Core Aggregate  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

**データモデル**は、システムが格納するエンティティ、その属性、そしてそれらの関係の集合です。すべての決定を支配する 2 つの問いがあります。何が単一のエンティティを構成するのか、どの関係が独自のテーブルを持つ価値があり、何が埋め込まれるべきか。

ドメイン駆動設計の語彙では、**アグリゲート**は単一のルートがアクセスを制御する形で、1 つの単位としてロード、変更、永続化されるエンティティのクラスターです。アグリゲート境界は一貫性境界です。トランザクションはアグリゲート全体を一貫して変更するか、何も変更しません。

Meridian の中心アグリゲートは**タスク**です。タスクは 1 つのワークスペースに属し、0 個以上のアサイニー、コメント、添付ファイル、締め切りを持ちます。境界の問いは、それらのうちどれをタスク行に埋め込むか、どれが FK でリンクされた別テーブルになるか、どれが完全に別のアグリゲートになるかです。

### Idiomatic Variation  [MID]

Meridian のコアスキーマは 3 つのアグリゲートルート — `workspaces`、`users`、`tasks` — を使い、ユーザーとタスクの多対多に結合テーブルを使います。

```sql
-- workspaces, users, workspace_members elided for brevity:
--   workspaces(id, name, plan_tier, created_at, deleted_at)
--   users(id, email UNIQUE, display_name, created_at, deleted_at)
--   workspace_members(workspace_id FK→workspaces ON DELETE CASCADE,
--                     user_id FK→users ON DELETE CASCADE, role, joined_at)

CREATE TABLE tasks (
    id              UUID        PRIMARY KEY,
    workspace_id    UUID        NOT NULL REFERENCES workspaces(id) ON DELETE RESTRICT,
    title           TEXT        NOT NULL,
    description     TEXT        NOT NULL DEFAULT '',
    status          TEXT        NOT NULL CHECK (status IN ('todo','in_progress','done','archived')),
    deadline_at     TIMESTAMPTZ NULL,
    deadline_tz     TEXT        NULL,
    assignee_count  INTEGER     NOT NULL DEFAULT 0,
    created_by      UUID        NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at      TIMESTAMPTZ NULL
);

CREATE TABLE task_assignments (
    task_id     UUID        NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    assigned_by UUID        NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    PRIMARY KEY (task_id, user_id)
);
```

ON DELETE の挙動は意図的に一様ではありません。`workspace_members` はカスケードします。削除されたワークスペースには意味のあるメンバーがいないからです。`tasks.workspace_id` は RESTRICT です。ワークスペースはタスクを所有している間は削除できないからです。`task_assignments` は `task_id` でカスケードします（タスクのないアサインメントは意味がない）が、`user_id` は RESTRICT です（ユーザーが削除されたときにアサイン履歴を失うことは監査証跡を破壊します）。

### Trade-offs and Constraints  [SENIOR]

`task_assignments` をタスクアグリゲート内の結合テーブルとして扱うこと — 独自のルートとしてではなく — は、アサイニーを含むタスクのロードが単一のリポジトリ呼び出しであることを意味します。この境界が正しいのは、アサインメントが独立したライフサイクルを持たないからです。タスクより前に存在することも、タスクなしにクエリされることも、タスク間で転送されることもできません。アサインメントを別のアグリゲートとして扱うことは、一貫性の利点なしに操作ごとに 2 つのアグリゲートを調整することを呼び出し元に強いるだけです。

コストは、大量のアサインメントアクティビティ（スプリント計画で数百のタスクを再アサイン）がタスクボディと同じアグリゲートに書き込み、`tasks` 行へのロック競合を引き起こすことです。約 50 顧客でピーク時にワークスペースあたり約 200 並行書き込みではボトルネックになりません。なった場合の対応は、アサインメントを独自のアグリゲートに分割し、「タスクは N 人のアサイニーと言っている」と「アサインメントテーブルに N 行ある」の間の結果整合性を受け入れることです — 現在の境界が買い戻すコストです。

Go のドメイン型はこれらのテーブルと 1 対 1 でマップされますが、`tasks.assignee_count` は例外です — 下記の [Denormalized Counters](#denormalized-counters-tasksassignee_count) を参照し、なぜそのカラムが `task_assignments` から導出できるにもかかわらず存在するかを確認してください。

### Related Sections

- [architecture → Repository Pattern](./architecture.md#repository-pattern) — `TaskRepository` インターフェースが `tasks` と `task_assignments` 両方を単一のアグリゲートとして所有する方法。
- [persistence-strategy → Indexing Strategy](./persistence-strategy.md#indexing-strategy) — このスキーマでカーソルページネーションをサポートするインデックス。

### Coach Illustration (default vs. hints)

> **例示目的のみ。** ライブエージェントの契約の一部ではありません。`.claude/skills/learn/coach-styles/` が定義します。

**シナリオ:** 学習者がエージェントに、ユーザーがフィルタリングのためにタスクに短い文字列ラベルを付けられる「タスクタグ」機能を追加するよう依頼します。

**`default` スタイル** — エージェントは `task_tags` 結合テーブル（`task_id`、`tag_name`、`created_at`）を追加するマイグレーション、ドメイン型、リポジトリメソッド（`AddTag`、`RemoveTag`、`ListTagsForTask`）、`(workspace_id, tag_name)` インデックスを作成します。`## Learning:` トレーラーはタグが `tasks` テーブルの PostgreSQL `text[]` カラムではなく結合テーブルに置かれる理由を説明します（配列のクエリ効率はフィルターセットが大きくなると低下します。結合テーブルはクリーンにインデックスされます）。

**`hints` スタイル** — エージェントはマイグレーションのスキャフォールド（カラム名と型のみ）と空のリポジトリメソッドシグネチャを出力し、パターン（多対多の結合テーブル）とトレードオフ（クエリ効率対行数）に名前を付ける `## Coach: hint` ブロックを続けます。学習者が制約とリポジトリのボディを実装します。

---

## ULID Identifiers Over Auto-Increment Integers  [MID]

### First-Principles Explanation  [JUNIOR]

**主キー**は各行を一意に識別します。3 つのファミリーが主流です。オートインクリメントの整数（`SERIAL`、`BIGSERIAL`）、ランダム UUID（v4）、時刻順の識別子（UUID v7、ULID、KSUID）。それぞれ異なるトレードオフをとります。

- **オートインクリメント整数**はコンパクトで作成順です。コストは中央シーケンス割り当てです — すべての INSERT がデータベースと調整し、マルチリージョンまたはシャーディングされたデプロイメントではレイテンシの下限になります。また量を漏らします。URL 内の `task_id` の値を数えれば、競合他社はタスクの総数を推測できます。
- **ランダム UUID（v4）**は調整を必要としませんが順序がありません。B ツリーに挿入するとインデックスが断片化します。各挿入がランダムな位置に着地するためです。書き込みスループットと範囲スキャンのキャッシュ効率が低下します。
- **時刻順の識別子**は両方の問題を解決します。128 ビットの識別子空間（調整不要）と、上位ビットがタイムスタンプから導出されること（挿入が追記される）。ULID は 48 ミリ秒ビット + 80 ランダムビットを 26 文字の base32 文字列としてエンコードし、UUID v7 は 48 ミリ秒ビット + 74 ランダムビットを標準 UUID 形式でエンコードします。

### Idiomatic Variation  [MID]

Meridian は ULID を PostgreSQL の `UUID` カラムとして保存します。128 ビットの ULID は UUID ストレージ形式とビット互換なため、データベースは `UUID` として認識し、アプリケーションはクライアントへのシリアライズ時に ULID 形式の文字列として認識します。

```go
// domain/id.go
type TaskID uuid.UUID

func NewTaskID() TaskID {
    return TaskID(ulid.Make().UUID())  // ULID bits stored in UUID column
}

func (id TaskID) String() string {
    return ulid.ULID(id).String()       // 26-char base32 in API responses
}
```

スキーマ（コアアグリゲート参照）はすべて `UUID PRIMARY KEY` を使います。DDL には ULID の痕跡はありません。この選択はドメインパッケージの ID コンストラクタとシリアライザに強制されたランタイム規約です。API レスポンスは ULID 形式（`01HQXR4Z8K3M2N1P6V7W8Y9X0A`）を提示します — 短く、大文字小文字を区別せず、`0`/`O` の曖昧さがありません — 一方、内部ログと `psql` はデフォルトでハイフン付き UUID 形式を使います。

### Trade-offs and Constraints  [SENIOR]

UUID カラムに ULID を格納するアプローチは、ネイティブの UUID v7 と比較して 2 つのものを諦めます。第一に、エンコードの分割（DB 内のビット、API 内の base32）はすべてのシリアライザが形式を変換することを意味し、ログとデータベース状態を相互参照するオペレーターはどのサーフェスがどの形式を使うかを学ばなければなりません。第二に、`oklog/ulid` はサードパーティの依存です。UUID v7（RFC 9562 で標準化済み）は同じ時刻順を第一者のツールで提供します。

Meridian が 2025 年に v7 ではなく ULID を選んだのは、v7 がまだドラフトでライブラリサポートが一貫していなかったからです。この決定は ADR-007（識別子形式）にドキュメント化されています。今日からグリーンフィールドのスキーマを開始し、Go、TypeScript、Postgres のツール全体で v7 サポートが確認された場合、v7 がデフォルトになるでしょう。既存スキーマの移行は有限（ストレージ形式は同一）ですが動機がありません。

### Related Sections

- [persistence-strategy → Index Locality](./persistence-strategy.md#index-locality) — 時刻順 ID が `tasks` 主キーインデックスの B ツリー断片化を軽減する理由。
- [api-design → Resource Hierarchy](./api-design.md#resource-hierarchy-tasks-and-assignments) — タスク ID が URL 内で ULID 形式として現れる方法。

---

## Soft Deletes with `deleted_at` Versus Hard Deletes  [MID]

### First-Principles Explanation  [JUNIOR]

**ソフトデリート**はカラム（通常 `deleted_at`）を設定することで行を削除済みとマークし、実際には削除しません。**ハードデリート**は行を完全に削除します。トレードオフは監査可能性対ストレージコストとクエリの単純さです。ソフトデリートは履歴を保持します（誤って削除されたタスクを復元でき、6 ヶ月後の監査で何が存在していたかを確認できます）が、ストレージとすべての読み取りに `WHERE deleted_at IS NULL` フィルタリングの複雑さを伴います。ハードデリートはストレージをすぐに解放しますが履歴を破壊します。

一般的な中間案: 復元と監査に価値があるユーザー向けエンティティ（タスク、コメント）はソフトデリートし、履歴に価値がなくストレージをすぐに回収すべき補助エンティティ（レート制限カウンター、冪等性キー、期限切れセッション）はハードデリートします。

### Idiomatic Variation  [MID]

Meridian は `tasks`、`users`、`workspaces`、`comments` をソフトデリートします。`task_assignments`、`idempotency_keys`、`sessions` はハードデリートします。このポリシーはリポジトリ層の規約で強制されます。

```go
// repository/task.go — soft delete sets deleted_at and writes an audit row in one tx
func (r *postgresTaskRepository) Delete(ctx context.Context, id, actorID uuid.UUID) error {
    return r.withTx(ctx, func(tx *sql.Tx) error {
        if _, err := tx.ExecContext(ctx, `
            UPDATE tasks SET deleted_at = now(), updated_at = now()
            WHERE id = $1 AND deleted_at IS NULL
        `, id); err != nil {
            return err
        }
        _, err := tx.ExecContext(ctx, `
            INSERT INTO audit_log (entity_type, entity_id, action, actor_id, occurred_at)
            VALUES ('task', $1, 'delete', $2, now())
        `, id, actorID)
        return err
    })
}
```

リポジトリ層のすべての読み取りクエリには `WHERE deleted_at IS NULL` が付きます（[architecture → Repository Pattern](./architecture.md#repository-pattern) の `Get` の例を参照）。

追記のみの `audit_log` テーブルは状態遷移の耐久性のある記録です。ソフトデリートされた `tasks` 行と `audit_log` エントリの組み合わせが、「何が存在して削除されたか」のビューと「誰がいつ何をしたか」のビューの両方を提供します。

GDPR 消去権リクエストに対しては、`users` 行はハードデリートされ、それを参照する監査エントリはトゥームストーンユーザー ID に匿名化されます。このポリシーは「ユーザーアクションによる削除」（ソフト）と「消去リクエストによる削除」（ハードプラス匿名化）を区別します。

### Trade-offs and Constraints  [SENIOR]

`WHERE deleted_at IS NULL` フィルタの最大のコストは忘れることです。フィルタを省いた一度きりのレポートクエリは削除済み行を黙って含みます。数値がアプリケーションの表示と乖離します。Meridian はこれを、フィルタを適用するリポジトリメソッドのみを公開すること（サービスコードからの生 SQL なし）と、新しいリポジトリクエリのすべてにその句があることをレビューで確認することで軽減しています。`WHERE deleted_at IS NULL` の部分インデックスは、削除済み行をインデックス化することなく一般的なクエリを高速に保ちます。

Postgres の行レベルセキュリティはフィルタをデータベースに強制できますが、Meridian は RLS を採用していません。アクセス制御をアプリケーションからデータベースに移し、接続プーリングを複雑にし、テストフィクスチャの構築を難しくします。この規模では規約プラスレビューのアプローチで十分です。

### Related Sections

- [error-handling → Domain Error Type Hierarchy](./error-handling.md#domain-error-type-hierarchy) — ソフトデリートされた行がリクエストされた場合に `domain.ErrNotFound` が返される方法。
- [security-mindset → GDPR Erasure](./security-mindset.md#gdpr-right-to-erasure) — ソフトデリートのデフォルトをオーバーライドするハードデリートプラス匿名化ポリシー。

---

## Denormalized Counters: `tasks.assignee_count`  [SENIOR]

### Idiomatic Variation  [MID]

`tasks` テーブルは `SELECT COUNT(*) FROM task_assignments WHERE task_id = $1` から正確に導出できるにもかかわらず、`assignee_count` 整数カラムを持っています。これは意図的な非正規化です。2 つの理由が動機です。

第一に、プロダクト内で最も読み込まれる画面であるタスクリストビューが、表示ウィンドウ内のすべてのタスク（約 50 タスク）のアサイニー数バッジを表示します。キャッシュされたカウントなしでは、リストは `GROUP BY` 集計の JOIN か、タスクごとのカウントクエリ（N+1 アンチパターン）になります。キャッシュされたカウントがあれば、リストはタスクあたり 1 行を読むだけです。

第二に、カウントはアサインメントの INSERT または DELETE と同じトランザクション内で同期的に更新されます。すべての書き込みが `AddAssignee` または `RemoveAssignee` を通るため、アプリケーションコードがリポジトリをバイパスしない限りカウントがずれることはありません。

```sql
-- inside one transaction, after INSERT INTO task_assignments(...)
UPDATE tasks
SET assignee_count = (SELECT COUNT(*) FROM task_assignments WHERE task_id = $1),
    updated_at = now()
WHERE id = $1;
```

サブクエリは同じトランザクション内で新しくインサートされたアサインメント行を読むため、キャッシュされたカウントはコミット時に常に正確です。

### Trade-offs and Constraints  [SENIOR]

非正規化はすべての書き込みに払われるコストです。各 `AddAssignee` または `RemoveAssignee` は親タスクへの行レベルロックを伴う 2 ステートメントトランザクションになるため、同じタスクへの並行アサインメントは直列化されます。Meridian の規模では、同じタスクが 1 ミリ秒以内に 2 人のユーザーによってアサインされることはめったにないため許容範囲です。発生した場合でも、2 番目の書き込み者は数ミリ秒待つだけです。

読み取りクエリでカウントを計算するという代替案は、タスクの読み取り対書き込み比率が約 200:1 であるとして却下されました — 共通の読み取りパスのコストで稀な書き込みパスを最適化するのは間違った方向です。非同期のバックグラウンド計算も却下されました。「バッジは 3 と言っているが 2 人しか名前が見えない」という窓が開くからです。同期的な非正規化は 1 回余分な書き込みごとの UPDATE のコストでカウントを正確に保ちます。

この決定は、数百のタスクをループでバルクアサインする機能（スプリントインポート機能）が出荷された場合に再検討しなければなりません。基準: 単一ワークスペースの `task_assignments` への持続的な書き込み量が毎秒 50 インサートを超えた場合。その時点でカウント更新のバッチ処理か、読み取り時の導出への移行が正当化されます。

### Related Sections

- [performance-intuition → N+1 Query Patterns](./performance-intuition.md#n-plus-1-query-patterns) — 読み取り時の集計という代替案が却下された理由。
- [persistence-strategy → Transaction Boundaries](./persistence-strategy.md#transaction-boundaries) — 上記の 2 つのステートメントをラップする `withTx` の仕組み。

---

## Temporal Modeling: Deadlines, Time Zones, and Recurrence  [MID]

### First-Principles Explanation  [JUNIOR]

時刻データには、スキーマが区別して保持しなければならない 3 つの独立した次元があります。**インスタント**（普遍的なタイムライン上の一点）、**ウォールクロック時刻**（特定のカレンダー上の時刻と分）、**タイムゾーン**（両者の間のマッピングルール）。3 つのうち 1 つだけを保存したスキーマは、他から回復不能な情報を失います。

「サンパウロで金曜日の午後 5 時」はウォールクロックプラスゾーンです。入力時に UTC インスタントに変換するとゾーンが破棄されます。そのため、ブラジルがこの金曜日までの間に夏時間ルールを変更した場合（実際に変更したことがあります）、保存されたインスタントはもはや「サンパウロで金曜日の午後 5 時」ではありません。ウォールクロックプラスゾーンだけを保存すると、「何が期限切れか？」のすべてのクエリが行ごとに変換を強いられます。

### Idiomatic Variation  [MID]

Meridian の `tasks.deadline_at` カラムは `TIMESTAMPTZ`（インスタント）で、コンパニオンの `tasks.deadline_tz` カラムは IANA タイムゾーン名（`America/Sao_Paulo`）です。両方が一緒に書き込まれ、どちらも互いから導出できません。

```sql
deadline_at  TIMESTAMPTZ NULL,
deadline_tz  TEXT        NULL,
CHECK ((deadline_at IS NULL) = (deadline_tz IS NULL))
```

CHECK 制約はペアリングを強制します。両方が設定されているか、どちらも設定されていないかのどちらかです。インスタントは期限切れチェッククエリ（`WHERE deadline_at < now()`）を駆動し、ゾーンは UI 表示と通知タイミングを駆動します（「明日が締め切り」リマインダーは UTC の午前 9 時ではなくローカルの午前 9 時に発火します）。カレンダーインテグレーションは両方のフィールドをエクスポートするため、外部カレンダーは締め切りを、締め切りの作成ゾーンとは異なる可能性があるユーザーの優先ゾーンでレンダリングできます。

繰り返しの締め切りは RFC 5545 RRULE 文字列を保存する別の `recurrence_patterns` テーブルに置かれます。バックグラウンドジョブは前のものが完了したときに次の具体的なインスタンスをマテリアライズし、作成時にすべての将来の発生を保存する N インスタンス問題を回避します。

### Trade-offs and Constraints  [SENIOR]

インスタントとゾーンを別々に保存することは、アプリケーションがすべてのドメイン型、API レスポンス、フォームでそれらをペアに保つことを要求します。CHECK 制約は書き込み時のスキーマ違反を捕捉しますが、アプリケーション層のコントラクトは暗黙的です。

代替案 — `TIMESTAMPTZ` だけを保存し、作成ユーザーのプロファイルからゾーンを推論する — は、作成ユーザーのゾーンが締め切りの意図されたゾーンではないとして却下されました。東京のユーザーが「サンパウロチームのために金曜日の午後 5 時」と作成する場合、サンパウロのゾーンが必要です。プロファイルゾーンのフォールバックは黙って間違ったリマインダー時刻を生成します。明示的なペアリングのコストはエンジニアリングに課せられます。プロファイルフォールバックはユーザーに課せられます。

### Related Sections

- [ecosystem-fluency → Time Handling in Go](./ecosystem-fluency.md#time-handling-in-go) — リポジトリがインスタントとウォールクロック表現の間で変換するために使う `time.Time` と IANA ゾーン API。

---

## Schema Evolution: Non-Nullable Columns on a Large Table  [SENIOR]

### Idiomatic Variation  [MID]

ダウンタイムなしでライブ PostgreSQL デプロイメントの 5,000 万行テーブルにデフォルト値付きの非 NULL カラムを追加するには注意が必要です。Postgres 11 以降は定数デフォルトをメタデータとして保存して書き直しを回避しますが、関数デフォルト（`gen_random_uuid()` など）はテーブルをロックする完全なテーブル書き直しを引き起こします。

Meridian の `tasks` テーブルは 2025 年末に約 5,000 万行に達しました。`tasks.assignee_count` を追加したマイグレーションは、ダウンタイムを回避するために 4 ステップで構成されました。

```sql
-- Migration step 1 (deployed first): add column as NULL with no default
ALTER TABLE tasks ADD COLUMN assignee_count INTEGER NULL;

-- Application step 2 (next deploy): writers populate column on every UPDATE; old rows NULL

-- Migration step 3 (background job): backfill in batches of 10,000
UPDATE tasks SET assignee_count = (SELECT COUNT(*) FROM task_assignments WHERE task_id = tasks.id)
WHERE id IN (SELECT id FROM tasks WHERE assignee_count IS NULL ORDER BY id LIMIT 10000);

-- Migration step 4 (after backfill complete): tighten the constraint
ALTER TABLE tasks ALTER COLUMN assignee_count SET DEFAULT 0;
ALTER TABLE tasks ALTER COLUMN assignee_count SET NOT NULL;
```

4 ステップはスキーマ変更をデータのバックフィルと制約の強化から切り離します。各ステップは独立して安全で可逆的です。アプリケーションは全体を通じて正しく動作します。

### Trade-offs and Constraints  [SENIOR]

4 つのデプロイにわたる 4 ステップは、新しいカラムを必要とする機能が 4 番目のデプロイが完了するまで出荷できないことを意味します — エンジニアリング時間ではなく、デプロイウィンドウとバックフィル期間が支配するカレンダータイムで約 2 週間。1 ステップでのマイグレーションによるメンテナンスウィンドウという代替案は、Meridian の SLA が月間 99.9% の稼働時間（月あたり約 43 分の許容ダウンタイム）を約束しているため却下されました。1 時間のウィンドウは月間予算全体を使い切ります。

段階的アプローチのコストは、マイグレーションごとの複雑さです。4 つの PR、4 つのデプロイ、監視するバックフィルジョブ、そして一部の行で NULL を許容しなければならないウィンドウ。小さなテーブルでは日常的なマイグレーションが大きなテーブルでは数週間のプロジェクトになります。`tasks` の後続のマイグレーションは `docs/en/runbooks/large-table-migration.md` に成文化されたこのパターンをデフォルトで踏みます。カラムの削除は逆のパターンに従います。読み取りを止め、書き込みを止め、DROP する — リーダーとライターが DROP のコミット前にカラムを外れていなければなりません。

### Related Sections

- [release-and-deployment → Migration Discipline](./release-and-deployment.md#migration-discipline) — 4 ステップマイグレーションが依存するデプロイステージング規約。
- [operational-awareness → Backfill Job Monitoring](./operational-awareness.md#backfill-job-monitoring) — ステップ 3 のバックフィルを観察し中断時に再開する方法。

---

## Prior Understanding: Auto-Increment Primary Keys  [MID]

> Superseded 2025-09-12: 元のスキーマはすべてのテーブルで `BIGSERIAL` 主キーを使っていました。これは Meridian のロードマップにとって誤りでした。マルチリージョンデプロイメント（2025 年末に計画）は調整レイテンシなしに中央シーケンスを共有できず、URL 内の ID は列挙できる人に誰でもタスク量を漏らします。

> 元のスキーマ（ターゲットデプロイメントモデルに対して誤り）:
> ```sql
> CREATE TABLE tasks (id BIGSERIAL PRIMARY KEY, workspace_id BIGINT NOT NULL, ...);
> -- API response: { "id": 8472, "title": "...", ... }   // ID is enumerable
> ```

**訂正後の理解:**

Meridian は 2025 年 9 月、マルチリージョンロールアウト前に `BIGSERIAL` から ULID 値を持つ `UUID` に移行しました。移行は段階的でした。新しい `uuid_id` カラムに新規行と既存行に `ulid.Make()` を設定し、外部キーを複製し、複数週間の検証の後に整数カラムを削除して UUID カラムを `id` に改名しました。

元の `BIGSERIAL` 設計の 3 つの問題が変更を強いました。

1. **マルチリージョン書き込み。** 中央 PostgreSQL シーケンスは定義上シングルリージョンです。リージョンごとのストライドは動作しますが、ストライドが重複するリージョンが外部キーの不変式を黙って壊すという運用上の危険性をもたらします。UUID 形式の ID はこの問題を回避します。
2. **情報漏洩。** URL 内のタスク ID `8472` は、Meridian がせいぜい 8,472 のタスクを処理したことを教えます。競合他社はベンダーの規模を推測するために ID を列挙します。ULID は作成時刻を漏らしますが総量は漏らしません。
3. **挿入時のホットスポット。** 単調増加する主キーは B ツリーの右端に書き込み負荷を集中させます。時刻順の ULID は書き込みの局所性を保ちつつリーフページ全体に負荷を分散させます。

移行には約 3 エンジニア週かかりました。強制要因はマルチリージョンロードマップでした。それがなければ、チームは `BIGSERIAL` を使い続けて漏洩を受け入れていたでしょう。パターンとして: スキーマ決定はシングルリージョンでは問題ないように見えても、ロードマップがスキーマを最初に設計したときには存在しなかった制約を追加すると誤りになります。スキーマの選択は現在ではなくロードマップに対して老化します。

### Related Sections

- [data-modeling → ULID Identifiers](#ulid-identifiers-over-auto-increment-integers) — BIGSERIAL を置き換えた現在の ID 戦略。
- [architecture → Multi-Region Considerations](./architecture.md#multi-region-considerations) — 移行を促したデプロイメントモデルの制約。
