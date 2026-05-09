# ADR-008: Research verification layer — primary-source-only Critic による敵対的レビュー

> 英語版: [008-research-verification-layer.md](./008-research-verification-layer.md)(原文・Source of Truth)

## ステータス

Accepted — 2026-05-08

## 背景

`docs-researcher` agent は ADR-006 の triage protocol と ADR-007 の
Anthropic-docs verification chain を通じて、freshness-safe なクエリと
ドキュメント照合をすでに実装しています。しかし freshness protocol が
守るのは *クエリの陳腐化* であって、*取得した回答の正しさ* ではあり
ません。実運用で 3 つの失敗モードが現れています。

1. **確証エコー**: 単一の調査パスで最初に出てきた妥当そうな回答に確
   定する。版数違い、条件付き API、廃止メソッドなどで微妙に誤って
   いる場合、下流の implementer がそのまま誤りを継承し、ビルド/テス
   ト時にようやく顕在化する。
2. **二次情報のドリフト**: ブログ、Q&A サイト、AI 要約は primary
   docs から数ヶ月遅れる。これらに依存した調査結果は内部整合性は
   あるが現行の公式ドキュメントとは矛盾する。
3. **API ハルシネーション**: ライブラリ版数が新しい、または使用頻度
   が低い場合、引数名・デフォルト値・メソッドシグネチャが文章として
   は通るがコードでは通らない値で生成される。

素朴な「調査結果をレビューする」ループにも独自の失敗モードがあります:
**共鳴**。Critic が Generator と同じ二次情報源を参照すると、両者が
同じ盲点を共有し、ループは誤った答えに高い確信度で収束します。

agent team council (architect / docs-researcher / code-reviewer /
orchestrator) が 4 段階のレビュー強度を検討し、ハイブリッドに収束し
ました: **二段階の独立再調査 + primary-source 限定の引用**、加えて
**有界の GAN 反復** と合意できない場合の明示的エスカレーション。

## 決定

`.claude/skills/research-verification/` に Skill を新設し、新規 agent
`research-critic` を導入します。意思決定を伴う外部調査 (アーキテク
チャ、ライブラリ選定、API 利用、版数制約) は、下流 agent が結果を消
費する前にこの層を通過します。

### 原則

1. **Generator と Critic は別 agent**。`docs-researcher` は Generator
   (初回調査、freshness-safe queries、`ours-vs-upstream` triage) を
   継続。`research-critic` は新 agent で、敵対的レビューだけを担当。
   分離することで、単一 agent 内の self-critique よりも確証エコーを
   確実に破る。
2. **Critic の引用は primary source 限定**。Critic は Generator が使
   わなかった情報源を最低 1 つ引用しなければならない。その情報源は
   **必ず** primary source (公式ドキュメント、ベンダー公式 GitHub
   README、CHANGELOG、型定義、RFC/W3C 仕様、公式 API リファレンス、
   Web 標準なら MDN) でなければならない。二次情報 (ブログ、Q&A サ
   イト、AI 要約、チュートリアル、キャッシュされた断片) は Critic の
   独立引用としては明示的に不可。理由: 二次情報は primary source か
   ら遅れる、それを捕まえることが Critic の存在意義そのものであり、
   二次情報を許せば仕組みが破綻する。
3. **有界反復**。GAN 反復は最大 2 周 (Generator → Critic → Generator
   → Critic)。2 周後に未解決事項が残った場合は両論を併記して
   orchestrator にエスカレーション。orchestrator はユーザーに確認す
   るか、当該 claim を `UNVERIFIED:` ラベル付きで下流に渡す。
4. **Tier 宣言によるスコープ制御**。Generator は外部調査出力ごとに
   Tier を宣言する。T1 (破壊的変更、認証、セキュリティ): 二段階 +
   GAN フル。T2 (API 引数、戻り値、一般的なライブラリ挙動): 二段階
   のみ、Critic 1 周。T3 (スタイル、使用例、広く知られたパターン):
   primary source への Generator self-check、Critic なし。Tier は宣
   言であって許可ではない。orchestrator は上方向に escalate でき
   るが下方向には下げられない。
5. **構造による共鳴防止**。Critic は Generator のツールログと引用一
   覧を入力として受け取り、異なるツールファミリ (例: Generator が
   Context7 を使ったら Critic は直接 URL fetch、または `gh` でベン
   ダー公式 repo) を使うよう指示される。同じツール + 同じクエリの
   組合せは禁止。
