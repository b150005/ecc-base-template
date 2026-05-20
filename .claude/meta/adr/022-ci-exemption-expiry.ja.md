# ADR-022: CI exemption allowlist expiry/review mechanism — ref-allow syntax の拡張 [optional expires:YYYY-MM-DD clause]、期限切れ時の WARN-not-FAIL、no-expiry 形式の永続 grandfather、5 検出器 ref-allow family 内の新規構造的 partition

## ステータス

採択済み — 2026-05-20

## 背景

テンプレート内の 5 つの検出器スクリプトは単一の免除機構を共有する。
`check-bilingual-parity.sh` [ADR-018]、`check-dangling-refs.sh`
[ADR-015]、`check-ecc-delegation-consistency.sh` [ADR-020]、
`check-roadmap-drift.sh` [ADR-017]、`check-research-tier-auth.sh`
[ADR-021] はそれぞれ同じ `<!-- ref-allow: <reason> -->` HTML コメント
マーカーを grep して、本来は false positive となる検出 [事前予約された
Spec パス、未だディスク上に存在しない計画済みアーティファクト、意図的な
規約逸脱など] を抑制する。マーカーの syntax は **理由のみ** で **期限を
持たない**。ref-allow がいったん配置されると、人間がそれに気づいて削除
するまでリポジトリ内に残り続ける。

これは 2 つの観測されたコストを生んでいる。第一に、ad-hoc な個別判定:
Roadmap #16 [ADR-001 status resolution] と Roadmap #17 [CHANGELOG↔ADR-
acceptance sync] の両方において、対応する成果物が実在化した後に個別の
ref-allow マーカーを手作業で再検査する必要があった。なぜならマーカー
自身は *いつ* 抑制を再検証すべきかについて何のシグナルも持たないから
である。第二に、期限なしによる over-suppression: 計画済み成果物のために
作成前に置かれた ref-allow は成果物の実在化後も有効なままで、検出器が
本来検出すべき以後の不整合をサイレントにマスクする。検出器ファミリーの
「1 つのパターン、N マイルストーン」レバレッジ [ADR-015 §Decision point
3] により、両コストは 5 検出器すべてに均一に分布する。

`specs/18-ci-exemption-allowlist-expiry.md` が信頼できるスコープであり、
その 13 個の受け入れ基準 [AC-1 から AC-13]、3 つのリスク、Non-goals を
規定する。Spec はこの作業を 4 つの隣接免除機構から意図的に分離する:
skill-invariants grandfather 条項、ADR-017 の absence-of-claim carve-out、
ADR-014 の Spec-reservation-rule carve-out、workaround-tracker の
`expires_on` フィールドである。それら 4 つはそれぞれ自身の成果物に
キーイングされ自身のドメインに住む。この ADR は **のみ** 5 検出器
ref-allow family を扱う。

この ADR は Spec が `architect` に委ねた構造的決定を記録する: 新規 syntax
の形、既存形式に対する grandfather ルール、期限切れ時の WARN-not-FAIL
シグナルレベル、`implementer` への実装スコープ委譲、レビュー cadence
所有権の分散、新規 ADR か ADR-015 amendment かの決定そのものである。
triad ディスクリミネーター [新規契約境界 + 新規キーイング + 新規構造的
アーティファクト] は 3/3 fire する — 下記 Decision §1 を参照。

## 決定

5 検出器が用いる ref-allow syntax に **optional `expires: YYYY-MM-DD`
clause** を導入し、既存の理由のみ形式を **永続 grandfather** として保ち、
期限切れイベントを **WARN severity [never FAIL]** で表出させ、実装スコープ
の選択 [shared library か検出器ごと amendment か] を `implementer` に
委譲する。具体的には:

### 1. 新規 ADR か ADR-015 amendment か — ADR-018 Alternative-B ディスクリミネーター、句ごとの適用

Spec は `architect` に「新規 ADR-022 か ADR-015 amendment か」の明示的
選択を委ね、ADR-018 の Alternative-B ディスクリミネーターを適用するよう
指示する: *#18 は新規契約境界 + 新規キーイング/機構 + 新規構造的アーティ
ファクトを導入するか [⇒ 新規 ADR]、それとも既存 ADR の既に承認された
決定の帰結明確化/拡張か [⇒ amendment] か?* 誠実に句ごとに適用すると:

- **新規契約境界か? Yes。** ADR-015 の決定は dangling-refs 検出器に対し
  ref-allow マーカーを確立し、後続検出器の作成時点でその再利用を承認した
  [ADR-017、ADR-018、ADR-020、ADR-021 が同 syntax を採用]。ADR-015 の
  契約は「ref-allow は理由文字列にキーイングされた *静的* 抑制である」
  というものである。この ADR はその契約に欠けていた *時間的* 次元を
  導入する: 自己期限化ライフサイクルを伴う抑制である。ADR-015 の
  amendment 注記 [path allowlist を anti-pattern とする; syntax 変更
  に対する grace period] は静的抑制契約の *内側* で機能する。期限化
  抑制はその内側にはない。境界は新規である。
- **新規キーイング/機構か? Yes。** ADR-015 は `<reason>` にキーイング;
  ADR-017 は Roadmap 行内の absence-of-claim にキーイング; ADR-018 は
  EN/JA ペア内の規約存在にキーイング; ADR-020 はプロンプト内整合性に
  キーイング; ADR-021 は research evidence trail 内の Tier-presence に
  キーイング。この ADR は **[reason, expiry-date] のペアにキーイング
  され、expiry-date は optional で grandfather 形式では不在** にキーイング
  する — 既存 5 キーイングのいずれも持たない時間的/構造的合成である。
  workaround-tracker の `expires_on` フィールド [ADR-006] が最も近い
  先例であるが、artifact-self-keyed [1 つの workaround、1 つの expiry]、
  workaround ごとの YAML metadata、ref-allow family の完全に外側に住む。
  この ADR のキーイングは 5 つの grep が読む inline HTML コメント
  syntax である。時間的アイデアが類似する箇所でも機構の形は異なる。
- **新規構造的アーティファクトか? Yes。** この ADR は ref-allow family
  内に新規 syntax partition を導入する: 共存する 2 つの形式 [grandfather
  no-expiry 形式と新規 optional-expires 形式] と、期限切れ時の文書化
  された WARN-not-FAIL エスカレーション契約である。partition は
  **ref-allow family 内で MECE** である — どのマーカーも両形式同時には
  ならず、すべてのマーカーは曖昧さなくどちらか一方であり、WARN 動作は
  新形式かつ期限経過のときのみ fire する。これは ADR-015 既存 syntax
  の帰結明確化ではなく新規構造的追加である。

3 つの句すべてが fire する。triad ディスクリミネーター [3/3] は
ADR-017/ADR-018/ADR-019/ADR-020/ADR-021 と正確に一致する: 検出器
ファミリーの上に新規構造的形を導入した先行マイルストーンはすべて
同じ道具により新規 ADR 相当と自己分類した。ADR-015 amendment は
**却下** される: ADR-015 の決定 [単一検出器 + reason-only マーカー
としての ref-allow syntax] はこの ADR によって *不変* である — grandfather
ルールがすべての既存マーカーのバイト互換性を保証する。この ADR は
既存形式の傍らに新規 optional 形を加える。それは
ADR-017/ADR-020/ADR-021 の「新規境界 + 新規キーイング + 新規アーティ
ファクト」形であり、既存決定の精緻化ではない。

### 2. 拡張 syntax — 明示的かつ最小

Grandfather 形式 [不変]:

```
<!-- ref-allow: <reason> -->
```

新規 optional-expires 形式:

```
<!-- ref-allow: <reason> | expires: YYYY-MM-DD -->
```

パイプ文字 `|` が理由 clause と expires clause 間の区切りである。日付
フォーマットは厳格な ISO 8601 `YYYY-MM-DD` [ゼロパディング月日、
タイムゾーンなし — 比較は CI 実行の `date +%F` に対するカレンダー
日付であり、決定性のため UTC で評価される]。パイプ周辺の空白は許容
される。理由 clause が先、expires clause が後。この ADR は他の clause
を導入しない [Spec Non-goals が表面を固定する]。新形式は **マーカー
ごとに opt-in**: 新規 ref-allow はどちらの形式でも author 可能である。
Grandfather 形式は **決して非推奨化しない** — sunset 日は設定されず、
no-expiry 形式に対する警告は emit されず、いかなるツールも古いマーカー
を書き換えない [Spec AC-3、AC-7]。

### 3. 期限切れ時の WARN-not-FAIL — grace period 哲学の適用

