# ADR-014: Roadmap インデックスを設計成果物の単一エントリポイントとする

## ステータス

Accepted — 2026-05-15

## 背景

本テンプレートの設計知識は、開発ワークフローの異なる手順で生成される
3 種類の成果物として存在する:

- **CLAUDE.md** — すべてのエージェントがすべての手順でロードする、
  常に参照されるプロジェクトコンテキスト。
- **仕様書 (Spec)** — `product-manager` がワークフロー手順 2 で生成する。
  Spec が持つ受け入れ基準がマイルストーンの権威的な *スコープ* である。
  `implementer` はコードを書く前に Spec を参照するようハードコードされており、
  `test-runner` も同じ受け入れ基準から合否基準を導出する。
- **ADR** — *構造的な* 決定が生じたときのみ `architect` が
  ワークフロー手順 4 で生成する。`architect` は新しい ADR を提案する前に
  一貫性のために過去の ADR を参照するようハードコードされている。

この 3 種類の成果物はロール別に正しく分離されているが、
マイルストーンをその権威的な文書にマッピングする **定義されたエントリポイントが
存在しない**。人間とエージェントの両方が、すべての手順で「このマイルストーンの
権威的な文書はどれか」を毎回探し直している。具体的な症状:

1. orchestrator は Analyze 手順で参照できるマイルストーン別インデックスを
   持たないため、目の前の作業に適した Spec/ADR を見つけるためにリポジトリを
   再スキャン (または推測) する。
2. `architect` は新しい ADR を作成する前に既存の `adr:` リンクを指し示す
   ものがないため、すでに ADR を持つマイルストーンに対して別の ADR を
   フォークしてしまう可能性がある。
3. `implementer` は Spec 件数が増えるにつれて脆くなるリポジトリ検索で
   「その Spec」を解決する。
4. 学習者 (テンプレートの主要ユーザー) が「何が構築済みで、何が進行中で、
   それぞれの設計はどこにあるか」を一箇所で把握できる場所がない。

テンプレートの CLAUDE.md には現在マイルストーン別インデックスがない。
CLAUDE.md はすべてのエージェント (orchestrator / architect / implementer) が
すべての手順でハードコードされて参照する唯一のファイルであり、
「インデックスを読むことを忘れずに」という問題を再導入することなく
インデックスを置ける唯一の場所である。

この決定はユーザーと直接議論した。「1 種類の文書タイプに統合する」という
反対提案 (後述代替案 A) がその対話の中で提起され、却下された。
ADR-012 がその内部反対提案を記録しているのと同じ理由 ── 却下された選択肢が
監査可能な状態で残るよう ── ここに記録する。

## 決定

`.claude/CLAUDE.md` に `## Roadmap` セクションを追加する。配置は
`## Development Workflow` セクションの **直前**。このセクションは
箇条書きではなく **テーブル** (表) とし、列構成は次のとおり:

`# | Milestone | Status | Design source`

テーブルを規律するルール:

- **1 マイルストーン 1 行。** 行番号は安定しており、ADR 番号と同じ
  規約に従って再利用しない。分割されたマイルストーンは新しい行と
  古い行へのメモになる。番号は再利用せず、番号を振り直さない。
- **`Design source` は文書タイプを明示する。**
  `spec: <パス>` および/または `adr: <パス>` を使用し、
  読者がリンク先の成果物タイプを推測しなくて済むようにする。
- **マイルストーン ↔ Spec は 1:1 かつ必須。** すべてのマイルストーン行に
  ちょうど 1 つの `spec:` リンクを持つ。これにより `implementer` /
  `test-runner` の契約が維持される: Spec の受け入れ基準が
  権威的なスコープであり続ける。
- **マイルストーン → ADR は 0:1 または 1:N かつ任意。** そのマイルストーンで
  1 つ以上の構造的決定が生じた場合のみ、行に `adr:` リンクを持つ。
  ADR の `## References` は行番号への逆参照を持つ。
- **ステータスは実装状態を反映する (設計状態ではない)。** 使用可能な値:
  `☐` todo / `◐` in-progress / `☑` done / `✗` dropped。
  dropped の行はテーブルに残す ── 履歴は書き換えない。
- **テーブルはインデックスのみ。** 受け入れ基準や根拠は決してテーブルに
  重複させない。内容の Source of Truth はリンク先の Spec/ADR に留まる。

インデックス更新のオーナーシップは成果物の生成者に割り当てることで、
インデックスと成果物が一緒に動くようにする:

- `product-manager` は Spec を生成する時点で Roadmap 行 (番号、1 行の
  マイルストーン説明、`spec:` リンク) を追加/更新する。
- `architect` は ADR を生成する時点で既存行に `adr:` リンクを追加し、
  新しい ADR を作成する前に既存の `adr:` リンクの有無を行で確認する。
- `orchestrator` は Roadmap を読むだけである (行を書かない)。

本 ADR は設計決定と、それが示唆するエージェント契約変更を記録する。
CLAUDE.md、エージェントプロンプト、テンプレート自体の変更は
**本 ADR では行わない** ── それらは `implementer` が所有する
ダウンストリームの実装タスクであり、トレーサビリティのために
帰結セクションに列挙する。

## 帰結

### ポジティブ

- 常に参照される単一のエントリポイントが「このマイルストーンの権威的な
  文書はどれか」をワンルックアップで答える。orchestrator の Analyze 手順が
  リポジトリスキャンではなくテーブル参照になる。
