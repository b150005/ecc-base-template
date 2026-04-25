> このドキュメントは `docs/en/learn/examples/business-modeling.md` の日本語訳です。英語版が原文（Source of Truth）です。

---
domain: business-modeling
type: example
status: reference
fictional-project: "Meridian — B2B task-management SaaS (Go + Gin + PostgreSQL + Redis backend, React + TanStack Query + TypeScript frontend, Kubernetes + GitHub Actions deployment, per-seat subscription pricing)"
version: v2.2.0
owning-agent: monetization-strategist
contributing-agents: [monetization-strategist, market-analyst]
---

> **読み取り専用リファレンス。** このファイルは ECC Base Template に同梱された実装例であり、実際のプロジェクトの多くのセッションを経て積み上がったナレッジファイルがどのような姿になるかを示しています。これはあなた自身のナレッジファイルでは**ありません**。あなた自身のナレッジファイルは `learn/knowledge/business-modeling.md` にあり、実際の作業においてエージェントが内容を拡充するまでは空の状態です。エージェントは `docs/en/learn/examples/` 配下のファイルを読み込んだり、引用したり、書き込んだりすることは一切ありません。このツリーは人間の読者専用です。設計の背景については [ADR-003 §5](../adr/003-learning-mode-relocate-and-rename.md) を参照してください。

---

<a id="how-to-read-this-file"></a>
## このファイルの読み方

各セクションのレベルマーカーは想定読者を示しています。
- `[JUNIOR]` — 第一原理からの説明。事前知識を前提としません。
- `[MID]` — このスタックにおける、一見しただけでは気づきにくい慣用的な応用。
- `[SENIOR]` — デフォルト以外のトレードオフの評価。何を諦めるかを明示します。

---

<a id="three-tier-per-seat-pricing"></a>
## 3 層構造のシート単価制料金  [JUNIOR]

<a id="first-principles-explanation--junior-"></a>
### 第一原理からの説明  [JUNIOR]

**料金ティア**は、固定価格（B2B SaaS ではユーザー 1 人 1 ヶ月あたり）で販売される、公開された機能バンドルです。**ティア構造**は 2 つ以上のバンドルを提供し、支払意欲（Willingness to Pay）の異なる顧客が自己選択できるようにします。

ティアが存在する理由は、支払意欲が均一ではないからです。5 人のエージェンシーは、SSO を必要とする 40 人チームが正当化できる金額を正当化できません。単一価格では、より安く買える顧客への取りこぼしか、小規模購入者の排除のどちらかになります。素朴な設計は「機能が多い = 高い価格」で、**アンカーティア**（料金ページが実際に売ろうとするティア）がないラダーを生み出します。よく設計されたセットは、1 つのアンカー、ファネルを広げるより安いティア、高い支払意欲を取り込む 1 つのプレミアムティアを持ちます。

<a id="idiomatic-variation--mid-"></a>
### 慣用的なバリエーション  [MID]

Meridian は 3 つのティアを販売しています。すべてユーザー 1 人 1 ヶ月あたりの年次請求です。

| ティア | 価格 | 含まれるもの | 含まれないもの |
|------|-------|------------|----------|
| Starter | $10/ユーザー/月 | ウェブアプリ、タスクボード、基本通知 | Slack/カレンダー、SSO、監査ログ |
| Team | $20/ユーザー/月 | Starter + Slack、カレンダー同期、繰り返しタスク | SSO、監査ログ |
| Business | $35/ユーザー/月 | Team + SSO（SAML/OIDC）、監査ログ、高度なロール、優先サポート | — |

**Team** ティアがアンカーです。Meridian のポジショニングを定義する Slack インテグレーションを持っています。課金シートの約 78% が Team にあります。価格の刻み（$10 → $20 → $35）は線形ではなく、おおよそ等比数列（2x、1.75x）です。等比間隔はアップグレードの決断を量的なもの（「7 ドル/シートの違いはどうか？」）ではなく質的なもの（「Slack インテグレーションが必要か？」）にします。線形間隔（$10、$15、$20）は下方への交渉を誘います。等比間隔は、より安いティアを目に見えて真剣さが不足しているものにします。