検出器は `expires:` 日付が [CI 実行の UTC カレンダー日付に対し] 過去で
ある ref-allow に遭遇したとき、ファイル、行、理由、期限日を明示する
WARN レベルの診断を emit し、その後 **マーカーが依然として有効である
かのように現在の実行を続行する**。マーカーの抑制は期限切れにより
撤回 *されない* — マーカーがカバーしていた検出が突然 CI 失敗となる
ことはない。WARN シグナルのみが emit され、実行ログに、また [該当
する場合] non-blocking なアノテーションとして表出する。これは
ADR-015 amendment の grace period 哲学を時間軸に適用したものである:
派生リポジトリのパイプラインは期限が経過した瞬間に壊れず、責任を持つ
保守者がマーカーを再訪する発見可能で非破壊的なシグナルを受け取る。

これは意図的である。FAIL-on-expiry セマンティクスは [a] この ADR が
解決のため存在する ad-hoc 個別判定問題を再生産し — 人間がマーカーを
手作業で再検査するまでパイプラインが red のまま、これは #16/#17
パターン — また [b] テンプレートが期限経過する expiry 付きマーカーを
出荷した瞬間にすべての fork に破壊を伝播する。WARN はシグナルを
正直 [visible、attributable、dated] に保ちつつ時間を deployment hazard
に変換しない。

### 4. 実装スコープ — `implementer` に委譲

パース ロジックが 5 検出器すべてが source する shared shell library に
住むか、各スクリプトの既存 ref-allow パーサーへの検出器ごとの amendment
として住むかは、**ステップ 5 で `implementer` に繰り越される** [Spec
AC-12]。ここでの architect レベルの選択は *契約* [syntax、grandfather
ルール、WARN-not-FAIL セマンティクス、日付比較ルール] である。実装の
形は cohesion vs duplication に関する engineering 判断であり、5 つの
スクリプトを並べて開いたときに `implementer` が最もよく行える。両方の
形が Spec の受け入れ基準を満たす。architect は予断しない。

### 5. レビュー cadence 所有権 — 三層責任

期限日には誰かが目を向ける必要がある。Spec の AC-10 は所有権を 3 つの
層に分散する:

- **テンプレート保守者 [本リポ]** は *テンプレート自身に* author された
  ref-allow マーカーの cadence を所有する。テンプレートの CHANGELOG と
  定期的な Roadmap 監査が自然なレビュー時点である。`main` の CI に
  おける期限切れテンプレート マーカーの WARN が引き金である。
- **Fork 保守者** は *自身の fork に* author された ref-allow マーカー
  の cadence を所有する。fork の CI における WARN が引き金である。
  fork は更新するか削除するか抑制自体を取り除くようエスカレートするか
  を決定する。
- **`technical-writer` [Development Workflow のステップ 7]** はドキュメ
  ンテーションが触られる時点での cadence を所有する: Spec や ADR が
  更新されるとき、ドキュメンテーション パスの一部として触れられる
  アーティファクトの内部または近傍にある ref-allow マーカーが検査される。
  これは #16/#17 ケースを構造的に捕捉する — ref-allow が *対象として*
  いた成果物が変更中であり、マーカーは同一変更内で再検証されるべきで
  ある。

3 つの層は *誰がレビューを引き金にするか* で非重複であるが、*どの
マーカーがレビュー可能か* で重複する — どの層も任意のマーカーを
正当に再検査してよい。この冗長性は意図的である: ある層で見逃された
マーカーは別の層で捕捉される可能性が依然として高い。

### 6. 設計上スコープ外

4 つの隣接免除機構はこの ADR で明示的に **扱われない** [Spec Non-goals]:
skill-invariants grandfather 条項 [`.claude/skills/claude-md-authoring/
invariants.md`、invariant ごとにキーイング]、ADR-017 の absence-of-claim
carve-out [Roadmap 行ごとにキーイング]、ADR-014 の Spec-reservation-rule
carve-out [Spec パス予約ごとにキーイング]、workaround-tracker の
`expires_on` フィールド [`.github/workaround-tracker.yml`、workaround
エントリごとにキーイング]。それら 4 つはそれぞれ独自のキーイングを
持つ独自のドメインに住む。それらを 1 つの機構の下に持ち込むことは Spec
が意図的に MECE に保つ境界を混同させる。具体的な必要が浮上したときには
将来の ADR がそれらを統一するかもしれない。この ADR はそれを予断しない。

## 帰結

### ポジティブ

- #16 および #17 で観測された ad-hoc 個別判定パターンが構造的に締結
  される: ref-allow は自身の再検証日を保持でき、検出器が日付経過を
  WARN として表出し、レビュー責任が 3 つの名指された所有者に分散される
  [§5]。
