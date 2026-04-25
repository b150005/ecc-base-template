---
domain: security-mindset
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: security-reviewer
contributing-agents: [security-reviewer, code-reviewer]
---

> このドキュメントは `docs/en/learn/examples/security-mindset.md` の日本語訳です。英語版が原文（Source of Truth）です。

> **読み取り専用リファレンス。** このファイルは ECC Base Template に同梱された作業事例であり、実際のプロジェクトで多くのセッションを重ねた後の knowledge ファイルがどのような状態になるかを示すためのものです。これはあなた自身の knowledge ファイルでは**ありません**。あなた自身の knowledge ファイルは `learn/knowledge/security-mindset.md` に置かれ、エージェントが実際の作業を通じて拡充するまでは空の状態です。エージェントは `docs/en/learn/examples/` 配下を読んだり参照したり書き込んだりしません — このツリーは人間の読者専用です。設計の意図については [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) を参照してください。

---

## このファイルの読み方

レベルマーカーは、各節の対象読者を示します。
- `[JUNIOR]` — 第一原理からの説明。事前知識を前提としない
- `[MID]` — このスタックにおける非自明な慣用的応用
- `[SENIOR]` — 非デフォルトのトレードオフ評価。何を手放したかを明示する

深刻度ラベル（CRITICAL、HIGH、MEDIUM、LOW）は、エントリを読む対象読者ではなく脆弱性の結果を表します。CRITICAL の指摘はすべてのレベルで CRITICAL です。レベルで深刻度を柔らかくしてはならないルールについては [preamble §4](../../../learn/preamble.md) を参照してください。

---

## マルチテナント分離: すべてのクエリに workspace_id を  [JUNIOR]

### 第一原理からの説明  [JUNIOR]

マルチテナントシステムは、多くの独立した顧客のデータを同じデータベースに保存します。テナント A のタスクはテナント B のタスクと同じ `tasks` テーブルに隣り合って存在し、`workspace_id` カラムのみで区別されます。製品全体の整合性は 1 つのルールに依存します: テナントスコープのテーブルを読み書きするすべてのクエリは、呼び出し側の workspace_id でフィルタリングしなければなりません。

素朴な失敗は `SELECT * FROM tasks WHERE id = $1` — プライマリキーでタスクを取得して返す — です。クエリは単独では正しいです。コンテキストではテナントデータのリークになります: UUID を推測または列挙できる認証済みユーザーは、どのワークスペースが所有しているかに関係なく対応するタスクを受け取ります。防御は積極的です: workspace_id が認証されたセッションから派生してすべてのクエリの WHERE 句の一部になるため、呼び出し側はチェックを忘れることができません — SQL に切り離せない句として存在します。

### 慣用的な応用  [MID]

Meridian のリポジトリレイヤーでは、すべてのテナントスコープのクエリが workspace_id をリクエストコンテキストから取得した最初の WHERE 句として持ちます。リクエストボディやパスからではありません:

```go
// repository/task.go
func (r *postgresTaskRepository) Get(ctx context.Context, id uuid.UUID) (domain.Task, error) {
    workspaceID, ok := tenant.FromContext(ctx)
    if !ok {
        return domain.Task{}, domain.ErrUnauthenticated
    }
    row := r.db.QueryRowContext(ctx, `
        SELECT id, workspace_id, title, assignee_id, status, created_at, archived_at
        FROM tasks
        WHERE workspace_id = $1 AND id = $2 AND deleted_at IS NULL
    `, workspaceID, id)
    // ... スキャンとエラー変換
}
```

リポジトリは workspace_id を関数パラメータとして受け付けません — それはサービスレイヤーの呼び出し側が任意の値を渡せることになり、分離を破ります。カスタムの golangci-lint ルールが規律を強制します: `internal/repository/` の SQL 文字列リテラルがテナントスコープのテーブル（`tasks`、`task_assignments`、`comments`、`attachments`）を参照して `workspace_id` という部分文字列を含まない場合、ビルドが失敗します。バイパスするには正当化の行を含む明示的な `//nolint:tenantscope` コメントが必要です; security-reviewer エージェントはすべてのバイパスを PR でフラグします。

### トレードオフと制約  [SENIOR]