<a id="trade-offs-and-constraints--senior-"></a>
### トレードオフと制約  [SENIOR]

3 つのティアは 2 つより運用コストが高くなります。3 つの SKU、3 つのフィーチャーフラグ、3 つのセールスモーション、3 つのコホート。単一の有料ティア設計はよりシンプルですが、SSO セグメントを見逃し、大規模アカウントから収益をリークします。

Starter には正当な批判があります。品質の低いトライアルをコンバートし、収益に対して不釣り合いなサポート負荷を生成します。反論は、Starter がトップオブファネルを倍増させており、純新規 ARR の約 14% が Starter から始まって成長したアカウントから来ているということです。常設ルール：Starter から Team へのコンバージョンが 90 日以内に 30% を下回った場合、ティアは再検討のために開かれます。

Business は価格ではなく機能によって制約されています。SSO がリリースされるまで（[market-reasoning → Deferring Enterprise SSO](./market-reasoning.md#deferring-enterprise-sso) 参照）、Meridian は本物の Business ティアを提供できませんでした。18 ヶ月で 1 件しか成約しない「営業にご連絡ください」のプレースホルダーしかありませんでした。

### 例（Meridian）

```ts
// frontend/src/lib/pricing.ts
export const TIERS = [
  { key: 'starter',  monthly: 10, annual: 96,  badge: null },
  { key: 'team',     monthly: 20, annual: 192, badge: 'most-popular' },
  { key: 'business', monthly: 35, annual: 336, badge: 'enterprise-ready' },
] as const;
```

Team の `most-popular` バッジが視覚的なアンカーです。実験でこれを削除すると、4 週間で新規コンバージョンにおける Team のシェアが約 9 パーセントポイント低下しました。このキューは実際の効果を発揮しています。

### 関連セクション

- [market-reasoning → Meridian Positioning](./market-reasoning.md#meridians-positioning-vs-linear-and-asana) を参照してください。Team が Slack インテグレーションを持つ理由について説明しています。
- [business-modeling → Unit Economics at $1.5M ARR](#unit-economics-at-15m-arr) を参照してください。ティア価格が LTV にどのようにフィードするかについて説明しています。
- [documentation-craft](./documentation-craft.md)（入力済みの場合）を参照してください。料金ページのコピーレビュープロセスについて説明しています。

### コーチイラストレーション（default vs. hints）

> **例示のみ。** ライブエージェントのコントラクトの一部ではありません。`.claude/skills/learn/coach-styles/` によって管理されます。

**シナリオ：** 学習者が、監査ログは必要だが SSO は不要な顧客向けに、Team と Business の間に $28/ユーザー/月の第 4 ティアを追加すべきかどうかを尋ねます。

**`default` スタイル** — エージェントは既存の等比数列に対して評価します。第 4 ティアはアップグレードの決断を価格比較に圧縮します。監査ログを SSO から分離すると 2 つのコンプライアンス SKU が生まれます。セグメントが大きくない限り、運用コストは通常増分収益を超えます。監査ログを Team に（Team を約 $22 に引き上げることで）バンドルして 3 ティアの形を維持することを推薦し、`## Learning:` トレーラーで説明します。

**`hints` スタイル** — エージェントはフレームワーク（等比間隔は質的なアップグレードの決断を維持する。ティア数は収益よりも速く運用コストを増大させる）に名前を付け、リスク（新しいティアが比較アンカーになり Team のコンバージョンを侵食する）に名前を付け、以下を出力します。

```
## Coach: hint
Step: Evaluate the proposed fourth tier against operational cost vs. revenue.
Pattern: Tier-count discipline (anchor tier preservation).
Rationale: A tier near the anchor shifts the conversation from "do we need integrations?"
to "is $7/seat worth the audit log?" — the latter invites negotiation downward.
```

`<!-- coach:hints stop -->`

学習者が分析を作成します。エージェントは次のターンで評価をやり直すことなく応答します。

---

<a id="unit-economics-at-15m-arr"></a>
## $1.5M ARR 時のユニットエコノミクス  [MID]

<a id="first-principles-explanation--junior--1"></a>
### 第一原理からの説明  [JUNIOR]

**ユニットエコノミクス**は顧客ごとの視点です。顧客を獲得するのにかかるコスト（CAC）、その顧客の価値（LTV）、そしてその間の関係です。

- **CAC：** ある期間の販売・マーケティング支出を、獲得した顧客数で割ったもの。
- **ACV：** 1 顧客からの年間収益。
- **LTV：** 顧客が関係の期間中に生み出すと期待される粗利益。標準的な SaaS の近似式は `LTV ≈ (粗利益率 × ACV) / チャーンレート`。

**3:1 LTV:CAC ヒューリスティック**は B2B SaaS で最も引用されるルールです。健全なビジネスは獲得に費やした 1 ドルあたり少なくとも 3 ドルの粗利益を回収します。1:1 未満ではすべての顧客で損失が出ます。1:1 から 3:1 の間では獲得コストは回収されますが、成長とオーバーヘッドはファンドされません。このヒューリスティックは出発点であり、終点ではありません。

<a id="idiomatic-variation--mid--1"></a>
### 慣用的なバリエーション  [MID]

$1.5M ARR 時点での Meridian のスナップショット（2026 年 Q1 直近 12 ヶ月）：

| メトリクス | 値 | 備考 |
|--------|-------|-------|
| ACV（ブレンド） | $3,200 | すべてのティア、課金シートで加重 |
| 購入時の平均チームサイズ | 14 シート | 最初の請求書。定常状態ではない |
| 粗利益率 | 78% | ホスティング + Slack/カレンダー API + 支払い |
| 年間粗ロゴチャーン | 12% | 下記のチャーンエントリ参照 |
| CAC（ブレンド） | $1,200 | 主にインバウンド + コンテンツ。Business には一部アウトバウンド |
| LTV（ブレンド） | (0.78 × $3,200) / 0.12 ≈ **$20,800** | 標準的な SaaS 近似式 |
| LTV:CAC | ~17:1 | トレードオフセクション参照 |

CAC が $1,200 と低いのは、獲得が主にインバウンドだからです。コンテンツ、比較ページの SEO、Slack App Directory のリスティング。Business 案件は（セキュリティレビューを伴うセールス主導のモーションを含むため）より高い CAC（約 $3,800）を持ちます。78% の粗利益率は、販売、マーケティング、R&D、オーバーヘッドではなく、インフラ、メッセージあたりの Slack コスト、カレンダー API クォータ、決済処理手数料、カスタマーサクセスに対して収益を差し引いたものです。

<a id="trade-offs-and-constraints--senior--1"></a>
### トレードオフと制約  [SENIOR]

17:1 の比率はスナップショットです。3 つの力が時間をかけてそれを圧縮します。

1. **チャネルが飽和するにつれての CAC インフレ。** 最初の $100K のコンテンツがインバウンドの大部分を生み出しました。次の $100K はそうではないでしょう。CAC が 4 倍に増加すると比率は約 4:1 になります。成長投資の再検討が必要な領域に近づきます。
2. **エンタープライズが成長するにつれての利益率の圧縮。** Business ティアの顧客はより多くのサポートを消費し、保持コストのかかる監査ログのボリュームを生み出します。78% の利益率は Team に偏った数値です。Business が多いミックスでは約 72% になります。
3. **顧客ミックスが変わるにつれてのチャーンのリベース。** 12% のレートは ICP 改訂後のミックスを反映しています（[market-reasoning → Prior Understanding: ICP Revision After 50 Customers](./market-reasoning.md#prior-understanding-icp-revision-after-50-customers) 参照）。改訂前のコホートは 35% 以上でチャーンしていました。より広いターゲティングに戻ると再導入されます。

より深い問題：Meridian は設立から 2 年半であるため、すべての LTV は完全な存続期間にわたって観察されていないチャーンレートからの外挿です。17:1 はモデルの出力であり、観察された事実ではありません。より誠実なフレーミングは「12 ヶ月のペイバックが CAC の約 1.7 倍を回収する」にチャーン曲線の感度テーブルを加えたものです。

### 例（Meridian）

モデルは 3 つのビューで月次更新されます。ブレンド（取締役会）、ティア別（プロダクト）、コホート別（1〜24 ヶ月の保持）。ティア別ビューが問題を捕捉します。2025 年に 2 四半期にわたって低下した Team ティアの LTV は、サポートチケットでは見えないが、シートの縮小で見えた Slack 通知のレートリミット問題が満足度を侵食しているという先行指標でした。

### 関連セクション

- [business-modeling → Net Dollar Retention and Land-and-Expand](#net-dollar-retention-and-land-and-expand) を参照してください。拡大が LTV とどのように相互作用するかについて説明しています。
- [business-modeling → Annualized Gross Logo Churn](#annualized-gross-logo-churn) を参照してください。LTV 近似式の背後にあるチャーン方法論について説明しています。
- [market-reasoning → SAM Calculation Methodology](./market-reasoning.md#sam-calculation-methodology) および [operational-awareness](./operational-awareness.md)（入力済みの場合）を参照してください。ユニットエコノミクスのドリフトとして現れた市場規模推計と Slack レートリミットインシデントについて説明しています。

---

<a id="net-dollar-retention-and-land-and-expand"></a>
## ネットドル保持とランド・アンド・エクスパンド  [MID]

<a id="first-principles-explanation--junior--2"></a>
### 第一原理からの説明  [JUNIOR]

シート単価制のサブスクリプションビジネスでは、顧客は静的ではありません。2 つのメトリクスがチャーンと拡大の純効果を表します。

- **GDR（グロスドル保持）：** 期間開始時の収益のうち、期間終了時に回収される割合。同じ顧客からの新規収益は除きます。100% を上限とします。
- **NDR（ネットドル保持）：** GDR に既存顧客からの拡大収益を加えたもの。拡大がチャーンと縮小を上回る場合、100% を超えることがあります。

NDR > 100% は強力な「ランド・アンド・エクスパンド」メカニクスのシグネチャーです。既存のベースがチャーンより速く成長し、新しいロゴを獲得することなく複利収益を生み出します。このメカニクスを持つプロダクトは、最初のチームでの成功がセールスなしに 2 番目のチームへの需要を生み出すものです。

<a id="idiomatic-variation--mid--2"></a>
### 慣用的なバリエーション  [MID]

Meridian は 4 つのモーションを個別に計測しています。直近 12 ヶ月（2026 年 Q1）：

- 新規ロゴ ARR：約 $540K
- 拡大 ARR（シート + ティアアップグレード）：約 $310K
- 縮小 ARR（解約なしのダウングレード）：約 $60K
- チャーン ARR（完全解約）：約 $140K
- **NDR ≈ 113%、GDR ≈ 86%**

NDR 113% は、新規ロゴがゼロでもビジネスが約 13% 成長することを意味します。拡大はシート成長が支配的です。追加された各シートは獲得コストなしに増分 ARR です。ティアアップグレード（Team → Business）は拡大 ARR の小さいシェア（約 22%）に貢献しており、シートあたりの利益率は高くなっています。

ダッシュボードは拡大と新規ロゴ成長を意図的に分離しています。それらは異なるエンジンであり、異なる入力によって制約されています。新規ロゴが鈍化するが拡大が加速する四半期は、両方が鈍化するものとは異なります。応答が異なります（チャネル投資 vs. プロダクト投資）。

<a id="trade-offs-and-constraints--senior--2"></a>
### トレードオフと制約  [SENIOR]

NDR には静かな障害モードがあります。**ロゴ保持**が弱い一方で強い NDR を示すことができます。1 つの大口アカウントのシートが倍増すると、10 の小口のチャーンアカウントを相殺できます。ドルの計算では問題ないように見えますが、実際には顧客ベースが空洞化しています。NDR と粗ロゴチャーンを一緒に報告することでこれが明らかになります。

NDR の最適化は、新規ロゴ獲得への過少投資リスクもあります。既存顧客には自然なシートの上限があります。新しいロゴが尽きたビジネスは最終的に拡大を使い果たします。常設ルール：新規ロゴ成長は総 ARR 成長の少なくとも 60% でなければなりません。これを下回ると、ファネル投資計画が見直されます。

拡大は主に Meridian がコントロールできない顧客の採用に依存します。採用の低迷期には、プロダクトの品質とは無関係な理由で拡大が鈍化します。健全な応答は、これを取締役会への報告でマクロ効果として公開することです。

### 例（Meridian）

```sql
-- 拡大の帰属。ベースライン = アカウントごとの MRR の 12 ヶ月前スナップショット
SELECT
  SUM(GREATEST(c.mrr_now - b.mrr_then, 0))                                 AS expansion_mrr,
  SUM(GREATEST(b.mrr_then - c.mrr_now, 0)) FILTER (WHERE c.id IS NOT NULL) AS contraction_mrr,
  SUM(b.mrr_then) FILTER (WHERE c.id IS NULL)                              AS churned_mrr
FROM baseline b LEFT JOIN current_state c USING (account_id);
```

シート変更とティア変更は 1 つの MRR デルタシグナルとして扱われます。顧客は価格を単一の月次請求として体験するためです。必要に応じてモーション別に分解する別のレポートがあります。

### 関連セクション

- [business-modeling → Annualized Gross Logo Churn](#annualized-gross-logo-churn) を参照してください。ロゴチャーンが NDR に埋め込まれるのではなく、NDR と並んで報告される理由について説明しています。
- [market-reasoning → Meridian Positioning](./market-reasoning.md#meridians-positioning-vs-linear-and-asana) を参照してください。シート成長の拡大メカニクスを駆動する Slack ネイティブのポジショニングについて説明しています。

---

<a id="annualized-gross-logo-churn"></a>
## 年間粗ロゴチャーン  [SENIOR]

<a id="first-principles-explanation--junior--3"></a>
### 第一原理からの説明  [JUNIOR]

**チャーン**は、2 つのディメンションで顧客が離れるレートを計測します。

- **ロゴ vs. 収益：** ロゴチャーンはアカウントを数えます。収益チャーンはドルを数えます。
- **グロス vs. ネット：** グロスは失ったものだけを数えます。ネットは拡大を差し引きます。

年換算は月次レートを年次の数値として表します（1% 月次レートは複利で正確に 12% ではなく約 11.4% に年換算されます）。収益チャーンは顧客ベースの空洞化を隠すことがあります。ロゴチャーンは小さなアカウントが失われたときの財務的影響を誇張することがあります。一方のみの報告は混乱のよくある原因です。

<a id="idiomatic-variation--mid--3"></a>
### 慣用的なバリエーション  [MID]

Meridian の主要チャーンメトリクスは**年間粗ロゴチャーン**で、現在約 12% です。チームは 3 つの理由からこれを収益チャーンより選びました。

1. **ロゴ数はディールサイズによって偏りません。** 収益チャーンは少数の大口アカウントに支配されます。1 つの Business ティアの損失がそれを歪めます。約 120 の課金アカウントでは、ロゴチャーンが平滑化されたシグナルです。
2. **グロス（ネットではなく）はプロダクトの失敗を明らかにします。** 信頼性の問題は影響を受けたアカウントがチャーンする一方で影響を受けていないアカウントが拡大します。ネットチャーンはインシデント全体を通じてマイナスのままかもしれません。
3. **初期段階では、顧客数が戦略的な制約です。** より多くのロゴは Slack との、App Directory のランキングとの、Linear と Asana に対して Meridian を評価している見込み客との価格交渉力を高めます。

最もチャーンするコホートは単一のアーキタイプに当てはまります。Starter で、ウェブアプリを有効化したが Slack を接続せず、2〜4 週目に沈黙した単一チームのトライアルです（チャーンしたロゴの約 64%）。2 つの行動は大幅に高い保持率を示します。7 日以内の Slack 有効化（12 ヶ月保持率約 92%）と 90 日以内の 2 番目のチームの採用（保持率約 95%）。2 番目は拡大メカニクスの種です。2 番目のチームが参加すると、アカウントは離脱を高コストにする組織的な閾値を越えたことになります。

<a id="trade-offs-and-constraints--senior--3"></a>
### トレードオフと制約  [SENIOR]

ロゴチャーンだけを報告することは、各損失の財務的規模について沈黙しています。取締役会はティア別の「チャーン ARR」も見ていますが、見出しはロゴチャーンのままです。診断の問いが「プロダクトは顧客を失敗させているか？」であり、カウントで答えられるからです。

12% の数値は**ICP 改訂後**の数値です。改訂前（Meridian が Slack をバイパスした 30 人以上のチームに販売していたとき）、そのコホートは 35% 以上でチャーンしていました。改善は主にプロダクトの変更ではなく、顧客ミックスの変化です。「プロダクトの改善」を評価するナラティブは誇張です。正直なナラティブは、ICP 改訂（[market-reasoning → Prior Understanding: ICP Revision After 50 Customers](./market-reasoning.md#prior-understanding-icp-revision-after-50-customers) 参照）が高チャーンのコホートをフィルタリングしたというものです。

メトリクスは進化します。$50K ACV での Business のチャーンは $1,200 ACV での Starter のチャーンと等価ではありません。計画：Business が ARR の約 25% に達したら**ティア加重粗ロゴチャーン**に切り替えます。

### 例（Meridian）

週次 Looker クエリは、4 週間のトレーリングロゴチャーンレートが直近 12 ヶ月のレートを 1.5 倍以上超えたときに発火します。2025 年 Q3 にトリガーが 18% で発火し、調査により 6 週間にわたって約 40 アカウントのインテグレーションをサイレントに切断した Slack OAuth トークンのローテーションバグが原因と判明しました。バグがパッチされる前に 3 アカウントがチャーンしました。ポストモーテムは「インテグレーション切断レートがベースラインを超えた」という上流のアラートを追加しました。

### 関連セクション

- [business-modeling → Net Dollar Retention and Land-and-Expand](#net-dollar-retention-and-land-and-expand) を参照してください。保持方程式の拡大側について説明しています。
- [business-modeling → Unit Economics at $1.5M ARR](#unit-economics-at-15m-arr) を参照してください。このレートが LTV 近似式にどのようにフィードするかについて説明しています。
- [market-reasoning → Prior Understanding: ICP Revision After 50 Customers](./market-reasoning.md#prior-understanding-icp-revision-after-50-customers) を参照してください。改訂後の低下を説明する顧客ミックスの変化について説明しています。

---

<a id="starter-tier-pricing-experiment-10-vs-12"></a>
## Starter ティアの価格実験（$10 vs. $12）  [MID]

<a id="first-principles-explanation--junior--4"></a>
### 第一原理からの説明  [JUNIOR]

B2B SaaS の価格実験は、コンシューマーソフトウェアより困難です。低トラフィックには長いウィンドウが必要であり、関心のあるメトリクス（生涯収益）はウィンドウ内で計測できません。チームはプロキシ（コンバージョン）を最適化し、長期的なメトリクスと相関しないかもしれないことを受け入れる必要があります。

構造的に誠実な設計は**2 段階の計測**です。ウィンドウ内の近位メトリクスを計測し、その後同じコホートで定義された期間後に下流メトリクスを計測します。2 番目の段階をスキップすることは、コンバージョンで「勝利」を生み出し、保持で静かな長期的損失を生む実験の最もよくある原因です。

<a id="idiomatic-variation--mid--4"></a>
### 慣用的なバリエーション  [MID]

2025 年 Q4 に、Meridian は Starter を $10 から $12 に値上げするテストを行いました。仮説：20% の値上げはコンバージョンにわずかな影響を与え、Starter 顧客あたりの年間収益に意味のある影響を与えるだろう。第 1 段階は 14 日目のトライアルから課金へのコンバージョン。第 2 段階は同じコホートの 90 日目の Team へのアップグレード。ウィンドウは 10 週間で、80% のパワーで 15% の相対変化を検出するようにサイジングされました。

結果：$12 コホートは $10 レートの 91% でコンバートしました（第 1 段階、許容範囲内）。Team には $10 レートの 73% でアップグレードしました（第 2 段階、予期しない結果）。

決定は $10 に戻すことでした。第 1 段階だけでは限界的な収益の勝利でした。第 2 段階が結果を再フレーミングしました。より高い価格は一部のコンバージョンを失っただけでなく、拡大の可能性が低い種類の顧客をコンバートさせる方法でコンバートした顧客の種類を変えていました。実験後の仮説：$12 は Starter で十分だとすでに決めた見込み客を選別しました。$10 は Starter を評価のステップとして見た見込み客を選別しました。

<a id="trade-offs-and-constraints--senior--4"></a>
### トレードオフと制約  [SENIOR]

2 段階の計測は、実験の終了から最終決定まで 90 日の追加を課します。インフラは第 2 段階を汚染することなく次の実験に再利用できません。Meridian のペースは年間最大 3〜4 回の価格実験です。これはプロセスの欠陥ではなく、B2B SaaS の構造的な特徴です。

結果も清潔に一般化できません。実験はその当時のプロダクト、ICP、ポジショニングで $10 vs. $12 をテストしました。2027 年に繰り返すと異なる答えが出るかもしれません。常設ルール：価格実験の結果は約 12 ヶ月の有効期限があります。

より微妙な制約は選択バイアスです。30 日間のバケットクッキーは戻ってきた見込み客を一貫性なくバケット化し、割り当ての約 6% を汚染しました。テストはマージンを持って有意に達成されたため結論は維持されましたが、より小さな効果に対するより厳密なテストでは信頼できないものになっていたでしょう。

### 例（Meridian）

```ts
// frontend/src/lib/pricing-experiment.ts
export function resolveStarterPrice(visitorId: string) {
  const flag = useFeatureFlag('starter-price-test-2025-q4', visitorId);
  if (flag === 'treatment') return { monthly: 12, bucket: 'treatment' };
  return { monthly: 10, bucket: 'control' };
}
```

バケットラベルはすべての分析イベントに流れるため、割り当てを再導出することなく両方の段階がセグメント化されます。実験の後、フラグが削除されました。残存するフラグは価格の不整合の繰り返しの原因です。

### 関連セクション

- [Three-Tier Per-Seat Pricing](#three-tier-per-seat-pricing) を参照してください。テストされている構造について説明しています。[Net Dollar Retention](#net-dollar-retention-and-land-and-expand) を参照してください。第 2 段階のメトリクスが保護するメカニクスについて説明しています。

---

<a id="prior-understanding-tier-anchor-position"></a>
## Prior Understanding：ティアアンカーポジション  [SENIOR]

<a id="prior-understanding-revised-2025-09-14"></a>
### Prior Understanding (revised 2025-09-14)

元のティアラダーは、**中間ティアをアンカー**として構成されていました。おとりとして低いティア、ターゲットとして中間ティア、シーリングを上げるシグナルとして高いティア。

- **Free：** 5 ユーザー、インテグレーションなし、SLA なし。
- **Pro：** $15/ユーザー/月、Slack インテグレーション、繰り返しタスク。
- **Enterprise：** $30/ユーザー/月、「営業にご連絡ください」。

目標は「Pro に誘導する」ことでした。Free は意図的に制限されていました。Enterprise は実体のないもの。その背後に本物のプロダクトはなく、「営業にご連絡ください」はファウンダーの受信ボックスに届いていました。

**最初の 18 ヶ月にわたるデータが示したもの：**

1. **ハイエンドでのティアスキッピング。** 25 シート以上の見込み客の約 22% が Pro を経由せず割引 Enterprise を交渉しようとしました。Enterprise の価格が期待値を設定しましたが、「営業にご連絡ください」は Meridian がその需要を取り込めないことを意味しました。
2. **Pro はアンカーではなくフロアとして扱われた。** Pro の顧客は「より多く払ったら何が得られるか？」と尋ねました。中間アンカーモデルは、顧客がアンカーをより低いオプションとのみ比較すると仮定していますが、B2B 購入者はより高いオプションとも比較します。実体のない高いティアはアンカーを弱めます。
3. **Free はファネルを増やすことなくサポートコストを増やした。** Free は 4% 未満でコンバートしました。スケールでサポートするコストを下回り、コンバーターはペイドトライアルの見込み客より下流の行動が悪化していました。

**修正後の理解（2025-09-14）：**

現在のラダー（Starter、Team、Business）は**トップティアをアンカー**として採用されました。理由：

- Business は本物でリリース可能です（SSO、監査ログ、高度なロール）。見込み客はそれにアンカーを置いて購入できます。実体のないティアはアンカーの役割に失敗します。
- Team は最も多く購入されているティア（課金シートの約 78%）ですが、設計上のアンカーではありません。ICP の自然な着地点です。料金ページは Business を信頼できるラダーのトップに見せ、それが関連づけで Team を持ち上げます。
- Starter が Free に置き換わりました。有料のフロアが非購入者をフィルタリングしてサポートを保護します。

**運用への影響：** Free は 14 日間の Team トライアルに移行されました（既存の Free アカウントはグランドファザー）。Enterprise プレースホルダーは Business が本物になるまで削除されました（2026 年 Q1 に SSO とともにリリース。[market-reasoning → Deferring Enterprise SSO](./market-reasoning.md#deferring-enterprise-sso) 参照）。約 18 ヶ月の空白期間中、料金ページには Starter と Team だけが表示されました。実体のないアンカーよりましです。

**原則：** 教科書の「おとり + アンカー + シーリング」ラダーは、可視オプション間の一度きりの比較を前提とします。B2B SaaS の購入者は顧客の生涯にわたってティアの選択を繰り返し行い、トップティアを将来へのコミットメント（「大きくなったらこれが必要になる」）として扱います。実体のないトップティアはそのコミットメントを壊し、即時の販売と将来の拡大の両方を静かにコストとして払います。

### 関連セクション

- [business-modeling → Three-Tier Per-Seat Pricing](#three-tier-per-seat-pricing) を参照してください。この改訂が生み出した現在のラダーについて説明しています。
- [business-modeling → Net Dollar Retention and Land-and-Expand](#net-dollar-retention-and-land-and-expand) を参照してください。本物のトップティアに依存する拡大メカニクスについて説明しています。
- [market-reasoning → Deferring Enterprise SSO](./market-reasoning.md#deferring-enterprise-sso) を参照してください。Business が本物になった時期をゲートしたプロダクト決定について説明しています。