6. **Skill が protocol、agent が実行者**。`.claude/skills/research-verification/SKILL.md`
   が protocol、checklist、出力フォーマットを定義する。agent
   (`docs-researcher` / `research-critic` / `orchestrator`) は自分
   のトリガポイントで Skill を参照する。CLAUDE.md には Workflow §3
   に 1 段落と Agent Team 表に 1 行を追加するのみ。protocol 詳細は
   CLAUDE.md には書かない (ADR-007 と同じ方針)。
7. **config による opt-out**。`.claude/research-verification.yml` で
   `enabled` (default `true`)、`max_iterations` (default `2`)、
   `default_tier` (default `T2`) を制御。軽量ワークフローを希望する
   adopter は `enabled: false` で層全体を不活化できる。エラーは出
   さず、agent はそのまま動く。
8. **Skill は英語のみ**。ADR-007 と既存の
   `.claude/meta/references/*.md` パターンに合わせる。

### Protocol 順序

research-verification 層は既存 protocol と次の順序で合成される:

1. **Freshness-safe query 構築** (`docs-researcher` 既存 protocol)
2. **Triage** (ADR-006 ours-vs-upstream 3-step) — 不具合調査の場合
   のみ。設計やライブラリ選定の研究では実行しない
3. **Tier 宣言** (Generator が研究出力に付与)
4. **Critic review** (本層) — T1 と T2 のみ
5. **Orchestrator verdict** — accept / request changes / escalate

ステップ 1-3 は `docs-researcher` 内部。ステップ 4 で
`research-critic` に dispatch。ステップ 5 で orchestrator に戻る。
ステップ 1 と 2 は本 ADR では変更しない。

### Tier 確認ガードレール

Generator は単独で Tier を宣言する。最高リスクの T1 を T2 と誤分類
した場合、検証コストが半減し最もリスクが高い経路で機構が薄くなる。
orchestrator はリスクキーワードの小さな allowlist —
`auth` / `authn` / `authz` / `crypto` / `breaking change` /
`migration` / `CVE` / `security` / `permission` / `token` — に該当
する研究トピックでは宣言された Tier を確認する。迷ったら T1 に上げ
る。primary source allowlist と同じく judgement-based のガードレー
ルであり、ヒューリスティック自動分類ではない。

### Tier 定義

| Tier | スコープ | 仕組み |
|---|---|---|
| T1 | 破壊的変更、認証/認可、セキュリティに関わる API、暗号プリミティブ | 二段階 (独立再調査 + primary source 照合) + GAN 最大 2 周 |
| T2 | 公開 API の引数、戻り値、デフォルト値、一般的ライブラリ挙動、版数別の機能可用性 | 二段階のみ。Critic は 1 周。CRITICAL/HIGH の指摘がない限り反復しない |
| T3 | 慣用スタイル、よくある使用例、広く知られたパターン | Generator が primary source 1 つに対して self-check。Critic なし |

### 重大度分類 (Critic findings)

`code-reviewer` の severity モデルを調査レビュー用に再定義:

| レベル | 定義 | 対応 |
|---|---|---|
| CRITICAL | ソースが存在しない (404、捏造 URL)、claim がハルシネーション | 棄却し全面再調査 |
| HIGH | 版数不一致、未明記の破壊的変更、primary source との矛盾 | 版数固定の primary source で再調査 |
| MEDIUM | Generator の引用が二次情報のみで primary source 照合がない | Generator が primary source 引用を追加 |
| LOW | 引用に日付がない、表現が曖昧 | 注記のみ。block しない |

残った指摘が LOW のみ、もしくは `max_iterations` に到達した時点で
ラウンド終了。

### Critic の primary source allowlist

Critic の独立引用は以下のいずれか:

- ベンダー公式ドキュメントサイト (例: `nextjs.org/docs`、`pub.dev`、
  `flutter.dev/docs`、`pkg.go.dev`)
- ベンダー公式 GitHub リポジトリ: README、CHANGELOG、ソースコード、
  型定義、公式 examples
- ベンダー公式 issue tracker (既知バグ確認用)
- RFC、W3C、ECMA、もしくは同等の標準化機関
- MDN Web Docs (Web プラットフォーム API のみ)
- 言語処理系の公式リファレンス (例: `docs.python.org`、`pkg.go.dev/std`、
  `doc.rust-lang.org/std`)