このルールには 1 つの文書化された例外があります: Meridian の内部サポートツールが使用するクロステナントの管理者クエリです。これらのクエリは意図的にワークスペースをまたいで動作します — たとえば、顧客のチケットを調査しているエンジニアが最初にワークスペースメンバーシップを証明することなく公開 URL ID でタスクを検索する必要があります。例外は `internal/admin/repository/` の別の `adminRepository` に存在し、会社の SSO プロバイダーが発行するスタッフの身元にバインドされた別の認証ミドルウェアで保護された `/admin/` ルートグループ経由でのみアクセスできます。すべての管理者クエリは、スタッフのユーザー、触れたワークスペース ID、クエリを記録する遅延監査ログ書き込みでラップされています。

コストは重複です — 管理者リポジトリはワークスペースフィルタを緩和した一般的なクエリを再実装します — しかし代替案（プロダクションリポジトリのメソッドへのフラグ）は却下されました。なぜならフラグは 1 回のレビューミスで非管理者パスから `true` を渡されることになりうるためです。失敗した監査書き込みはログに記録されますが基礎となる操作を失敗させません: スタッフがインシデント対応中の場合、部分的な監査証跡は操作なしよりも有用であり、監査パイプラインには書き込みのドロップでページするための独自のモニタリングがあります。

### 関連節

