# ADR-013: Invariant 2 情報源 Tier モデル — 法令遵守引用における規制当局ガイダンス

## ステータス

Accepted — 2026-05-09

ユーザは 2026-05-09 に、ADR-013 が両案 (Option A と Option D) を
併記した Proposed として出された後、**Option A — Tier 1.5 allow-list
拡張** を **verification-layer 全体スコープ** で選択した。
architecture-critic の反対提案 (Option D — 条文のみへの厳格化) は
ADR-010 design-domain プロトコルに従って `## Counter-proposal` に
逐語保存し、再評価トリガーを明記する。

## 背景

ADR-011 は `compliance-checklist` Skill とその 6 つの不変ルールを
導入した。**Invariant 2 — 一次情報のみの引用** は、法令リポジトリ
(e-Gov 法令検索、EUR-Lex、California Legislative Information) と
プラットフォームポリシーページを許容引用源として列挙し、「ブログ
要約、Q&A サイト、AI 要約、ニュース記事、法律事務所の解説」を
明示的に disqualifying としている。系譜は ADR-008 (research
verification layer) と ADR-010 (verification layer generalization)
であり、両者ともに一次情報のみの引用を verification-layer の
load-bearing 不変ルールとして確立している。

第三のカテゴリが規定されていない: **規制当局が公式に発する解釈
ガイダンス**。Skill 本体で既に引用されている具体例:

- **EDPB Guidelines** (GDPR 第 70 条に基づく。例: Guidelines 03/2022
  on deceptive design patterns。
  `.claude/skills/compliance-checklist/jurisdictions/EU.md` の
  73-76 行で引用。DPIA に関する EDPB Guidelines は同 52-54 行で引用)。
- **個人情報保護委員会 (PPC)** の Q&A、ガイドライン、通達
  (`.claude/skills/compliance-checklist/jurisdictions/JP.md` の
  81-84 行で、越境移転の十分性認定国リストに関連して引用)。
- **Apple Privacy Manifest 仕様** (Required Reasons API。
  `.claude/skills/compliance-checklist/jurisdictions/platform.md` の
  38-40 行で引用)。
- **Google Play SDK Index** (User Data ポリシーに基づく義務。
  `platform.md` の 69 行で参照)。
- (将来的に) **California Privacy Protection Agency (CPPA)
  Regulations** (CCPA §1798.185 に基づく。US-CA の引用を拡張する際)。

これらの文書は **立法テキストでもなければ、二次的解説でもない**。
親法から授権された規制当局が発する文書である (EDPB は GDPR
第 70 条 (1) (e)、PPC は 個人情報保護法 §132、CPPA は CCPA
§1798.185、Apple Privacy Manifest 仕様は Apple のファースト
パーティのプラットフォーム権限)。Invariant 2 を厳格に解すると
これらの引用を削除する必要があるが、それは Skill の実用価値を
損なう:

- GDPR 第 35 条の DPIA 必要性判定は、9 つの基準テスト
  (EDPB が支持する WP248 と EDPB Guidelines に存在) によるもので
  あり、第 35 条の条文だけでは導けない。
- ePrivacy 第 5 条 (3) における cookie 同意 dark pattern 基準は、
  EDPB Guidelines 03/2022 に存在する。指令本体は「deceptive」も
  「free choice」も運用的には定義していない。
- PPC の越境移転 (§28) と漏えい等報告 (§26) の運用姿勢は、PPC の
  ガイドラインと通達に存在する。条文は義務を定めるが、運用上の
  閾値は与えない。

2026-05-09 の内部議論 (architect / architecture-critic /
security-reviewer) では、本問題を半年ケイデンス (目標
2026-11-09) へ持ち越すことが決定された。ユーザは今、ケイデンス
前に本セッションでの解決を求めている。`jurisdictions/*.md`
全引用の半年再検証は依然として 2026-11-09 前後にスケジュール
されており、本 ADR とは独立に実施する。

### 対立する力学

- **Bright-line な検証可能性** (verification-layer の基盤特性) は、
  CI スクリプトで強制可能な閉じた allowlist を要請する。新しい
  tier の追加は境界を移動させるが、境界は依然として閉じている
  必要がある。
- **compliance-checklist Skill の運用上の有用性** は、人間レビュアーが
  実際に答えを得られる文書を指し示せるかに依存する。条文だけでは
  指し示せない。