明示的に **不可**: Stack Overflow、Qiita、Zenn、dev.to、Medium、
個人ブログ、AI 要約サイト、キャッシュ断片、スクリーンショット、
ベンダー公式でないチュートリアルリポジトリ。

### 提供成果物

| パス | 役割 |
|---|---|
| `.claude/skills/research-verification/SKILL.md` | エントリポイント、protocol、Pre/Post checklist、ナビゲーション |
| `.claude/skills/research-verification/checklist.md` | Critic checklist (10 項目) と primary source allowlist |
| `.claude/skills/research-verification/failure-modes.md` | 典型的な調査誤りパターン 5 種と対策 |
| `.claude/agents/research-critic.md` | 新 Critic agent 定義 |
| `.claude/templates/research-review-template.md` | 出力フォーマット (Generator claims + Critic findings + verdict) |
| `.claude/research-verification.yml.example` | opt-out config テンプレート |

### 変更成果物

| パス | 変更 |
|---|---|
| `.claude/CLAUDE.md` | Workflow §3 に 1 段落、Agent Team 表に 1 行 |
| `.claude/agents/docs-researcher.md` | 出力フォーマットを Critic 入力契約に整合、Tier 宣言を必須化 |
| `.claude/agents/orchestrator.md` | Skill トリガ条件と escalation flow |

### 意図的にスコープ外

- code review 用の別 Critic (それは `code-reviewer` の領分。両用途
  に流用すると両方が薄くなる)。
- Tier の自動推論。Generator が宣言、orchestrator が escalate でき
  る。ヒューリスティック自動分類は誤りの第二の発生源になるため却下。
- primary-source-only 引用を強制する linter。判定は judgement-based
  (`nextjs.org/learn/...` は primary か二次か?)。人間レビューを残す。
- セッションを跨いだ検証済み調査のキャッシュ。セッション越しメモリ
  は drift を導入し、freshness protocol の保証を打ち消す。

## 結果

### Positive

- 確証エコーと二次情報ドリフトを同じ仕組み (primary-source-only
  Critic 引用) で同時に解消。
- API ハルシネーションが調査ステップ内で表面化する (build/test 時
  に出るより修正コストが大幅に低い)。
- Tier 宣言によりコストがリスクに比例する。T3 は primary source 1
  回のみ、T1 のみが二段階 + GAN のフルコストを払う。
- opt-out が config 1 行。希望しない adopter はゼロコスト。

### Negative

- T1 調査は単一調査パスの約 2-3 倍のコスト。ライブラリ評価が多い
  プロジェクトでは実際に予算を圧迫する。Tier 宣言により T1 を必要
  な箇所だけに限定する設計で緩和。
- ベンダー側のドキュメントが本当に貧弱な場合、primary-source-only
  制約が満たせない。その場合 Critic は二次情報に緩めず orchestrator
  にエスカレーションする — 隠れた調査 blocker を表面化させる方向。
- 共鳴は構造的に防いでいるが排除はできない。Generator と Critic
  が同じ primary source に依存し、その primary source 自体が誤って
  いれば合意される。第三の独立 oracle なしには避けられない。

### Neutral

- Skill は英語。ユーザーへの Critic findings はプロジェクト言語で
  良いが、Skill protocol 本体は英語。
- `research-verification.yml` は `.example` として配布。
  `.github/workaround-tracker.yml` 同様、adopter が opt-in で作成。

## 検討した代替案

| 代替案 | Pros | Cons | 採用しなかった理由 |
|---|---|---|---|
| `docs-researcher` 内で self-critique (新 agent なし) | agent が 1 つ少なく簡素 | 確証エコーを破れない、agent prompt が更に長くなる | 共鳴が支配的失敗モードであり self-critique では破れない |
| Critic の独立引用にブログ等を許可 | 引用源が広く満たしやすい | 仕組みそのものを破壊する。二次情報の遅れこそ Critic が捕まえる対象 | ユーザーから直接 "二次情報は最新の情報でない可能性が非常に高い" |
| Critic 指摘 0 まで無制限反復 | 理論精度は最高 | コスト暴走、病理ケースで終わらない、人間が介入できない | ADR-006 と同じ「有界 + 明示エスカレーション」方針 |
| 単一 Tier (全調査に T1 適用) | 設計が単純 | 些末なスタイル調査にも 3 倍コスト | Tier 宣言でリスクと仕組みを一致させる方が筋が良い |
| `code-reviewer` を Critic 兼任 | 既存 agent を再利用 | コードレビューと調査レビューは対象 (diff vs claim+citation) が異なり prompt が分岐する | agent 境界の原則に反する |
| 全部 `docs-researcher` にインライン (Skill なし) | ファイル数最少 | protocol が固定化され、運用で見つかる失敗を反映しづらい | ADR-007 と同じ Skill+agent 分割で protocol を更新可能に保つ |

