> このドキュメントは `.claude/meta/references/examples/release-and-deployment.md` の日本語訳です。英語版が原文（Source of Truth）です。

---
domain: release-and-deployment
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: devops-engineer
contributing-agents: [devops-engineer]
---

> **読み取り専用リファレンス。** このファイルは ECC Base Template に同梱された実装例であり、実際のプロジェクトの多くのセッションを経て積み上がったナレッジファイルがどのような姿になるかを示しています。これはあなた自身のナレッジファイルでは**ありません**。あなた自身のナレッジファイルは `.claude/learn/knowledge/release-and-deployment.md` にあり、実際の作業においてエージェントが内容を拡充するまでは空の状態です。エージェントは `.claude/meta/references/examples/` 配下のファイルを読み込んだり、引用したり、書き込んだりすることは一切ありません。このツリーは人間の読者専用です。設計の背景については [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) を参照してください。

---

<a id="how-to-read-this-file"></a>
## このファイルの読み方

各セクションのレベルマーカーは想定読者を示しています。
- `[JUNIOR]` — 第一原理からの説明。事前知識を前提としません。
- `[MID]` — このスタックにおける、一見しただけでは気づきにくい慣用的な応用。
- `[SENIOR]` — デフォルト以外のトレードオフの評価。何を諦めるかを明示します。

---

<a id="cicd-pipeline-shape"></a>
## CI/CD パイプラインの形状  [JUNIOR]

<a id="first-principles-explanation--junior-"></a>
### 第一原理からの説明  [JUNIOR]

**CI/CD パイプライン**は、コードが変更されるたびに実行されるチェックと操作の自動化されたシーケンスです。CI（継続的インテグレーション）はすべての変更を自動的に検証します。コンパイル、リント、テスト。CD（継続的デプロイメントまたは継続的デリバリー）は検証済みの変更をパッケージ化してデプロイ可能な状態にします。本番前の手動ゲートはある場合もない場合もあります。

パイプラインがなければ、デプロイは手動です。開発者がローカルでビルドコマンドを実行し、成果物をプッシュして、サーバーをその場で編集します。これにより一貫性のないビルド（開発者の環境が異なる）、スキップされたテスト、再現できないステップが生まれます。パイプラインは同じシーケンスが毎回制御された環境で実行されるため、これら 3 つの障害モードをすべて排除します。

<a id="idiomatic-variation--mid-"></a>
### 慣用的なバリエーション  [MID]

Meridian のパイプラインは GitHub Actions で実行され、CI とデプロイを 2 つの別々のワークフローファイルに分割しています。CI はすべてのブランチへのすべてのプッシュおよびすべてのプルリクエストで実行されます。デプロイワークフローは `main` で CI がパスした後にのみ実行されます。フロントエンドは自動的に、バックエンドは手動確認ゲート付きで実行されます。

**CI ワークフロー（`.github/workflows/ci.yml` — バックエンドマトリックス）：**

```yaml
jobs:
  backend:
    name: Backend — ${{ matrix.job }}
    runs-on: ubuntu-latest
    strategy:
      matrix:
        job: [lint, vet, unit, integration, build]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
          cache: true

      - name: lint
        if: matrix.job == 'lint'
        run: golangci-lint run ./...

      - name: unit
        if: matrix.job == 'unit'
        run: go test -race -count=1 ./... -short

      - name: integration
        if: matrix.job == 'integration'
        run: go test -race -count=1 -run Integration ./...
        env:
          TEST_DB_DSN: ${{ secrets.TEST_DB_DSN }}

      - name: build
        if: matrix.job == 'build'
        run: go build -o /dev/null ./cmd/server
```

マトリックスは 5 つのジョブを並行してファンアウトさせます。`integration` ジョブは（シークレット注入された DSN 経由で）実際のデータベースに触れる唯一のものです。`build` ジョブは `/dev/null` にコンパイルして、モックテストが見逃す「テストでは動くがコンパイルで失敗する」エラーを捕捉します。

**イメージビルドとステージングデプロイ（`main` でトリガー）：**