- **ADR-008 / ADR-010 とのスコープ結合**。ここでの決定は
  verification-layer 全体 (research、implementation、design ドメイン)
  に波及するか、compliance-checklist にのみスコープするか。スコープ
  自体が決定事項である。

## 決定

verification-layer 全体 (および citation discipline を継承する
compliance-checklist Skill) において Invariant 2 を拡張し、
**Tier 1.5 — 発令する規制当局の公式解釈ガイダンス** を許容する。
次の 5 つの拘束的なサブルールを伴う。ADR-008 と ADR-010 には
協調的な amendment を加え、伝播を記録する。各ドメインのプロトコル
本体はそれ以外には書き換えない。

### Option A — Tier 1.5 allow-list 拡張

Invariant 2 を拡張し、**Tier 1.5 — 発令する規制当局の公式解釈
ガイダンス** を許容する。次の 5 つの拘束的なサブルールを伴う。

1. **閉じた allowlist、ADR 層で固定**。Tier 1.5 は次の規制当局
   からの引用のみを許容する:
   - **EDPB** Guidelines、Recommendations、Opinions (GDPR 第 70 条
     (1) (e) に基づき採択されたもの)。
   - **個人情報保護委員会 (PPC)** ガイドライン、Q&A、通達
     (個人情報保護法 §147-§149 の授権に基づき発出されたもの)。
   - **California Privacy Protection Agency (CPPA)** Regulations
     (CCPA §1798.185 に基づき採択されたもの)。
   - **Apple** Privacy Manifest 仕様および Required Reasons API
     ドキュメント (Apple のファーストパーティのプラットフォーム
     権限に基づくもの)。
   - **Google** Play User Data ポリシーおよび SDK Index
     ドキュメント (Google のファーストパーティのプラットフォーム
     権限に基づくもの)。

   6 つ目の規制当局を追加するには新規 ADR を要する。Skill
   メンテナは Skill 本体の編集ではリストを拡張できない。

2. **ペアリングルール**。Tier 1.5 引用は同一チェックリスト項目に
   おいて常に Tier 1 (条文またはファーストパーティのプラット
   フォーム仕様) 引用と併記されなければならない。Tier 1.5 単独は
   無効な出力とみなし、Skill は拒否する。

3. **権威下限**。Tier 1.5 は、当該規制当局が enabling statute の
   授権に基づき発出する **正式な instrument のみ** を許容する。
   除外: 規制当局のブログ記事、プレスリリース、規制当局スタッフ
   個人の op-ed、規制当局の SNS 投稿、FAQ ランディングページ、
   会議スライド。これらは Tier 3 (引用不可)。

4. **古いガイダンスの取り扱い**。各 Tier 1.5 引用は再検証時に
   現行 (superseded by / withdrawn でない) であることを確認する。
   撤回されたガイダンスは自動的に Tier 3 に降格し、
   `jurisdictions/*.md` から削除される。半年ケイデンス
   (JP / EU / US-CA は 180 日、platform は 90 日) がこの確認を
   カバーする。

5. **スコープ: verification-layer 全体**。Tier 1.5 は
   verification-layer の 3 ドメイン (`research`、`implementation`、
   `design`) と、citation discipline を継承する `compliance-checklist`
   Skill において許容される。同じ 5 つのサブルールが一様に適用
   される。
   - `docs-researcher` と `research-critic` は、検討中の問いが、
     条文が名指しの規制当局 (allowlist 上のもの) に解釈を **委任**
     している規制ドメインに関するものである場合に Tier 1.5 を
     引用しうる (例: GDPR DPIA メカニクスに関する問いは GDPR
     第 35 条と並べて EDPB Guidelines を引用してよい。React の
     `useEffect` に関する問いは引用してはならない — そこには
     enabling regulator が存在しない)。
   - `architecture-critic` (design ドメイン) と
     `adversarial-implementer` (implementation ドメイン) も同じ
     ルールを継承する: レビュー対象の設計または実装が、委任
     規制当局のドメインと交わる場合に Tier 1.5 を引用しうる。
   - ペアリングルール (サブルール 2) と権威下限 (サブルール 3) は
     ドメイン横断で変わらず適用される。
   - 委任規制当局のドメイン外のトピックは引き続き Tier 1 のみを
     必要とする。verification-layer の bright-line は、法令遵守
     とは無関係な研究の 95%+ について維持される。

   ADR-008 と ADR-010 にはそれぞれ amendment セクションが追加
   され、本伝播を記録する (ADR-008 の既存 2026-05-08 amendment が
   ADR-010 を記録するのと並行する形)。各ドメインのプロトコル
   (`research/protocol.md`、`research/checklist.md`、
   `implementation/protocol.md`、`design/protocol.md`) は Tier 1.5
   allowlist を参照するように更新する。それ以外にプロトコル本体は
   書き換えない。閉じた allowlist 自身は本 ADR (サブルール 1) に
   存在し、`verification-layer/SKILL.md` から single source of
   truth として参照される。