## 参照

- ADR-006 — upstream-workaround-tracking。triage protocol はこの層
  の上流 (Generator の入力)。
- ADR-007 — claude-md-authoring Skill。同じ Skill+agent 分割と同じ
  CLAUDE.md 最小化方針を踏襲。
- council deliberation 2026-05-08 — architect / docs-researcher /
  code-reviewer / orchestrator が並列レビューしハイブリッド (二段階
  + GAN) と primary-source 制約に収束。council 後にユーザーから
  Critic の独立情報源を primary-only に厳格化する明示的指示。
- `.claude/skills/research-verification/SKILL.md` — protocol と
  Pre/Post checklist。
- `.claude/skills/research-verification/checklist.md` — Critic
  checklist と primary source allowlist。
- `.claude/skills/research-verification/failure-modes.md` — Critic
  checklist を支える典型誤りパターン。

## Amendment — 2026-05-08 (ADR-010 による)

ADR-010 で research-verification 層は 3 ドメインを持つ統合
`verification-layer` Skill に一般化されました。本 ADR の research
ドメインは semantics として完全に保持され、ファイルの配置だけが
移動しています。**本 ADR 本文中で言及されたパスを参照する読者向け
の対応表:**

| ADR-008 本文中のパス | 現在の位置 |
|---|---|
| `.claude/skills/research-verification/SKILL.md` | `.claude/skills/verification-layer/research/protocol.md` (research ドメイン protocol) と `.claude/skills/verification-layer/SKILL.md` (shared invariants) |
| `.claude/skills/research-verification/checklist.md` | `.claude/skills/verification-layer/research/checklist.md` |
| `.claude/skills/research-verification/failure-modes.md` | `.claude/skills/verification-layer/research/failure-modes.md` |
| `.claude/research-verification.yml.example` | `.claude/verification.yml.example` (`research:` セクション付き) |
| `.claude/research-verification.yml` | `.claude/verification.yml` |
| `.claude/templates/research-review-template.md` | `.claude/templates/verification-review-template.md` (ドメイン別セクション化) |

ADR-010 — `.claude/meta/adr/010-verification-layer-generalization.ja.md`
を参照 — がドメイン横断抽象化の正典です。本 ADR-008 の本文は変更
されません — research ドメインの決定とその根拠は、当該ドメインに
ついての正典の記録のままです。

## Amendment — 2026-05-09 (ADR-013 による)

ADR-013 は本 ADR が確立した primary-source-only citation 規律に
verification-layer 全体スコープで拡張を加え、**Tier 1.5 — 発令する
規制当局の公式解釈ガイダンス** を導入した。Tier 1.5 allowlist
(EDPB Guidelines、PPC ガイドライン/Q&A/通達、CPPA Regulations、
Apple Privacy Manifest 仕様、Google Play SDK Index) は、検討中の
問いが委任規制当局ドメインと交わる場合に限り、かつ同一項目で
Tier 1 引用と併記する場合に限り、research ドメインで許容される。

research ドメインのプロトコルファイルは Tier 1.5 allowlist を参照
するように更新された:

- `.claude/skills/verification-layer/research/checklist.md` — primary
  source allowlist の後に `## Tier 1.5` セクションを追加。
- `.claude/skills/verification-layer/SKILL.md` — shared invariant 3 が
  Tier 1.5 の single source of truth として ADR-013 を参照。

ADR-008 の元の Decision テキストは変更されない。Tier 1.5 は委任
規制当局トピックのために Critic の primary-source allowlist を狭く
閉じた形で拡張する。一般的なフレームワーク / ライブラリ / 言語の
研究ではルールを緩和しない。それらは引き続き Tier 1 のみ。

closed allowlist、ペアリングルール、権威下限、古いガイダンスの
取り扱い、再評価トリガーは ADR-013 を参照。