```yaml
  image:
    name: Build and push image
    needs: [ci-gate]     # CI ワークフローを必須ゲートとして再利用
    runs-on: ubuntu-latest
    steps:
      - uses: docker/build-push-action@v5
        with:
          push: true
          tags: ghcr.io/meridian/backend:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy-staging:
    needs: image
    environment: staging
    steps:
      - name: Update staging image tag
        run: |
          kubectl set image deployment/meridian-backend \
            backend=ghcr.io/meridian/backend:${{ github.sha }} \
            --namespace=staging
```

本番デプロイは別の `workflow_dispatch` ワークフローです。チームメンバーがステージングを少なくとも 1 時間観察した後に手動でトリガーします。

<a id="trade-offs-and-constraints--senior-"></a>
### トレードオフと制約  [SENIOR]

マトリックス戦略はプッシュごとに 9 つの同時ジョブ（バックエンド 5 + フロントエンド 4）を生成します。チームのコミットペースで 1 日あたり約 900 ランナー分。逐次 CI はランナーコストは安くなりますが、ウォールクロックフィードバックを約 3 分から約 12 分に押し上げます。チームは 3 分の CI フィードバックを開発者体験の優先事項として扱います。12 分待ちのコンテキストスイッチングコストはランナー予算より高くなります。

デプロイワークフロー内で CI を再実行する `ci-gate` ジョブは、プッシュが新鮮な実行をトリガーしたばかりの場合には冗長です。約 2 分かかり、デプロイワークフローを自己完結したものにします。手動で再トリガーされたデプロイは、イメージをビルドする前にも検証されます。

### 関連セクション

