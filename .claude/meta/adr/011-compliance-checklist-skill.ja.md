# ADR-011: 法令チェックリスト Skill

## ステータス

Accepted — 2026-05-09

## 既知の曖昧性 (次回再検証ケイデンスへ持ち越し)

Invariant 2 (「一次情報のみの引用」) は、許容される情報源として
法令リポジトリ (e-Gov、EUR-Lex、California Legislative Information)
とプラットフォームポリシーページを列挙し、「ブログ要約、Q&A サイト、
AI 要約、ニュース記事、法律事務所の解説」を disqualifying として
列挙している。**規制当局が公式に発する解釈ガイダンス**
(GDPR 第 70 条に基づく EDPB Guidelines、個人情報保護委員会 Q&A
および通達、California Privacy Protection Agency Regulations、
Apple の Privacy Manifest spec、Google Play SDK Index) は、いずれの
リストにも属さない ── 立法テキストでもなければ二次的解説でも
ない。現行の Skill 本体 (`jurisdictions/EU.md`, `JP.md`,
`platform.md`) は、これらのガイダンスを補助的な位置で引用している。
Invariant 2 を厳格に解すると引用削除を要するが、それは Skill の
実用価値を大きく損なう ── DPIA 必要性判定、cookie 同意の dark
pattern 基準、PPC の運用姿勢は、条文テキストだけからは導けない。

Agent Team はこの問題を 2026-05-09 に議論した
(architect / architecture-critic / security-reviewer)。2 つの構造的
方向性が俎上に上った:

- **Tier 許容リストの拡張**: Invariant 2 を拡張し、発令する規制
  当局のガイダンスを「Tier 1.5」として明示的に許容する。Tier 1 の
  条文参照と必ず併記することを条件とし、許容される規制当局の
  allow-list は ADR 層で固定する。(architect と security-reviewer
  が支持)
- **条文テキストのみへの厳格化**: 規制当局ガイダンスの引用を
  完全に削除し、`## See also` セクションに非引用扱いの参考リンクと
  して残す。当局ガイダンスを読みたい人間レビュアーは、引用ではなく
  参照として辿る。(architecture-critic が bright-line / 検証可能性の
  観点から反対提案として擁護)

両提案ともに筋が通っている。どちらを選ぶかは、verification-layer 全体が
どのような情報源規律を標準化したいかというより深い問いに関わり、
回答は本 Skill だけでなく ADR-008 と ADR-010 にも波及する。これを
本 Skill のリリースサイクル内で解決しようとすると、即断になるか、
v3.6.0 をブロックするかのいずれかになる。

**判断は次回の半年ケイデンスへ持ち越す (目標: 2026-11-09 前後)。**
そのパスでは `docs-researcher` を介して `jurisdictions/*.md` の
全引用を一次情報源に対して再取得することが既に要請されており、
規制当局ガイダンス参照を sweep して Tier モデルを選定する自然な
タイミングとなる。それまでの間、Skill は現行の引用で運用する。
実務リスクは限定的である ── (a) Invariant 1 は依然として
negative-applicability claims を禁じており、(b) すべての報告に
必須の免責ブロックが含まれるため、下流の法務レビュアーは警告を
受け取る。

2 つの構造的方向性は、ケイデンスパス時に ADR-013 (*proposed*)
として立てる。architecture-critic の反対提案は ADR-010 の
design-domain プロトコルに従い逐語で保存する。

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
| Skill をデフォルトオンにする | デフォルトで最大カバレッジ | エンドユーザリリースとは無関係なフォークでも、セッション開始前に司法管轄宣言を強制してしまう | デフォルトオフはテンプレートの役割を尊重する。オプトインは設定ファイル 1 行 |
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
