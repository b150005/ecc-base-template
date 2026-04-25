> このドキュメントは `docs/en/learn/examples/persistence-strategy.md` の日本語訳です。英語版が原文（Source of Truth）です。

---
domain: persistence-strategy
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: architect
contributing-agents: [architect, implementer]
---

> **読み取り専用リファレンス。** このファイルは ECC Base Template に同梱された実装例であり、実際のプロジェクトの多くのセッションを経て積み上がったナレッジファイルがどのような姿になるかを示しています。これはあなた自身のナレッジファイルでは**ありません**。あなた自身のナレッジファイルは `learn/knowledge/persistence-strategy.md` にあり、実際の作業においてエージェントが内容を拡充するまでは空の状態です。エージェントは `docs/en/learn/examples/` 配下のファイルを読み込んだり、引用したり、書き込んだりすることは一切ありません。このツリーは人間の読者専用です。設計の背景については [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) を参照してください。

---

<a id="how-to-read-this-file"></a>
## このファイルの読み方

各セクションのレベルマーカーは想定読者を示しています。
- `[JUNIOR]` — 第一原理からの説明。事前知識を前提としません。
- `[MID]` — このスタックにおける、一見しただけでは気づきにくい慣用的な応用。
- `[SENIOR]` — デフォルト以外のトレードオフの評価。何を諦めるかを明示します。

---

<a id="postgres--redis-split-what-lives-where"></a>
## Postgres + Redis の分割：何をどこに置くか  [JUNIOR]

<a id="first-principles-explanation--junior-"></a>
### 第一原理からの説明  [JUNIOR]

バックエンドサービスは通常、質的に異なる 2 種類のストレージ機能を必要とします。**耐久性・クエリ可能・トランザクション対応**のストレージはビジネスレコード（タスク、ユーザー、監査履歴）を保持します。リレーショナルデータベースはその典型的な用途に合っています。**高速・短命**のストレージは、毎リクエストで読み取り負荷が高いか短命な状態（セッショントークン、レートリミットカウンター、重複排除キー、ホットパスキャッシュ）を保持します。リレーショナルデータベースでも 2 番目の負荷に対応できますが、そうすることで最もコストのかかる耐久性とクエリ能力が無駄になります。インメモリのキーバリューストアは、単一キーアクセスを桁違いに高速に処理し、計画的なスケジュールでデータを忘れることも厭いません。この分割によって、各ストアは設計されたアクセスパターンに合った用途に使われます。コストは運用面（2 つの監視サーフェス、2 つの障害モード）にありますが、ベネフィットは各ストアが得意なことに専念できる点です。

<a id="idiomatic-variation--mid-"></a>
### 慣用的なバリエーション  [MID]

Meridian のルール：**PostgreSQL が信頼の源泉（Source of Truth）であり、Redis には再構築できないものは何も置かない。** Redis のすべての状態は、Postgres データから導出可能であること、リクエスト入力から再計算可能であること、またはビジネス上の損失なしに期限切れにできることが条件です。深夜 3 時に Redis を完全フラッシュしても、ユーザーに見えるレコードが破損してはなりません。

| 懸念事項 | ストア | 根拠 |
|---------|-------|------|
| タスク、ワークスペース、ユーザー、アサイン、監査ログ | Postgres | 耐久性あり；リレーショナル；トランザクション対応 |
| 冪等性キー（Slack webhook イベント ID） | Redis（24 時間 TTL） | 損失 = せいぜい 1 件の重複通知 |
| レートリミットカウンター（スライディングウィンドウ） | Redis（60 秒 TTL） | 損失 = 一時的な超過バースト |
| ログアウト後の JWT リフレッシュ拒否リスト | Redis（JWT 有効期限まで） | 損失 = ログアウト済みトークンが自然失効まで有効になる |
| ワークスペースメタデータキャッシュ（リードスルー） | Redis（5 分 TTL） | 損失 = 1 回の低速リクエストでキャッシュが再ウォームされる |

Redis に**置かないもの**：課金状態、タスクコンテンツ、アサインレコード、監査履歴。これらが失われるとユーザーが驚いたりサポートチケットが発生するような内容は、Postgres のみに置きます。

<a id="trade-offs-and-constraints--senior-"></a>
### トレードオフと制約  [SENIOR]