- テナントコンテキストがリクエストフローに注入される場所については [architecture → Hexagonal Split](./architecture.md#hexagonal-split) を参照してください。
- ワークスペースでフィルタリングされたクエリから返された missing-row の結果が `domain.ErrNotFound` になる方法については [error-handling → Boundary Translation](./error-handling.md#boundary-translation-from-postgres-to-domain-errors) を参照してください — プローブする呼び出し側からクロステナントリソースの存在を隠す意図的な選択です。

---

## 認証: ステートレス JWT ではなく Redis バックのセッション  [MID]

### 第一原理からの説明  [JUNIOR]

認証済みのリクエストは身元の証明を運ばなければなりません。**ステートレストークン**（JWT）は自己完結しています: サーバーはシグネチャを検証してトークンからクレームを読み取り、ルックアップは不要です。JWT は JWT が回避しようとしていたまさにサーバーサイドの状態を導入せずに有効期限前に取り消せません。**セッション識別子**は共有ストアのセッションデータにマップされたランダムな不透明文字列です; 取り消しは簡単です（エントリを削除する）が、リクエストごとのルックアップのコストがかかります。

### 慣用的な応用  [MID]

Meridian は Redis バックのセッションを使用しています。セッション ID は 256 ビットの `crypto/rand` 値で、base64url エンコードされ、`meridian.app` にスコープした HttpOnly、Secure、SameSite=Lax Cookie として設定されます。セッションレコードはユーザー ID、アクティブなワークスペース ID、発行時のタイムスタンプ、絶対有効期限、ローリングアクティビティタイムスタンプを持ちます。セッションはすべての権限変更イベントでローテーションされます（新しい ID が発行され古いものが無効化されます）: ログイン、別のデバイスからのログアウト、パスワード変更、MFA 登録、ワークスペース切り替え。

```go
// middleware/auth.go
func (m *AuthMiddleware) Require() gin.HandlerFunc {
    return func(c *gin.Context) {
        cookie, err := c.Cookie(sessionCookieName)
        if err != nil || len(cookie) != expectedCookieLength {
            c.AbortWithStatusJSON(http.StatusUnauthorized, unauthorizedResponse())
            return
        }
        sess, err := m.sessions.Get(c.Request.Context(), cookie)
        if err != nil || sess == nil || time.Now().After(sess.ExpiresAt) {
            c.AbortWithStatusJSON(http.StatusUnauthorized, unauthorizedResponse())
            return
        }
        ctx := tenant.WithWorkspace(c.Request.Context(), sess.WorkspaceID)
        ctx = identity.WithUser(ctx, sess.UserID)
        c.Request = c.Request.WithContext(ctx)
        c.Next()
    }
}
```

### トレードオフと制約  [SENIOR]

グリーンフィールドの Go サービスでのデフォルトは JWT です。Meridian は 2 つの理由で意図的にそれを却下しました。即時の取り消しは、退職する従業員のアクセスを顧客管理者がすぐに削除しなければならない B2B 製品では厳格な要件です。次のトークン有効期限ではありません。次に、ユーザーがワークスペースを切り替えるとセッション中にワークスペースコンテキストが変わり、署名されたトークンにミュータブルな状態を埋め込むことは混乱のレシピです: トークンが切り替えのたびに再発行されるか（ステートレスの恩恵を否定する）、ワークスペースクレームが古くなります。

コストはリクエストごとの Redis ルックアップです。Meridian は API ポッドと Redis を同じ Kubernetes ネームスペースに配置し、ルックアップをサブミリ秒 p99 に抑えています。Redis 自体が利用不可能になると、認証ミドルウェアはフェイルクローズします: リクエストは認証なしでトラフィックを処理するのではなく 503 を返します。インプロセスのセッションキャッシュはありません; パフォーマンスコストは現在のトラフィックでは許容範囲内です。ボトルネックになった場合の正しい対応は、明示的な無効化チャネルを持つ短い TTL のローカルキャッシュです — JWT ではありません。

### 関連節

- Meridian が依存するもう一つの Redis バックのパターンについては [api-design → Idempotency Key Handling](./api-design.md#idempotency-key-handling) を参照してください; 同じ運用上の懸念が両方に適用されます。
- ミドルウェアが存在するレイヤーについては [architecture → Hexagonal Split](./architecture.md#hexagonal-split) を参照してください。

---

## 認可: ワークスペース RBAC + タスクレベル ABAC  [MID]

### 第一原理からの説明  [JUNIOR]

認可は「呼び出し側は何を許可されているか」に答えます。**RBAC** はユーザーをロールに割り当てます; ロールはパーミッションを持ちます; パーミッションは操作をゲートします。ロールは粗粒度で推論しやすいです。**ABAC** は呼び出し側、リソース、コンテキストの属性からパーミッションを計算します。ABAC は RBAC がきれいに表現できない細粒度で関係駆動のルールを処理します。

### 慣用的な応用  [MID]

Meridian はワークスペース境界で RBAC を、タスク境界で ABAC を使用しています。ワークスペースポリシーは定数テーブルです; タスクポリシーは `service/policy/` の純粋な Go 関数です:

```go
// service/policy/task.go
func CanEditTask(task domain.Task, caller domain.Member) bool {
    if caller.Role == RoleAdmin || caller.Role == RoleOwner {
        return true
    }
    if task.AssigneeID != nil && *task.AssigneeID == caller.UserID {
        return true
    }
    if task.AssigneeID == nil && caller.Role == RoleMember {
        return true // 未アサインのタスクはどのメンバーでも編集可能
    }
    return false
}
```

ポリシーエンジンには DSL もルールファイルも外部評価者もありません。関数は純粋です — 引数のみで I/O なし — つまりすべての決定はユニットテスト可能であり、すべてのテストが実際のプロダクションコードパスをカバーしています。

### トレードオフと制約  [SENIOR]

純粋な Go ポリシーエンジンはコード変更とデプロイなしに再設定できません。ポリシーアズデータシステム（Open Policy Agent、Cedar）は柔軟性で勝り、トレーサビリティとテスタビリティで負けます。Meridian はコードを選びました。なぜなら B2B 製品でのポリシーバグは CRITICAL だからです: 間違ったユーザーに編集アクセスを付与する誤ったルールはテナントデータの公開であり、ルールの正しさを推論する最速の方法は関数を読んでそのテストを実行することです。

ポリシーエンジンの場所が重要です: ミドルウェアではなくサービスレイヤーに存在します。ミドルウェアはリソースが読み込まれる前に利用可能な属性 — 通常は呼び出し側の身元と URL パス — のみをチェックできます。タスクレベルのルールにはタスク自体（アサイニーを読む）が必要なため、サービスはポリシーを実行する前にタスクを読み込まなければなりません:

```go
// service/task.go
func (s *TaskService) UpdateTask(ctx context.Context, taskID uuid.UUID, params domain.UpdateTaskParams) (domain.Task, error) {
    task, err := s.tasks.Get(ctx, taskID) // ワークスペーススコープのフェッチ
    if err != nil {
        return domain.Task{}, err
    }
    callerID, _ := identity.FromContext(ctx)
    member, err := s.workspaces.GetMember(ctx, task.WorkspaceID, callerID)
    if err != nil {
        return domain.Task{}, err
    }
    if !policy.CanEditTask(task, member) {
        return domain.Task{}, &domain.AuthorizationError{Action: "edit", Resource: "task"}
    }
    return s.tasks.Update(ctx, taskID, params)
}
```

1 つのメソッドに 3 層の防御: フェッチ時の workspace_id フィルタ（クロステナント ID は `ErrNotFound` を返し、タスク自体を返さない）、メンバーシップルックアップ（セッションが無効化された後でも元のメンバーがアクションを実行できない）、ポリシーチェック。

### 関連節

- 欠けている認可チェックがコードレビューで CRITICAL に分類される方法については [review-taste → The Severity Ladder](./review-taste.md#the-severity-ladder) を参照してください。
- ポリシーゲートが返す `AuthorizationError` 型については [error-handling → Domain Error Type Hierarchy](./error-handling.md#domain-error-type-hierarchy) を参照してください。

---

## Slack Webhook シグネチャ: HMAC-SHA256、タイミングセーフ、リプレイ制限付き  [MID]

### 第一原理からの説明  [JUNIOR]

Webhook エンドポイントは、リクエストが本当に主張された送信者から来ているかを確認しなければなりません。標準的なメカニズムは共有シークレットと HMAC です: 送信者がシークレットを使ってボディの上に HMAC を計算してヘッダーとして送り、受信者が再計算して比較します。

3 つの失敗モードが導入されやすいです。**タイミング攻撃が可能な比較**: `==` で 2 つの MAC 文字列を比較すると最初のミスマッチで短絡し、バイト単位の情報が漏洩します; 防御は定時間比較です。**リプレイ**: キャプチャされたペイロードに対する有効な MAC は永遠に有効です; 防御はタイムスタンプウィンドウです。**アルゴリズムの信頼**: 送信者のアルゴリズム選択を信頼することで、攻撃者はダウングレードを引き起こせます; 受信者がアルゴリズムをピンします。

### 慣用的な応用  [MID]

Meridian のミドルウェアは Slack の文書化されたコントラクトに従ってシグネチャを確認します: `v0:{timestamp}:{raw_body}` に対する HMAC-SHA256 で、ヘッダー値の `v0=` プレフィックスを持ちます:

```go
// middleware/slack_signature.go
const slackSignatureWindow = 5 * time.Minute

func (m *SlackSignatureMiddleware) Verify(c *gin.Context) {
    timestampStr := c.GetHeader("X-Slack-Request-Timestamp")
    signature := c.GetHeader("X-Slack-Signature")
    if timestampStr == "" || signature == "" {
        c.AbortWithStatus(http.StatusUnauthorized); return
    }
    ts, err := strconv.ParseInt(timestampStr, 10, 64)
    if err != nil {
        c.AbortWithStatus(http.StatusUnauthorized); return
    }
    if time.Since(time.Unix(ts, 0)).Abs() > slackSignatureWindow {
        c.AbortWithStatus(http.StatusUnauthorized); return // 双方向リプレイウィンドウ
    }
    body, err := io.ReadAll(c.Request.Body)
    if err != nil {
        c.AbortWithStatus(http.StatusBadRequest); return
    }
    c.Request.Body = io.NopCloser(bytes.NewReader(body))

    secret := m.secrets.Get("<SLACK_SIGNING_SECRET_FROM_VAULT>")
    mac := hmac.New(sha256.New, secret)
    mac.Write([]byte("v0:" + timestampStr + ":"))
    mac.Write(body)
    expected := "v0=" + hex.EncodeToString(mac.Sum(nil))

    if subtle.ConstantTimeCompare([]byte(expected), []byte(signature)) != 1 {
        c.AbortWithStatus(http.StatusUnauthorized); return
    }
    c.Next()
}
```

署名シークレットはシークレットプロバイダー（本番では Vault）から取得します。プレースホルダー `<SLACK_SIGNING_SECRET_FROM_VAULT>` はシークレット自体ではなくルックアップキーです。リプレイウィンドウは双方向です: 過去に遡りすぎる**または**未来に進みすぎるタイムスタンプは拒否されます。未来日付のタイムスタンプはウィンドウを延長する試みです; それらを拒否することは安価で防御的です。

### トレードオフと制約  [SENIOR]

5 分のウィンドウは Slack が公開している値です。より厳しいウィンドウ（1 分）はクロックドリフトによる誤拒否のコストでリプレイの表面を減らします。Meridian は時刻同期に chrony を使用し、5 分を運用上のデフォルトとして採用する前に 1 ヶ月間クロックドリフトのテレメトリを実行しました。ミドルウェアは MAC を計算する前にリクエストボディ全体をメモリに読み込みます。Slack のペイロード（数キロバイト）ではこれで問題ありません; Meridian がより大きな Webhook ペイロードを受け付けるようになれば、同じパターンにストリーミング MAC 計算が必要になります — `io.ReadAll` のみが変わります。

ルートのミドルウェアの順序が重要です: シグネチャ確認は呼び出し側が Slack であることを証明する最も安価なフィルタなので最初に実行されます; 冪等性は Redis を使用してより高コストなので後で実行されます。認証されていないリクエストは Redis ルックアップを消費しません。

### 関連節

- シグネチャウィンドウ内での正当な Slack リトライを処理する多層防御レイヤーについては [error-handling → Idempotent Retry on the Slack Webhook](./error-handling.md#idempotent-retry-on-the-slack-webhook) を参照してください。
- サードパーティの HMAC パッケージよりも標準ライブラリの `crypto/subtle` と `crypto/hmac` が好まれる理由については [dependency-management → Pinning Strategy](./dependency-management.md#pinning-strategy) を参照してください — 暗号プリミティブを標準ライブラリに収めることでサプライチェーンの表面が減ります。

---

## シークレット管理: 本番では Vault、リポジトリには .env.example、常にログ削除  [MID]

### 第一原理からの説明  [JUNIOR]

シークレットとは、開示されると攻撃者がシステムまたはユーザーを偽装できる値です。3 つの失敗モードがほぼすべての実際のリークを説明します: **バージョン管理にコミットされたシークレット**（一度チェックインされた `.env` ファイルは永遠に公開されます — 履歴の書き直しは、書き直し前にリポジトリをフェッチした人への開示を取り消しません）; **本番でログに記録されたシークレット**（リクエストボディをプリントするデバッグログ、接続文字列を含むスタックトレース、トークンをエコーするエラーメッセージ — ログは集約されてサードパーティと共有されることが多い）; **必要としないプロセスに環境を通じて渡されるシークレット**。

### 慣用的な応用  [MID]

Meridian の規律:

- **リポジトリに `.env` はなし。** リポジトリには実際の値が存在する場所（Vault パスまたはローカル開発スタブ）を指すプレースホルダー値を持つ `.env.example` があります。`.gitignore` は `.env` をリストし、プリコミットフックは `.env` を導入するコミットを拒否します。
- **本番では Vault。** Kubernetes マニフェストは Vault Agent Injector を使用して、シークレットをインメモリファイルとして `/var/run/secrets/meridian/` にマウントします。アプリケーションはスタートアップ時に読み取ってメモリにキャッシュします; ローテーションは再読み込みのために SIGHUP をトリガーします。
- **ログ削除ミドルウェア。** すべてのログラインは、既知のシークレットパターン（Slack の署名シークレットフォーマット、JWT のような文字列、AWS キー、プロジェクトのセッション Cookie フォーマット）に一致する値を固定マーカーに置き換える `slog.Handler` ラッパーを通ります。フィルターはマーシャリングされたログエントリに対して動作するため、エラーメッセージ、リクエストボディ、スタックトレースに埋め込まれたシークレットも捕捉します。

```go
// internal/log/redact.go
type RedactHandler struct {
    next     slog.Handler
    patterns []*regexp.Regexp
}

func (h *RedactHandler) Handle(ctx context.Context, r slog.Record) error {
    redacted := slog.NewRecord(r.Time, r.Level, redactString(r.Message, h.patterns), r.PC)
    r.Attrs(func(a slog.Attr) bool {
        redacted.AddAttrs(redactAttr(a, h.patterns))
        return true
    })
    return h.next.Handle(ctx, redacted)
}
```

パターンはシークレットの**形**にマッチし、その値にはマッチしません。実際の値にマッチするパターンはそれ自体がシークレットになります。形ベースのアプローチは既知のシークレットと、シークレットのように見えたたまたま未知の値の両方を捕捉します — 防御的な偽陽性バイアスです。

### トレードオフと制約  [SENIOR]

パターンベースの削除には偽陰性があります: 既知のパターンにマッチしないカスタムフォーマットのシークレットは通り抜けます。`internal/auth/` と `internal/payments/` での緩和策はより厳格なルールです: 構造化ログの呼び出しは承認されたセットの属性キーのいずれかを使用しなければならず、`password`、`token`、`secret`、`key` 属性は `[REDACTED]` を出力する `Redacted` 型に値をラップしなければなりません。コストはデバッグ時の摩擦であり、運用上の実践として、シークレットに触れるコードパスが、シークレットを開示することなく 2 つのログエントリが同じシークレットを指していることを確認するのに十分な、値のハッシュ（`sha256(value)[:8]`）を削除された値とともに出力します。

プレーンな Kubernetes シークレットよりも Vault を本番で使用する決定は、Kubernetes シークレットが（KMS インテグレーションが有効でない限り）保存時に暗号化されずに base64 エンコードされており、正しいサービスアカウントを持つすべてのポッドがその名前空間の任意のシークレットを読み取れるためです。Vault はシークレットごとのアクセスポリシー、監査ログ、ローテーションを追加します。追加の運用上の依存関係のコストと引き換えに。Meridian の顧客ベースには、調達時に「シークレットはどこに存在するか」を尋ねる規制対象の業界が含まれており、Kubernetes シークレットはその回答として満足のいくものではありません。

### 関連節

- Vault クライアントライブラリの更新がセキュリティレビューでどのようにゲートされるかについては [dependency-management → Pinning Strategy](./dependency-management.md#pinning-strategy) を参照してください。

---

## 修正済み: bcrypt コストファクター 10  [MID]

> 2026-02-09 に supersede: ピークトラフィック時のログインエンドポイントの CPU プロファイルにより、bcrypt が元のコストファクターの選択が想定していたレイテンシのボトルネックではないことが示されました; コストファクターは、システムが抱えていなかった問題に対して控えめに低く設定されていました。

元の Meridian のパスワードハッシュ呼び出しは bcrypt コストファクター 10 を使用していました。ライブラリのデフォルトであり、当時の Go エコシステムで一般的な選択でした。根拠はパフォーマンスでした: コストファクターが高いとログインが遅くなります。

```go
// service/identity.go — original
hash, err := bcrypt.GenerateFromPassword([]byte(password), 10)
```

**修正後の理解:**

CPU プロファイルにより、コスト 10 の bcrypt が呼び出しごとに約 12ms を消費しており、ログインパスの残り — Redis セッション書き込み、監査ログ出力、レスポンスシリアライゼーション、ネットワーク — が 80ms 以上を占めていることが示されました。bcrypt はボトルネックではありませんでした。

修正後の値は 14 で、bcrypt ステップを呼び出しごとに約 200ms にプッシュするよう選択されました。これはログインにレイテンシを追加しますが、パスワードハッシュテーブルを外部流出した攻撃者のブルートフォースコストを約 16 倍引き上げます。ログインエンドポイントは IP ごとおよびアカウントごとに 1 分あたり 5 回の試行にレート制限されているため、追加のレイテンシによるユーザー向けの影響は正当なログインパスに限定されます。

```go
// service/identity.go — current
hash, err := bcrypt.GenerateFromPassword([]byte(password), 14)
```

原則: パスワードハッシュのコストファクター決定は、オンラインのログインレイテンシのワーストケースではなく、オフライン攻撃のコストに対してキャリブレーションすべきです。オンラインパスはレート制限できます; オフラインコストは一度設定されて、ハッシュが漏洩した後には引き上げられません。デフォルトの 10 は 2010 年代のキャリブレーションであり、10 年間のムーアの法則がそれを侵食しました。

移行は遅延適用されました: 既存のハッシュは元のコストでマークされ、次の成功したログイン時にコスト 14 への再ハッシュが発生しました。新しいアカウントは移行日からコスト 14 で始まりました。これにより再ハッシュの嵐を避け、移行が数週間かけてドレインできるようにしました。

### 関連節

- `golang.org/x/crypto/bcrypt` がどのようにピンされ、格納されたハッシュを無効化する可能性のあるアルゴリズム変更に対してアップグレードがどのようにレビューされるかについては [dependency-management → Pinning Strategy](./dependency-management.md#pinning-strategy) を参照してください。

---

### コーチイラストレーション（default vs. review-only）

> **説明のみ。** ライブエージェントのコントラクトの一部ではありません。`.claude/skills/learn/coach-styles/` によって規定されます。

**シナリオ:** 学習者がすべてのワークスペースをまたいでその公開 ID でタスクを取得する管理者エンドポイントを追加する PR を提出します。ハンドラは `SELECT * FROM tasks WHERE public_id = $1`（意図的に workspace フィルタなし）を実行する新しいリポジトリメソッドを呼び出します。

**`default` スタイル** — エージェントが差分をレビューして指摘を書きます: 欠けている監査ログラッパー（クロステナントクエリは意図的だが監査されていない）に CRITICAL、ハンドラでのスタッフ身元アサーションの欠如に HIGH、非スタッフセッションが拒否されることをアサートするテストの不在に MEDIUM。提案された修正は `withAudit` ラッパーとスタッフコンテキストチェックを参照します。

**`review-only` スタイル** — エージェントはプロダクションコードの記述を断り、同じ深刻度ラベルを持つ構造化されたレビューのみを作成します。CRITICAL は学習者の宣言されたレベルにかかわらず CRITICAL のままです — [preamble §4](../../../learn/preamble.md) を参照してください。
