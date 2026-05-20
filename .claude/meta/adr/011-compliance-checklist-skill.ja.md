# ADR-011: 法令チェックリスト Skill

## ステータス

Accepted — 2026-05-09; Amended — 2026-05-20 (Roadmap #20): `.claude/compliance.yml` を「デフォルトで absent」ではなく **デフォルトでコミット済み (`enabled: false`)** として出荷する。下記 §Amendment — 2026-05-20 (commit-by-default transition) を参照。Skill の 6 つの不変ルールは変更なし。アクティベーション設定のディスク存在性のみが反転する。

## 既知の曖昧性 — ADR-013 により解決 (2026-05-09)

ここに記録された Invariant 2 の曖昧性は、半年ケイデンスを待たずに
前倒しで解決された。ADR-013 (Invariant 2 情報源 Tier モデル) は
2026-05-09 に起票・議論・採択され、**Option A — Tier 1.5 allow-list
拡張** が **verification-layer 全体スコープ** で確定した。元の
曖昧性:

> Invariant 2 (「一次情報のみの引用」) は、許容される情報源として
> 法令リポジトリ (e-Gov、EUR-Lex、California Legislative
> Information) とプラットフォームポリシーページを列挙し、「ブログ
> 要約、Q&A サイト、AI 要約、ニュース記事、法律事務所の解説」を
> disqualifying として列挙している。**規制当局が公式に発する
> 解釈ガイダンス** (GDPR 第 70 条に基づく EDPB Guidelines、個人
> 情報保護委員会 Q&A および通達、California Privacy Protection
> Agency Regulations、Apple の Privacy Manifest spec、Google Play
> SDK Index) は、いずれのリストにも属さない。

architecture-critic の反対提案 (Option D — 条文のみへの厳格化、
`## See also` 非引用扱いリンク) は、ADR-010 の design-domain
プロトコルに従って ADR-013 の `## Counter-proposal` セクションに
逐語保存され、再評価トリガーを伴う。

解決の詳細は
[`.claude/meta/adr/013-invariant-2-source-tier-model.ja.md`](./013-invariant-2-source-tier-model.ja.md)
を参照。ADR-008 と ADR-010 への amendment が verification-layer 全体
への伝播を記録する。本 Skill の `SKILL.md` における Invariant 2 の
テキストは、同一リリースサイクル内で 3 段構造 (Tier 1 / Tier 1.5 /
disqualifying) を反映するように更新された。

## 背景

AI エージェントの普及により、アプリケーションのリリースコストは劇的に
下がった。その結果、リリースプロセスのなかで最も省略されやすい工程が
**法令遵守** になっている。「作れなかった」が失敗モードだった時代は終わり、
今は「リリースしてよいか確認せずにリリースしてしまった」が主たる失敗モード
になっている。

ユーザは、趣味開発から小規模チーム開発まで繰り返し発生している具体例を
挙げている:

- チャットや messaging 機能が、日本の **電気通信事業法** の届出または
  登録の対象になりうるケース。
- サブスクリプションや単発購入のフローが、日本の **特定商取引法** §11
  の表示義務、および Apple App Store / Google Play のプラットフォーム
  ポリシーの対象になるケース。
- 個人情報の収集が、日本の **改正個人情報保護法**、EU **GDPR** 第 3 条
  の域外適用、米国 **CCPA** を発動させるケース。
- 業界別の文書保存義務 (例: 請求書・領収書を対象とする **電子帳簿
  保存法**) が、コードベースではなく業種に依存して発生するケース。

本テンプレートの既存エージェントチームは「何を作るか」「どう作れば
良質か」をカバーするが、「作ったものにどの法律が適用されうるか」を
浮上させるエージェントや Skill は今のところ存在しない。ユーザは
「法務専門エージェントが必要では」と問題提起した。

Agent Team では、5 つの視点 (`product-manager`, `architect`,
`architecture-critic`, `security-reviewer`, `technical-writer`) で議論を
行った。論点は次の通り:

1. **上流に同等品が無い。** ECC は `hipaa-compliance`,
   `healthcare-phi-compliance`, `customs-trade-compliance` の各 Skill を
   提供するが、汎用的なアプリ法務 Skill やエージェントは存在しない。
   本テンプレートが先行して導入する余地がある。
2. **エージェント vs Skill は設計判断であり、自明ではない。** 当初の
   提案は新規エージェント `compliance-reviewer` だったが、
   `architecture-critic` は Skill のほうが適合するという反対提案を
   生成し、その論拠は審査に耐えた:
   - Skill は「チェックリスト + 参照資料」型のワークロードのために
     設計されている。エージェントは自律的判断ロールのための抽象である。
   - 本テンプレートは既に「規制スタイルの不変ルール検証」を Skill
     (`claude-md-authoring`) と Pre/Post チェックリストで実装している。
     その対称性を破る正当化を当初提案は欠いていた。
   - Skill 化はエージェント数を 18 のまま据え置き、orchestrator の
     ルーティング表を拡張せずに済む。
   - Skill の本体は markdown であり、学習用テンプレートにとって
     エージェント内に推論を隠すよりも教材性が高い。
3. **セキュリティレビューから 6 つのブロッキング前提条件が浮上した。**
   これらが満たされない Skill は、何もしないより悪い ── 偽の安心を
   生んでしまう:
   - 出力で適用否定の断言 ("この法律は適用されない") を行ってはならない。
     許容形式は「適用の可能性あり、要確認」または「適用除外と仮定する
     前に要確認」のみとする。
   - 適用に関するすべての主張は一次情報を引用する (e-Gov 法令検索、
     EU 規則の公式テキスト、米国の州法、プラットフォームポリシー
     ページ)。二次情報は失格 ── ADR-008/010 の研究ドメインと同じ
     ルールに従う。
   - PII を取り込まない。Skill はテストデータ、seed、環境ファイル、
     DB dump を含む可能性が高いパスでの実行を拒否し、出力前には
     正規表現ベースの PII マスクを通す。具体的な path-glob リストと
     PII マスクの正規表現は、本 ADR ではなく Skill 本体の
     `triggers.md` 参照ファイル側で管理する。ADR は「何を、なぜ」を
     記録するものであり、「どう実現するか」は Skill とともに進化する
     ── 厳格化のたびに ADR 改訂を要しないのが望ましい。
   - **デフォルト オフ** で出荷し、プロジェクト単位でオプトインする。
     ADR-010 の検証レイヤドメインと一貫させる。
   - 評価対象とする司法管轄はプロジェクトが宣言する。推測しない。
     `.claude/CLAUDE.md` (または兄弟設定ファイル) で
     `target_jurisdictions: [JP, EU, US-CA, ...]` を宣言する。
     未宣言の場合、Skill は実行を拒否する。
   - トリガーはコード根拠であり、名前根拠ではない。ファイル名や
     ルート名ではなく、法的露出を示唆する **ケイパビリティ** を
     検出する (websocket 依存、Stripe SDK、個人データを収集する
     フォーム等)。

## 決定

法務サポートを **エージェント化せず、Skill として実装する**:

- パス: `.claude/skills/compliance-checklist/SKILL.md`、兄弟参照ファイル
  (`disclaimers.md`, `triggers.md`, `jurisdictions/`) を伴う。
- ステータス: **デフォルト オフ** で出荷。プロジェクト単位の有効化は、
  `.claude/compliance.yml` 内の単一フィールド `compliance.enabled: true`
  で行う (オプトイン時に作成され、デフォルトでは存在しない)。
- Generator: 既存エージェントが Skill を呼び出す。主に
  `product-manager` (受入基準)、`security-reviewer` (PII /
  同意 UI)、`technical-writer` (利用規約・プライバシーポリシーの起草)
  が呼び出す。Skill 自身は自律ループを持たない。
- 出力契約: 各呼び出しは (a) 適用の可能性がある義務のチェックリスト、
  (b) 各項目の一次情報引用、(c) 必須の免責ブロック、(d) 人間の
  レビュー必須マーカ、を返す。各項目のステータスは「適用」「適用の
  可能性あり ── 要確認」「宣言された司法管轄では対象外」のいずれか。
  Skill は項目を「遵守済み」と決してマークしない ── 人間の
  レビュアーだけがマークできる。
- セキュリティレビューから出てきた 6 つのブロッキング前提条件は、
  `claude-md-authoring` の 4 つの不変ルールと並列に、Skill の不変
  ルールとして符号化される。これらからの逸脱はチューニング選択では
  なく、defect (欠陥) として扱う。
- MVP の司法管轄セット: **JP** (電気通信事業法、特定商取引法、改正
  個人情報保護法、資金決済法)、**EU** (GDPR)、**US-CA** (CCPA)、
  **platform** (Apple App Store Review Guidelines、Google Play
  Policy Center)。業種別レジーム (医療、フィンテックの KYC/AML、
  公共放送等) は MVP スコープ外とし、適用される場合は既存 ECC Skill
  (`hipaa-compliance`, `healthcare-phi-compliance`) を指し示す。
- トリガーモデル: 依存マニフェストスキャンによるケイパビリティ検出
  (`socket.io`, `firebase-messaging`, `stripe`, `expo-auth-session`
  などの存在) と、依存シグナルが曖昧な場合の人間への明示的な質問
  ("この機能はユーザ間通信 / 金銭授受 / 個人情報収集を伴いますか?") を
  併用する。名前ベースのマッチングは行わない。
- 免責は構造的に強制する: Skill 出力テンプレートは免責ブロックを
  先頭にハードコードし、出力が法的助言ではないこと、リリース前に
  資格を持つ弁護士のレビューが必要であることを明記する。Skill 側で
  このブロックを除去できない。
- Skill は法的文書 (利用規約、プライバシーポリシー、返金ポリシー) を
  起草しない。`technical-writer` が入力として使える **要件リスト** を
  生成し、同じ免責を伴って渡す。

## 結果

### Positive

- 新しい抽象を導入せずに、テンプレートのリリース前準備の最大の
  ギャップを塞ぐ ── この形状の作業のためには Skill が既に存在する。
- エージェント数は 18 のまま。orchestrator のルーティング表面は
  変わらない。
- `claude-md-authoring` (Skill + Pre/Post チェックリストによる規制
  スタイルの不変ルール検証) と対称的になり、テンプレート内部の
  整合性が保たれる。
- Plain-markdown コンテンツは、人間のレビュアーにとって監査可能で
  あり、ユーザにとって学習可能である ── 学習用テンプレートとしての
  教育目的に適合する。
- 一次情報のみという引用規律を、最も重要な領域である法的推論に
  まで拡張する。GDPR 第 3 条のブログ要約はまさに、法令遵守の助言に
  混入してはならない種類の情報源である。
- ECC ユーザが従来持っていなかったものを得る。Skill はテンプレート
  ローカルだが、設計はポータブルである。有用性が証明されれば、
  ECC への昇格を提案できる。

### Negative

- Skill は呼び出されるものであり、自動起動するものではない。呼び忘れ
  は実在する失敗モードであり、常時稼働エージェントよりも発生しやすい。
  緩和策: `.claude/templates/spec-template.md` の受入基準に「法令
  チェックを実施したか?」の必須行を追加し、`product-manager` の
  プロンプトから本 Skill を明示参照する。
- Skill は本質的にチェックリストである。ジュニアの社内弁護士が
  行うような司法管轄をまたぐ統合分析はできない ── そしてできる
  ふりをすべきでない。免責で明示する。実用上の限界として、複雑な
  クロスボーダー案件は依然として人間の弁護士が必要であり、Skill 自身
  もそう述べる。
- メンテナンスコストは現実的に発生する。法律は変わる。MVP の司法
  管轄セットは定められたケイデンスで再検証する必要がある (初回は
  半年に一度、`docs-researcher` による手動パス。
  `.claude/skills/compliance-checklist/SKILL.md` の更新ケイデンス節
  に記録する。`claude-md-authoring` のパターンと同一)。このケイデンス
  にコミットできない場合、Skill の価値は静かに侵食される。

### Neutral

- 新しい設定ファイル `.claude/compliance.yml` が
  `.claude/verification.yml.example` の兄弟として加わる。両ファイル
  ともデフォルト オフ、両ファイルとも単一トグル。各ドメインの設定を
  ローカルに読みやすく保つ代償として、ファイル増殖は許容する。
- `target_jurisdictions` が宣言されたプロジェクトプロパティとなる。
  テンプレートをフォークしても Skill を有効化しないプロジェクトは
  何も支払わない。有効化しつつ司法管轄を宣言しないプロジェクトは、
  推測ではなく明示的な拒否エラーを受け取る。
- 業種別法令 (医療 PHI、金融 KYC 等) は既存 ECC Skill への委任を
  維持する。compliance-checklist Skill は内容を複製せず、それらを
  指し示す。

## 検討した代替案

| 代替案 | 利点 | 欠点 | 採用しなかった理由 |
|---|---|---|---|
| 新規エージェント `compliance-reviewer` を追加する (当初提案) | orchestrator 経由で自動トリガー可能、決定型出力を生成 | エージェント数を増やす、`claude-md-authoring` との対称性を破る、推論をエージェントプロンプトに隠す、`architecture-critic` の反対提案が審査に耐えた | Skill 形式のほうがワークロードに適合し、テンプレート内部の整合性を保つ |
| 何もせず、`product-manager` の受入基準で法務レビューに言及するに留める | 最低コスト | 受入基準はプロジェクト固有だが、法的要件は cross-cutting で繰り返し発生する。Skill が無いと、すべてのプロジェクトが要件を再導出することになる ── しかも下手に | ユーザの問題提起 (多くのリリースで再発するパターン) は、まさに cross-cutting なインフラを置くべきケースである |
| 上流の ECC へ即座にプッシュし `~/.claude/skills/app-compliance/` として置く | テンプレート利用者だけでなく ECC ユーザ全体が裨益 | ECC 側はまだ法令更新の半年ケイデンスにコミットしていない。早すぎる移管は、ECC の名のもとで法令コンテンツが陳腐化するリスクを増やす | まずテンプレートローカルで作り、ケイデンスを実証してから ECC への昇格を提案する |
| Skill をデフォルトオンにする | デフォルトで最大カバレッジ | エンドユーザリリースとは無関係なフォークでも、セッション開始前に司法管轄宣言を強制してしまう | デフォルトオフはテンプレートの役割を尊重する。オプトインは設定ファイル 1 行 _(Roadmap #20 にて 2026-05-20 に再評価: Skill レイヤのデフォルトオフは維持。変更は `.claude/compliance.yml` のディスク存在性のみ ── 下記 §Amendment — 2026-05-20 を参照)_ |
| Skill が項目を「遵守済み」と自動マークできるようにする | 人間のサインオフを介さずにループを閉じられる | 誤った場合の被害が壊滅的 ── 法的なカバーが無いところに法的なカバーがあるかのような外観を生む | 法令遵守ステータスをマークできるのは人間だけ。Skill はチェックリストを生成するのであり、attestation を行わない |
| Skill 内で法的文書 (利用規約、プライバシーポリシー) を起草する | リリース準備のワンストップ化 | チェックリスト生成器から法的文書を起草するのは、本領域における LLM の最高リスク用途である。免責と直接矛盾する | Skill は **要件リスト** を生成する。文書起草は `technical-writer`、最終的には人間の弁護士の責任に留める |

## 参照

- ADR-007 (CLAUDE.md Authoring Skill) — 本 Skill の構造的テンプレート:
  不変ルール + Pre/Post チェックリスト + 半年ごとの再検証ケイデンス。
- ADR-008 (Research Verification Layer) — 本 Skill が継承する一次情報
  のみという引用規律。
- ADR-010 (Verification Layer Generalization) — 本 Skill が踏襲する
  デフォルトオフ・ドメイン別オプトインのパターン。
- `.claude/skills/claude-md-authoring/SKILL.md` — Skill の形状の
  具体的な参照 (frontmatter、Invariant Core、Override Protocol、
  更新ケイデンス節)。
- e-Gov 法令検索 (https://elaws.e-gov.go.jp/) — 日本の法令の一次情報。
  Skill 本体での JP 司法管轄の引用バックボーンとなる。
- EUR-Lex (https://eur-lex.europa.eu/) — GDPR を含む EU 規則・指令の
  一次情報。
- California Legislative Information (https://leginfo.legislature.ca.gov/)
  — CCPA / CPRA の一次情報。
- Apple App Store Review Guidelines
  (https://developer.apple.com/app-store/review/guidelines/) と
  Google Play Policy Center
  (https://support.google.com/googleplay/android-developer/topic/9858052)
  — プラットフォーム公式ポリシー。プラットフォーム側の権威ある
  テキストとして一次情報扱い。
- ECC Skill `hipaa-compliance`, `healthcare-phi-compliance`,
  `customs-trade-compliance` — compliance-checklist Skill が複製せず
  委任する業種別法令 Skill。
- Roadmap row: #20 (この ADR の 2026-05-20 amendment は、当該
  マイルストーンが決定した commit-by-default 移行を記録する。下記
  §Amendment — 2026-05-20 を参照)

## Amendment — 2026-05-20 (commit-by-default transition)

本 amendment は、法令アクティベーション設定のディスク上の既定状態を
**absent** (`.claude/compliance.yml.example` のみ出荷) から
**コミット済み・存在する** (`enabled: false` で出荷される
`.claude/compliance.yml`) に反転する。Roadmap マイルストーン #20
(「`compliance.yml` をアクティブな既定として出荷する」) の設計判断を
記録し、ADR-011 §決定の "absent by default" 条項を書面で扱う Spec
AC-5 の要件を解消する。本 amendment は元の §決定の load-bearing な
プロパティをすべて維持する ── Skill は Skill 層では依然
デフォルトオフ (Invariant 4)、オペレータによる司法管轄宣言が依然
必要 (Invariant 5)、`enabled: false` の状態では Skill は出力を
一切生成しない。反転するのは **アクティベーション設定のディスク
存在性の極性のみ** である。

### Triad 分類 — 1/3、amendment-not-new-ADR

Spec は `architect` に ADR-018 Alternative-B の triad discriminator
を渡す。#20 に対し各条項を適用すると:

- **新規の契約境界? Yes。** §決定 (原文、2026-05-09):
  「`.claude/compliance.yml` 内の `compliance.enabled: true`
  (オプトイン時に作成され、デフォルトでは存在しない)」。代替案表は
  「Skill をデフォルトオンにする」を理由付きで却下している。
  アクティベーション設定のディスク存在性の極性を反転させることは、
  契約レベルでのデフォルト方向の変更であり、未変更の契約内での
  値の調整ではない。
- **新規のキー / メカニズム? No。** `compliance.enabled` の YAML
  フィールド、`target_jurisdictions:` のリスト形状、SKILL.md の
  Invariant 4 デフォルトオフ拒否ロジック、Invariant 5 の司法管轄
  宣言要件、`triggers.md` のケイパビリティ検出トリガー面は、
  byte-for-byte 不変 (Spec AC-6)。新規 YAML キー無し、新規正規表現
  無し、新規 short-circuit 構文無し。`operator_attestations` と
  `reverification_days` はコミットされるファイルでも optional /
  comment-out のまま。
- **新規の構造的アーティファクト? No。** 新しいファイル種、新しい
  ディレクトリ、新しい CI workflow、新しい detector、新しいテスト
  スイート、新しい SKILL 不変ルールは存在しない。
  `.claude/compliance.yml.example` は保持 (Spec AC-4) され、コミット
  されるアクティブ設定の隣に注釈完備のリファレンスとして残る。
  コミットされる `.claude/compliance.yml` は、元の §Neutral
  Consequences (「新しい設定ファイル `.claude/compliance.yml` が
  `.claude/verification.yml.example` の兄弟として加わる」) で既に
  命名されたアーティファクトのディスク存在性昇格であり、新規
  アーティファクト・カテゴリではない。

Triad 合計: **1/3**。ADR-018 Alternative-B と ADR-022 §1
「new-ADR-vs-amendment」推論によれば、1-2/3 は **既存 ADR の
amendment** にルーティングされる ── 新規 ADR ではない。これは
ADR-006 が Roadmap #19 のために採った形と同じである (こちらも
1/3、こちらも姉妹オプトイン CI スキャフォールドの
commit-default 極性反転)。新規 ADR-023 (Spec AC-5 はこの amendment <!-- ref-allow: counterfactual reference; ADR-023 deliberately not issued per triad 1/3 outcome | expires: 2026-06-20 -->
との OR 条件でこの名称を使用) は検討の上で却下された: 解消を
ADR-011 自身に折り畳むことで、歴史的な §決定テキスト、却下された
"default-on" 代替案、#20 後の再調整が単一の正本源にまとまる ──
ADR-006 amendment の形と一致し、未来の読者が 2 つの ADR にまたがる
ことを強いられる断片化を回避する。

### 元の "absent by default" 条項がもはや成立しない理由

元の 2026-05-09 §決定および §代替案での "default-on" 却下は、
起票時点では妥当だった。両者を、現在利用可能な具体的証拠に対して
再検証する:

1. **"Absent by default" は手続き的安全性であり、Skill レベルの
   安全性ではなかった。** Load-bearing な安全性は Skill 内にある:
   Invariant 4 (`compliance.enabled: true` 以外では Skill は決して
   起動しない)、Invariant 5 (空または欠如した `target_jurisdictions:`
   に対して Skill は実行を拒否する)、両条件を要求する SKILL.md の
   「When to invoke」契約。`enabled: false` で
   `.claude/compliance.yml` をコミットしても、これらの何も弱化しない;
   オペレータが 2 つの明示的アサーション (`enabled` をフリップし、
   `target_jurisdictions` を populating する) を行うまで、Skill は
   構造的に非活性である。「absent」プロパティが提供していたのは
   手続き的障壁 (「ファイルを探してコピーしなければならない」) で
   あって、安全性の障壁ではなかった。
2. **テンプレートの「安全な空状態を持つ CI スキャフォールドは
   default-active」という慣行が安定した。** Roadmap #01
   (`verification.yml` を `research.enabled: true` でコミット) と
   Roadmap #19 (`.github/workaround-tracker.yml` を `enabled: true`
   にフリップ) は、いずれも空インベントリでの挙動が静かであることが
   検証可能なアクティブ既定値を出荷している。法令設定は同じ
   オプトイン スキャフォールドのファミリーに属するが、固有の制約を
   持つ: Invariant 5 はテンプレートがフォークに代わって司法管轄を
   主張することを禁ずる。したがって Invariant 5 を尊重する
   commit-by-default 形は `enabled: false` であり、オペレータ
   アサーション コメントを伴う ── `enabled: true` ではない。
3. **「`.example` をコピーし忘れる」失敗モードは実在する。** Spec
   §Problem に記録: ADR-011 を読み、Skill を使う意図のあるフォーク
   メンテナでも、`.claude/compliance.yml.example` を
   `.claude/compliance.yml` にコピーする手順は省略可能であり、
   省略しても可視的な失敗が無く、実行を促すプロンプトも無い。
   アクティブパスをコミットされた状態で出荷することで、この失敗
   クラスは完全に排除される。

元の「absent by default」選択は 2026-05-09 時点で妥当だった
(#01 の先行事例はまだ着地していなかった;
`verification.yml` commit-by-default パターンはまだ批准されていな
かった)。2026-05-20 時点では成立しない。

### 本 amendment が変更する内容

| 項目 | Before (2026-05-09) | After (2026-05-20) |
|---|---|---|
| 新規フォークでの `.claude/compliance.yml` のディスク状態 | Absent (`.example` のみ出荷) | **`enabled: false` でコミットされた状態** (Spec AC-1) |
| `.claude/compliance.yml.example` | 唯一の設定アーティファクト | 注釈完備のリファレンスとして保持 (Spec AC-4) |
| コミットされるファイル内の `compliance.enabled` の既定値 | N/A (ファイル不在) | `false` (SKILL.md Invariant 4 の文言を byte-for-byte 保持) |
| コミットされるファイル内の `target_jurisdictions:` | N/A (ファイル不在) | **オペレータアサーション説明の inline コメント付きの空リスト** (Spec AC-2; Invariant 5 はテンプレートによる事前 populating を禁ずる) |
| SKILL.md Invariant 4 (「Default-off, opt-in per project」) | Default-off | Default-off (不変; Skill は 2 つの明示的オペレータアサーション無しでは依然非活性) |
| SKILL.md Invariant 5 (project-declared jurisdictions, never guessed) | 必須 | 必須 (不変; Spec AC-6) |
| SKILL.md 「When to invoke」契約 | `enabled: true` + 非空の `target_jurisdictions:` を要求 | `enabled: true` + 非空の `target_jurisdictions:` を要求 (byte-for-byte 不変) |
| 空リストでの SKILL.md 拒否ロジック | 1 行の拒否 | 1 行の拒否 (不変) |
| 6 つの不変ルール | Intact | Intact (Spec AC-6 ── 本 amendment はいずれの不変ルールも弱化しない) |
| ケイパビリティ検出トリガー面 (`triggers.md`) | ADR-011 に従う | ADR-011 に従う (不変) |

### §決定 — 修正される条項テキスト

元の §決定 第 2 項は次の通り:

> ステータス: **デフォルト オフ** で出荷。プロジェクト単位の有効化は、
> `.claude/compliance.yml` 内の単一フィールド `compliance.enabled: true`
> で行う (オプトイン時に作成され、デフォルトでは存在しない)。

修正後の §決定 第 2 項は次の通り (2026-05-20 発効):

> ステータス: Skill 層では **デフォルト オフ** で出荷
> (Invariant 4 は不変)。アクティベーション設定
> `.claude/compliance.yml` は **`enabled: false` で
> commit-by-default** とし、Skill を有効化したいフォーク メンテナが
> `.example` をコピーするのではなく、既に存在する 1 ファイルを編集
> する形にする。有効化は依然として 2 つの明示的オペレータ
> アサーション: `enabled: true` にフリップし、`target_jurisdictions:`
> を少なくとも 1 つの宣言済み司法管轄で populate する。コミット
> されるファイルはフォークに代わって `target_jurisdictions:` を
> 事前 populate してはならない ── Invariant 5 はテンプレートが
> どの法的司法管轄が適用されるかを主張することを禁ずる。
> 説明用にコメントアウトされた例示エントリは文書として許容される;
> ライブ値ではない。`.claude/compliance.yml.example` は注釈完備の
> リファレンスとして保持。#20 後の形は、元の "absent by default"
> 文言の load-bearing な安全性 (手続き的障壁であって Skill レベルの
> 安全性ではなかった) をすべて維持しつつ、「`.example` をコピーし
> 忘れる」失敗モードを排除する。

Load-bearing な安全性プロパティ ── Invariant 4 のデフォルトオフ
挙動、Invariant 5 の no-guessing ルール、「When to invoke」の
2 条件ゲート、空リストでの refusal-on-empty-list 契約 ── は
変更なく維持される。反転するのはアクティベーション設定のディスク
存在性の極性のみ。

### Counter-proposal

ADR-010 design-domain プロトコルに従い、却下された代替案 (新規
ADR-023 がコミットされるファイルで `enabled: true` + <!-- ref-allow: counterfactual reference; ADR-023 deliberately not issued per triad 1/3 outcome | expires: 2026-06-20 -->
`target_jurisdictions:` 空リストを発行する案) を真剣に検討する。
その形は次の通り:

- `.claude/meta/adr/023-compliance-yml-commit-default.md` に
  ADR-023 を起票。 <!-- ref-allow: counterfactual reference; ADR-023 deliberately not issued per triad 1/3 outcome | expires: 2026-06-20 -->
- `enabled: true` と `target_jurisdictions: []` でコミットされた
  `.claude/compliance.yml` を出荷。Skill はケイパビリティトリガーで
  起動し、Invariant 5 の拒否ロジックに当たり、オペレータに司法管轄
  宣言を求める 1 行プロンプトを emit する。
- セッションごとの拒否を、宣言を促す **明示的オペレータ圧力** として
  扱う ── #19 の「デフォルトオン CI workflow が PR 毎に走り
  `Markers found: 0` を報告する」と対称的。

却下理由:

1. **Triad 採点は 1/3。** コミットされる `enabled:` 値に関わらず、
   条項 (c) (新規構造的アーティファクト) は否定; YAML キー形状が
   不変なため条項 (b) も否定。ルーティングルールは amendment と
   言っている ── 新規 ADR ではない。同じ triad-1/3 の決定を
   ADR-023 で記録するのは、triad 結果を変えないまま §決定テキストを <!-- ref-allow: counterfactual reference; ADR-023 deliberately not issued per triad 1/3 outcome | expires: 2026-06-20 -->
   2 つの ADR に断片化することになる。
2. **Invariant 4 の文言の再検討が必要になる。** SKILL.md は現在
   「This Skill ships **default-off**」と述べる。コミットされる
   設定で `enabled: true` を出荷するには、その文言を qualify する
   SKILL.md 編集が必要だが、Spec AC-6 は明示的にこれを禁ずる
   (`SKILL.md` は本マイルストーンでは read-only)。選択された
   `enabled: false` 形は SKILL.md を byte-for-byte 保持する。
3. **セッション毎の拒否は silent-inert 状態よりノイジーである。**
   エンドユーザリリースの予定が無いフォークでは、`enabled: true` +
   空リスト状態はケイパビリティ検出シグナルが発火するたびに
   トリガー毎の拒否行を生成する。選択された `enabled: false` 形は
   出力を 0 にする (Spec AC-3、ブランチ (a))。
4. **#01 の先行事例は対称ではない。** Spec §Risks は、研究ティア
   検証はデフォルトで安全な部分集合であるため #01 が
   `research.enabled: true` を出荷したと述べる。法令には
   オペレータ司法管轄宣言なしで安全な部分集合は存在しない;
   法令の safe-default アナログは **コミットされたファイル + Skill
   が非活性** であり、**コミットされたファイル + Skill 活性 +
   空リスト** ではない。

再評価トリガー: もし将来の監査で、Skill を採用するフォーク
メンテナが Skill 利用にコミットした後で一貫して `enabled: true` への
フリップに失敗していることが判明した場合、counter-proposal の
「明示的オペレータ圧力」議論は経験的に支持され、`enabled: false` と
`enabled: true` + 構造化拒否の選択は再オープンに値する。それまでは、
`enabled: false` がより blast-radius の小さい既定値である。

### 本 amendment のスコープ

- §決定 第 2 項を上記のとおり修正。他の項 (Path、Generator、
  出力契約、6 つの不変ルール、MVP 司法管轄セット、トリガー
  モデル、免責、文書起草スコープ) は不変。
- 「検討した代替案」表 ── 「Skill をデフォルトオンにする」行に
  「Roadmap #20 にて 2026-05-20 に再評価」の inline note が追加;
  歴史的な却下テキストは隣で逐語保存。
- ステータス行に `Amended — 2026-05-20` 表記を追加。
- §Neutral Consequences 第 1 項 (「`.claude/compliance.yml` が
  `.claude/verification.yml.example` の兄弟として加わる、両ファイル
  ともデフォルト オフ」テキスト) は 2026-05-09 時点の状態を述べる。
  両姉妹ファイルは以後コミットされた既定値に遷移している
  (`verification.yml` は #01、`compliance.yml` は本 amendment)。
  歴史的文言は authored のまま保存。
- SKILL.md 内の 6 つの不変ルールは触れない。コミットされる設定は
  Invariant 4 および 5 を設計通りに行使する。
- 英語版 (`011-compliance-checklist-skill.md`) と同一の change で
  本 amendment 相当を受領 ── Roadmap #06 heading-tree parity
  ownership に従う。
- `.claude/CLAUDE.md` の `## Development Workflow` §6a 節
  (「デフォルトオフ」) は、#20 後の Skill レイヤ対 設定レイヤの
  区別に合わせて修飾が必要かもしれない; その編集は `technical-writer`
  が step 7 で所有し、本 amendment では行わない。
- commit-by-default 移行の CHANGELOG エントリは step 7 で
  `technical-writer` が所有する。

### `implementer` への実装ディレクティブ

上記の architect レベル決定: **`enabled: false` と空の
`target_jurisdictions:` リストで `.claude/compliance.yml` を
コミットする**。具体的な形:

```yaml
compliance:
  # Master switch. Default false in the template's committed config.
  # Flip to true once target_jurisdictions is populated by your project.
  # The Skill refuses to run on an empty or absent list (Invariant 5).
  enabled: false

  # Declared jurisdictions for evaluation. EMPTY in the template's
  # committed config — Invariant 5 forbids the template from asserting
  # which legal jurisdictions apply to any given fork. Your project
  # MUST declare at least one of JP / EU / US-CA / platform here
  # before flipping `enabled: true`. The Skill never infers
  # jurisdiction — declaration is a project assertion.
  #
  # Example (uncomment and edit for your project):
  #   - JP
  #   - EU
  #   - US-CA
  #   - platform
  target_jurisdictions: []
```

代替案 (`enabled: true` + 空リスト + 構造化拒否) は、上記
Counter-proposal セクションに記録された 4 つの理由により却下。
`.claude/compliance.yml.example` は注釈完備のリファレンスとして
不変保持 (Spec AC-4); そこにある `JP`-uncommented 形は説明用
ドキュメントのままであり、ライブ既定値ではない。

実装ステップでは SKILL.md 編集無し、CLAUDE.md §6a 編集無し、
CHANGELOG エントリ無し ── これらは Spec §Key interactions に従い
`technical-writer` が step 7 で所有する。