### なぜ整合性のある 2 つのパスで決定を提示したか

ADR-008 と ADR-010 は、議論が **mechanism** (Generator / Critic の
分担、反復回数の制限) に関するものであったため、それぞれ単一
決定で着地した。Invariant 2 の問題は **境界** の問題である —
何が一次情報に該当するか — そして境界自体が価値観に依存する:
Option A は運用上の有用性を優先し、Option D は検証可能性を優先
する。両者ともに整合性がある。最も近い前例は ADR-012 であり、
却下された代替案を ADR-010 design-domain プロトコルに従って
`## Counter-proposal` として保存した。ADR-013 はそのパターンに
従った。ユーザは 2026-05-09 に Option A を verification-layer 全体
スコープで選択した。Option D は下の `## Counter-proposal` に
逐語保存し、再評価トリガーを明記する。

### 移行作業は別 commit で行う

ADR-011 の what / why vs how の分離原則に従い、移行作業は別 commit
として整理する。

- `compliance-checklist/SKILL.md` の Invariant 2 を 3 段構造
  (Tier 1 / Tier 1.5 / disqualifying) に書き換える。
- `jurisdictions/EU.md` / `JP.md` / `platform.md` の各規制当局
  ガイダンス引用に `[Tier 1.5]` マーカを付与し、Tier 1 の条文
  またはプラットフォーム仕様の引用と併記する。
- `verification-layer/SKILL.md` の shared invariants 節
  (invariant 3 — primary-source-only citation) を本 ADR の allowlist
  へのポインタとして更新し、`research/checklist.md` の
  primary-source allowlist を Tier 1 リファレンスとして相互参照する。
- `verification-layer/research/checklist.md` を更新し、本 ADR を
  参照する Tier 1.5 セクションを追加する。

## Counter-proposal

> `architecture-critic` による反対レビュー、2026-05-09。Round 1/1。
> ADR-010 design-domain プロトコルに従い逐語保存。

### 選択した代替案

Option D — 規制当局ガイダンスを引用 tier システムから完全に
除外し、非引用扱いの `## See also` 参考リストに降格させる。

### 反対決定

Invariant 2 の primary-source allowlist は、制定条文および
ファーストパーティのプラットフォーム仕様に限定したまま維持
する。規制当局ガイダンス (EDPB Guidelines、PPC Q&A、Apple の
レビューノート) は、参考読書として `## See also` セクションに
出現してよいが、チェックリスト項目を支持する証拠として引用
してはならない。

### 反対結果

#### Positive

- Bright-line な検証可能性: 引用される全ソースが、それぞれの
  enabling statute のもとで独立に権威を持つ (GDPR Art. 288 TFEU、
  個人情報保護法 §132 が PPC を指定)。
- Tier ドリフトなし: 1.0 / 1.5 の境界議論を境界自体の除去で解消。
- レビュアー負荷低下: 引用ごとの Tier 判定が不要。

#### Negative

- **解釈** 上の補強を必要とする法令遵守項目 (例: GDPR Recital 26
  の匿名化基準) は直接の引用支持を失い、条文テキストのみに依拠
  することになる。

#### Neutral

- `## See also` は jurisdiction ファイルの恒久セクションとなり、
  technical-writer がその hygiene を所有する。

### 独立引用

- https://eur-lex.europa.eu/eli/reg/2016/679/oj — GDPR 第 70 条
  (EDPB の役割は **advisory** であり、立法ではない) — 取得
  2026-05-09。
- https://elaws.e-gov.go.jp/document?lawid=415AC0000000057 —
  個人情報保護法 §132 (PPC の enabling statute のスコープ) —
  取得 2026-05-09。

### 再評価トリガー

D から A への切り替えは、**1 つのケイデンスサイクル内で、
チェックリスト項目が「規制当局ガイダンスを引用として使えなかった
こと」のみを理由に 2 回レビューに失敗した時点** で発動する。
verification-review ログに記録する。このシグナルが現れるまで、
D を維持する。