- `architect` の ADR フォーク問題が構造的に解決される: 新しい ADR を
  作成する前に行の既存 `adr:` リンクを確認することで、フォークではなく
  amend/supersede に誘導される。
- `implementer` が Spec 件数の増大に対してロバストな安定したポインターで
  Spec を解決できる。
- MECE は文書タイプを統合するのではなく **ロール分離** (Spec = *何を作るか* /
  ADR = *なぜこの構造か*) によって維持される。「構造的決定が生じた場合のみ
  ADR を作成する」というルールにより冗長性を抑制し、ほとんどのマイルストーンは
  Spec のみで済む。
- テンプレートの主要ユーザー (学習者) が、何が構築済みで何が進行中で
  各設計がどこにあるかを一画面で把握できる ── 実装ステータスは設計とは
  別に追跡される。
- 常時参照される新しいファイルを導入しない。インデックスはすべての
  エージェントがすでに読んでいる唯一のファイルに存在するため、
  エージェントに「インデックスを読むことを忘れずに」という指示が増えない。

### ネガティブ

- **インデックス↔実態のドリフト。** Spec や ADR が Roadmap 行を更新せずに
  作成される可能性があり、インデックスが古くなる。本 ADR では自動的な
  強制手段はない。緩和策は `.github/workflows/workaround-check.yml` を
  モデルにした将来の default-off CI チェックに **延期** されており、
  本 ADR の対象ではない。それまでは、成果物生成者によるオーナーシップが
  唯一の安全策であり、エージェントプロンプトへの遵守に依存する。
- **テーブル形式のバージョン管理された契約がない。** 列の形式とステータス
  グリフは CLAUDE.md とテンプレートフラグメントに文書化されているが、
  テーブルを手動編集したフォークは静かにドリフトする可能性があり、
  形式を検証するものはない。
- 3 つのエージェントプロンプト (`orchestrator`、`architect`、`implementer`) と
  `product-manager` がそれぞれ新しい手順を得る。これはエージェントチームと
  人間の読者が持つべき概念がひとつ増えることを意味する ── インデックス規律は
  すべての生成者がオーナーシップを守る場合にのみ機能する。

### 中立

- これは ADR-012 (単一のエージェントプロンプト変更で動作を合理化し、
  エージェント数を変えなかった先例) が確立したパターンに従う
  **エージェントプロンプト + CLAUDE.md** の変更である。エージェントの
  追加・削除はなく、エージェント数は変わらない。
- 行番号の枯渇/振り直しの圧力は ADR 番号と同じ規約で処理する:
  番号を再利用しない。分割は新しい行と古い行へのメモ。
  特別なツールは不要。
- 100 以上のマイルストーンによるテーブル肥大は、形式として許容される:
  `## Roadmap` 見出しの下に `### Phase N` のサブテーブルに分割する。
  列の契約は分割によって変わらない。
- `implementer` が所有するダウンストリーム実装タスク (本 ADR では実施せず、
  トレーサビリティのために記録する):
  - `.claude/CLAUDE.md` — `## Development Workflow` の直前に `## Roadmap`
    セクションを追加し、`## Extending This File` に「マイルストーンを
    計画する際は Roadmap を埋めてください」という一文を追加する。
  - `orchestrator.md` Analyze 手順 — 「最初に CLAUDE.md の `## Roadmap` を
    参照し、対象マイルストーン行を特定して、リンクされた設計ソースのみを
    開く」。
  - `architect.md` Design Mode「コンテキスト分析」— 「新しい ADR を作成する
    前に Roadmap 行の既存 `adr:` リンクを確認する ── フォークではなく
    amend/supersede を優先する」。
  - `implementer.md`「Spec を読む」手順 — 「Roadmap 行を経由して Spec を
    解決する。リポジトリで検索しない」。
  - `product-manager.md` Spec 生成手順 — 「CLAUDE.md の Roadmap 行を
    追加/更新する (番号、1 行の説明、`spec:` リンク)」。
  - 新規 `.claude/templates/roadmap-section.md` — CLAUDE.md 用の
    貼り付けスケルトンフラグメント。
  - `.claude/templates/spec-template.md` `## References` — 「Roadmap row: #NN」
    の例を追加 (`.ja.md` も同様)。
  - `.claude/templates/adr-template.md` `## References` — 「Roadmap row: #NN」
    の逆参照例を追加 (`.ja.md` も同様)。
  - 本 ADR の日本語版
    (`014-roadmap-index-single-entry-point.ja.md`) は
    `technical-writer` が所有する (本タスクではない)。

## 検討した代替案

