> このドキュメントは `docs/en/learn/examples/documentation-craft.md` の日本語訳です。英語版が原文（Source of Truth）です。

---
domain: documentation-craft
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: technical-writer
contributing-agents: [technical-writer]
---

> **読み取り専用リファレンス。** このファイルは ECC Base Template に同梱された実装例であり、実際のプロジェクトの多くのセッションを経て積み上がったナレッジファイルがどのような姿になるかを示しています。これはあなた自身のナレッジファイルでは**ありません**。あなた自身のナレッジファイルは `learn/knowledge/documentation-craft.md` にあり、実際の作業においてエージェントが内容を拡充するまでは空の状態です。エージェントは `docs/en/learn/examples/` 配下のファイルを読み込んだり、引用したり、書き込んだりすることは一切ありません。このツリーは人間の読者専用です。設計の背景については [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) を参照してください。

> このファイルのナレッジピラーにおけるホームは `learn/knowledge/documentation-craft.md` です。

---

<a id="how-to-read-this-file"></a>
## このファイルの読み方

各セクションのレベルマーカーは想定読者を示しています。
- `[JUNIOR]` — 第一原理からの説明。事前知識を前提としません。
- `[MID]` — このスタックにおける、一見しただけでは気づきにくい慣用的な応用。
- `[SENIOR]` — デフォルト以外のトレードオフの評価。何を諦めるかを明示します。

---

<a id="the-four-documentation-audiences"></a>
## 4 つのドキュメント読者層  [JUNIOR]

<a id="first-principles-explanation--junior-"></a>
### 第一原理からの説明  [JUNIOR]

ドキュメントは、全員に一度に応えようとすると失敗します。新しいコントリビューター、オンコールのオペレーター、API コンシューマー、将来のメンテナーを対象にした単一のドキュメントは、そのどれも十分にサービスできない結果になります。2 分以内に決断が必要なオペレーターには遅すぎ、制約を理解する必要があるメンテナーには浅すぎ、ローカルサーバーを起動したいコントリビューターには詳細すぎます。

ドキュメントが他の何よりも先に答えなければならない問いは：「誰がこれを読んでいて、次に何をする必要があるか？」です。この答えが声調、深さ、構造を決めます。

**新しいコントリビューター**は実際に機能する最小限のステップを必要とします。アーキテクチャの概要ではありません。テストの実行方法を説明する前にヘキサゴナルアーキテクチャを説明するコントリビュータードキュメントは、読者を間違えています。

**オンコールのオペレーター**は最小限の決断で生きているインシデントを診断して緩和する必要があります。ランブックがこの読者に対応します。ランブックは観察可能な症状を中心に構築され、アーキテクチャではありません。背景理論で始まるランブックは読者を間違えています。

**API コンシューマー**は、呼び出しが何を受け取るか、何を返すか、何が失敗しうるかを、コピーして修正できる例とともに知る必要があります。データベースがどのようにデータを格納するかを知る必要はありません。

**将来のメンテナー**は、決断がなぜ行われたかを理解する必要があります。コードは何をするかを表現します。アーキテクチャ決定レコード（ADR）は、なぜを表現します。却下された代替案と、それらを劣ったものにした制約も含めて。

<a id="idiomatic-variation--mid-"></a>
### 慣用的なバリエーション  [MID]

Meridian は各読者層を特定のドキュメントタイプと場所にマッピングしています。

| 読者層 | ドキュメントタイプ | 場所 |
|----------|---------------|----------|
| 新しいコントリビューター | README + `docs/en/onboarding.md` | リポジトリルート + `docs/en/` |
| オンコールのオペレーター | ランブック | `docs/en/runbooks/` |
| API コンシューマー | OpenAPI スペック + 使用例 | `docs/en/api/` |
| 将来のメンテナー | アーキテクチャ決定レコード | `docs/en/adr/` |

README はビジターが最初の 5 分以内に知る必要があることのみをカバーします。プロジェクトが何をするか、ローカルで実行する方法、より詳しいドキュメントの場所。他のすべては `docs/` にあります。オンボーディング、API リファレンス、アーキテクチャの理由もカバーする README は数千語に成長し、更新されるより速くスタールになり、4 つの読者層のどれも十分にサービスしません。

<a id="trade-offs-and-constraints--senior-"></a>
### トレードオフと制約  [SENIOR]