### 推奨

D を採用する。再評価は上記トリガーまたは 2026-11-09 ケイデンス
時点でのみ行う。

## 結果

### Positive

- compliance-checklist Skill は、レビュアーが実際の運用上の問いに
  答えを得られる文書 (DPIA 9 つの基準、cookie 同意 dark pattern、
  PPC の越境移転リスト) を指し示し続ける。
- Skill 本体による Invariant 2 の暗黙的違反が解消される — 規制
  当局ガイダンスが「補助的位置」で引用されているがそれを規律する
  ルールが存在しないという従来の状態が終わる。
- 5 つの拘束的サブルール (閉じた allowlist、ペアリングルール、権威
  下限、古いガイダンスの取り扱い、verification-layer 全体スコープ) は
  境界を移動させても閉じたまま保つ。CI で強制可能。
- verification-layer 全体への伝播により、architect が steering
  時に flag した非対称が解消される: research / implementation /
  design の Critic が、委任規制当局ドメインのトピックで EDPB
  Guidelines を引用として拒否することはなくなる。ドメインを
  横断するオペレータは 2 つではなく 1 つのルールを見る。

### Negative

- Invariant 2 は 1 行ルールではなくなる。Tier 1.5 は名指しの規制
  当局を少数許容するが、各当局は文書の発行・supersede・撤回を
  行いうる。メンテナンスは現実的かつ継続的。緩和策: 各引用に
  retrieval date を pin し、ケイデンス時に再検証する。
- ADR-008 と ADR-010 は amendment される (rewrite ではない) — 各
  ドメインの Critic checklist が Tier 1.5 サブルールを内部化する
  必要がある。プロトコル 3 ファイル (`research/checklist.md`、
  `implementation/checklist.md`、`design/checklist.md`) で表面積が
  増える。
- ペアリングルールにより認知負荷が「これは一次情報か」(binary)
  から「このトピックは委任規制当局ドメインに該当するか」(judgement)
  へシフトする。Generator と Critic が後者で合意できなければ、
  Critic は Tier 1.5 引用をトピック範囲外として拒否する。

### Risks

- ある規制当局が controversial な Guideline を発出し、後に裁判所が
  これを無効とする。引用規律は「規制当局が発出したものを引用せよ」
  と言うが、法的価値は争われている状態となる。緩和策:
  compliance-checklist の Disclaimer ブロックは既に「出力は法的
  助言ではなく、資格を持つ counsel のレビューを要する」と明記して
  おり、本リスクは Skill 内の他全リスクを束ねる同じ層で限界
  づけられている。research / implementation / design ドメインに
  ついては、同じ Critic finding メカニズムが「Tier 1.5 引用済みだが
  係争中」を標準の severity 表で扱う。
- 反対提案の失敗モード: 読者がペアリングルールを回避し、Tier 1.5
  を実務上 primary として扱う可能性がある。`## Counter-proposal`
  に明記された再評価トリガー (1 ケイデンスサイクル内に Tier 1.5
  誤用が原因で 2 件失敗) が、これを捕捉し bright-line オプションを
  再検討するための公式メカニズムである。

### Neutral

- ADR-011 の `## Known ambiguity` 節は `Resolved by ADR-013` に
  更新される。
- CHANGELOG `[Unreleased]` は ADR と移行 commit を別個に記録する。
- 2026-11-09 前後の半年ケイデンスパスは影響を受けない。引用は
  どのオプションが選ばれても primary source に対して再検証される。
- ADR-008 と ADR-010 は amendment セクションを受け取り、Tier 1.5
  伝播を記録する (ADR-008 の既存 2026-05-08 amendment が ADR-010
  を記録するのと並行する形)。各 ADR の元の Decision テキストは
  書き換えない。amendment はクロスドメイン変更を記録する。

## 検討した代替案