- [operational-awareness → Alerting on Deploy](./operational-awareness.md#alerting-on-deploy) を参照してください。K8s ロールアウト完了時にデプロイメントマーカーを発火する Datadog インテグレーションについて説明しています。
- [dependency-management → Supply Chain in the Image Build](./dependency-management.md#supply-chain-in-image-build) を参照してください。CI 内のイメージビルドでサプライチェーンの整合性を強制する `go mod verify` と `pnpm --frozen-lockfile` について説明しています。

---

<a id="rolling-deploy-in-kubernetes"></a>
## Kubernetes でのローリングデプロイ  [JUNIOR]

<a id="first-principles-explanation--junior--1"></a>
### 第一原理からの説明  [JUNIOR]

**デプロイメント戦略**は新しいバージョンが古いバージョンを置き換える方法を制御します。一般的なものが 3 つあります。**直接置換**（古いものを停止して新しいものを開始する。ダウンタイムが発生する）、**ブルーグリーン**（2 つの完全な環境を同時に実行してトラフィックをアトミックに切り替える）、**ローリング**（残りのものがリクエストを処理し続けながらインスタンスを 1 つずつ置き換える）です。

ローリングデプロイは古い Pod を新しいものに徐々に置き換えることで機能します。ロードバランサーはヘルシーな Pod にのみトラフィックをルーティングします。各新しい Pod がレディネスプローブにパスするにつれて、プールに参加します。古い Pod は少なくとも 1 つの新しい Pod が準備完了になった後にのみ終了されます。新しい Pod がレディネスプローブに失敗すると、ロールアウトは自動的に一時停止されます。Kubernetes は現在のものが安定するまで次の置換に進みません。

<a id="idiomatic-variation--mid--1"></a>
### 慣用的なバリエーション  [MID]

Meridian のバックエンドは 6 レプリカで実行されます。`Deployment` マニフェスト：

```yaml
# k8s/production/deployment.yaml
spec:
  replicas: 6
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    spec:
      containers:
        - name: backend
          image: ghcr.io/meridian/backend:PLACEHOLDER
          readinessProbe:
            httpGet:
              path: /healthz/ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 3
          livenessProbe:
            httpGet:
              path: /healthz/live
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 10
```

`maxSurge: 1` はロールアウト中に必要な数より 1 つ多い Pod を許可します。一時的に最大 7 Pod になります。`maxUnavailable: 0` は交換先が準備完了になるまで Pod が終了されないことを保証します。デプロイ中はクラスターの Pod 数が 6 を下回ることはありません。

`/healthz/ready` はレディと報告する前に Postgres と Redis の接続を確認します。データベースに到達できない Pod はロードバランサープールの外に留まります。Kubernetes はそれを成功した交換としてカウントせず、その代わりに古い Pod を終了しません。

<a id="trade-offs-and-constraints--senior--1"></a>
### トレードオフと制約  [SENIOR]

**なぜブルーグリーンではないか？** ブルーグリーン戦略は各デプロイで通常の 7 Pod の代わりに 12 Pod が必要になり、デプロイウィンドウのコンピュートコストが倍増します。Meridian の 99.9% SLA（月あたり約 43 分のエラーバジェット）はローリングアップデートで達成可能です。SLA が厳しくなるかロールアウトウィンドウが大幅に増えるまで、ブルーグリーンのコストは正当化されません。

**なぜカナリアではないか？** 6 レプリカでは、カナリア Pod はトラフィックの約 1/7 を受け取ります。モニタリングウィンドウが閉じる前にエラーを統計的に有意に検出するには小さすぎるサンプルです。カナリアは、5% のトラフィックが数分以内に意味のあるシグナルを提供するのに十分なトラフィックボリュームがあるときに価値を発揮します。この問いは約 50 万 DAU 時点で再検討する価値があります。

**なぜ `maxUnavailable: 0` か？** ロールアウト中に 1 Pod の利用不可を許可するとロールアウト時間は短縮されますが、ピーク負荷ウィンドウで Meridian の Pod 数が 6 から 5 に低下します。6 レプリカ数は p99 負荷に合わせてサイジングされています。デプロイ中に 5 で動作すると、SLA が基準としている 200ms ターゲットを超えて p95 レスポンスタイムが押し上げられるリスクがあります。

### 関連セクション

- [persistence-strategy → Online Migrations on the 50M-Row Tasks Table](./persistence-strategy.md#online-migrations-on-the-50m-row-tasks-table) を参照してください。新しい Pod が起動する前に完了しなければならないマイグレーションパターンについて説明しています。デプロイワークフローのマイグレーションジョブゲートによって強制されます。

---

<a id="database-migrations-as-a-deploy-gate"></a>
## デプロイゲートとしてのデータベースマイグレーション  [MID]

<a id="first-principles-explanation--junior--2"></a>
### 第一原理からの説明  [JUNIOR]

データベースマイグレーションはバージョン管理されたスキーマ変更です。スキーマにまだない列を期待する新しいアプリケーションコードはすぐに失敗します。順序の問題は：マイグレーションは新しい Pod が起動する前に実行すべきか後に実行すべきか？

マイグレーションが新しい Pod の後に実行されると、新しいコードは短いウィンドウの間古いスキーマに対して実行されます。クエリが失敗します。マイグレーションが新しい Pod の前に実行されると、古いコードが新しいスキーマに対して実行されます。マイグレーションが**追加的**である限りこれは安全です。新しい列、新しいテーブル、新しいインデックス。古いコードは新しい列を無視します。列が存在しても壊れません。

これが**エクスパンド-コントラクトパターン**です。スキーマを後方互換性のある方法で拡張します。古いコードは動作を継続します。新しいコードは拡張されたスキーマを使用します。破壊的な変更（ドロップ、リネーム）は別途明示的に計画されたウィンドウと個別のランブックを必要とします。

<a id="idiomatic-variation--mid--2"></a>
### 慣用的なバリエーション  [MID]

Meridian はローリングアップデートが開始される前に Kubernetes の `Job` を実行します。このジョブは同じコンテナイメージを使用しますが、エントリポイントをオーバーライドして `golang-migrate` を実行します。

```yaml
# k8s/production/migration-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: meridian-migrations-${{ github.sha }}
  namespace: production
spec:
  backoffLimit: 0   # 失敗時は高速に失敗する。部分的なマイグレーションはリトライしない
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: migrate
          image: ghcr.io/meridian/backend:${{ github.sha }}
          command:
            - /app/migrate
            - -database
            - $(DATABASE_URL)
            - -path
            - /app/migrations
            - up
```

デプロイワークフローはローリングアップデートをジョブにゲートしています。

```yaml
      - name: Run migrations
        run: |
          kubectl apply -f k8s/production/migration-job.yaml
          kubectl wait --for=condition=complete \
            job/meridian-migrations-${{ github.sha }} \
            --timeout=300s --namespace=production
      # kubectl wait がタイムアウトするか非ゼロで終了するとステップが失敗する。
      # マイグレーションの失敗時、ローリングアップデートステップには到達しない。
```

`backoffLimit: 0` は失敗した部分的なマイグレーションがサイレントにリトライするのを防ぎます。ジョブが失敗すると、デプロイは停止してチームが進める前に調査します。`golang-migrate` は適用済みのバージョンを `schema_migrations` テーブルで追跡するため、部分的な失敗後の再実行は冪等な DDL に対して安全です。

追加マイグレーションルールはツールではなくコードレビューで強制されます。非推奨の列はそのままにされます。アプリケーションコードはそれへの書き込みを停止します。削除は、明示的なランブックを持つ低トラフィック時間帯の別のデプロイウィンドウでスケジュールされます。

<a id="trade-offs-and-constraints--senior--2"></a>
### トレードオフと制約  [SENIOR]

追加マイグレーションルールはスキーマの死荷重を蓄積します。5,000 万行の `tasks` テーブルでは、null でないデフォルト値を持つ未使用の `TIMESTAMPTZ` 列は行あたり約 8 バイトを追加します。フルスケールで約 400 MB になります。チームはメンテナンスアナウンスと明示的なロールバックプランを組み合わせた四半期ごとの破壊的なウィンドウをスケジュールします。

代替案（通常のデプロイで破壊的なマイグレーションを許可する）はスキーマのクリーンアップを簡略化しますが、ロールバックのリスクを生じさせます。デプロイが 5 分以内にロールバックされる場合（ロールバックセクション参照）、ドロップされた列はなくなり、リバートされたコードはそれを読み取れません。破壊的なマイグレーションのロールバックはリストア操作であり、ワンコマンドの取り消しではありません。追加ルールはスキーマの蓄積を保証されたロールバックの安全性と交換します。四半期ごとの破壊的なウィンドウは、明示的に計画されたリスクウィンドウでクリーンアップを処理します。

### 関連セクション

- [persistence-strategy → Online Migrations on the 50M-Row Tasks Table](./persistence-strategy.md#online-migrations-on-the-50m-row-tasks-table) を参照してください。デプロイウィンドウ内の追加マイグレーションが従う `NOT VALID`、`CONCURRENTLY`、2 デプロイ列削除パターンについて説明しています。
- [testing-discipline → Integration Tests Against a Real Schema](./testing-discipline.md#integration-tests-against-a-real-schema) を参照してください。CI インテグレーションジョブがマイグレーション済みスキーマに対して実行し、ステージングに到達する前にマイグレーションとコードのミスマッチを捕捉する方法について説明しています。

---

<a id="rollback-procedure"></a>
## ロールバック手順  [MID]

<a id="first-principles-explanation--junior--3"></a>
### 第一原理からの説明  [JUNIOR]

ロールバックは、デプロイされたバージョンを前の既知の良好な状態に戻します。すべてのデプロイメントには定義されたロールバック手順が必要です。この手順は「このデプロイは悪い」から「サービスが健全である」への最速のパスを答えます。

アプリケーションコードのロールバックは安価です。前のバージョンのコンテナイメージはレジストリにキャッシュされており、Kubernetes は 1 分以内に再デプロイできます。データベースマイグレーションのロールバックは高コストです。逆マイグレーションが必要で、大きなテーブルでは遅くなる可能性があり、データがすでに新しいスキーマに書き込まれている場合はデータ損失なしには不可能かもしれません。この非対称性が Meridian の設計を形作っています。追加マイグレーションはコードのロールバックをスキーマの決定から切り離します。

<a id="idiomatic-variation--mid--3"></a>
### 慣用的なバリエーション  [MID]

**ポリシー：** デプロイが本番インシデントを引き起こした場合、チームはロールバックするか修正をフォワードするかを 5 分以内に決定します。5 分以内に決定がなければ、オンコールエンジニアはデフォルトでロールバックを開始します。

**アプリケーションロールバック（2 分未満）：**

```bash
# 前の Deployment リビジョンにロールバック
kubectl rollout undo deployment/meridian-backend --namespace=production

# すべての Pod が前のイメージになるまで確認
kubectl rollout status deployment/meridian-backend --namespace=production

# スモークテストで検証
curl -s https://api.meridian.app/healthz/ready | jq .
```

`maxUnavailable: 0` が設定されているため、ロールバック自体もローリング置換です。ゼロダウンタイムです。

**マイグレーションロールバック決定ツリー：**

```
1. ロールバックされたコードは新しいスキーマと互換性があるか？
   （古いスキーマと新しいスキーマの両方に存在した列のみを読み書きするか？）
   はい → スキーマをそのままにします。マイグレーションのロールバックは不要。

2. フォワードマイグレーションは追加のみだったか？
   はい → 新しいスキーマには古いコードが無視する追加の列やテーブルがあります。安全。ロールバック不要。
   いいえ → マイグレーションが古いコードが必要とする何かをドロップまたはリネームしました。
           DBA にエスカレート。docs/en/runbooks/migration-recovery.md のランブックで逆マイグレーションを実行。データ損失の可能性を受け入れる。
```

Meridian の追加マイグレーションポリシーでは、ステップ 1 または 2 の答えは常に「はい」です。決定ツリーは安全チェックであり、レアな破壊的ウィンドウのエスカレーションパスです。

**フォワードロールバック vs. ロールバック：** フォワードロール（修正をデプロイする）は、欠陥が理解されていて修正が小さく、15 分以内にデプロイが完了できる場合に推奨されます。フォワードロールは古いリグレッションを持つコードを再デプロイすることを避け、次の本当のデプロイ時にマイグレーションを再実行することを避けます。5 分のウィンドウは選択を強制します。修正が 5 分以内に準備できなければ、安定した条件でロールバックしてデバッグします。

<a id="trade-offs-and-constraints--senior--3"></a>
### トレードオフと制約  [SENIOR]

`kubectl rollout undo` は直前のリビジョンに戻ります。2 つのデプロイが続けて行われた場合、`rollout undo` は実際には安全でない中間状態になる可能性があります。Meridian はこれを、すべての本番デプロイに git SHA をタグ付けすることで処理します。

```bash
kubectl set image deployment/meridian-backend \
  backend=ghcr.io/meridian/backend:<known-good-sha> \
  --namespace=production
```

これはリビジョン履歴を完全にバイパスし、リビジョンスタックがロールバックターゲットを反映していない場合に適切です。

5 分の決定ウィンドウは 99.9% SLA（月あたり 43 分のエラーバジェット）に合わせて調整されています。ロールバック前に 10 分間実行されたインシデントは月次バジェットの 23% を消費します。より速い決定は同じ期間の他のインシデントのためのヘッドルームを保持します。

### 関連セクション

- [operational-awareness → Error Budget Tracking](./operational-awareness.md#error-budget-tracking) を参照してください。月次エラーバジェット 43 分の追跡方法とデプロイインシデントがどのようにそれを消費するかについて説明しています。
- [persistence-strategy → Online Migrations on the 50M-Row Tasks Table](./persistence-strategy.md#online-migrations-on-the-50m-row-tasks-table) を参照してください。通常ケースでマイグレーションロールバック決定に常に「安全」と答えるマイグレーションパターンについて説明しています。

---

<a id="prior-understanding-deploy-on-every-pr-merge"></a>
## Prior Understanding：すべての PR マージでデプロイする  [MID]

<a id="prior-understanding-revised-2026-01-15"></a>
### Prior Understanding (revised 2026-01-15)

Meridian の元の CI/CD 設計は、`main` へのすべてのマージで自動的にバックエンドを本番にデプロイしていました。理由は「コードがマージされた」から「コードが本番にある」までのギャップを最小化することでした。実際には、2 つの繰り返し問題が発生しました。

1. **マイグレーションタイミングのサプライズ。** 3 回、ローカルで素早く検証されたマイグレーションが 5,000 万行の本番データベースに対してはるかに長くかかりました。マイグレーションジョブが 5 分のタイムアウトを超え、デプロイワークフローが途中で失敗し、バックエンドの Deployment はマイグレーションが部分的に適用された状態で古いイメージを指したままでした。各インシデントは手動での回復を必要としました。

2. **ステージングのソーク時間が不十分。** 本番への自動デプロイは、ステージングと本番デプロイの間が CI の期間、約 3 分しかないことを意味していました。持続的な負荷や特定の顧客データのもとでのみ現れるエラーはそのウィンドウでは見えませんでした。

**修正後の理解：**

現在のポリシーは、ステージングを少なくとも 1 時間観察した後の手動 `workflow_dispatch` に本番バックエンドデプロイをゲートしています。フロントエンド（CDN 経由で提供される静的 React ビルド）は自動デプロイを継続しています。フロントエンドのロールバックは簡単です（CDN キャッシュの無効化、マイグレーションなし）。1 時間のソークはそのリスクプロファイルに対して不釣り合いです。

教訓：「マージごとにデプロイする」はロールバックパスが簡単なステートレスサービスには適切であり、ロールバックにデータベースマイグレーションが伴う場合や本番負荷の状況がステージングと大きく異なるサービスには管理すべきリスクです。適切なペースはロールバックのコストと環境パリティに依存し、一様な原則ではありません。

---

<a id="coach-illustration-default-vs-hints"></a>
## コーチイラストレーション（default vs. hints）

> **例示のみ。** 以下はこのドメインのタスクにおける 2 つのコーチングスタイルの違いを示した実例です。ライブエージェントのコントラクトの一部ではありません。実際のエージェントの動作は `.claude/skills/learn/coach-styles/` のスタイルファイルによって管理されます。

**シナリオ：** 学習者が Meridian の新しいバルクエクスポート機能を実装しており、99.9% SLA 要件と機能が新しいデータベーステーブルとスキーママイグレーションを必要とすることを踏まえて、安全にリリースする方法を尋ねます。

**`default` スタイル** — エージェントは完全な実装計画を作成します。追加マイグレーションファイル（`bulk_export_jobs` テーブル、NULL 許容列のみ）、`config/flags.go` のフィーチャーフラグ宣言、マイグレーション用の Kubernetes `Job` マニフェスト、マイグレーション完了でロールアウトをゲートする更新されたデプロイワークフロー、そしてこの特定のスキーマ変更のロールバック決定ツリー。エクスパンド-コントラクトマイグレーションパターンと手動本番デプロイゲートの背後にある推論を説明する `## Learning:` トレーラーを追記します。学習者は完成した実行可能な成果物を受け取ります。

**`hints` スタイル** — エージェントはマイグレーションファイルスタブ（テーブル名と列を宣言し、インデックスは TODO のまま）と `config/flags.go` のフィーチャーフラグスタブを書きます。それから以下を出力します。

```
## Coach: hint
Step: Write the Kubernetes Job manifest for the migration and add the kubectl wait gate
to the deploy workflow before the rolling update step.
Pattern: Migration job gating (expand-contract; migrations run before new pods come up).
Rationale: If new pods start before the migration completes, queries to the new table
fail until the migration finishes — a window of errors consuming error budget. The Job
manifest ensures migrations complete successfully before Kubernetes proceeds with the
image swap.
```

`<!-- coach:hints stop -->`

学習者が Job マニフェストとワークフローゲートを書きます。次のターンで、エージェントはマイグレーションやフラグのスキャフォールドを再書き込みせずにロールバックに関するフォローアップの質問に応答します。