読者層でドキュメントを分離することは、単一の機能変更に 4 つのドキュメントへの更新が必要かもしれないことを意味します。オンボーディングガイド、ランブック、API リファレンス、ADR。コストは規律です。観察可能な動作を変更するすべての PR はドキュメントチェックリストを持ちます。ベネフィットは各ドキュメントが焦点を当てて読みやすい状態を保つことです。

代替案（単一のウィキ）は読者がスキャンしてフィルタリングすることを要求します。Meridian は最初の 3 ヶ月間ウィキを運用しました。失敗のシグナルは、オンコールのエンジニアがランブックスタイルのページを開いて軽減ステップの前に 2 段落の背景を見つけていたことでした。

### 関連セクション

- [documentation-craft → ADR Discipline](#adr-discipline-when-and-how-to-write-an-adr) を参照してください。将来のメンテナードキュメントを管理するフォーマットについて説明しています。
- [operational-awareness → Three-Pillar Observability](./operational-awareness.md#three-pillar-observability-logs-metrics-and-traces) を参照してください。オペレーターがインシデント中にシステムが公開することを期待するものと、オペレータードキュメントが従う runbook の規約について説明しています。

---

<a id="adr-discipline-when-and-how-to-write-an-adr"></a>
## ADR の規律：いつどのように ADR を書くか  [MID]

<a id="first-principles-explanation--junior--1"></a>
### 第一原理からの説明  [JUNIOR]

アーキテクチャ決定レコードは 1 つの決断をキャプチャします。何が決断されたか、なぜか、どの代替案が検討されて却下されたか。レコードは一度書かれたら決して編集されません。同じトピックを再検討する将来の決断は、以前の決断を supersede する新しい ADR を作成します。この不変性が重要です。ADR は歴史的なアーティファクトであり、生きているドキュメントではありません。

ADR の最も重要な部分は代替案のテーブルです。却下された代替案のない決断は半分のレコードです。何が選ばれたかを語りますが、他のパスがなぜ劣っていたかを語りません。決断のみを読んだメンテナーは、それが明白なものだったか、重要な制約のある接戦だったかを判断できません。

<a id="idiomatic-variation--mid--1"></a>
### 慣用的なバリエーション  [MID]

Meridian の ADR ヘッダーブロック：

```markdown
# ADR-007: Cursor-Based Pagination for Task Lists

**Status:** Accepted
**Date:** 2026-01-14

## Context

Task list queries return results ordered by (created_at DESC, id DESC). Two pagination
strategies were evaluated: offset-based (LIMIT n OFFSET m) and cursor-based (encoding
the last row's (created_at, id) pair).

## Decision

Use cursor-based pagination for all task list endpoints.

## Alternatives Considered

| Alternative | Why rejected |
|-------------|--------------|
| Offset pagination | Produces skipped or duplicated results when tasks are inserted between page fetches, which occurs frequently during active sprints. |
| Keyset on id only | Breaks when two tasks share a created_at timestamp, which occurs during bulk imports. |

## Consequences

Clients cannot jump to an arbitrary page number. Continuous-scroll UIs (Meridian's
primary pattern) are unaffected. Reporting views requiring row skipping will need a
separate strategy if that feature is ever built.
```

ADR は `docs/en/adr/` に連番で格納されています。Meridian は決断のタイミングで書きます。ドラフトは決断を実装する PR に存在します。レビュアーはコードとともに ADR を承認します。

<a id="trade-offs-and-constraints--senior--1"></a>
### トレードオフと制約  [SENIOR]

しきい値の問いは：「将来のコントリビューターがなぜこのように行われたかを尋ねるか？」です。そうであれば ADR を書きます。小さな実装上の選択（ループ構造、変数名、どのアサーションライブラリを呼ぶか）は ADR を必要としません。重要な動作上の選択（ページネーション戦略、データベースの選択、インターフェースが実装パッケージではなく `domain` に存在する理由）は必要です。

ADR がない場合のコストは数ヶ月後に具体化します。メンテナーがコンテキストなしに決断を再検討し、すでに却下された代替案を探索し、より劣った解決策を実装するか元の推論を再発見するのに時間を費やします。不必要な ADR のコストは、レビュアーがスキャンしなければならないより長いログです。これらのコストの間で、Meridian は本当の選択だと感じた決断に対して ADR を書く方向に誤ることを好みます。

### 例（Meridian）

ADR-007（カーソルベースのページネーション）はタスクリストエンドポイントを追加した PR とともに書かれました。それなしでは、新しいリストエンドポイントを追加する将来のエンジニアがオフセットページネーションをデフォルトにして、並行したタスク作成時の競合状態を再導入する可能性が高かったでしょう。

### 関連セクション

- [api-design → Cursor-Based Pagination on Task Lists](./api-design.md#cursor-based-pagination-on-task-lists) を参照してください。ADR-007 が管理する実装について説明しています。
- [review-taste → Design Review Heuristics](./review-taste.md#design-review-heuristics) を参照してください。レビュアーが ADR にふさわしいしきい値を超える決断を特定する方法について説明しています。

---

<a id="comment-policy-in-code-why-not-what"></a>
## コードのコメントポリシー：何ではなくなぜ  [JUNIOR]

<a id="first-principles-explanation--junior--2"></a>
### 第一原理からの説明  [JUNIOR]

コードは、その言語を読める読者に何をするかを伝えます。コードを英語で言い換えるコメントは情報を追加せず、メンテナンスサーフェスを倍増させます。コードが変わると、コメントも変わらなければなりません。さもなければ静かに間違いになります。間違ったコメントはコメントがないより悪い。積極的に誤解させます。

Meridian のルール：**コメントは何をするかではなく、なぜするかを説明します。** コードはすでに何をするかを言っています。コメントはコードには見えない理由を説明することで存在価値を得ます。外部システムからの制約、パフォーマンス上の考慮事項、将来の変更が破ってはならない安全上の不変条件。

1 つの例外：エクスポートされた Go 識別子の godoc コメント。パッケージの外の呼び出し元が本体を読まないかもしれません。エクスポートされた関数では、godoc コメントは API コントラクトの一部です。関数が何をするか、どのエラーを返すかもしれないかを説明します。

<a id="idiomatic-variation--mid--2"></a>
### 慣用的なバリエーション  [MID]

Meridian の Go コードには 3 つのカテゴリの許容されるコメントがあります。

**エクスポートされた識別子の godoc**（what コメント、必須）：

```go
// CheckAndRecord checks whether the given idempotency key has been seen before.
// It records the key on first encounter with the given TTL.
// Returns (true, nil) if already present; (false, nil) on first record;
// (false, err) if the Redis operation failed.
func (s *IdempotencyService) CheckAndRecord(ctx context.Context, key string, ttl time.Duration) (bool, error) {
```

**外部から制約された動作を説明するインライン why コメント**：

```go
// Fetch limit+1 rows to determine hasMore without a separate COUNT query.
// COUNT(*) on large tables causes a sequential scan; the extra-row technique avoids it.
rows, err := r.db.QueryContext(ctx, q, args...)
```

**単独の関数では強制できない制約について将来の編集者に警告する安全上の不変条件コメント**：

```go
// SET NX is atomic: no window between the existence check and the write.
// Do NOT replace this with GET followed by SET — that introduces a race condition.
set, err := s.redis.SetNX(ctx, "idempotency:"+key, "1", ttl).Result()
```

Meridian が許可しないもの：削除されたコードを説明するコメント。コードが削除されたら、それは削除されます。コミットメッセージが記録です。`// removed feature X — no longer needed` と読むコメントは、削除コンテキストなしに誰かがそれを読む瞬間にスタールになります。

<a id="trade-offs-and-constraints--senior--2"></a>
### トレードオフと制約  [SENIOR]

「なぜであって何ではない」ポリシーは、エンジニアが不明確なコードの松葉杖としてコメントを使うことを控えるよう求めます。「what」コメントを必要とするコードへの正しい応答は、コード自体を明確化することです。より良い名前、より小さな関数、説明的なヘルパー。コメントは明確さの代替品であるべきではありません。

コメントが why テストに合格すると、それはシグナルとして機能します。コメントは Meridian のコードベースで十分にまばらであるため、開発者はそれに注目することを学びます。コメントは「これは明白でなく、理由がある」を意味します。すべての行にコメントがあるコードベースは、開発者にそれらをスキップするよう訓練します。

### 関連セクション

- [documentation-craft → The Four Documentation Audiences](#the-four-documentation-audiences) を参照してください。godoc コメントが具体的に API コンシューマーの読者層に対応する理由について説明しています。
- [review-taste → Testing Depth](./review-taste.md#testing-depth) を参照してください。コードレビュアーがカバレッジとともにコメントの品質を評価する方法について説明しています。

---

<a id="bilingual-documentation-maintenance"></a>
## バイリンガルドキュメントのメンテナンス  [MID]

<a id="first-principles-explanation--junior--3"></a>
### 第一原理からの説明  [JUNIOR]

プロジェクトが 2 言語でドキュメントを維持するとき、一方が信頼の源泉でなければなりません。その指定がないと、両方のバージョンがドリフトします。それぞれが一部の更新を受け取り、他を見逃し、読者はどれが最新かを知らずに時代遅れの情報に遭遇します。ドリフトが修正されないまま続くほど、調整はコストが高くなります。

信頼の源泉の規約は 1 つの問いに答えます：英語版と日本語版が一致しない場合、どちらが正しいか？答えが常に英語であれば、英語が最初に更新されて日本語がそれに続かなければなりません。日本語版が何か時点でより最新であれば、規約が崩れています。

このプロジェクトと Meridian は同じ規約に従っています：英語が信頼の源泉です。すべてのドキュメント変更は英語ファイルから始まります。日本語ファイルは維持された翻訳であり、独立して書かれたドキュメントではありません。

<a id="idiomatic-variation--mid--3"></a>
### 慣用的なバリエーション  [MID]

Meridian のバイリンガルツリーは並行です。

```
docs/
  en/
    onboarding.md       # 信頼の源泉
    runbooks/slack-webhook-latency.md
  ja/
    onboarding.md       # 維持された翻訳
    runbooks/slack-webhook-latency.md
```

すべての日本語ファイルはソースを特定するヘッダーで始まります。

```markdown
> このドキュメントは `docs/en/onboarding.md` の日本語訳です。英語版が原文（Source of Truth）です。
```

PR レビューがペアリングを強制します。`docs/en/` 配下のファイルを変更するすべての PR は、同じ PR で `docs/ja/` 配下の対応するファイルが更新されたことを確認するチェックリストアイテムを含みます。日本語の更新がない場合、レビュアーは承認前にそれをリクエストします。

<a id="trade-offs-and-constraints--senior--3"></a>
### トレードオフと制約  [SENIOR]

ペアリングチェックは PR レベルのドリフトを防ぎますが、ポリシーが存在する前に導入されたギャップは捕捉できません。Meridian が v0.3 でバイリンガルポリシーを導入したとき、いくつかの英語ドキュメントが最初の日本語翻訳以降に更新されていました。これらのギャップは専用のクリーンアップ PR で解決されました。

より深いトレードオフ：すべてのドキュメント変更に 2 つのファイルが必要になります。日本語能力のないエンジニアにとって、日本語の更新は機械翻訳の後にレビューが必要か、流暢なチームメンバーによる別のパスが必要です。これは小さなドキュメント変更に摩擦を加えます。Meridian はこのコストを受け入れます。日本語を話す読者は顧客ベースの重要な割合を占め、ドキュメントの障壁を減らすことがプロダクトの優先事項だからです。

### 例（Meridian）：v0.4 のドリフトインシデント

v0.4 リリースサイクル中の PR が、新しい必須環境変数を反映するために `docs/en/onboarding.md` を更新しました。PR は `docs/ja/onboarding.md` を更新せずにマージされました。ペアリングチェックリストは PR テンプレートに存在していましたが、まだ通常のレビューフローに組み込まれていませんでした。レビュアーはそれを確認する習慣がまだありませんでした。

ギャップは 2 週間後に、日本語を話す新しいコントリビューターが日本語のオンボーディングガイドに従い、不足している変数からエラーが発生し、イシューを提出したときに気づかれました。日本語ファイルは 24 時間以内に更新されました。PR テンプレートは以前に「テストが通る」項目の下に埋もれていたバイリンガルチェックリストを 2 番目の項目に配置するよう改訂されました。

このインシデントがチームのノームを確立しました：バイリンガルチェックリストは今やレビュアーが CI ステータスの次に確認する 2 番目のアイテムであり、最後ではありません。

### 関連セクション

- [documentation-craft → The Four Documentation Audiences](#the-four-documentation-audiences) を参照してください。バイリンガルのコミットメントを駆動する読者モデルについて説明しています。
- [release-and-deployment → Changelog and Release Notes](./release-and-deployment.md#changelog-and-release-notes) を参照してください。リリースノートもバイリンガルで維持される方法について説明しています。

---

<a id="prior-understanding-readme-as-the-documentation-system"></a>
## Prior Understanding：ドキュメントシステムとしての README  [SENIOR]

<a id="prior-understanding-revised-2026-01-28"></a>
### Prior Understanding (revised 2026-01-28)

Meridian の元のアプローチ（2025-08 の最初のコミットから存在）は、リポジトリルートの単一の README にすべてを含めることでした：プロジェクト概要、ローカルセットアップ、環境変数リファレンス、アーキテクチャ概要、API エンドポイントリスト、デプロイガイド。README は約 1,800 語に達しました。

これが改訂された理由：

1. **更新頻度が異なるためRAREDME が壊れました。** 環境変数はすべてのデプロイメント更新で変わりました。API エンドポイントリストはすべての機能 PR で変わりました。アーキテクチャはめったに変わりませんでした。これらの頻度を 1 つのファイルに混ぜると、README は常に部分的にスタールになり、読者はどのセクションを信頼すべきかわかりませんでした。

2. **ナビゲーションが劣化しました。** 1,800 語の README には意味のある構造がありません。オンコールのエンジニアも新しいコントリビューターも、タスクに関連するセクションを見つけるためにドキュメント全体をスキャンしました。

3. **README は本来属さないコンテンツを蓄積しました。** 「README に入れる」というパターンが確立されると、すべてのチームメンバーがセクションを追加しました。機能比較テーブル、FAQ、既知の問題のリスト、3 人のエンジニアからの 3 アイテムを持つ「ヒント」セクションが蓄積されました。一貫したテーマはありませんでした。

**修正後の理解：**

README はリポジトリビジターに 5 つのことを伝えます：プロジェクトが何をするか、10 分未満で実行する方法、詳しいドキュメントの場所、貢献する方法、適用されるライセンス。他のすべては `docs/` に属します。境界は PR テンプレートで強制されます。README に 20 行を超える行を追加する PR は、コンテンツが代わりに `docs/` に属するかどうかを尋ねるフラグを発生させます。

修正された構造は 94 行の README を生み出しました。置き換えられたコンテンツは以下に移動しました：

- ローカルセットアップの詳細 → `docs/en/onboarding.md`
- 環境変数リファレンス → `docs/en/configuration.md`
- API エンドポイントリスト → `docs/en/api/`（OpenAPI スペック）
- デプロイガイド → `docs/en/runbooks/` および devops-engineer のスコープ

原則：README の長さはドキュメント規律のプロキシです。長い README は、プロジェクトがドキュメントの置き場所をまだ決めておらず、最も目立つサーフェスをデフォルトにしていることを示します。

### 関連セクション

- [documentation-craft → The Four Documentation Audiences](#the-four-documentation-audiences) を参照してください。各置き換えられたセクションがどこに着地したかを決定した読者モデルについて説明しています。

---

<a id="coach-illustration-default-vs-hints"></a>
## コーチイラストレーション（default vs. hints）

> **例示のみ。** ライブエージェントのコントラクトの一部ではありません。`.claude/skills/learn/coach-styles/` によって管理されます。

**シナリオ：** 学習者は Meridian バックエンドに Redis キースペースモニタリングコマンドを追加したばかりです。エージェントにそれをドキュメント化するよう依頼します。

**`default` スタイル** — エージェントは関連する読者層（オペレーターはランブックでコマンドが必要です。関数がエクスポートされている場合、API コンシューマーは godoc が必要です）を特定します。コマンドが内部の運用ツールであると判断し、Triage の下の関連するランブックセクションへの更新を作成し、エクスポートされた関数に godoc コメントを追加します。モニタリング戦略が ADR を必要とするかどうかを確認します。すでに記録されたパターンに従っているため不要です。読者層からドキュメントへのマッピングと godoc（what）とインライン why コメントのコメントポリシーの区別を説明する `## Learning:` トレーラーを追記します。

**`hints` スタイル** — エージェントは 2 つの関連するサーフェス（オペレーター向けランブック、エクスポートされた関数の godoc）に名前を付け、コメントタイプ（キースペースの命名規則のためのインライン why コメント）を特定し、以下を出力します。

```
## Coach: hint
Step: Add the monitoring command to docs/en/runbooks/redis-keyspace.md under Triage,
and a godoc comment to the exported function explaining what it returns.
Pattern: Audience-specific documentation — runbook for operators, godoc for API consumers.
Rationale: The command is operational; it belongs in the runbook where on-call engineers
will find it, not in the README or a general tutorial.
```

`<!-- coach:hints stop -->`