| 代替案 | 利点 | 欠点 | 採用しなかった理由 (または「co-equal — ユーザ選択」) |
|---|---|---|---|
| **A: Tier 1.5 allow-list 拡張 (verification-layer 全体)** | Skill の運用価値を保つ; 閉じた allowlist は CI で強制可能; ペアリングルールが Tier 1.5 単独引用を防ぐ; verification-layer ドメイン横断で一様なルール | メンテナンス面が増える; ペアリングルールは負荷の一部をトピックスコープの判断にシフトする | **2026-05-09 にユーザが verification-layer 全体スコープで選択**。これが採択された決定 |
| **A-narrow: Tier 1.5 を compliance-checklist のみにスコープ** | 表面積変更が最小; ADR-008 / ADR-010 を変更不要 | 非対称: verification-layer の Critic が EDPB Guidelines を依然として拒否する一方、compliance-checklist は許容する。ドメインを横断するオペレータは 2 つのルールを見ることになる | 選択時に検討した。ユーザは非対称を避けるため verification-layer 全体スコープを明示的に選んだ |
| **D: 条文のみへの厳格化と `## See also` 降格** | Bright-line な検証可能性; bright-line における verification-layer 全体の一貫性; 新 tier 不要 | Skill が運用上の閾値の直接引用を失う; 読者は indirection を回避する | ADR-010 design-domain プロトコルに従い `## Counter-proposal` に逐語保存。再評価トリガーをそこに明記 |
| **B: 文書ごとの tier ラベル** (Skill が出力時に各引用文書の tier マーカを判断する) | 最大の granularity | 不変ルールの目的を破壊する — ルールが「ケースバイケースの判断」となり、Invariant 2 が排除しようとしたものそのものになる | verification-layer の価値は **closure** であり granularity ではない |
| **C: 現状維持 — 曖昧性を残置** | 作業ゼロ | 曖昧性自体が defect である; ADR-011 が既にそう記録している | ユーザは defer ではなく解決を明示的に求めた |
| **E: ADR-013 を 2 つの並行 ADR に分割** (1 オプション 1 ADR、follow-up review に耐えた方を採用) | 最大の reversibility | 1 つの決定のために ADR 面を倍化する; design-domain プロトコルは 1 ADR 内での却下案保存をすでにサポート (ADR-012 前例) | 1 ADR + 2 オプション + counter-proposal が確立されたパターンであり、分割は明瞭性を加えずファイルだけ増やす |

## 参照

- [`.claude/meta/adr/008-research-verification-layer.ja.md`](./008-research-verification-layer.ja.md)
  — primary-source-only citation を verification-layer の load-bearing
  不変ルールとして確立。本 ADR では修正しない。
- [`.claude/meta/adr/010-verification-layer-generalization.ja.md`](./010-verification-layer-generalization.ja.md)
  — ADR-013 の `## Counter-proposal` セクションを生成する design-domain
  Critic プロトコルを定義。本 ADR では修正しない。
- [`.claude/meta/adr/011-compliance-checklist-skill.ja.md`](./011-compliance-checklist-skill.ja.md)
  — compliance-checklist Skill の Invariant 2 を導入し、本 ADR が解決
  する `## Known ambiguity` を記録。
- [`.claude/meta/adr/012-code-reviewer-dispatcher.ja.md`](./012-code-reviewer-dispatcher.ja.md)
  — 「却下された代替案を `## Counter-proposal` として逐語保存して
  Accepted」パターンの最も近い前例。
- [`.claude/skills/compliance-checklist/SKILL.md`](../../skills/compliance-checklist/SKILL.md)
  — 現行 Invariant 2 のテキスト (100-106 行)。
- [`.claude/skills/compliance-checklist/jurisdictions/EU.md`](../../skills/compliance-checklist/jurisdictions/EU.md)
  — EDPB Guidelines 引用の現状 (52-54 行および 73-76 行)。
- [`.claude/skills/compliance-checklist/jurisdictions/JP.md`](../../skills/compliance-checklist/jurisdictions/JP.md)
  — PPC 引用の現状 (81-84 行)。
- [`.claude/skills/compliance-checklist/jurisdictions/platform.md`](../../skills/compliance-checklist/jurisdictions/platform.md)
  — Apple Privacy Manifest 引用の現状 (38-40 行) と Google Play
  SDK Index 参照の現状 (69 行)。
- [`.claude/skills/verification-layer/research/checklist.md`](../../skills/verification-layer/research/checklist.md)
  — primary-source allowlist。両オプション共通の Tier 1 リファレンス。
- EUR-Lex (https://eur-lex.europa.eu/) — GDPR 統合テキストの一次情報。
  第 70 条が EDPB の advisory な役割を定義。
- e-Gov 法令検索 (https://elaws.e-gov.go.jp/) — 個人情報保護法の
  一次情報。§132-§149 が PPC の enabling 権限を定義。
- California Legislative Information
  (https://leginfo.legislature.ca.gov/) — CCPA の一次情報。§1798.185
  が CPPA に rulemaking 権限を委任。
