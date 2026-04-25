> このドキュメントは `docs/en/learn/examples/_template.md` の日本語訳です。英語版が原文（Source of Truth）です。

---
domain: <replace-with-domain-key>
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
---

> **読み取り専用リファレンス。** このファイルは ECC Base Template に同梱されたサンプルです。実際のプロジェクト上で多くのセッションを重ねた後の、ポピュレートされたナレッジファイルの見た目を示すために提供されています。**あなた自身のナレッジファイルではありません。** あなたのナレッジファイルは `learn/knowledge/<domain>.md` に置かれ、エージェントが実際の作業の中で拡充するまでは空の状態で始まります。エージェントは `docs/en/learn/examples/` 配下を読んだり引用したり書き込んだりしません — このツリーは人間の読者専用です。設計根拠については [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) を参照してください。

---

## このファイルの読み方

ナレッジファイルの各エントリは、ドメイン内の持続的なトピックである 1 つの**コンセプト**を扱います。エントリは日付やセッションではなく、コンセプト単位で整理されています。各エントリには 1 つ以上のレベルマーカーが付いています。

| マーカー | 想定読者 | 扱う内容 |
|--------|----------|----------------|
| `[JUNIOR]` | そのコンセプトに初めて触れる読者 | 第一原理からの説明。語彙を使用前に導入。素朴な代替案に名前を付けて対比する |
| `[MID]` | このスタックに慣れていない実務エンジニア | 自明でない慣用的な適用方法。経験者が自然に行うが、初心者には分からないこと |
| `[SENIOR]` | 非デフォルトのトレードオフの評価 | プロジェクトがデフォルト以外の選択をとった理由。何を諦めたか。いつ再検討すべきか |

1 つのコンセプトエントリに複数のマーカーが付くことがあります。`[JUNIOR]` と `[MID]` のセクションは 1 つのエントリ内で順を追って展開されます。`[SENIOR]` セクションはトレードオフを名指しし、何を諦めたかを明示します。`[SENIOR]` マーカーのみのエントリは、強制要因に直面するまで junior の開発者がスキップしてよい決定を記録するものです。

**Prior Understanding エントリと Corrected エントリ**は、理解が時間をかけてどのように進化したかを示します。自身のナレッジファイルを書き始める前に最も読む価値があるエントリです — ナレッジベースが静的なスナップショットではなく生きた記録であることを実感できます。

---

## Canonical Concept Entry Shape

以下は完全に仕上げたサンプルエントリです。ドメイン担当エージェントはこの形を参考にして各ドメインのエントリを作成します。エントリが `[JUNIOR]` レベルで最初に書かれる時点では 5 つのセクションすべてが揃っており、`[MID]` と `[SENIOR]` のセクションは理解が深まるにつれてその後のセッションで追加されます。

---

## Example Concept: Thin Handler Pattern  [JUNIOR]

### First-Principles Explanation  [JUNIOR]

レイヤード Web サービスにおいて、HTTP ハンドラーには 2 つの責務があります。受信リクエストをドメイン型へデコードすることと、レスポンスを HTTP へエンコードして返すことです。ビジネスルールのバリデーション、データベースクエリの実行、計算処理はハンドラーの責務ではありません。それらはサービス層に属します。ハンドラーがこの 2 つの責務を超えて膨れ上がると、サービスのロジックを実行中の HTTP サーバーなしにテストできなくなり、ビジネス的な振る舞いをアサートするためにフルのリクエスト/レスポンスサイクルを構築しなければならなくなります。

**Thin Handler パターン**は責務の厳密な分離を強制します。ハンドラーは変換ロジックのみを保持します。サービス層はすべてのビジネスロジックを保持します。リポジトリ層はすべての永続化ロジックを保持します。30 行でそのほとんどが型変換というハンドラーは、設計どおりに機能しています。

### Idiomatic Variation  [MID]

Meridian の Go + Gin スタックでは、ハンドラーは `*gin.Context` を受け取り、`ShouldBindJSON` でバリデーション済みのパラメータを取り出し、サービスを呼び出し、サービスの戻り値またはエラーを JSON レスポンスに変換します。ハンドラーはデータベースを直接呼び出しません — ちょっとした存在確認であっても例外はありません。あるチェックがフローに必要であれば、それはサービスに属し、サービスがリポジトリへ委譲します。