- Grandfather ルールがリポジトリおよびすべての fork におけるすべての
  既存 ref-allow に対しゼロ破壊を保証する。マーカーは書き換える必要
  がなく、既存マーカーに対する検出器スクリプト動作は何も変わらない。
- 新規 syntax の形はマーカーごとに opt-in であるため、採用は逐次的で
  ある — 保守者はライフサイクルの問いが実在する箇所にのみ期限日を
  導入し、永続抑制はそのまま残せる。
- WARN-not-FAIL シグナルレベルが ファミリー全体で grace period 哲学
  を整合に保つ [ADR-015 amendment、ADR-018 の全角括弧 WARN、ADR-021
  の research-tier WARN]: 時間経過は情報を生み、パイプライン破壊を
  生まない。
- 4 つの隣接免除機構に対する MECE 境界 [§6] が明示的に述べられている
  ため、将来のマイルストーン著者はスコープをルーティングする際に
  マップすべきクリーンな分割を持つ。

### ネガティブ

- 6 番目の独自の形が検出器ファミリーの概念的表面に住むことになる
  [既存 5 キーイング + 新規 reason-plus-expiry 合成]。緩和策:
  grandfather ルールにより、明示的に opt-in しないすべてのマーカーに
  対する既定メンタルモデルは no-expiry 形式のままである。新形式は
  追加であり遍在ではない。
- 実装スコープ決定 [shared library vs 検出器ごと amendment] は
  `implementer` に繰り越されるため、この ADR は単一のアーティファクト
  を指して「ここにパーサーが住む」と言えない。Spec の AC-12 がこの
  選択を明示的に下流に渡すが、「ファミリーは shared library を正当化
  するほど結合的か?」という architect の問いは `implementer` が具体
  的に答えるまで開いたままである。
- WARN シグナルが CI ログに蓄積する。多くの expiry 付きマーカーを
  採用する fork はより多くの WARN ノイズを見る。フィルタリングの負担
  は fork 保守者にシフトする。緩和策: 三層レビュー cadence [§5] が
  構造的な答えである — WARN は読まれることを意図され、沈黙化される
  ことを意図されていない。

### 中立

- リポジトリ内の既存 ref-allow マーカー — `main` 上の grep は
  `specs/04-dangling-reference-detector.md`、
  `specs/11-verification-domain-opt-in-guidance.md`、
  `specs/17-changelog-adr-sync.md`、および検出器テスト スクリプト内
  の fixture 例にそれらを見つける — は影響を受けない。それらは
  grandfather 形式のまま無期限に留まる。
- workaround-tracker の `expires_on` フィールド [ADR-006] とこの ADR
  の `expires:` clause は統一 *されない*。時間的アイデアを共有するが、
  異なるドメインに属し異なる表面 [YAML config vs inline HTML コメント]
  を用いる。Spec Non-goals が境界を固定する。
- ADR-014 §[d] の MECE テーブルは #18 のスロットを事前予約しない。
  これは #12/ADR-019、#13/ADR-020、#14/ADR-021 の先例 — 新しい分割
  を ADR-014 amendment ではなく ADR 自身に述べる — と一致する。
  パターンは今や 4 回適用され安定している。

## 検討した代替案