| 代替案 | 利点 | 欠点 | 採用しなかった理由 |
|---|---|---|---|
| **A: 1 種類の文書タイプ (ADR のみ、または Spec のみ) に統合してインデックス化する** | インデックス化する成果物タイプが 1 つのみ、自明に MECE、`spec:`/`adr:` の曖昧さが不要 | `implementer` は Spec の受け入れ基準を権威的なスコープとして読むようハードコードされており、`architect` は一貫性のために過去の ADR を読むようハードコードされている ── 1 種類に統合すると 2 つのエージェントの参照契約が壊れる。ADR と Spec は異なる問いに答える (*なぜこの構造か* vs *何を作るか*) ため、統合するとどちらかが肥大化するか、もう一方のロールが失われる | ユーザーとの対話の中で提起され、却下された。MECE はロール分離によって維持されるものであり、文書タイプを 1 つにすることによるものではない。契約破壊のコストが種類を 1 つ減らす利益を上回る。真剣な反対提案として記録する |
| **B: リポジトリルートに独立した `ROADMAP.md` をインデックスとして置く** | CLAUDE.md を短く保てる、人間にとって慣習的で発見しやすいファイル名 | どのエージェントも `ROADMAP.md` をハードコードで参照しない。権威的にするにはすべてのエージェントに「まず `ROADMAP.md` を読む」という指示を追加する必要があり、本 ADR が解消しようとしている「インデックスを読むことを忘れずに」問題を再導入する | 単一エントリポイントのプロパティが成立するのは、インデックスがすべてのエージェントがすべての手順ですでに読んでいる唯一のファイルに存在する場合のみ |
| **C: 現状維持 ── インデックスなし、エージェントが手順ごとに権威的文書を再発見する** | 作業ゼロ、新しい規約なし | orchestrator が毎手順再スキャン/推測する。`architect` が重複 ADR をフォークする。`implementer` が Spec を検索する。学習者にマイルストーン概観がない ── コンテキストに挙げた具体的な症状がそのまま残る | コストはすべてのワークフロー手順で永続的に発生する。常時参照コンテキストファイルの目的はまさにこの再発見をなくすことにある |
| **D: CLAUDE.md 内の `## Roadmap` テーブル、インデックスのみ、ロール別の Spec/ADR リンク (採用)** | 常時参照される単一エントリポイント。`implementer`/`test-runner`/`architect` の参照契約を維持。インデックスのみなのでコンテンツ重複なし。実装ステータスを設計とは別に追跡。`### Phase N` 分割でスケールに対応 | 本 ADR では自動強制手段のないインデックス↔実態ドリフト。形式契約のバージョン管理なし。4 つのエージェントプロンプトに手順が増える | 採用: 再発見コストをなくしつつ既存のエージェント参照契約を壊さない最低コストの選択肢 |

## 参照

- ADR-007 (CLAUDE.md Authoring Skill) — Roadmap セクションは CLAUDE.md への
  構造的変更であり、`claude-md-authoring` Skill のチェックリストと
  不変条件ルールに従って作成する必要がある。
- ADR-012 (Code Reviewer as Dispatcher) — エージェント数を変えることなく
  単一のエージェントプロンプト変更で動作を合理化した先例、および
  レビュー時に提起・却下された反対提案を記録した先例。
- `.claude/agents/orchestrator.md` — Analyze 手順に「まず Roadmap 行を参照する」
  指示が追加される (ダウンストリームタスク)。
- `.claude/agents/architect.md` — 「コンテキスト分析」に「フォーク前に Roadmap 行の
  既存 `adr:` リンクを確認する」指示が追加される (ダウンストリームタスク)。
- `.claude/agents/implementer.md` — 「Spec を読む」手順に「Roadmap 行を経由して
  Spec を解決する」指示が追加される (ダウンストリームタスク)。
- `.claude/agents/product-manager.md` — Spec 生成手順に「Roadmap 行を追加/更新する」
  指示が追加される。`product-manager` が行作成を所有し、`architect` が
  `adr:` リンクを所有し、`orchestrator` は読むだけ (ダウンストリームタスク)。
- `.claude/templates/spec-template.md` と
  `.claude/templates/adr-template.md` — `## References` に
  「Roadmap row: #NN」の例/逆参照が追加される (ダウンストリームタスク)。
- `.github/workflows/workaround-check.yml` — 後で追加される場合に、
  対象外の drift-check CI が従うべき形。

## Amendment — 2026-05-16 (Spec reservation rule)

本テンプレート自身の `## Roadmap` セクションに監査駆動の 21 マイルストーンを
投入する dogfooding 作業の中で、`product-manager` は元の決定の 2 つのルールの
間に実際の緊張を発見した。「マイルストーン ↔ Spec は 1:1 かつ必須」はすべての
行に `spec:` リンクを要求するが、未着手のマイルストーンに対して 21 本の
Spec ファイルを先行作成することは無駄であり、マイルストーンが実際に着手される
時点で行うべきスコープ決定を前倒しすることになる。本 amendment は、その緊張を
解消した運用上の解釈を批准するものであり、CLAUDE.md の Roadmap セクションに
すでに反映されている。

**予約ルール (reservation rule)。** すべての Roadmap 行は、行作成時点で
`spec:` リンクを持つ。パスは `specs/NN-slug.md` という決定論的な形式を使い、
`NN` は安定した行番号である。Spec **ファイル** は `product-manager` が
マイルストーンを着手するとき (ステータスが `◐ in-progress` に移行するとき)
にのみ作成される。予約済みのリンクは行が存在した瞬間から安定して存在し、
ファイルはその後にディスク上に実体化される。

**これが元の決定に違反しない理由。** 決定の 1:1 必須ルールが制約するのは
**リンク** であり、**ファイル** ではない: 「すべてのマイルストーン行には
ちょうど 1 つの `spec:` リンクを持つ」。このプロパティは行作成時点で成立し、
それ以降変わらない ── マッピングはインデックスのプロパティであり、
インデックスのみのテーブルがまさに担うものである。ADR-014 が要求するのは
リンクが *存在し安定していること* であって、ターゲットが *ディスク上に存在すること*
ではない。また、不変の行番号をキーとする `specs/NN-slug.md` という決定論的な
パスにより、曖昧さのない安定性が保証される。`implementer`/`test-runner` の
参照契約は、そのコントラクトが実行されるのが `implementer` がマイルストーンに
対して呼び出されたときであることから、同様に守られる。本 ADR の書き込み
オーナーシップモデルにより、`product-manager` は `◐ in-progress` への移行時に
Spec を作成する ── これはコードが書かれる前であることが構造的に保証されている。
したがって、`implementer` がポインターを解決してファイルが存在しないという
ウィンドウは存在しない: 実装ステップに達した行は、オーナーシップルールにより
すでに Spec が作成されている。予約ルールは 1:1 マッピングが成立することと
Spec がコードに先行することを弱めることなく、ファイルが書かれる *タイミング*
を厳密に定める。