```go
// handler/task.go — thin handler, Meridian pattern
func (h *TaskHandler) CreateTask(c *gin.Context) {
    var req CreateTaskRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, errorResponse(err))
        return
    }
    task, err := h.svc.CreateTask(c.Request.Context(), req.ToParams())
    if err != nil {
        h.writeError(c, err)
        return
    }
    c.JSON(http.StatusCreated, task)
}
```

`h.writeError` はドメインエラーを HTTP ステータスコードへ変換します。ドメインエラーと HTTP エラーのマッピングが明文化されているのはハンドラー層のこの 1 箇所だけです。

### Trade-offs and Constraints  [SENIOR]

Thin Handler の代償は、サービス層に複雑さが蓄積することです。ある機能が 5 つのエンティティに触れる場合、サービスメソッドが膨れ上がります。「今回だけ」と一部のロジックをハンドラーに押し戻す誘惑が生じます。このトレードオフはテスタビリティです。サービスをファットに保つことで、すべてのビジネスルールを `go test` で HTTP スキャフォールドなしにテストできます。ハンドラーをシンに保つことで、ルーティング層を入れ替え（Gin を標準の `net/http` に変更）してもビジネスロジックに一切触れずに済みます。

このパターンは、バリデーションが 2 箇所に分散することも意味します。スキーマバリデーション（型、必須フィールド）はハンドラーで、ビジネスバリデーション（ユーザーは自分が所属していないプロジェクトにタスクをアサインできない）はサービスで行います。この分割は意図的ですが、維持するには規律が必要です。junior エンジニアがどちらの層にバリデーションが属するか分からないときの経験則は、「答えを得るのにデータベースルックアップが必要であればサービスに属する」です。

### Example (Meridian)

Idiomatic Variation セクションの `CreateTask` スニペットを参照してください。対応するサービスメソッド `svc.CreateTask` には、認可チェック、重複検出、Slack 通知トリガーが含まれており、これらはいずれもハンドラーには現れません。

### Related Sections

- [api-design → Error Envelopes](./api-design.md#error-envelope-rfc-9457) — `h.writeError` がドメインエラーをプロジェクトの HTTP エラー形式に変換する仕組み。
- [architecture → Hexagonal Split](./architecture.md#hexagonal-split) — ハンドラー、サービス、リポジトリが配置される全レイヤー図。

### Coach Illustration (default vs. hints)

> **例示目的のみ。** 以下はこのドメインのタスクに対して 2 つのコーチングスタイルがどう違うかを示したサンプルです。ライブエージェントの契約の一部ではありません。実際のエージェントの挙動は `.claude/skills/learn/coach-styles/` のスタイルファイルが定義します。

**シナリオ:** 学習者がエージェントに、Meridian ユーザーがタスクをアーカイブできるエンドポイントを追加するよう依頼します。

**`default` スタイル** — エージェントは完全な実装を作成します。ハンドラーメソッド、サービスメソッド、リポジトリの `Archive` 呼び出し、エラー変換、テストを生成し、Thin Handler パターンとドメインエラー変換を説明する `## Learning:` トレーラーを付けます。学習者は完成した動作するコードを受け取ります。

**`hints` スタイル** — エージェントはハンドラースタブ（シグネチャと `ShouldBindJSON` 呼び出し、ボディは空）、サービスインターフェースのメソッドシグネチャ、テストスタブを書きます。そして次のヒントを出力します。

```
## Coach: hint
Step: Implement TaskService.ArchiveTask — validate ownership, call repo.Archive, trigger notification.
Pattern: Service-layer orchestration (thin handler pattern).
Rationale: Business rules (ownership check, notification) belong in the service, not the
handler, so the handler stays testable without HTTP scaffolding.
```

`<!-- coach:hints stop -->`

学習者がサービスのボディを実装します。次のターンで、エージェントはエラーやフォローアップの質問に、スキャフォールドを書き直さずに応答します。