キャッシュ層では**ステール読み取り**が発生します。ワークスペースの名前を変更した管理者は、隣接するページで一時的に古い名前を見ることがあります。ターゲットを絞った無効化（書き込みのたびに影響を受けるキーに対して Redis `DEL` をエンキューする）によって低減できますが、完全には排除できません。チームはこのパスで強い整合性を追い求めるよりも、一時的なステールネスを受け入れています。

2 つの代替案は却下されました。キャッシュなしのアプローチは、2026 年 Q1 の 200 席顧客へのロールアウト中に Postgres のコネクションプール負荷を許容範囲を超えて押し上げました。ライトスルーは書き込みレイテンシを倍増させ、新たな障害モード（Postgres は成功したが Redis が失敗した場合どうするか）を導入しました。ターゲット無効化を伴うリードスルーが中間点となりました。

### 関連セクション

- [architecture → Hexagonal Split](./architecture.md#hexagonal-split) を参照してください。リポジトリ層が Postgres と Redis の両方のアクセスをインターフェースの背後にカプセル化する方法について説明しています。
- [error-handling → Idempotent Retry on the Slack Webhook](./error-handling.md#idempotent-retry-on-the-slack-webhook) を参照してください。冪等性レイヤーを支える Redis `SET NX` パターンについて説明しています。
- [api-design → Idempotency Key Handling](./api-design.md#idempotency-key-handling) を参照してください。この分割を消費する HTTP サーフェスについて説明しています。

---

<a id="indexing-strategy-on-the-tasks-table"></a>
## tasks テーブルのインデックス戦略  [MID]

<a id="first-principles-explanation--junior--1"></a>
### 第一原理からの説明  [JUNIOR]

リレーショナルデータベースは、インデックスがなくても全行をスキャンすることであらゆるクエリに答えられますが、スキャンコストはテーブルサイズとともに線形に増加します。**インデックス**は、一致する行を対数時間で特定する別の B ツリーです。コストは、書き込みのたびにすべてのインデックスを更新しなければならないこと、そして各インデックスがディスクとメモリを占有することです。使われていないインデックスは純粋なオーバーヘッドです。

<a id="idiomatic-variation--mid--1"></a>
### 慣用的なバリエーション  [MID]

`tasks` テーブルは全顧客にわたって約 5,000 万行を保持しています。Meridian が維持するインデックスは次のとおりです。

```sql
CREATE TABLE tasks (
    id            UUID PRIMARY KEY,
    workspace_id  UUID NOT NULL REFERENCES workspaces(id),
    title         TEXT NOT NULL,
    assignee_id   UUID REFERENCES users(id),
    status        TEXT NOT NULL,  -- 'active' | 'archived' | 'deleted'
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    archived_at   TIMESTAMPTZ,
    deleted_at    TIMESTAMPTZ
);

CREATE INDEX tasks_workspace_created_idx
    ON tasks (workspace_id, created_at DESC, id DESC)
    WHERE deleted_at IS NULL;

CREATE INDEX tasks_assignee_status_idx
    ON tasks (assignee_id, status)
    WHERE deleted_at IS NULL AND assignee_id IS NOT NULL;

CREATE INDEX tasks_workspace_status_idx
    ON tasks (workspace_id, status)
    WHERE deleted_at IS NULL;
```

すべてのインデックスは `WHERE deleted_at IS NULL` による**部分インデックス**です。ソフトデリートされた行はインデックスストレージから完全に除外されます。それらを必要とする監査エクスポートジョブは、ヒープを直接スキャンします。複合インデックス `(workspace_id, created_at DESC, id DESC)` は、[api-design → Cursor-Based Pagination on Task Lists](./api-design.md#cursor-based-pagination-on-task-lists) のカーソルページネーションクエリに直接対応しており、列の順序は `WHERE` および `ORDER BY` と正確に一致しています。`assignee_id` インデックスは null を除外しています。これは、タスクの大半が作成時に未割り当てであるためで、部分インデックスによってインデックスサイズを約 40% 削減しています。

<a id="trade-offs-and-constraints--senior--1"></a>
### トレードオフと制約  [SENIOR]

Meridian が検討したが**作成しなかった**インデックス：

- **`title` 全文検索 GIN インデックス。** 2025 年 Q4 にプロダクトから要求がありました。却下された理由は、tasks が最も書き込み頻度の高いテーブルであること（`title` が変わると GIN インデックスの書き込みコストが約 3 倍になる）と、5,000 万行全体を対象にした全文検索は、1 ワークスペースの 1 万件のタスクをフィルタリングする前にグローバルなポスティングを読み込むためです。検索は、5 分遅延でワークスペースごとの転置インデックスをマテリアライズする別の Postgres バックエンドサービスにルーティングされました。受け入れたトレードオフ：直近 5 分以内に編集されたタイトルはまだマッチしません。
- **`updated_at` インデックス。** ホットパスのクエリで `updated_at` による並び替えをするものはありません。インデックスを追加しても、存在しないクエリのために書き込みコストがかかるだけです。
- **ステータス別インデックス（`tasks_active_idx`、`tasks_archived_idx`）。** 複合インデックス `(workspace_id, status)` はステータスフィルタリングをカバーしており、選択性も高くなっています。単一列のステータスインデックスは冗長として却下されました。

ルール：インデックスは、本番相当のデータに対する `EXPLAIN ANALYZE` が p95 クエリレイテンシを 99 パーセンタイルのワークスペースサイズで 50ms 以内に収めるために必要であることを示した場合にのみリリースされます。

### 例（Meridian）

`tasks_workspace_created_idx` に対するカーソルページネーションクエリのプランは、複合インデックスをエンドツーエンドで使用します（`WHERE` は先頭の `workspace_id` を使用し、行タプルは `(created_at, id)` を使用）。実行時間は約 2ms に収まっています。複合インデックスを 2 つの単一列インデックスに置き換えると、同じデータで約 80ms に退行します。

### 関連セクション

- [api-design → Cursor-Based Pagination on Task Lists](./api-design.md#cursor-based-pagination-on-task-lists) を参照してください。複合インデックス設計を駆動するクエリパターンについて説明しています。
- [error-handling → Boundary Translation: Postgres to Domain Errors](./error-handling.md#boundary-translation-from-postgres-to-domain-errors) を参照してください。`(workspace_id, external_slug)` のユニークインデックス（上記には示していません）が生成する `23505` ユニーク違反の変換について説明しています。

---

<a id="transaction-boundaries-live-in-services-not-repositories"></a>
## トランザクション境界はサービス層に置く。リポジトリ層には置かない  [MID]

<a id="first-principles-explanation--junior--2"></a>
### 第一原理からの説明  [JUNIOR]

データベースの**トランザクション**は複数の書き込みをグループ化し、すべてコミットするかすべてロールバックするかのどちらかになります。これは、概念的に一体のものである複数行にわたって（タスクとそのアサイン、アーカイブとその監査エントリ）不変条件を保持するためのリレーショナルデータベースの仕組みです。レイヤー化されたサービスにおける設計上の問題は、**トランザクション境界をどこに置くか**です。リポジトリがメソッドごとに独自のトランザクションを開くと、2 つのリポジトリにまたがる複数ステップの操作が 1 つを共有できません。サービスがトランザクションを開いてリポジトリにハンドルを渡すと、リポジトリはトランザクションのライフサイクルに結合されてしまいます。

<a id="idiomatic-variation--mid--2"></a>
### 慣用的なバリエーション  [MID]

Meridian はトランザクション境界を**サービス**層に置いています。リポジトリメソッドは、プールされたコネクションとアクティブなトランザクションの両方を満たすインターフェースを受け取るため、同じメソッドがトランザクションの内外どちらでも動作します。

```go
// repository/task.go — dbtx インターフェースを受け取り、具体的なプールは受け取らない
type dbtx interface {
    QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
    Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error)
}

func (r *postgresTaskRepository) ArchiveWithTx(ctx context.Context, tx dbtx, id uuid.UUID) error {
    _, err := tx.Exec(ctx, `UPDATE tasks SET archived_at = now(), status = 'archived' WHERE id = $1`, id)
    return translatePostgresError(err)
}

// service/task.go
func (s *TaskService) ArchiveWithAuditEntry(ctx context.Context, taskID, callerID uuid.UUID) error {
    tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.ReadCommitted})
    if err != nil {
        return err
    }
    defer tx.Rollback(ctx) // Commit が成功した場合は no-op
    if err := s.tasks.ArchiveWithTx(ctx, tx, taskID); err != nil {
        return err
    }
    if err := s.audit.RecordWithTx(ctx, tx, callerID, "task.archive", taskID); err != nil {
        return err
    }
    return tx.Commit(ctx)
}
```

単一ステートメントの操作では、サービスはプールを直接使用するトランザクションなしのリポジトリメソッドを呼び出します。リポジトリは両方の形（`Archive` と `ArchiveWithTx`）を公開しており、重複によって呼び出し元がトランザクションスコープについて明示的に表現できます。

<a id="trade-offs-and-constraints--senior--2"></a>
### トレードオフと制約  [SENIOR]

サービスが所有するトランザクションは、サービス層がリポジトリが隠してくれるはずのデータベースのセマンティクス（分離レベル、デッドロックのリトライ、読み取り対書き込みトランザクション）を理解することを強います。チームがこれを受け入れた理由は、代替案であるリポジトリが所有するトランザクションでは、集約をまたぐ書き込みが 1 つのリポジトリ内に収まらなければならない（アグリゲートごとのリポジトリという原則に違反する）か、部分失敗時の手動補償を伴う別々のトランザクションに分割しなければならない（原子性に違反する）かのどちらかになるためです。

強制ケース：タスクのアーカイブと監査ログエントリの書き込みは、成功するか失敗するかのどちらかでなければなりません。アーカイブがコミットされて監査エントリが失敗すると、Meridian にはコンプライアンス上の欠陥が生じます。サービスが所有するトランザクションはこれをアトミックにしますが、リポジトリが所有するトランザクションではそれができません。ルール：操作が異なる集約の複数テーブルに書き込む場合、サービスがトランザクションを開きます。単一テーブルへの書き込みはトランザクションなしのメソッドを使用します。

### 関連セクション

- [architecture → Repository Pattern](./architecture.md#repository-pattern) を参照してください。このトランザクションポリシーが機能するレイヤー分割について説明しています。
- [error-handling → Boundary Translation: Postgres to Domain Errors](./error-handling.md#boundary-translation-from-postgres-to-domain-errors) を参照してください。サービスがコミットするかどうかを決定する前に `ArchiveWithTx` 内で実行される SQLSTATE 変換について説明しています。

---

<a id="connection-pooling-with-pgxpool"></a>
## pgxpool によるコネクションプーリング  [MID]

<a id="first-principles-explanation--junior--3"></a>
### 第一原理からの説明  [JUNIOR]

PostgreSQL への TCP 接続を開いて認証するには約 30〜50ms かかります。リクエストごとに新しいコネクションを開くサービスは、その大半の時間をコネクションの設定に費やすことになります。**コネクションプール**は少数のオープンなコネクションを維持し、各リクエストはその中の 1 つを借りて返します。重要なサイジングパラメータは、**コネクションの最大数**と**アイドルタイムアウト**の 2 つです。最大数はアプリケーションレプリカ数で割った Postgres 自身の `max_connections` を考慮しなければなりません。10 個の Pod がそれぞれ 50 接続を保持している場合、200 接続の Postgres は 11 個目の Pod の最初のクエリを拒否します。

<a id="idiomatic-variation--mid--3"></a>
### 慣用的なバリエーション  [MID]

Meridian は `jackc/pgx/v5` の `pgxpool` を使用しています。

```go
func NewPool(ctx context.Context, dsn string) (*pgxpool.Pool, error) {
    cfg, err := pgxpool.ParseConfig(dsn)
    if err != nil {
        return nil, err
    }
    cfg.MaxConns = 25
    cfg.MinConns = 5
    cfg.MaxConnLifetime = 30 * time.Minute
    cfg.MaxConnIdleTime = 5 * time.Minute
    cfg.HealthCheckPeriod = 1 * time.Minute
    return pgxpool.NewWithConfig(ctx, cfg)
}
```

`MaxConns = 25` は、本番 K8s `Deployment` が 6 レプリカで動作することと組み合わせられています。6 × 25 = 150 接続となり、マネージド Postgres の `max_connections = 200` に余裕をもって収まっています。50 接続の余裕はマイグレーションジョブ、アナリティクスレプリカ、`psql` デバッグセッション用に確保されています。`MaxConnLifetime = 30 minutes` は、コネクションを定期的にクローズして再オープンすることで、計画されたフェイルオーバー（DNS を再ルーティングする）がアプリケーションの再起動なしに反映されるようにします。`HealthCheckPeriod = 1 minute` は、アイドルなコネクションに対してバックグラウンドで `SELECT 1` を実行し、ネットワーク分断が次のリクエスト時ではなく素早く検出されるようにします。

<a id="trade-offs-and-constraints--senior--3"></a>
### トレードオフと制約  [SENIOR]

`MaxConns = 25` は意図的なものです。Postgres のパフォーマンスは、物理 CPU コア数を超えるとコネクション数に比例してスケールしません。コネクション数が多いと、Postgres 内部でロック競合とコンテキストスイッチのオーバーヘッドが発生します。Meridian のプライマリは 8 vCPU で動作しており、負荷テストでは 16〜32 の同時アクティブクエリがスイートスポットであることが確認されています。6 レプリカで各 25 接続の場合、ピーク時の同時クエリ数はそのバンド近傍に収まります。

プールをより締まった状態にした場合のコストは、スパイクが Postgres 側のロック競合としてではなく、アプリケーション層の「コネクション待機」レイテンシとして現れることです。Meridian は `pgxpool.Stat().AcquireDuration` を計測し、p95 取得時間が 100ms を超えるとアラートを発します。これはプールが小さすぎるか、クエリがプールを枯渇させているシグナルです。どちらも対処可能ですが、Postgres 内部のロック競合はランタイムでの診断がはるかに困難です。K8s のレプリカ数とプールサイズは連動しており、デプロイメントマニフェストにはこのファイルを指し示すコメントが含まれており、その値である理由を説明しています。

<a id="prior-understanding-revised-2025-09-14"></a>
### Prior Understanding (revised 2025-09-14)

最初の実装（Meridian の本番稼働最初の 6 ヶ月間）では、Go の標準 `database/sql` パッケージを `lib/pq` ドライバーと `db.SetMaxOpenConns(50)` とともに使用していました。低トラフィック時はうまく動いていましたが、2025 年 9 月に本番インシデントが発生しました。Postgres のフェイルオーバーにより、すべての Pod が数分間ステールなコネクションを保持し続けたのです。`database/sql` プールは次のクエリがそれを使用しようとするまで死んだピアを検出せず、`lib/pq` のコネクション健全性の挙動がチームのメンタルモデルと一致していませんでした。

改訂の理由：`jackc/pgx/v5` と `pgxpool` に切り替えることで、明示的な `HealthCheckPeriod`、`MaxConnLifetime`、取得ごとのコンテキストキャンセルが提供されました。`database/sql` の抽象化は、限定的なフェイルオーバー回復には不十分でした。この移行により、バイナリプロトコルのパラメータエンコーディングも利用可能になり、`time.Time` ↔ `TIMESTAMPTZ` 境界における微妙な型変換バグのカテゴリが解消されました。

### 関連セクション

- [error-handling → Domain Error Type Hierarchy](./error-handling.md#domain-error-type-hierarchy) を参照してください。プール取得タイムアウト（ラップされた `context deadline exceeded`）がハンドラー層によって 503 Service Unavailable に変換される方法について説明しています。

---

<a id="online-migrations-on-the-50m-row-tasks-table"></a>
## 5,000 万行の tasks テーブルに対するオンラインマイグレーション  [SENIOR]

<a id="first-principles-explanation--junior--4"></a>
### 第一原理からの説明  [JUNIOR]

スキーマ変更は DDL として発行されます。DDL ステートメントの中には、操作の期間中ターゲットテーブルに排他ロックを取得するものがあり、その間他のクエリはテーブルの読み書きができません。小さなテーブルでは気づかれません。5,000 万行のテーブルで連続スキャンのために排他ロックが保持されると、それはアウテージとなります。**オンラインマイグレーション**パターンは、見かけ上アトミックな 1 つの操作を、より小さな操作の連続に分割し、それぞれが短時間だけロックを保持し、ステップとステップの間データベースが有効な中間状態にあるようにします。Postgres は特定のキーワード（`CONCURRENTLY`、`NOT VALID`、`VALIDATE CONSTRAINT`）を提供しており、中間ウィンドウ中のいくつかの制約チェック保証を犠牲にしてオンライン動作を選択できます。

<a id="idiomatic-variation--mid--4"></a>
### 慣用的なバリエーション  [MID]

`tasks` テーブルに対する Meridian のポリシー：

1. **NULL 許容列、デフォルトなし** — 1 ステートメント、いつでも安全。
2. **デフォルト値を持つ列** — Postgres 11 以降、ヒープの書き直しなし。これも 1 ステートメントで安全。
3. **インデックス** — 常に `CREATE INDEX CONCURRENTLY`。単純な `CREATE INDEX` は使いません。
4. **NOT NULL 制約** — 2 ステップの `NOT VALID` パターン（以下参照）。
5. **列の削除** — 2 デプロイシーケンス。デプロイ 1 が列への書き込みを停止し、デプロイ 2 が `ALTER TABLE ... DROP COLUMN` を発行します（高速：列はカタログでドロップ済みとしてマークされ、ヒープは遅延回収される）。

5,000 万行のテーブルに `priority SMALLINT NOT NULL` 列を追加する場合：

```sql
-- Migration 0042（デプロイ N）：NULL 許容列を追加する。
ALTER TABLE tasks ADD COLUMN priority SMALLINT;
-- デプロイ N は新しいタスクに priority を書き込み始める。バックフィルジョブが
-- 5000 行ずつのバッチで履歴行を埋め、残りがなくなるまで続ける。

-- Migration 0043（デプロイ N+1、バックフィル後）：NOT NULL を適用する。
ALTER TABLE tasks ADD CONSTRAINT tasks_priority_not_null
    CHECK (priority IS NOT NULL) NOT VALID;
ALTER TABLE tasks VALIDATE CONSTRAINT tasks_priority_not_null;
```

`NOT VALID` はテーブルスキャンなしに制約を追加し、その後の `VALIDATE CONSTRAINT` は同時書き込みをブロックせずにスキャンします。

<a id="trade-offs-and-constraints--senior--4"></a>
### トレードオフと制約  [SENIOR]

2 デプロイの列削除は運用コストが高くなります。列が存在するが使われていないウィンドウ（多くの場合数日間）が生じます。代替案（書き込みを停止した同じデプロイでドロップする）はロールバックのリスクを生じさせます。再デプロイされたコードは、マイグレーションがすでに削除した列を期待する可能性があります。意図的な間隔を空けた 2 デプロイによって、どちらの方向へのロールバックも安全になります。

`CREATE INDEX CONCURRENTLY` はトランザクションブロック内で実行できないため、マイグレーションツール（`golang-migrate`）はこれらに対してマイグレーションごとの `no-transaction` ヒントを設定します。コストは部分的な失敗モードです。同時ビルドが失敗すると `INVALID` なインデックスが残り、リトライ前にドロップしなければなりません。代替案（ブロッキングな `CREATE INDEX`）は tasks テーブルで数分間のアウテージになります。

チームは ORM の自動マイグレーションツールを完全に拒否しています。すべてのスキーマ変更は手書きのマイグレーションファイルであり、テーブルのサイズと書き込みレートを理解している人間によって明示的な `NOT VALID`、`CONCURRENTLY`、バッチサイズの選択がなされています。スキーマ作業は変更ごとに遅くなりますが、このポリシーを採用して以来、マイグレーションが本番インシデントを引き起こしたことはありません。

### 関連セクション

- [architecture → Repository Pattern](./architecture.md#repository-pattern) を参照してください。スキーマ変更を吸収するレイヤーについて説明しています。列の追加は通常リポジトリの更新を必要としますが、サービスやハンドラーの変更は不要です。

---

<a id="corrected-all-reads-routed-to-the-primary"></a>
## 修正済：すべての読み取りをプライマリにルーティング  [MID]

> 2025-12-08 に廃止：元の読み取りルーティングポリシーはすべての読み取りクエリを Postgres プライマリに送り、読み取りレプリカをまったく活用していませんでした。これは誤りでした。利用可能な読み取りキャパシティの半分を無駄にし、読み取りレプリカがアイドル状態であるにもかかわらず、2025 年 12 月の顧客オンボーディングスパイク中にプライマリ CPU を安全なヘッドルームを超えて押し上げました。

> 元のポリシー（誤り）：
> ```go
> // 単一プール、プライマリのみ
> pool, _ := pgxpool.New(ctx, primaryDSN)
> // すべてのリポジトリ読み取りが `pool` を直接使用していた。
> ```

**修正後の理解：**

読み取りレプリカは、プライマリのストリーミングレプリケートされたコピーから読み取り専用クエリを処理します。レプリカは通常の負荷下でプライマリに数ミリ秒遅れ、持続的な書き込み負荷下では数秒遅れます。レプリカに読み取りをルーティングすることで、プライマリ CPU が書き込みとラグを許容できない読み取りのために解放されます。修正後のポリシーは、レプリカを一律に使用するのではなく、**エンドポイントごとのレプリカルーティング**です。

| 読み取りパターン | ルーティング先 | 理由 |
|--------------|----------|------|
| タスク一覧（`GET /v1/workspaces/{wid}/tasks`） | レプリカ | 1 秒未満のラグを許容できる |
| 監査履歴の読み取り | レプリカ | 読み取り専用、書き込みパスに影響しない |
| 書き込み直後の同一リクエスト内での読み取り | プライマリ | "Read your writes" が保たれなければならない |
| トランザクション内での読み取り | プライマリ | レプリカはプライマリ側のトランザクションを処理できない |
| 書き込み前の認可チェック | プライマリ | ステールなレプリカデータが、ユーザーがもはや権限を持たない書き込みを許可してしまう可能性がある |

実装では、リポジトリに 2 つの `pgxpool.Pool` インスタンスを組み込み、**2 つの読み取りメソッド**を公開しています。`Get`（レプリカ、ラグを許容）と `GetFresh`（プライマリ、最新）です。

```go
type postgresTaskRepository struct {
    primary *pgxpool.Pool
    replica *pgxpool.Pool
}

func (r *postgresTaskRepository) List(ctx context.Context, p ListParams) ([]domain.Task, error) {
    return r.queryList(ctx, r.replica, p)
}

func (r *postgresTaskRepository) GetFresh(ctx context.Context, id uuid.UUID) (domain.Task, error) {
    return r.queryGet(ctx, r.primary, id)
}
```

サービスは、読み取りが読み取り-変更-書き込みであるか、リクエスト内の書き込み後の読み取りであるか、スタンドアロンの表示読み取りであるかに基づいてメソッドを選択します。

修正後、同じトラフィックレベルでプライマリ CPU は 78% の持続から 41% に低下し、レプリカはアイドル状態から 35% に移行しました。コストは注意すべきバグのカテゴリです。`Get`（レプリカ）で読み取り、その結果に基づいて書き込みを行うサービスは、書き込みが最新でないスナップショットに基づいて行われる可能性があるため、書き込み後読み取りの一貫性についてレビューが必要です。Meridian のコードレビュアーは、`replica.Query` の後に同じ行への書き込みが続くケースを HIGH の発見として記録します。

### 関連セクション

- [architecture → Repository Pattern](./architecture.md#repository-pattern) を参照してください。ラグ許容と最新読み取りメソッドの両方を公開するリポジトリインターフェースについて説明しています。
- [api-design → Cursor-Based Pagination on Task Lists](./api-design.md#cursor-based-pagination-on-task-lists) を参照してください。レプリカルーティングの恩恵を受けるリストエンドポイントのパターンについて説明しています。

---

<a id="coach-illustration-default-vs-hints"></a>
## コーチイラストレーション（default vs. hints）

> **例示のみ。** 以下はこのドメインのタスクにおける 2 つのコーチングスタイルの違いを示した実例です。ライブエージェントのコントラクトの一部ではありません。実際のエージェントの動作は `.claude/skills/learn/coach-styles/` のスタイルファイルによって管理されます。

**シナリオ：** 学習者がエージェントに、`tasks` テーブルに NOT NULL 制約付きの `due_date` 列を追加するよう依頼します。マイグレーションとリポジトリの更新も含みます。

**`default` スタイル** — エージェントは完全な 2 ステップマイグレーション（NULL 許容の追加、バックフィル計画、`NOT VALID` + `VALIDATE CONSTRAINT`）を作成し、リポジトリの `INSERT`/`UPDATE` ステートメントを更新し、ドメイン型を更新し、ユニットテストを書きます。`NOT VALID` パターンと 2 デプロイシーケンスを説明する `## Learning:` トレーラーを追記します。

**`hints` スタイル** — エージェントは最初のマイグレーション（NULL 許容の追加）のみ、ドメイン型のスタブ、そして NOT NULL ケースの TODO を含むテストスタブを書きます。それから以下を出力します。

```
## Coach: hint
Step: Write migration 0043 to enforce NOT NULL on `tasks.due_date` after backfill.
Pattern: NOT VALID + VALIDATE CONSTRAINT (online NOT NULL on a 50M-row table).
Rationale: A direct ALTER TABLE ... SET NOT NULL acquires an exclusive lock for the
duration of a sequential scan — minutes-long write outage. NOT VALID adds the
constraint without a scan; VALIDATE CONSTRAINT scans without blocking writes.
```

`<!-- coach:hints stop -->`

学習者が 2 番目のマイグレーションを書きます。次のターンで、エージェントはスキャフォールドを再書き込みせずにフォローアップの質問に応答します。