**率直に認める緊張。** `product-manager` は、行 #16–#21 が S サイズの
散文編集 (ステータスの不一致、CHANGELOG の後追い補完、allowlist の有効期限)
であり、フルの Spec は作業量に対して過剰だと指摘した。予約ルールはこれを
解消しない ── それらの行も着手時には Spec ファイルを必要とする。
受け入れた緩和策は、それらの Spec を半ページ程度に留めることである:
`test-runner` のコントラクトを果たすための受け入れ基準を持つだけで、
それ以上の形式は要らない。これは意図的な、目を開けたトレードオフである:
「小さな」マイルストーンに対する例外を設けるのではなく (例外を設けると
ADR-014 が解消しようとしている「このマイルストーンに Spec はあるか」という
再発見問題をそのまま再導入してしまう)、1:1 コントラクトを一様に維持し、
比例コストを Spec の簡潔さとして支払う。

元のステータス行 (`Accepted — 2026-05-15`) は変更しない。本 amendment は
運用上の解釈を追記するものであり、決定を再開するものではない。日本語版
(`014-roadmap-index-single-entry-point.ja.md`) は `technical-writer` タスクで
本 amendment に相当する内容を受け取る必要がある ── 本変更の対象ではない。

## Amendment — 2026-05-16 (CLAUDE.md line-budget vs. the Roadmap)

21 行の Roadmap を投入したことで `.claude/CLAUDE.md` が 220 行に達した。
`claude-md-authoring` Skill の事後チェックリストには「CLAUDE.md は 200 行以下」
とあり、その超過の直接の原因は Roadmap の ~25 行 (ヘッダー + テーブル + ルール)
である。ADR-014 の決定はすでに 100 以上のマイルストーンでのテーブル肥大を
想定していた (`### Phase N` 分割) が、そのメカニズムは 21 行では役に立たず、
より根本的には ── Roadmap を *どこかに* 分割することは、単に非実用的なのでは
なく構造的に不可能である。本 amendment はその解決策を記録する。
なお、CLAUDE.md 自体の編集は本 ADR では **行わない** (それは下記に
トレーサビリティのために列挙したダウンストリームの `implementer` タスクである)。

**通常の回避策が Roadmap に対してのみ閉じている理由。** Skill の
過長 CLAUDE.md に対する修正策は「セクションをサブディレクトリの `CLAUDE.md`
または Skill に分割する (散文を圧縮するのではなく)」である。この修正策は
対象セクションが *移動可能* であることを前提としている。Invariant 2
(`.claude/skills/claude-md-authoring/invariants.md` §2:
「ルートコンテンツは compaction に残る。サブディレクトリおよびパス指定コンテンツ
は残らない」) は、Roadmap がまさにその前提が崩れる文書化されたケースにする:
Roadmap は ADR-014 の単一の常時参照エントリポイントであり、compaction に
残る場合にのみエントリポイントとして機能する。サブディレクトリの `CLAUDE.md`
や Skill はオンデマンドでロードされ、compaction 時に要約されてしまう ──
Roadmap をそこに移動することは、Roadmap を正当化する性質そのものを破壊する。
Invariant 4 は残りの扉を閉じる: `@path` インポートは「構成を改善するが
コンテキストトークンを節約しない」。Roadmap *のみ* については、
再配置によって予算を回収することができない。

**「around 200」ルールの実際の強制ステータス。** これは **volatile rule
(揮発性ルール) であって invariant (不変条件) ではない**。Skill は次のとおり
明示している: 「Docs にアクセスできない場合は『around 200』として扱う。
**CI の hard failure として強制しない**」(SKILL.md §「Volatile rules」)。
事後の「200 行以下」という行はチェックリストのプロンプトであり、ゲートではない。
したがって、恒久的な超過は *Skill 自体によって許可されている*。
唯一の未解決の問いは、その超過が *最小限か* である。

**決定: ハイブリッドアプローチ (回収可能なスラックを回収してから、
削減不可能な残余を認可する)。** 約半分が compaction 耐久コンテンツに
触れることなく安価に回収できるときに、~20 行の超過全体を認可済み例外として
費やすことは最小限ではない。したがって:

1. **Roadmap の行説明を圧縮する。** テーブルはインデックスのみ
   (リンク先の Spec が Source of Truth) であるため、行テキストは
   自己説明的な散文である必要はない。安定したスキャン可能なハンドルが
   あれば十分である。各マイルストーンの 1 行説明を短い名詞句に絞り、
   括弧書きの補足説明 (「incl. …」「note: …」「A-08/C-06」) をテーブル
   から外に出す ── それらは Spec/ADR のコンテンツであり、インデックス
   コンテンツではない。そして行に置くことは決定の「インデックスのみ ──
   根拠を複製しない」ルールに違反する。目標: 25 行の Roadmap ブロックを
   21 行すべてを維持しながら ~18–19 行に削減する。