| 代替案 | 利点 | 欠点 | 不採用の理由 |
|--------|------|------|-------------|
| **A: `.claude/exemptions.yml` 内の path allowlist** | 中央集権、リスト可視、監査する 1 ファイル | ADR-015 自身の amendment が path-allowlist 形を明示的に anti-pattern と分類した: 抑制を守る成果物から分散させ、ファイル rename 下で壊れ、レビュアーが抑制された行を文脈内で読むことを抑制する | 却下: ADR-015 amendment と直接矛盾する。inline マーカーが意図的な ADR-015 契約である |
| **B: 期限切れ時に FAIL [WARN ではなく]** | 厳格な強制; ログ フィルタリング負担なし; 期限切れマーカーは無期限に腐敗できない | 時間的圧力下で #16/#17 ad-hoc 個別判定問題を再生産する; 期限日にすべての fork に破壊を伝播する; ADR-015 amendment / ADR-018 / ADR-021 のファミリー全体に適用された grace period 哲学と矛盾する | 却下: ファミリーのシグナルレベル規約は時間/規約経過に対し WARN である。FAIL は代償的便益なしに乖離する |
| **C: 既存 syntax の破壊的置換 [すべての ref-allow に `expires:` 必須]** | 単一の正規形、保持すべき 2 形態表面なし | リポジトリおよびすべての fork におけるすべての既存 ref-allow を 1 つの変更で書き換える必要がある; grace period 哲学が即座に失敗する; ADR-015 契約が壊れる | 却下: grandfather なしの形は viable でない。grandfather ルールがこの ADR を安全に出荷可能にするものである |
| **D: ADR-015 amendment、新規 ADR-022 なし** | ADR 番号が 1 つ少ない; 「帰結明確化は amendment に畳む」と一貫 | triad ディスクリミネーターが 3/3 fire する [新規境界 + 新規キーイング + 新規構造的アーティファクト]; ADR-015 の決定は不変; この ADR は ADR-015 出荷 *後に* 観測されたコストを締結し、ADR-015 のスコープ外である。同じ道具による ADR-017/ADR-018/ADR-019/ADR-020/ADR-021 自己分類と一致する | 却下: ADR-017/020/021 と正確に同様に構造的半分が支配する。amendment は新規キーイングと新規アーティファクトを過小に表現する |
| **E: workaround-tracker の `expires_on` 機構を再利用** | 「期限切れする免除」の既存先例; 新規 syntax なし | 異なるドメイン [workaround ごと YAML、inline ref-allow ではない]; 異なるキーイング [workaround-id vs 理由文字列]; 異なる表面 [config ファイル vs HTML コメント]; 両者の混同は Spec が意図的に保つ MECE 境界を溶解させる | 却下: Spec Non-goals が分離を固定する。類比はアイデア レベルのみ |
| **F: optional `expires:` clause を伴う拡張 syntax、no-expiry 形式の grandfather、期限切れ時の WARN-not-FAIL、実装スコープを `implementer` に委譲、三層レビュー cadence [採用]** | #16/#17 ad-hoc 個別判定パターンを締結; grandfather によりすべての既存マーカーのバイト互換性を保持; opt-in 採用; grace period 哲学を保持; 4 つの隣接機構に対する MECE 境界を明示的に述べる | ファミリーの概念的表面に 6 番目の形を加える; 実装スコープ決定が繰り越される; 採用する fork での WARN ノイズ | 採用: 観測されたコストを締結し、grace period 哲学を保持し、既存マーカーを手付かずに残し、ADR-018 Alternative-B ディスクリミネーターにより ADR-017/020/021 のように新規 ADR と正しく分類する唯一のオプション |

## 参照

- Roadmap row: #18
- `specs/18-ci-exemption-allowlist-expiry.md` — 信頼できるスコープ [AC-1 から AC-13、3 つのリスク、Non-goals]
- ADR-015 [`.claude/meta/adr/015-dangling-reference-detector.md`] — ref-allow syntax の起源。その amendment が path-allowlist を anti-pattern と分類し、この ADR が継承する grace period 哲学を確立する
- ADR-017 [`.claude/meta/adr/017-roadmap-drift-detector.md`] — absence-of-claim 免除先例 [Spec Non-goals によりスコープ外]; ref-allow マーカーを再利用する姉妹検出器
- ADR-018 [`.claude/meta/adr/018-bilingual-parity-detector.md`] — §1 で逐語的に適用される Alternative-B triad ディスクリミネーター [新規境界 + 新規キーイング + 新規構造的アーティファクト ⇒ 新規 ADR、帰結明確化/拡張 ⇒ amendment]
- ADR-020 [`.claude/meta/adr/020-ecc-absent-signal.md`] — triad ディスクリミネーターの最も最近の適用; ADR-014 §[d] 非事前予約 MECE partition を ADR 自身に述べる先例
- ADR-021 [`.claude/meta/adr/021-research-tier-auth-validation.md`] — ADR-022 の前の最も最近に消費された ADR 番号; ref-allow マーカーを再利用する姉妹検出器
- ADR-006 [`.claude/meta/adr/006-upstream-workaround-tracking.md`] — `expires_on` フィールド先例 [Spec Non-goals によりスコープ外]; 異なるドメイン、類比はアイデア レベルのみ
- 5 つの検出器スクリプト: `.claude/meta/scripts/check-bilingual-parity.sh`、`check-dangling-refs.sh`、`check-ecc-delegation-consistency.sh`、`check-roadmap-drift.sh`、`check-research-tier-auth.sh`