2. **他の箇所で 1 つのターゲットを絞ったトリミングを行う。**
   `## Plan-First & Learning-Aware Defaults` セクションの 3 段落目
   (`coaching-context.sh` フックの仕組み) は、Invariant 2 でロックされた
   運用上の詳細ではない ── `.claude/meta/adr/004-coaching-pillar.md` と
   フックファイル自体から完全に再構築可能であり、Invariant 3 の下で
   コード派生可能なものとして適格である。その段落の仕組みを
   Learning Mode のメタ参照に移動し、1 行のポインターを残す。
   ~6 行の真に移動可能なコンテンツを回収する
   (Learning Mode がアクティブなときにオンデマンドでロードされるため、
   そのコンテンツに compaction 耐久性は不要である)。
3. **削減不可能な残余をインラインで認可する。** (1) と (2) の後に残る
   超過は Invariant 2 が移動を禁じている Roadmap の削減不可能な
   コアに起因する。CLAUDE.md の `## CLAUDE.md authoring guidance`
   セクションに、ラインガイダンスが Roadmap に設計上譲歩することを記録する
   短い認可済み例外ノートを追記する。具体的な文言は下記の
   `implementer` への指示を参照。

これはハウススタイルの範囲内にある: ADR-014 の既存の決定の *帰結* の
明確化である (Roadmap はルート CLAUDE.md に存在し、compaction に残る必要がある ──
すでに決定済み)。加えてダウンストリームの編集指示を含む。
これは新しい構造的決定ではなく、したがって **独自の ADR を正当化しない**。
ECC の先例 (ADR-008、ADR-010 は帰結の明確化を amendment に折り込む。
新しい ADR 番号は新しい構造的決定のために予約する) により、本変更は
ADR-015 ではなく ADR-014 amendment として位置付けられる。ADR-015 は作成しない。

**`implementer` が CLAUDE.md の `## CLAUDE.md authoring guidance` セクションに
追記する認可済み例外の文言** (最終段落として追記。既存の段落は変更しない):

> **Sanctioned line-budget exception (per ADR-014 amendment
> 2026-05-16).** The `## Roadmap` section is exempt from the
> ~200-line CLAUDE.md guidance. The Roadmap is the single always-read
> entry point for design artifacts and must survive compaction
> (Invariant 2), so it cannot be relocated to a subdirectory
> `CLAUDE.md` or a Skill without defeating its purpose. The "around
> 200" rule is a volatile guideline, never a hard CI failure; it
> yields to the Roadmap by design. Reclaim budget by compressing
> Roadmap row text (index-only) and trimming non-compaction-durable
> sections elsewhere — not by moving the Roadmap.

**ダウンストリームの `implementer` タスク (トレーサビリティのために記録。
本 ADR では実施しない):**

- `.claude/CLAUDE.md` — 21 行の Roadmap 行説明を短い名詞句に圧縮する。
  括弧書きの補足説明をテーブルの外に出す (決定の「インデックスのみ」ルールに
  従い、Spec/ADR コンテンツである)。
- `.claude/CLAUDE.md` — `## Plan-First & Learning-Aware Defaults` の
  `coaching-context.sh` フックの仕組み段落を Learning Mode のメタ参照に
  移動し、1 行のポインターを残す。
- `.claude/CLAUDE.md` — 上記の認可済み例外段落を
  `## CLAUDE.md authoring guidance` に追記する。
- CLAUDE.md の日本語版 (存在する場合) と本 ADR の日本語版は
  相当する編集を受け取る ── `technical-writer` タスクであり、
  本変更の対象ではない。

元のステータス行 (`Accepted — 2026-05-15`) は変更しない。

## Amendment — 2026-05-17 (status-transition ownership matrix)

本 amendment は、この ADR 自身の §帰結 → ネガティブが明記した「形式的なステータス遷移状態機械は本 ADR の対象外。それまでは、成果物生成者によるオーナーシップが暫定的な唯一の安全策である」というギャップを閉じる。`specs/07-roadmap-status-transitions.md` (Roadmap row #07) が権威的なスコープであり、構造的な *どのように* を `architect` に委ねている (リスク R-01 (a)-(d))。本 amendment はその決定を記録する。これは **ADR-014 の既存の決定の帰結明確化** であり、新しい構造的決定ではない: §決定はすでに暫定形式でグリフオーナーシップを割り当てており (「成果物生成者によるオーナーシップ」)、本 ADR はその形式化を自身の延期されたフォローアップとして事前宣言していた。新しいディテクター、境界、キーイング、またはメカニズムは導入しない。ECC の先例 (本 ADR の 2 つの 2026-05-16 amendment と ADR-018 の 2026-05-17 amendment が適用する「帰結明確化は amendment に折り込む; 新しい ADR 番号は新しい構造的決定のために予約する」── ADR-015 §Context、ADR-017/ADR-018 Alternative B) により、本変更は ADR-014 amendment であり、**ADR-019 ではない**。ADR-019 は作成しない; Roadmap <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal; it is intentionally never created (see Counter-proposal below) -->
row #07 は `spec:` のみのまま維持される (マイルストーン → ADR は 0:1; Roadmap メカニズム ADR への amendment は #07 固有の ADR ではない ── ADR-014 にはそれ自身のマイルストーン行がないため、row #07 から ADR-014 へ `adr:` リンクを追加することは存在しないマイルストーン→ADR マッピングを主張することになる)。

**なぜ状態機械ではないか。** Spec の Non-goals は「一般的なワークフロー状態機械エンジンの設計」を禁じている。本 amendment は、ADR-014 の §決定がすでに認可した 4 つのグリフ遷移 (`☐`/`◐`/`☑`/`✗`) それぞれに *オーナーとワークフローステップのトリガー* を割り当てる。新しいグリフ、新しい遷移、新しいワークフローステップは追加しない。マイルストーン #03、#05、#06 (および本セッションでの #07 の着手) が逐語的に実践した暫定慣行を成文化するものであり ── ドキュメント/オーナーシップの形式化であり、すべての歴史的な変更と遡及的に整合しており、動作変更ではない。

### The status-transition ownership matrix

各遷移に対して正確に 1 つのオーナーロールが割り当てられ、`## Development Workflow` の名前付きステップまたはゲートに紐付けられる:

| 遷移 | オーナーロール | トリガー / ゲート条件 | ADR-014 / ADR-016 との整合性 |
|---|---|---|---|
| `☐ todo → ◐ in-progress` | `product-manager` | マイルストーン着手時に Spec ファイル `specs/NN-slug.md` を作成すると同時に実施 (ワークフロー手順 2)。Spec がディスク上に存在し作業が開始された後も、グリフが `☐` のままであってはならない。 | ADR-014 の既存の書き込みオーナーシップ (`product-manager` が行 + `spec:` リンクを所有) および Spec 予約ルール (ファイルは `◐` 遷移時に作成される) と整合する。 |
| `◐ in-progress → ☑ done` | `product-manager` | そのマイルストーンのワークフロー手順 6 のクオリティゲート (code-reviewer、linter、security-reviewer、performance-engineer がすべて通過) および手順 7-9 (docs、release、commit) が完了した後。ADR-014 の下でその行の既存の書き込みオーナーである `product-manager` が変更を実施する; 他のロールは `◐→☑` を変更できない。 | ADR-014 の下で行を所有するロールがクローズアウトの変更を所有する。変更オーナーは同一変更で `specs/NN-progress.md` も削除する (ADR-016 §4 退役)。これにより ADR-016 の削除トリガーと #07 の変更オーナーが同一ロールになり、オーナーシップのギャップが生じない。 |
| `◐ in-progress → ✗ dropped` | `product-manager`、`orchestrator` 確認済みの削除決定に基づく | orchestrator (ワークフロー手順 1 の Analyze 権限) がマイルストーンが時代遅れ/実現不可能と判断したとき、`product-manager` (行の書き込みオーナー) がグリフを変更する; 行はテーブルに残る (履歴は書き換えない)。 | 削除権限は意図的に分割される: `orchestrator` が *決定する* (Analyze を所有し、常に読む唯一のロール)、`product-manager` が *書き込む* (ADR-014 はすべての行の書き込みを `product-manager`/`architect` に予約; `orchestrator` は行を書き込まない)。同一変更オーナーが ADR-016 §4 に従って `specs/NN-progress.md` を削除する。 |
| `☑ done → ✗ dropped` (revert) | `product-manager`、`orchestrator` 確認済みの差し戻し決定に基づく | 出荷済みマイルストーンが後に実現不可能/差し戻しと判明したとき、`◐→✗` と同じ分割: `orchestrator` が決定し、`product-manager` が書き込む。行はテーブルに残る; ADR-014 の「削除行はテーブルに残る / 履歴は書き換えない」が適用される。 | `◐→✗` と同一の権限分割。`☑` 時点では `specs/NN-progress.md` は存在しない (ADR-016 §4 が `◐→☑` 時に削除済み) ため、progress-file 操作は不要。 |

**「クオリティゲートのクローズアウト担当者」の曖昧さの解消 (Spec R-01 (b))。** 暫定慣行では `◐→☑` のオーナーを「クオリティゲートのクローズアウト担当者」と表現していたが、Spec はこれを未解決の名称としてフラグしていた。本 amendment はこれを **名前付きロール: `product-manager`** として解消する (複合責任ではない)。根拠: ADR-014 の書き込みオーナーシップモデルはすでにすべての Roadmap 行の書き込みを `product-manager` (行 + `spec:`) または `architect` (`adr:`) に予約しており、`orchestrator` は読み取り専用である。ステータスグリフは行セルであり、グリフ変更は行の書き込みである。`◐→☑` を 2 つの認可された行書き込み者以外の誰かに割り当てることは ADR-014 の既存の決定と矛盾する。2 者の間では、`architect` は `adr:` リンクのみを書き込む; 行のライフサイクルオーナーは `product-manager` である。したがって `product-manager` は `◐→☑` を所有し、手順 6 のクオリティゲート通過を条件とする (ゲートは *条件* であり、*オーナー* は行書き込み者である)。これにより、グリフ次元が ADR-014 のリンク/行書き込みオーナーシップと矛盾せず整合し続け、Spec の互換性受け入れ基準を満たす。

**ADR-016 との合成可能性 (Spec R-01、ADR-016 §4)。** ADR-016 は `specs/NN-progress.md` の削除を「`◐→☑` または `◐→✗` 変更」によってトリガーされると定義し、削除を「Roadmap グリフを変更するエージェント」に割り当てる。本 amendment はそのエージェントに名前を付ける (`◐→☑` と `◐→✗` の両方に `product-manager`)。これにより 2 つのルールがギャップなく合成可能になる: 本 amendment が変更を授権するロールは、ADR-016 §4 がすでに progress-file 削除に拘束しているロールである。本 amendment はすべての `◐→{☑,✗}` 変更を `product-manager` に割り当てるため、`product-manager` はペアの削除も所有する。

### Documentation placement (Spec R-01 (b))

形式化されたマトリックスは、**CLAUDE.md の `## Roadmap` の Rules ブロック** に 1 つの追加箇条書きとして記載される ── Development Workflow セクションではなく、エージェントプロンプトにも複製しない。根拠:

- Rules ブロックは **インデックスに隣接しており compaction 耐久性がある**: Roadmap テーブルのすぐ下に存在し、すべてのエージェントがすべての手順で読む (Invariant 2)。そのため `product-manager` は Spec を作成したりゲートをクローズしたりする正確な手順でグリフオーナーシップルールに出会い、**ゼロの追加ファイル読み取り** で済む ── Spec の R-01 (b) 受け入れ基準を満たす。
- **最もタイトな配置**: Rules ブロックは Roadmap セクション *内部* にあり、そのセクションは既に認可された行予算例外 (本 ADR の 2026-05-16 行予算 amendment) である。既に免除されているセクションへの 1 つの追加箇条書きは、他の場所で予算を消費しない; `## Development Workflow` に散文を追加することは免除されていないセクションを肥大化させる。
- **インデックスと整合**: グリフオーナーシップは Roadmap メカニズムのプロパティ (Status セルを書き込める者) であり、これはまさに Rules ブロックが統治するもの (既に `Status =` グリフセットと行/リンク書き込みオーナーシップを記載している)。遷移マトリックスは既存の「Write-ownership:」箇条書きの自然な補完であり、新しい場所の新しい概念ではない。

正確な 1 箇条書きの文言は下記の `implementer` に渡される; マイルストーン #05 のグリフ *整形性* チェック (ADR-017: #05 はグリフ *値* が 4 つの認可された文字のいずれかであることを検証する; #07 は *誰が* いつ変更できるかを統治する ── 別個で重複しない; CI は #07 を自動化しない) に対する MECE 境界は Spec の R-03 に記述され、箇条書きにも再記載される。

### Spec R-01 (c)(d) judgements recorded for the implementer

- **(c) Amendment か新しい ADR か:** ADR-014 amendment (上記で決定)。ADR-019 なし。Row #07 の Design-source セルは変更なし (`spec:` のみ)。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
- **(d) claude-md-authoring Skill の必要性:** 延期された CLAUDE.md 編集は **既存の `## Roadmap` Rules リストへの 1 箇条書きの追加** ── CLAUDE.md の `## CLAUDE.md authoring guidance` セクションの明示的なカーブアウトによる「ルーティン的な小さな編集 (… 単一の箇条書き …)」(「Routine small edits (typo, single bullet, version bump) do not need the Skill」)。「重要な再構成」ではない (セクションの追加/移動/分割なし、見出し変更なし、不変条件の変更なし)。**判断: claude-md-authoring Skill は #07 実装編集に不要**。(実装者が代わりにサブ見出しやテーブルを追加することを選択した場合、それは再構成に該当し Skill が適用される ── しかしここの設計は、ルーティン編集カーブアウトの範囲内に留まるよう意図的に単一箇条書きである。)
- **(d) エージェントプロンプトへの影響:** **エージェントプロンプトの編集は不要**。マトリックスは ADR-014 が *すでに確立した* Roadmap 書き込みコントラクトを持つロールに遷移を割り当てる (`product-manager` は行書き込みを所有; `orchestrator` は読み取り/Analyze で決定; `architect` は `adr:` のみを所有)。`product-manager` はすでに Spec 作成時に行 + `spec:` の書き込みを所有している (ADR-014) ── `☐→◐` と `◐→{☑,✗}` の変更は、プロンプトではなく Rules ブロックで明示された、その既に所有されている行書き込みのグリフファセットである。`orchestrator` の削除 *決定* 権限はその既存の Analyze ステップロールである (ADR-014: 「orchestrator は読むだけ」; 削除決定は Analyze の出力であり、行の書き込みではない)。ADR-016 はすでに `product-manager`/`implementer` の progress-file 削除プロンプト行を追加した; 本 amendment は *どのロールの変更が* それらをトリガーするかに名前を付けるだけであり、これは Rules ブロック箇条書きがプロンプト編集なしに伝える。常時読まれる Rules ブロック (プロンプトではなく) にルールを記録することは、ADR-017/ADR-018 が変更をエージェントプロンプトの外に置いたことと整合する意図的な最小サーフェス選択である。

### Downstream `implementer` tasks (recorded for traceability, not performed by this amendment — implementation is a future session, per the #03/ADR-016 · #05/ADR-017 · #06/ADR-018 two-session decision-then-implementation split)

- `.claude/CLAUDE.md` `## Roadmap` **Rules** ブロック ── 既存の「Write-ownership:」箇条書きの後に 1 つの箇条書きを追加する。形式: *「Status glyph transitions: `product-manager` が Spec 作成と同時に `☐→◐` を変更し、手順 6 のクオリティゲート通過後に `◐→☑` を変更する (同一変更で ADR-016 に従って `specs/NN-progress.md` を削除する); 削除 (`◐→✗`、`☑→✗`) は Analyze 時に `orchestrator` が決定し `product-manager` が書き込む、行は保持 (履歴は書き換えない)。#05 はグリフ *値* の整形性を検証し; #07 は *誰が* いつ変更するかを統治する ── CI は #07 を強制しない。」* 単一箇条書き、サブ見出しなし、テーブルなし ── ルーティン編集カーブアウトの範囲内 (claude-md-authoring Skill の呼び出しは不要)。
- **エージェントプロンプトの編集なし** (上記の判断)。実装者は `product-manager.md`、`orchestrator.md`、`architect.md`、`implementer.md` にグリフオーナーシップの散文を追加してはならない; Rules ブロックが唯一のソースである。
- **CI ワークフローなし** (Spec Non-goals; #07 はプロセス/ドキュメント割り当てであり、自動チェックではない ── ADR-017 に対する #05 のグリフ *値* チェックおよび Spec の R-03 MECE 境界とは別個)。
- 本 ADR の日本語版 (`014-roadmap-index-single-entry-point.ja.md`) はミラーされた amendment を受け取る必要があり、CLAUDE.md の日本語版 (存在する場合) はミラーされた Rules ブロック箇条書きを受け取る ── `technical-writer` タスクであり、本変更の対象ではない。**本 amendment は ADR-014 に EN/JA 見出し不一致を一時的に作り出す。#06 の bilingual-parity detector (`check-bilingual-parity.sh`) は `technical-writer` のミラーが反映されるまで ADR-014 で FAIL する。これは期待されるキューに入った `technical-writer` タスクであり、本 EN amendment を省略する理由ではない。**

### Counter-proposal

深刻な反対案は **新しい ADR-019 ── ステータス遷移マトリックスを ADR-014 amendment ではなくスタンドアロン ADR として形式化する** である。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 の慣例に従い、却下された代替案を藁人形としてではなく真剣に記録する。議論:

1. Spec は `architect` に明示的な (c) 選択肢 (「ADR-014 amendment か新しい ADR-019 か」) を渡しており、構造的に並行した兄弟マイルストーン #05 と #06 はどちらも延期された構造的質問の Spec を *新しい* ADR (017、018) で解決しており、amendment ではない。プロセスの対称性は #07 → ADR-019 を示唆する。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
2. 4 つのエージェントロールが遵守しなければならない名前付きオーナーシップマトリックスはファーストクラスの引用可能なコントラクトである; 長い ADR-014 トレイルの 3 番目の amendment として埋め込むことは、読者が「ステータス遷移 ADR」として引用できる専用 ADR-019 より発見しやすさが劣る。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
3. ADR-019 はそれ自身の Roadmap バックリンク (`Roadmap row: #07`) を持ち、 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   row は `adr:` リンクを獲得する ── #05/#06 が行使する同じ双方向コントラクトを #07 に与え、その兄弟と同じ成果物形状になる。

**反対案が採用されなかった理由:**

- ADR-017 と ADR-018 は特定の、明記された識別基準に基づいて新 ADR に値すると自己分類した: それぞれが **新しいディテクター + 新しい MECE コントラクト境界 + 新しい免除キーイングルール** を導入した (ADR-017 Alternative B; ADR-018 Alternative B)。#07 はそれらのいずれも導入しない ── ディテクターなし、境界なし、キーイングなし、メカニズムなし、新しいグリフなし、新しいワークフローステップなし。ADR-014 の §決定が *すでに認可した* 遷移のオーナーを割り当て、ADR-014 *自身が自身の延期されたフォローアップとして事前宣言した* 形式化 (「本 ADR の対象外… それまでは」) を行う。兄弟対称性の議論は詳細に見ると逆転する: #05/#06 自身の識別基準を #07 に適用すると「amendment」になる、なぜなら #05/#06 にとって支配的だった構造的な半分が #07 には不在だからである。これは ADR-014 の 2026-05-16 行予算 amendment が自身の ADR-015 を拒否した際に使用したのと全く同じ推論であり (「ADR-014 の既存の決定の帰結の明確化… 新しい構造的決定ではない」)、ADR-018 の 2026-05-17 amendment が新しい番号なしにすでに決定されたオーナーシップルールを精緻化するために使用した推論でもある。
- 発見しやすさは ADR-014 amendment の方が *良い*、悪くない: グリフオーナーシップは ADR-014 が所有する Roadmap メカニズムのプロパティであり; 正規の場所として読者が「Roadmap セルを誰が変更できるか」を探す先は Roadmap を定義してすでに行/リンク書き込みオーナーシップを割り当てている ADR である。別個の ADR-019 は Roadmap オーナーシップコントラクトを 2 つの ADR に *分断* する ── orchestrator/architect は完全な書き込みオーナーシップ像を知るために ADR-014 *と* ADR-019 の両方を読む必要があり、ADR-014 が除去しようとした「どの文書が権威的か」という再発見の問題をまさに再導入する。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
- 双方向バックリンクの議論は無意味: ADR-014 は自身のマイルストーン行を持たないため、ADR-014 への amendment は正しく `Roadmap row:` 行を持たず #05 ドリフトコントラクトをトリガーしない。バックリンクを作成するためだけに新しい ADR-019 を強制することは、真の構造的決定を反映するのではなく双方向成果物を製造することになる。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->

**この反対案を再評価するトリガー条件:**

- 将来のマイルストーンが真に *ワークフロー状態機械エンジン* を導入する場合 (新しい遷移、新しい状態、*誰が* グリフを変更したかの自動強制ディテクター) ── それは新しい構造的決定 (新しいメカニズム + 新しい境界) であり、独自の ADR を持つに値し、本 amendment のマトリックスをその継承されたベースラインとする。
- ステータス遷移ルールがプロジェクトタイプごとに異なるオーナーシップを必要とすることが判明した場合 (例: `product-manager` を削除するフォーク)、単一マトリックスが ADR-014 で表現できなくなった時点で、プロファイル別マトリックスを持つ専用 ADR が適切になる可能性がある。

反対案は ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 の慣例に従い、決定の最も深刻な異論の歴史的記録として本 amendment に残る。

元のステータス行 (`Accepted — 2026-05-15`) は変更しない; 本 amendment はすでに認可されたメカニズムのオーナーシップ形式化を追記するものであり、決定を再開するものではない。
