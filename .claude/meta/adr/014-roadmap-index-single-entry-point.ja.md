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

## Amendment — 2026-05-17 (orchestrator Analyze row-guard)

本 amendment は、この ADR 自身の §帰結 → ネガティブが逐語的に明記した
「インデックス↔実態のドリフト。Spec や ADR が Roadmap 行を更新せずに作成される
可能性があり、インデックスが古くなる。本 ADR では自動的な強制手段はない…
それまでは、成果物生成者によるオーナーシップが唯一の安全策であり、エージェント
プロンプトへの遵守に依存する。」というギャップを閉じる。
`specs/08-orchestrator-row-guard.md` (Roadmap row #08) が権威的なスコープであり、
構造的な *どのように* を `architect` に委ねている (リスク R-01 (a)–(d)、R-02、R-03)。
本 amendment はその決定を記録する。これは **ADR-014 の既存の決定の帰結明確化** であり、
新しい構造的決定ではない: §決定はすでに orchestrator の Analyze 手順を Roadmap 参照
とし (「orchestrator の Analyze 手順がリポジトリスキャンではなくテーブル参照になる」)、
orchestrator に読み取り専用の Roadmap コントラクトを割り当てている
(「`orchestrator` は読むだけ」)。#08 はその参照が *dispatch 前に何を検証しなければ
ならないか* を強化する。新しいディテクター、CI ワークフロー、コントラクト境界、
キーイングルール、またはメカニズムは導入しない ── ガードは ADR-014 の既存の
Analyze ステップエントリポイントと ADR-016 の既存の `specs/NN-progress.md`
コントラクトをそのまま再利用する。

### The (b) decision — ADR-014 amendment, not new ADR-019, by the ADR-018 Alternative-B discriminator <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal; it is intentionally never created (see Counter-proposal below) -->

Spec の R-01 (b) は `architect` に「ADR-014 amendment か新しい ADR-019 か」という <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
明示的な選択肢を渡し、ADR-018 の Alternative-B 識別基準を逐語的に適用するよう
指示する: *#08 は新しいディテクター + 新しい MECE コントラクト境界 + 新しいキーイング/
メカニズムを導入するか (⇒ 新しい ADR)、それとも既存 ADR のすでに認可された決定の
帰結明確化/拡張か (⇒ amendment)?* 正直に条項ごとに適用すると: <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->

- **新しいディテクター? いいえ。** Spec の Non-goals と Out of scope は CI ワークフロー
  を明示的に禁じている (「新しい CI ワークフローファイルの追加。#08 は静的分析の追加
  ではなく、ランタイム orchestrator の動作変更である」; 「ガードを CI で機械的に強制
  すること (将来のマイルストーンとして可能性はあるが、#08 ではない)」)。ADR-017 と
  ADR-018 はそれぞれ新しいスクリプト + 新しいワークフロー (`check-roadmap-drift.sh` /
  `check-bilingual-parity.sh`) を導入したがゆえに新 ADR に値すると自己分類した。#08 は
  スクリプト **ゼロ**、ワークフロー **ゼロ** である。ADR-017/ADR-018 にとって支配的だった
  構造的な半分が ここには存在しない。
- **新しい MECE コントラクト境界? 新たな分割なし。** 境界の *記述* は必要だが
  (Spec Goal 4、R-03)、#04/#05/#06 ディテクターファミリーのコントラクト分割に 4 番目の
  ディテクターを追加するわけではない。#08 はその分割の *外部* に位置することを記述する:
  #04/#05 はコミット時の静的チェックであり、#08 はランタイムの orchestrator 動作である。
  これは ADR-014 の Analyze ステップ義務がどこに存在するかのスコープ限定であり、
  ADR-017 の absence-of-claim や ADR-018 の convention-presence のような新しいキーイング
  ルールではない。
- **新しいキーイング/メカニズム? いいえ。** 免除キーイングルールも、allowlist と
  pattern の選択も、パース戦略も、新しいファイル成果物もない。3 つのガード条件は、
  ADR-014 (エントリポイント不変条件; orchestrator 読み取り専用) と ADR-016
  (`specs/NN-progress.md` 書き込みオーナーシップ) がすでに確立した不変条件の
  *帰結* である。
- **既存の決定の帰結明確化? はい、決定的に。** ADR-014 §帰結 → ネガティブは
  正確なギャップを逐語的に名指ししている (上記引用)。#08 ガードは ADR-014 の
  エントリポイント不変条件が満たされない場合に dispatch を拒否する orchestrator の
  ランタイム義務である。これは 2026-05-17 のステータス遷移 amendment (#07) と同一の
  構造的形状であり、#07 は別の ADR-014 §帰結 → ネガティブのギャップを ADR-019 ではなく <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  amendment で閉じた。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->

**兄弟対称性の議論は詳細に見ると逆転する** (#07 amendment が同じトラップを指摘した):
「#05/#06 → ADR-017/ADR-018; したがって対称性から #08 → ADR-019; そして ADR-016 は <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
ADR-014 と合成するが別の ADR である」 ── しかし #05/#06 自身の識別基準を #08 に
適用すると **amendment** になる、なぜなら 3 つの構造的条項がすべて不在だからである。
ADR-016 が別の ADR である理由は、*新しいメカニズム* を導入したから ── 独自の <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
書き込みオーナーシップ/ライフサイクル/削除トリガーコントラクトを持つ新しいファイル成果物
(`specs/NN-progress.md`); #08 は新しい成果物もメカニズムも導入しない ── 既に存在する
2 つのメカニズムの *使用* を制約するだけである。**決定: ADR-014 amendment。ADR-019 は <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
作成しない。** Roadmap row #08 は `spec:` のみのまま維持される (マイルストーン → ADR は <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
0:1; Roadmap メカニズム ADR への amendment は #08 固有の ADR ではない ── ADR-014 には
それ自身のマイルストーン行がないため、row #08 から ADR-014 へ `adr:` リンクを追加
することは存在しないマイルストーン→ADR マッピングを主張することになる ── #07 amendment
と同一の推論)。

### The Analyze pre-dispatch guard (three named conditions, three routing outcomes)

ADR-014 の §決定は Analyze ステップを Roadmap 参照とする。本 amendment は、
orchestrator がマイルストーン作業のためにサブエージェントを dispatch する *前に*
その参照が満たさなければならない個別の前提条件に名前を付ける。各条件にはちょうど
1 つのルーティング結果があり、いずれも Roadmap を自動変更しない (orchestrator は
ADR-014 §決定に従い読み取り専用のまま):

| # | ガード条件 | 未満時のルーティング結果 |
|---|---|---|
| G1 | 受け付けたタスクに対応する Roadmap 行が存在する。 | 不足している行をユーザーに伝え、行の作成 (および着手時の #07 `☐→◐` 遷移で Spec を作成) を `product-manager` にルーティングする; orchestrator はサブエージェントを dispatch せず、行を自分で挿入しない (ADR-014: orchestrator は行を書かない)。新しく作成された行で Analyze を再実行する。 |
| G2 | 次のアクションが `implementer` または `test-runner` への dispatch となる **場合に限り**、行の `spec:` ファイルがディスク上に存在する (以下の R-02 解決を参照)。 | `product-manager` に Spec を作成してからその dispatch を行うようルーティングする。*プロダクト計画またはアーキテクチャ* が次のアクションである `☐` 行の予約済みだがファイル未作成の `spec:` は ADR-014 予約ルールの有効な中間状態であり、ガードをトリガーしない。`spec:` が存在しない `◐` 行は不完全な着手であり: 実装 dispatch の前に欠けている Spec を作成するよう `product-manager` にルーティングする。 |
| G3 | `◐ in-progress` 行に対して `specs/NN-progress.md` が存在する。 | 存在しない場合、**progress レコードが存在しないことを明示的に表明し**、`git log` から状態を再導出する; いずれのワークフロー手順も暗黙に仮定しない。これは orchestrator.md Workflow step 1 がすでに持つフォールバックを、埋め込まれた散文ではなく名前付きの可視ガード条件として形式化する。orchestrator は progress ファイルに対して読み取り専用のまま (ADR-016 書き込みオーナーシップは変更なし)。 |

G1–G3 がすべて満たされた場合、orchestrator は変更なく Feasibility 評価
(Workflow step 2) と既存の dispatch フローに進む ── ガードは dispatch 前の
ゲートを追加するものであり、満たされたパスを変更するものではない。

**(R-02) ☐ 行の dispatch 粒度サブ決定 ── 単純なヒューリスティックに解決。**
Spec の R-02 は architect に選択肢を渡す: G2 に意図した下流エージェント
(「`implementer`/`test-runner` に dispatch しようとしている」) を内省させるか、
それとも「行が `☐` で Spec がない場合は、意図した下流エージェントに関わらず
まず `product-manager` にルーティングする」というより単純なヒューリスティックに
集約するか。**決定: より単純なヒューリスティックを採用する。** 根拠:
(1) *安全* である ── `product-manager` が Spec を作成して `☐→◐` (の #07 遷移) を
行うことは、`☐` 行が着手時にいずれにせよ行うべきことそのものであり、そこに
まずルーティングすることで誤った結果は生じない; (2) ガード評価時の下流エージェント
内省を不要とし、ガードを (KISS に従い) まだ決まっていない dispatch 対象への
分岐ではなく平坦な前提条件チェックとする; (3) 過少発動が起きない ── ガードが
存在する目的である障害 (「Spec がディスクにない状態で `implementer` が dispatch
される」) は、`☐`+Spec 未作成の行が *あらゆる* dispatch の前に `product-manager`
にルーティングされれば構造的に不可能である。したがって G2 行は次のように読む:
*Spec ファイルが存在しない `☐` 行はまず `product-manager` にルーティングし;
Spec ファイルが存在しない `◐` 行は不完全な着手であり同様に `product-manager`
にルーティングする; Spec がディスク上に存在する `☐` 行は通常どおり進む。*
ガード時に下流エージェントのテストは行わない。(Spec の「次のアクションが
プロダクト計画またはアーキテクチャである `☐` 行はこのガードをトリガーしない」
という括弧書きはそのまま効果を持つ: そのような行を `product-manager` にルーティング
することが *まさにその次のアクション* ── ヒューリスティックと Spec のカーブアウトは
収束しており、矛盾しない。)

### (a) Documentation placement — orchestrator.md Workflow step 1, as a named guard, zero extra file reads

ガード条件は **`.claude/agents/orchestrator.md` Workflow step 1 (Analyze)** の
中に、名前付きの個別の dispatch 前チェックとして記載される ── CLAUDE.md の
Roadmap Rules 箇条書きではなく、新しい CI スクリプトでもなく、エージェント
プロンプト全体に複製するのでもない。Spec の R-01 (a) 「Analyze ステップで
追加のファイル読み取りをゼロにする」という基準に照らした根拠:

- **orchestrator はすでに Analyze ステップを実行するために orchestrator.md を
  読んでいる。** Workflow step 1 は orchestrator が Roadmap 行と (◐ 行に対して)
  progress ファイルを読む *場所* である。そのステップ内にガードを名付けることで、
  orchestrator は参照を行う正確な瞬間に G1–G3 と出会い、**追加ファイル読み取り
  ゼロ** ── R-01 (a) の基準が構造的に満たされる。CLAUDE.md の Rules 箇条書きも
  ゼロの追加読み取りとなる (CLAUDE.md は常に読まれる) が、ガードは
  *orchestrator のランタイム動作* であり Roadmap メカニズムのプロパティではない;
  Rules ブロックは *Roadmap セルを誰が書けるか* を統治し (#07 のホーム)、#08 は
  *orchestrator が dispatch 前に何を検証しなければならないか* を統治する。
  配置はコントラクトオーナーに従う: グリフオーナーシップ → Rules ブロック (#07);
  Analyze dispatch 前提条件 → Analyze ステップ (#08)。
- **CLAUDE.md 行予算ガイダンスを尊重する最もタイトな配置。** orchestrator.md は
  行予算の制約を受けない; CLAUDE.md は受ける (本 ADR の 2026-05-16 行予算
  amendment)。#08 を orchestrator.md に置くことで CLAUDE.md 予算をゼロ消費する。
  これは #07 の配置決定と意図的に異なる: #07 は Roadmap セル書き込みオーナーシップ
  に関する単一の Rules ブロック箇条書き (インデックスメカニズム、性質上 Rules
  ブロック) であり; #08 は orchestrator dispatch 動作に関する複数条件のランタイム
  ガード (エージェント動作、性質上エージェントプロンプト) である。コントラクトが
  異なり、正しいホームも異なる ── 不整合ではない。
- **インデックス整合かつ単一ソース。** ガードは Workflow step 1 の既存の
  progress-file フォールバック散文の自然な完成形である (G3 はその散文を名前付き
  条件に昇格させる)。G1/G2 は同じステップの既存の「対象マイルストーン行を特定し
  リンクされた設計ソースのみを開く」という文を、行と (実装 dispatch の場合) Spec が
  実際に存在するという前提条件で拡張する。1 つのソース、すでにその動作を所有する
  ステップの中にある。

### (c) orchestrator.md edit scope + claude-md-authoring Skill judgement

- **orchestrator.md への直接編集が必要 ── Analyze ステップ (Workflow step 1)
  のみ。** orchestrator.md の他のセクションは変更しない; 他のエージェントプロンプトも
  変更しない (`product-manager.md`、`architect.md`、`implementer.md`、
  `test-runner.md` は変更なし ── ガードは `product-manager` にルーティングするが、
  `product-manager` の既存の ADR-014 行+Spec 書き込みオーナーシップと #07 の
  `☐→◐` トリガーが受信時に行うべき内容をすでにカバーしている; 新しいプロンプト
  行は必要ない)。
- **claude-md-authoring Skill: orchestrator.md 編集には不要。** Skill のスコープ
  (CLAUDE.md の `## CLAUDE.md authoring guidance` と ADR-007 より) は
  `CLAUDE.md` / `README.md` / `.claude/agents/*.md` の「作成または重大な再構成」
  である。orchestrator.md は `.claude/agents/*.md` ファイルなので *ファイルスコープ内*
  だが、#08 の編集は **重大な再構成ではない**: 既存の Workflow ステップの既存の
  散文を名前付きガードで拡張する (新しいトップレベルセクションなし、見出しツリー
  変更なし、不変条件への変更なし、ロール追加なし)。「ルーティン的な小さな編集」の
  カーブアウトに近い。**判断: claude-md-authoring Skill は #08 実装編集に不要。**
  (実装者が orchestrator.md に新しい `##` レベルセクションを追加したり Workflow
  リストを再構成することを選択した場合は再構成に該当し Skill が適用される ──
  ここの設計はルーティン編集カーブアウトの範囲内に留まるよう意図的に
  インステップの名前付きガード拡張である。注記: ADR-014 の既存の参照にはすでに
  「`.claude/agents/orchestrator.md` — Analyze 手順に『まず Roadmap 行を参照する』
  指示が追加される (ダウンストリームタスク)」と記載されている ── #08 ガードは
  同じ Analyze ステップのコントラクトを同じステップで、同じダウンストリームタスクの
  規律によって強化するものである。)
- **CLAUDE.md 編集なし。** #07 (Roadmap Rules ブロック箇条書き) と異なり、
  #08 は CLAUDE.md に何も追加しない。ガードはエージェント動作であり、Roadmap
  メカニズムルールではない。CLAUDE.md の既存の Development Workflow と
  `specs/NN-progress.md` 段落はすでに orchestrator.md Workflow step 1 を
  Analyze の権威として指し示している; CLAUDE.md への変更は不要である。

### (d) MECE boundary statement against #04 / #05 / #07 (R-03)

境界は **トリガーポイント + コントラクト** で引かれており、将来のマイルストーン
作成者がランタイムの懸念を静的ディテクターに誤ってルーティングしたり、
その逆が起きたりしないよう、ここで改めて記述する:

| マイルストーン | 所有する問い | トリガーポイント |
|---|---|---|
| #04 `check-dangling-refs.sh` | 文書散文中のパス/参照は実際のファイル/ADR に **解決するか**? | コミット時 (CI) |
| #05 `check-roadmap-drift.sh` | **双方向 Roadmap インデックスコントラクト** は成立しており、すべてのステータスグリフは **整形式か**? | コミット時 (CI) |
| #07 (ADR-014 2026-05-17 matrix) | ステータスグリフを **誰が** かつ **いつ** 変更できるか? | プロセス/ドキュメント (CI なし) |
| #08 (本 amendment) | orchestrator の **Analyze 前提条件は dispatch 前に満たされているか** (行が存在する; 実装 dispatch に対して Spec がディスク上にある; `◐` の progress ファイルが存在するか明示的に不在か)? | **ランタイム** (orchestrator 動作、CI なし) |

欠陥はちょうど 1 つのオーナーにマッピングされる: *壊れた散文パス* は #04
(コミット時解決); *一貫したポインターだが Roadmap コントラクトの不整合または
不正なグリフ* は #05 (コミット時整合性); *グリフを誰がいつ変更できるか* という
問いは #07 (プロセスオーナーシップ); *orchestrator が行の不在/予約済みだがファイル
未作成の Spec/明示されない progress ファイルの欠如に対して dispatch しようとしている*
は #08 (ランタイム前提条件)。**(R-03 隣接性、明示):** #05 の Non-goals はすでに
予約済みの `spec:` リンクがディスク上のファイルとして解決するかどうかの検証を
明示的に除外している ── ADR-017 §1 は「主張が存在するときの整合性を検証し、
普遍性は検証しない」とキーイングしており、`☐` 行の予約済み `spec:` は
設計上有効な不在である。その同じ予約済みだがファイル未作成の `spec:` は
*ランタイム時、orchestrator が実装を dispatch しようとするときのみ* 欠陥となる
── それが #08 のコントラクトであり #05 のコントラクトではない。#05 は「Roadmap は
構造的に有効か?」をコミット時に問い; #08 は「Analyze 前提条件は満たされているか?」
をランタイムに問う。予約ルールのカーブアウトが縫い目である: #05 は意図的に
確認せず、#08 は意図的に確認する ── 異なるトリガーポイント、異なるコントラクトで。
2 つのオーナーによる曖昧さは存在しない。

### Composability with ADR-016 and #07 (no ownership gap)

- **ADR-016 (`specs/NN-progress.md`)。** G3 は `◐` 行の progress ファイルが
  存在しない場合の orchestrator の名前付き動作を形式化する。ADR-016 §書き込みオーナー
  シップは作成/更新/削除を `product-manager`/`implementer` に予約している;
  orchestrator は読み取りのみ。G3 の「明示的に表明しフォールバックする」は
  読み取り専用であり ADR-016 と整合している ── 書き込みを追加せず、従来の散文で
  暗示されていたものを名前付きの可視診断として追加するだけである。
- **#07 (ステータス遷移マトリックス)。** G1/G2 が行の作成または Spec の作成のために
  `product-manager` にルーティングする場合、そのオーサリングアクションは
  `product-manager` がすでに所有する #07 の `☐→◐` 遷移そのものである。#08 は
  着手をトリガーする orchestrator 側の前提条件を提供し; #07 は着手オーナーシップ
  そのものを所有する。2 つはギャップなく合成可能である: #08 は「orchestrator は
  Spec がディスク上にあるまで実装を dispatch してはならない」と言い; #07 は
  「`product-manager` がその Spec を作成することと同時に `☐→◐` を変更する」と言う。
  同じ境界の 2 つの補完的な側面。

### Downstream implementer tasks (recorded for traceability, not performed by this amendment — implementation is a future session, per the #03/ADR-016 · #05/ADR-017 · #06/ADR-018 · #07/ADR-014-amendment two-session decision-then-implementation split)

- `.claude/agents/orchestrator.md` **Workflow step 1 (Analyze)** ──
  既存のステップ散文を、上記のとおり 3 つの条件 G1–G3 とそのルーティング結果を
  持つ名前付き dispatch 前ガードで拡張する。**単純な R-02 ヒューリスティック**
  を使用する (Spec ファイルが存在しない `☐` または `◐` 行は `product-manager` に
  まずルーティングし; ガードで下流エージェント内省は行わない)。G3 は *名前付きの
  可視* 条件として表現し、現在のインフォーマルな「progress レコードが存在しない
  場合は明示的に表明し、`git log` から状態を再導出する」という文を吸収・置換する
  (複製しない ── 名前付きガードに昇格させる)。**インステップ拡張** に留める:
  新しい `##` レベルセクションなし、Workflow リストの再構成なし ── ルーティン編集
  カーブアウトの範囲内に留め、claude-md-authoring Skill がトリガーされないようにする
  (上記の判断 (c))。
- **他のエージェントプロンプトの編集なし。** 実装者は `product-manager.md`、
  `architect.md`、`implementer.md`、`test-runner.md` にガード散文を追加しては
  ならない; orchestrator.md Workflow step 1 が唯一のソースである。`product-manager`
  の受信動作は既存の ADR-014 行+Spec 書き込みオーナーシップと #07 の `☐→◐`
  トリガーですでにカバーされている。
- **CLAUDE.md 編集なし** (判断 (c)): #08 はエージェント動作であり、Roadmap
  メカニズムルールではない; CLAUDE.md の Development Workflow と
  `specs/NN-progress.md` 段落はすでに orchestrator.md Workflow step 1 を指し示している。
- **CI ワークフローとスクリプトなし** (Spec Non-goals / Out of scope:
  「#08 は静的分析の追加ではなくランタイム orchestrator の動作変更である」;
  機械的な CI 強制は明示的に延期された将来の可能性あるマイルストーンであり、
  #08 ではない ── (d) の MECE テーブルに従い #04/#05 のコミット時チェックとは
  異なる)。
- **Roadmap 行の変更なし。** Row #08 の `Design source` セルは `spec:` のみの
  ままとする ── これは ADR-014 amendment であり、ADR-014 はそれ自身の
  マイルストーン行を持たないため、row #08 に `adr:` リンクは追加しない
  (マイルストーン → ADR は 0:1; #07 amendment の row #07 の推論と同一)。
- 本 ADR の日本語版
  (`014-roadmap-index-single-entry-point.ja.md`) はミラーされた amendment を
  受け取る必要がある ── `technical-writer` タスクであり、本変更の対象ではない。
  **本 amendment は ADR-014 に一時的な EN/JA 見出し不一致を作り出す (EN は
  1 つの `##` レベル見出しとその `###` サブ見出しを獲得し; JA は本変更前に
  18 見出しで同等だった) ── `technical-writer` のミラーが反映されるまで
  #06 の bilingual-parity detector (`check-bilingual-parity.sh`) は ADR-014 で
  FAIL する。これは期待されるキューに入った `technical-writer` タスクであり、
  この EN amendment を省略する理由ではない**、まさに 2026-05-17 の
  ステータス遷移 amendment が行ったとおり。

### Counter-proposal

深刻な反対案は **新しい ADR-019 ── Analyze dispatch 前ガードを ADR-014 amendment <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
ではなくスタンドアロン ADR として形式化する** である。
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 の慣例に従い、
却下された代替案を藁人形としてではなく真剣に記録する。議論:

1. Spec は `architect` に明示的な (c) 選択肢 (「ADR-014 amendment か新しい
   ADR-019 か」) を渡しており、構造的に並行した兄弟マイルストーン #05 と #06 は <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   どちらも延期された構造的質問の Spec を *新しい* ADR (017、018) で解決しており、
   amendment ではない。プロセスの対称性は #08 → ADR-019 を示唆する。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
2. 4 つのエージェントロール (orchestrator、product-manager、implementer、テンプレート
   メンテナー) がランタイムで遵守しなければならない 3 条件 3 ルーティング結果を
   持つ名前付き dispatch 前ガードはファーストクラスの引用可能な動作コントラクトである
   ── ADR-016 のように、ADR-014 と合成するが別の ADR である。長い ADR-014 トレイルの
   4 番目の amendment として埋め込むことは、読者が「Analyze ガード ADR」として
   引用できる専用 ADR-019 より発見しやすさが劣る。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
3. ADR-019 はそれ自身の Roadmap バックリンク (`Roadmap row: #08`) を持ち、 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   row は `adr:` リンクを獲得する ── #05/#06 が行使する同じ双方向コントラクトを
   #08 に与え、その兄弟と同じ成果物形状になる。

**反対案が採用されなかった理由:**

- ADR-017 と ADR-018 は特定の、明記された識別基準に基づいて新 ADR に値すると
  自己分類した: それぞれが **新しいディテクター + 新しい MECE コントラクト境界 +
  新しい免除キーイングルール** を導入した (ADR-017 Alternative B; ADR-018
  Alternative B)。#08 はそれらをいずれも導入しない ── Spec の Non-goals と
  Out of scope は新しい CI ワークフローやスクリプトを明示的に禁じている
  (「#08 は静的分析の追加ではなくランタイム orchestrator の動作変更である」);
  MECE 記述はディテクターファミリー分割の外部に #08 を置くスコープ限定であり、
  その分割内の 4 番目のパーティションではない; そして免除キーイングも、新しい
  ファイル成果物も、新しいメカニズムも存在しない。orchestrator の Analyze 参照
  (ADR-014 §決定) が dispatch 前に検証しなければならない内容を強化する ──
  ADR-014 §帰結 → ネガティブが事前にフラグした正確なギャップを閉じる。
  兄弟対称性の議論は詳細に見ると逆転する: #05/#06 自身の識別基準を #08 に
  適用すると「amendment」になる、なぜなら #05/#06 にとって支配的だった構造的な
  半分が #08 には不在だからである。これは ADR-014 の 2026-05-16 行予算 amendment
  が自身の ADR-015 を拒否した際に使用したのと全く同じ推論であり、ADR-018 の
  2026-05-17 amendment が新しい番号なしにすでに決定されたオーナーシップルールを
  精緻化するために使用した推論でもあり、2026-05-17 のステータス遷移 (#07) amendment
  が ADR-019 を拒否するために使用した推論でもある。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
- ADR-016 の類比は詳細に見ると崩れる。ADR-016 が別の ADR である理由は、**新しい
  メカニズム** を導入したからである ── 独自の書き込みオーナーシップ、ライフサイクル、
  削除トリガーコントラクトを持つ新しいファイル成果物 (`specs/NN-progress.md`)。
  #08 は **新しい成果物もメカニズムも導入しない**; ADR-014 (Roadmap 行) と
  ADR-016 (progress ファイル) がすでに定義する 2 つの成果物の *使用* を制約する
  だけである。既存のメカニズムに対するガードは、それらのメカニズムの所有する決定の
  帰結明確化であり、新しいメカニズムではない。
- 発見しやすさは ADR-014 amendment の方が *良い*、悪くない: 「orchestrator は
  Roadmap について dispatch 前に何を検証しなければならないか」を読者が探す正規の
  場所は、Roadmap を定義し、Analyze ステップを Roadmap 参照とし、すでに orchestrator
  に読み取り専用 Roadmap コントラクトを割り当てている ADR である。別個の ADR-019 は <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  Analyze ステップのコントラクトを 2 つの ADR に *分断* する ── orchestrator は
  Analyze 義務の全体を知るために ADR-014 *と* ADR-019 の両方を読む必要があり、 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  ADR-014 が除去しようとした「どの文書が権威的か」という再発見の問題をまさに
  再導入する。
- 双方向バックリンクの議論は無意味: ADR-014 はそれ自身のマイルストーン行を
  持たないため、ADR-014 への amendment は正しく `Roadmap row:` 行を持たず
  #05 ドリフトコントラクトをトリガーしない。バックリンクを作成するためだけに
  新しい ADR-019 を強制することは、真の構造的決定を反映するのではなく <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  双方向成果物を製造することになる ── #07 amendment による同じ異論の解決と同一。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->

**この反対案を再評価するトリガー条件:**

- 将来のマイルストーンがガードの *機械的な CI 強制* を genuinely 追加する場合
  (orchestrator が G1–G3 を遵守したこと、または dispatch されたマイルストーンが
  ディスク上に Spec を持っていたことを静的に検証する新しいディテクター) ──
  それは新しいディテクター + 新しい境界 + 新しいキーイングであり、ADR-017/ADR-018
  識別基準の構造的な半分に当たり、独自の ADR を持つに値し、本 amendment の
  ガードをその継承されたベースラインとする。Spec はこれを「#08 ではなく将来の
  可能性あるマイルストーン」と明示的にフラグしている。
- ガードがプロジェクトタイプごとに異なる動作を必要とすることが判明した場合
  (例: `product-manager` を削除するフォークが異なるルーティング対象を必要とする)、
  単一のガードが ADR-014 で表現できなくなった時点で、プロファイル別ガードバリアント
  を持つ専用 ADR が適切になる可能性がある。
- orchestrator の Analyze ステップではない *別の* エージェントに対する新しい
  常時参照ランタイムコントラクトが追加される場合 (ADR-014 の決定の帰結ではなく
  それと合成する、ADR-016 のような genuinely 新しいメカニズム) ── 独自の ADR に
  値する。

反対案は ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 の慣例に従い、
決定の最も深刻な異論の歴史的記録として本 amendment に残る。

元のステータス行 (`Accepted — 2026-05-15`) は変更しない; 本 amendment は
すでに認可された Analyze ステップメカニズムのランタイム前提条件明確化を追記する
ものであり、決定を再開するものではない。

## Amendment — 2026-05-17 (spec filename convention)

本 amendment は、この ADR 自身の 2026-05-16 **Spec 予約ルール** amendment が
すでに *使用している* が *名前付きルールとして明記していない* ファイル名規約を
規範化する。その amendment は予約済みリンクのパスを決定論的な形式
`specs/NN-slug.md` として固定した (「決定論的パス `specs/NN-slug.md` を使用し、
`NN` は安定した行番号」); 現在までに作成された 8 つの Spec ファイル
(`specs/01-*.md` … `specs/08-*.md`) はすべて適合している。
`specs/09-spec-filename-convention.md` (Roadmap row #09) が権威的なスコープであり、
規約がカバーしなければならない内容 (正規形式、最小 2 桁ゼロパディング、100+ 拡張
ルール、`specs/NN-slug.ja.md` 兄弟、`specs/NN-progress.md` 除外) を記述し、
構造的な *どのように* を `architect` に委ねている (リスク R-01 (a)-(d)、R-02、R-03)。
本 amendment はその決定を記録する。これは **ADR-014 の既存の決定の帰結明確化**
であり ── 具体的には、すでに承認された 2026-05-16 Spec 予約 amendment の帰結明確化で
あり、その予約パスが *まさに* `specs/NN-slug.md` である ── 新しい構造的決定ではない。
新しいディテクター、CI ワークフロー、コントラクト境界、キーイングルール、またはメカニズムは
導入しない: 規約は ADR-014 がすでに義務付けているパス方式のファイル名コンポーネントに
名前を付けるものであり、`specs/NN-progress.md` 例外は ADR-016 の既存のライフサイクルの
再記述であって新しいルールではない。

### The (b) decision — ADR-014 amendment, not new ADR-019, by the ADR-018 Alternative-B discriminator <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal; it is intentionally never created (see Counter-proposal below) -->

Spec の R-01 (b) は `architect` に明示的な選択肢 「ADR-014 amendment か新しい
ADR-019 か」を渡しており、ADR-018 の Alternative-B 識別基準を逐語的に適用するよう <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
指示している: *#09 は新しいディテクター + 新しい MECE コントラクト境界 + 新しい
キーイング/メカニズムを導入するか (⇒ 新しい ADR)、それとも既存 ADR のすでに認可
された決定の帰結明確化/拡張か (⇒ amendment)?* 条項ごとに誠実に適用する:

- **新しいディテクター? No.** Spec の Non-goals と Out of scope は CI ファイル名
  形式ディテクターを *明示的に禁じている* (「機械的にファイル名準拠を検証する新しい
  CI ディテクターの追加。… #09 はドキュメント/規約記述マイルストーン; CI 強制は
  任意の帰結であり、このマイルストーンの成果物ではない」; 「CI ファイル名形式
  チェックの追加 ── architect に延期された構造的決定」)。ADR-017 と ADR-018 は
  それぞれが新しいスクリプト + 新しいワークフロー (`check-roadmap-drift.sh` /
  `check-bilingual-parity.sh`) を導入したからこそ新 ADR 相当と自己分類した。
  #09 はスクリプトもワークフローも **ゼロ** 導入する。ADR-017/ADR-018 で支配的
  だった構造的な半分がここには不在 ── ディテクターなしの #07 amendment、
  CI ワークフローを Non-goals が禁じた #08 amendment と同一。
- **新しい MECE コントラクト境界? 新しいパーティションなし。** 境界の *記述*
  は必要 (Spec Goal 5、受け入れ基準、R-02) だが、#04/#05/#06 のディテクター
  ファミリーコントラクトパーティションに 4 番目のディテクターを追加しない。
  #09 がそのパーティションの*外側*に完全に位置することを記述する: #09 は
  ADR-014 の予約ルールがすでに生成する *予約された `spec:` パスのファイル名*
  に関するドキュメント/規約記述であり、*隣接ディレクトリマイルストーン #10*
  に対してのものである。これは ADR-014 の予約ルールの帰結がどこに位置するかの
  スコープ限定であり、ADR-017 の不在宣言や ADR-018 の規約存在のような新しい
  キーイングルールではない。
- **新しいキーイング/メカニズム? No.** 免除キーイングルール、許可リスト対パターン
  選択、解析戦略、新しいファイル成果物はない。`specs/NN-slug.md` は 2026-05-16
  Spec 予約 amendment がすべての予約された `spec:` リンクに義務付けている
  決定論的パスであり; #09 はそのすでに使用されている形式をファイルについても
  規範的と名付ける。`specs/NN-progress.md` 除外は ADR-016 の確立済み
  progress-file ライフサイクル (セッション境界で作成、`◐→☑`/`◐→✗` 反転で削除)
  の *帰結* であり、本 amendment が導入する新しいメカニズムではない。
- **既存の決定の帰結明確化? Yes、決定的に。** ADR-014 の 2026-05-16 Spec 予約
  amendment はすでに不変の行番号をキーとした予約パス方式として逐語的に
  `specs/NN-slug.md` を使用している。#09 の規約は、その既に認可されたパスの
  ファイル名コンポーネントの、名前付き規範ルールとしての記述である。これは
  ADR-014 §帰結 → ネガティブが事前にフラグした暫定慣行を形式化した
  2026-05-17 ステータス遷移 amendment (#07)、ADR-014 の Analyze 参照が検証
  しなければならない内容を強化した 2026-05-17 Analyze 行ガード amendment (#08)
  と構造的に同一 ── いずれも ADR-014 amendment で解決し、ADR-019 ではない。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->

**兄弟対称性の議論は詳細に見ると逆転する** (同じ罠を #07 と #08 の amendment が
特定した): 「#05/#06 → ADR-017/ADR-018; したがって #09 → 対称性のために ADR-019」 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
── しかし #05/#06 自身の *識別基準* を #09 に適用すると **amendment** になる。なぜなら
3 つの構造的条項 (新しいディテクター、新しいパーティション、新しいキーイング/メカニズム)
がすべて不在だからである。ADR-016 が別の ADR である理由は *新しいメカニズム*
(独自の書き込みオーナーシップ / ライフサイクル / 削除トリガーコントラクトを持つ新しい
ファイル成果物) を導入したからであり; #09 は新しい成果物も新しいメカニズムも導入しない
── ADR-014 自身の予約 amendment がすでに定義する成果物 (`specs/NN-slug.md`) の
ファイル名形式に名前を付け、ADR-016 のメカニズムに完全に委ねることで
`specs/NN-progress.md` を明示的に除外する。**決定: ADR-014 amendment。ADR-019 は <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
作成しない。** Roadmap row #09 は `spec:` のみのまま維持される (マイルストーン → <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
ADR は 0:1; Roadmap メカニズム ADR への amendment は #09 固有の ADR ではない ──
ADR-014 にはそれ自身のマイルストーン行がないため、row #09 から ADR-014 へ `adr:`
リンクを追加することは存在しないマイルストーン→ADR マッピングを主張することになる
── #07 と #08 の amendment の行推論と同一)。

### The normative filename convention

規約は 2026-05-16 Spec 予約 amendment がすでに義務付けている `specs/NN-slug.md`
パスのファイル名コンポーネントに名前を付ける。新しいパス方式は追加しない;
既存のものを名前付きルールとして記述する:

| ルール | 記述 | 明確化する出典 |
|---|---|---|
| 正規 Spec ファイル名 | Spec ファイルは `specs/NN-slug.md` であり、`NN` は **最小 2 桁** にゼロパディングされた Roadmap 行番号、`slug` は行の予約済み `spec:` パスに **すでに固定されたケバブケース slug** である (オーサリング時に曖昧さなし ── `product-manager` は Roadmap 行から slug をコピーし、再導出しない)。 | ADR-014 2026-05-16 Spec 予約 amendment (予約パスはまさにこの形式)。 |
| 100+ 拡張 | 最小 2 桁は一桁行のみをパディングする (`1→01`); すでに複数桁の行は追加パディングなしで記述する (`100`、`101`、…)。行番号規約 (番号は再使用/再番号付けしない) と安定する。 | ADR-014 §決定「行番号は安定しており再使用しない」。 |
| JA 兄弟ファイル名 | 日本語兄弟は `specs/NN-slug.ja.md` ── 同一 `NN`、同一 `slug`、`.md` の前に `.ja` を挿入。EN プライマリとの見出しツリーパリティは **#06 / ADR-018 が所有**; 本規約は兄弟の *ファイル名形式* のみを記述し、パリティチェックを再定義または拡張しない。 | ADR-018 (パリティチェックがコンテンツパリティを所有; 本規約が兄弟名を所有)。 |
| `specs/NN-progress.md` 除外 | `specs/NN-progress.md` は `specs/` ディレクトリと `NN` プレフィックスを共有するが、**Spec ファイルではなく**、`NN-slug.md` 要件から**除外**される。`progress` は ADR-016 のライフサイクル下の予約サフィックス (◐ の間セッション/コンパクション境界で作成、`◐→☑`/`◐→✗` 反転で削除); その命名とライフサイクルは ADR-016 によって完全に統治され、本規約によらない。 | ADR-016 §書き込みオーナーシップ / §退役 (例外は ADR-016 の再記述であり、新しいルールではない)。 |

本規約は **既存のすべての Spec ファイルと遡及的に整合** し
(`specs/01-*.md` … `specs/08-*.md` のすべてが適合)、これが一括リネームではなく
規約 *記述* amendment であることを確認する ── ステータス遷移 amendment (#07) が
「すべての歴史的な成果物と遡及的に整合しており、動作変更ではない」として
確立したプロパティと全く同じである。

### (a) Documentation placement — the CLAUDE.md `## Roadmap` Rules block, one added bullet, zero extra file reads

規約は CLAUDE.md の **`## Roadmap` Rules ブロック** に 1 つの追加箇条書きとして
記載される ── spec-template の `## How to use this template` ブロックではなく、
新しい CI スクリプトでもなく、エージェントプロンプトに複製もしない。根拠、
Spec の R-01 (a) 「追加ファイル読み取りなしに Spec オーサリングステップで出会う」
基準に対して:

- **`product-manager` はすでに Spec を作成するために CLAUDE.md の
  `## Roadmap` セクションを読む。** 2026-05-16 Spec 予約 amendment はその
  Rules ブロックに存在し、`product-manager` の ADR-014 書き込みオーナーシップ
  (行 + 予約 `spec:` リンクの作成/更新) はすでにそこで行使される。ファイル名
  規約は *同じ* 予約ルールの名前付き完成形 ── `product-manager` は所有する行から
  予約済み `specs/NN-slug.md` パスを読み、そのパスでファイルを作成する。予約
  ルールの 1 箇条書き下に規約を記述することで、`product-manager` が Spec を
  作成する正確な瞬間に出会い、**追加ファイル読み取りゼロ** ── R-01 (a) 基準が
  構造的に満たされる。spec-template の `## How to use this template` ブロックは
  *著者がテンプレートを開いた場合のみ* 読まれ、これは 1 つの追加ファイル読み取りで
  あり保証されない (経験豊富なエージェントがテンプレートをスキップしても規約は
  成立しなければならない) ── したがってテンプレートは単一ソースとして不適切。
- **これは意図的に #08 の配置ではなく #07 の配置を反映する。なぜならコントラクト
  はインデックスメカニズムであり、エージェントランタイム動作ではないからである。**
  #07 (Roadmap セル書き込みオーナーシップルール) は Rules ブロックに記載;
  #08 (orchestrator ランタイム dispatch 前提条件) は orchestrator.md Workflow
  step 1 に記載。#09 は Roadmap メカニズム自体のプロパティ (予約された `spec:`
  パスのファイル名が *何であるか*)、Rules ブロックが統治するコントラクトクラスの
  まさにそれ ── 予約ルール、行/リンク書き込みオーナーシップ、グリフセット、
  #07 遷移マトリックスをすでに記述している。ファイル名規約は既存の「Spec 予約
  ルール」/ 「`spec:` パスは行作成時に予約される」箇条書きの自然な完成形であり、
  新しい場所の新しいコンセプトではない。配置はコントラクトオーナーに従う、
  まさに #08 amendment が推論したとおり (「グリフオーナーシップ → Rules ブロック
  (#07); Analyze dispatch 前提条件 → Analyze ステップ (#08)」)。
- **CLAUDE.md 行予算ガイダンスをすでに免除されているセクションに記載することで
  尊重する。** `## Roadmap` セクションは認可された行予算例外 (本 ADR の
  2026-05-16 行予算 amendment、CLAUDE.md の `## CLAUDE.md authoring guidance`
  で再記述)。すでに免除されているセクションへの 1 つの追加箇条書きは他の
  予算を消費しない ── #07 amendment の配置根拠と同一。非免除セクションへの
  散文追加 (例: 新しい `## Spec filename convention` 見出し) は予算を膨張させ、
  再構成 (下記判断 (c)) に踏み込む。

正確な 1 箇条書きの文言は下記の `implementer` に渡される; MECE 境界 (次節) は
*その箇条書きに* 再記述され、将来のマイルストーン著者がディレクトリ問題を #09 に、
ファイル名問題を #10 にルーティングしないようにする。

### (c) Edit scope + claude-md-authoring Skill judgement

- **CLAUDE.md への編集が必要 ── `## Roadmap` Rules ブロックのみ。**
  既存の予約ルールガイダンスの後に 1 箇条書きを追加。他の CLAUDE.md セクションは
  変更しない。
- **`product-manager.md` への編集は不要。** 規約は `product-manager` が
  ADR-014 下ですでに所有する予約済み `spec:` パスのファイル名に名前を付ける
  (行 + `spec:` リンク書き込みオーナーシップ) で、#07 の `☐→◐` ピックアップ
  遷移ですでに作成する。予約パスでファイルを *作成する* ことは既存の書き込み
  オーナーシップ; 規約はそのパスの *形式* を `product-manager` がすでに読む
  Rules ブロックで明示し、新しいプロンプト義務ではない。これは #07 amendment が
  「エージェントプロンプトの編集は不要」と結論づけるために使用した推論と同一
  (マトリックスはすでに所有されている行書き込みを Rules ブロックで明示し、
  プロンプトではない) で、`product-manager.md` に対する #08 amendment が使用した
  推論でもある (「`product-manager` の受信動作は既存の ADR-014 行+Spec 書き込み
  オーナーシップと #07 の `☐→◐` トリガーですでにカバーされている」)。
- **spec-template への編集は不要。** テンプレートの `## References` はすでに
  `Roadmap row: #NN` バックリンク例を持つ (ADR-014 の元のダウンストリームタスク)。
  ファイル名は Rules ブロック箇条書きが記述する予約ルールの *ファイルが作成される
  場所* のプロパティ; テンプレートの *コンテンツ* は影響を受けない。テンプレートに
  ファイル名ノートを追加すると同じルールのソースが 2 つになる (Rules ブロック箇条書き
  *かつ* テンプレート行)、ADR-014 が除去しようとした「どの文書が権威的か」という
  再発見問題をまさに再導入する。単一ソース: Rules ブロック。
- **claude-md-authoring Skill: #09 CLAUDE.md 編集に不要。** 延期された CLAUDE.md
  編集は **既存の `## Roadmap` Rules リストへの 1 箇条書きの追加** ── CLAUDE.md
  の `## CLAUDE.md authoring guidance` セクションの明示的なカーブアウトによる
  「ルーティン的な小さな編集 (… 単一の箇条書き …)」(「Routine small edits
  (typo, single bullet, version bump) do not need the Skill」)。「重要な再構成」
  ではない (セクションの追加/移動/分割なし、見出し変更なし、不変条件の変更なし)。
  **判断: claude-md-authoring Skill は #09 実装編集に不要** ── #07 amendment が
  その単一箇条書き Rules ブロック編集について記録した同一判断と同一推論。(実装者が
  代わりに CLAUDE.md に `##` レベルの「Spec filename convention」セクションや
  テーブルを追加することを選択した場合は再構成に該当し Skill が適用される ──
  ここの設計はルーティン編集カーブアウトの範囲内に留まるよう意図的に単一箇条書き
  であり、まさに #07 がそうだったとおり。)

### (d) MECE boundary statement against #04 / #05 / #10 / ADR-014-reservation-rule / ADR-016-progress-files (R-02)

境界は **各オーナーが所有するもの** で引かれており、将来のマイルストーン著者が
ファイル名の懸念をディレクトリピンや、パス解決ディテクターや、progress-file
ライフサイクルに誤ってルーティングできないよう、ここと実装者の箇条書きに再記述する:

| オーナー | 所有する問い | トリガーポイント |
|---|---|---|
| #04 `check-dangling-refs.sh` | 文書散文中のパス/参照は実際のファイル/ADR に **解決するか**? | コミット時 (CI) |
| #05 `check-roadmap-drift.sh` | **双方向 Roadmap インデックスコントラクト** は成立しており、すべてのステータスグリフは **整形式か**? | コミット時 (CI) |
| #10 (Spec/ADR ディレクトリピン) | Spec/ADR ファイルは **どのディレクトリ** に存在するか (`specs/`、`.claude/meta/adr/`)? | ドキュメント/規約 (#10 のスコープに CI なし) |
| #09 (本 amendment) | `specs/` 内の Spec ファイルの **ファイル名形式は何か** (`NN-slug.md`、最小 2 桁、JA 兄弟形式)? | ドキュメント/規約 (CI なし; CI は明示的に延期された任意の帰結であり、#09 ではない) |
| ADR-014 予約ルール | すべての行が行作成時に予約済み `spec:` リンクを持つ *こと*、不変の行番号をキーとして。 | 行作成時 (プロセス) |
| ADR-016 progress ファイル | `specs/NN-progress.md` の *ライフサイクル* (境界で作成、反転で削除)。`progress` はその予約サフィックス; **#09 の `NN-slug.md` ルールから除外**。 | セッション/コンパクション境界 (プロセス) |

懸念はちょうど 1 つのオーナーにマッピングされる: *壊れた散文パス* は #04 (コミット時
解決); *不正なグリフまたは壊れた双方向 ADR リンク* は #05 (コミット時整合性);
*Spec がどのディレクトリに存在するか* は #10; *ディレクトリ内での Spec ファイルの名前が
何か* は #09; *予約リンクがそもそも存在すること* は ADR-014 予約ルール;
*`specs/NN-progress.md` がどのように生まれ退役するか* は ADR-016。完全な正規パス
`specs/NN-slug.md` は #10 のディレクトリスコープと #09 のファイル名スコープの
**合成** であり: どちらも他方を包含せず、ディレクトリに不確かな将来の著者は #10 を
読み、ファイル名に不確かな著者は #09 を読む。`specs/NN-progress.md` の縫い目は
明示的: #09 のディレクトリと `NN` プレフィックスを共有するがその命名とライフサイクルは
ADR-016 の完全な管轄 ── #09 は意図的にそれを統治しない、まさに #08 amendment の
MECE テーブルが #05 (確認しない) と #08 (異なるトリガーで確認する) の間の
予約済みだがファイル未作成の `spec:` 縫い目を引いたとおり。

### Composability with ADR-014's reservation rule, ADR-016, and #06/ADR-018 (no gap)

- **ADR-014 2026-05-16 Spec 予約 amendment。** #09 はその amendment がすでに
  義務付ける `specs/NN-slug.md` 予約パスのファイル名コンポーネントに名前を付ける。
  2 つはギャップなく合成可能: 予約 amendment は *行作成時から予約済み `spec:`
  リンクが `specs/NN-slug.md` の形式で存在する* と言い; #09 は *ピックアップ時に
  作成されるファイルはすでに予約されているその名前を正確に使用する* と言う。
  #09 は 2 番目のパス方式を追加しない; 既存のものを規範的と記述する。
- **ADR-016 (`specs/NN-progress.md`)。** #09 は progress ファイルを ADR-016 の
  ライフサイクルに完全に委ねることで除外する。ADR-016 §書き込みオーナーシップ/
  §退役は `specs/NN-progress.md` の唯一の権威のままであり; #09 は書き込みも
  ライフサイクルルールも追加せず、`progress` が `NN-slug.md` 要件の外の予約
  サフィックスであるという名前付き記述のみ ── ADR-016 に対して読み取り専用で
  あり、まさに #08 amendment の G3 が ADR-016 の書き込みオーナーシップに対して
  読み取り専用だったとおり。
- **#06 / ADR-018 (bilingual parity)。** #09 は JA 兄弟の *ファイル名形式*
  (`specs/NN-slug.ja.md`) を記述; ADR-018 は JA ファイルの *見出しツリー/
  全角括弧コンテンツパリティ* を所有する。準拠した bilingual Spec には両方が
  成立しなければならない: #09 が兄弟名を統治し、#06 がその構造を統治する。
  重複なし ── 命名上の欠陥は #09、見出し順序の欠陥は #06。

### Downstream implementer tasks (recorded for traceability, not performed by this amendment — implementation is a future session, per the #03/ADR-016 · #05/ADR-017 · #06/ADR-018 · #07/ADR-014-amendment · #08/ADR-014-amendment two-session decision-then-implementation split)

- `.claude/CLAUDE.md` の `## Roadmap` **Rules** ブロック ── 既存の予約ルール
  ガイダンス (「**Spec 予約ルール:**」段落 / 「`spec:` パスは行作成時に予約される」
  Rules 箇条書き) の後に 1 箇条書きを追加。形式: *「Spec filename convention:
  a Spec file is `specs/NN-slug.md` where `NN` is the row number
  zero-padded to a two-digit minimum (`1→01`; rows ≥100 written without
  extra padding) and `slug` is the kebab-case slug already fixed in the
  row's reserved `spec:` path (copy it from the row, do not re-derive).
  The JA sibling is `specs/NN-slug.ja.md` (same `NN`/`slug`, `.ja`
  before `.md`); its heading-tree parity is owned by #06.
  `specs/NN-progress.md` is excluded — `progress` is ADR-016's reserved
  suffix, governed by ADR-016's lifecycle, not by this convention. #10
  pins the directory; #09 pins the filename — MECE."* 単一箇条書き、
  サブ見出しなし、テーブルなし ── ルーティン編集カーブアウトの範囲内
  (claude-md-authoring Skill 呼び出し不要; 上記判断 (c))。
- **エージェントプロンプトの編集なし** (上記判断 (c))。実装者は
  `product-manager.md`、`orchestrator.md`、`architect.md`、`implementer.md`
  にファイル名規約の散文を追加してはならない; Rules ブロックが単一ソース。
  `product-manager` の予約パスでのオーサリング動作は既存の ADR-014 行+`spec:`
  書き込みオーナーシップと #07 の `☐→◐` ピックアップトリガーですでにカバーされている。
- **spec-template の編集なし** (上記判断 (c))。テンプレートの `## References`
  `Roadmap row: #NN` 例は影響を受けない; ファイル名は Rules ブロック箇条書きが
  記述する予約パスのプロパティであり、テンプレートコンテンツではない。テンプレートに
  ノートを追加すると同じルールのソースが 2 つになる。
- **CI ワークフローとスクリプトなし** (Spec Non-goals / Out of scope:
  「#09 はドキュメント/規約記述マイルストーン; CI 強制は任意の帰結であり、
  成果物ではない」; 「CI ファイル名形式チェックの追加 ── architect に延期された
  構造的決定」)。将来の機械的ファイル名形式チェックは可能性ある後のマイルストーンで
  あり、**#09 ではない**。それは下記の反対案トリガー条件下で再評価される ──
  (d) MECE テーブルに従い #04/#05 のコミット時チェックとは異なる。
- **リネームなし。** 既存の 8 つの Spec ファイルはすべて適合; #09 は
  規約記述であり一括リネームではない (Spec Non-goals)。
- **Roadmap 行の変更なし。** Row #09 の `Design source` セルは `spec:` のみの
  ままとする ── これは ADR-014 amendment であり、ADR-014 はそれ自身の
  マイルストーン行を持たないため、row #09 に `adr:` リンクは追加しない
  (マイルストーン → ADR は 0:1; #07 と #08 amendment の行推論と同一)。
- 本 ADR の日本語版
  (`014-roadmap-index-single-entry-point.ja.md`) はミラーされた amendment を
  受け取る必要がある ── `technical-writer` タスクであり、本変更の対象ではない。
  **本 amendment は ADR-014 に一時的な EN/JA 見出し不一致を作り出す (EN は
  1 つの `##` レベル見出しとその `###` サブ見出しを獲得し; JA は本変更前に
  26 見出しで同等だった) ── `technical-writer` のミラーが反映されるまで
  #06 の bilingual-parity detector (`check-bilingual-parity.sh`) は ADR-014 で
  FAIL する。これは期待されるキューに入った `technical-writer` タスクであり、
  この EN amendment を省略する理由ではない**、まさに 2026-05-17 の
  ステータス遷移 (#07) と Analyze 行ガード (#08) の amendment が行ったとおり。

### Counter-proposal

深刻な反対案は **新しい ADR-019 ── Spec ファイル名規約を ADR-014 amendment <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
ではなくスタンドアロン ADR として形式化する** である。
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 の慣例に従い、
却下された代替案を藁人形としてではなく真剣に記録する。議論:

1. Spec は `architect` に明示的な (b) 選択肢 (「ADR-014 amendment か新しい
   ADR-019 か」) を渡しており、構造的に並行した兄弟マイルストーン #05 と #06 は <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   どちらも延期された構造的質問の Spec を *新しい* ADR (017、018) で解決しており、
   amendment ではない。プロセスの対称性は #09 → ADR-019 を示唆する。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
2. 将来のすべてのマイルストーン著者とすべてのフォークが遵守しなければならない
   名前付きファイル名規約はファーストクラスの引用可能なコントラクトであり; 長い
   ADR-014 トレイルの 5 番目の amendment として埋め込むことは、読者が
   「Spec ファイル名 ADR」として引用できる専用 ADR-019 より発見しやすさが劣る。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   隣接マイルストーン #10 (ディレクトリピン) もそれ自体が ADR になる可能性がある;
   ファイル名ルールとディレクトリルールの対称性は両方が同じ形状の ADR であるべきと
   主張する。
3. ADR-019 はそれ自身の Roadmap バックリンク (`Roadmap row: #09`) を持ち、 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   row は `adr:` リンクを獲得する ── #05/#06 が行使する同じ双方向コントラクトを
   #09 に与え、その兄弟と同じ成果物形状になる。

**反対案が採用されなかった理由:**

- ADR-017 と ADR-018 は特定の、明記された識別基準に基づいて新 ADR に値すると
  自己分類した: それぞれが **新しいディテクター + 新しい MECE コントラクト境界 +
  新しい免除キーイングルール** を導入した (ADR-017 Alternative B; ADR-018
  Alternative B)。#09 はそれらを **いずれも** 導入しない ── Spec の Non-goals と
  Out of scope は CI ファイル名形式ディテクターを明示的に禁じている
  (「#09 はドキュメント/規約記述マイルストーン; CI 強制は任意の帰結であり、
  成果物ではない」); MECE 記述はディテクターファミリー分割の外部に #09 を置く
  スコープ限定であり、その分割内の 4 番目のパーティションではない; そして
  免除キーイングも、新しいファイル成果物も、新しいメカニズムも存在しない。
  ADR-014 の Spec 予約 amendment が確立した予約パス (`specs/NN-slug.md`) の
  ファイル名コンポーネントに名前を付ける ── ADR-014 §帰結 → ネガティブが
  事前フラグした正確なギャップを閉じる。兄弟対称性の議論は詳細に見ると逆転する:
  #05/#06 自身の識別基準を #09 に適用すると「amendment」になる、なぜなら
  #05/#06 にとって支配的だった構造的な半分が #09 には不在だからである。これは
  ADR-014 の 2026-05-16 行予算 amendment が自身の ADR-015 を拒否した際に
  使用した推論と全く同じであり、ADR-018 の 2026-05-17 amendment が新しい番号
  なしにすでに決定されたオーナーシップルールを精緻化するために使用した推論でも
  あり、2026-05-17 のステータス遷移 (#07) amendment が ADR-019 を拒否するために <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  使用した推論でもあり、2026-05-17 の Analyze 行ガード (#08) amendment が
  ADR-019 を拒否するために使用した推論でもある。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
- ADR-016 の類比は詳細に見ると崩れる。ADR-016 が別の ADR である理由は、
  **新しいメカニズム** を導入したからである ── 独自の書き込みオーナーシップ、
  ライフサイクル、削除トリガーコントラクトを持つ新しいファイル成果物
  (`specs/NN-progress.md`)。#09 は **新しい成果物もメカニズムも導入しない**;
  ADR-014 の Spec 予約 amendment がすでに定義する成果物 (`specs/NN-slug.md`) の
  ファイル名形式に名前を付け、ADR-016 のメカニズムに完全に委ねることで
  `specs/NN-progress.md` を明示的に除外するだけである。
- 発見しやすさは ADR-014 amendment の方が *良い*、悪くない: 「Spec ファイルの
  ファイル名はどのような形式か」を読者が探す正規の場所は、Spec 予約ルールを
  定義し、すべての行に決定論的な予約パスを要求し、すでに `product-manager` に
  行+`spec:` 書き込みオーナーシップを割り当てている ADR である。別個の ADR-019 は <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  ファイル名コントラクトを 2 つの ADR に *分断* する ── `product-manager` は
  ファイル名規約の全体を知るために ADR-014 *と* ADR-019 の両方を読む必要があり、 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  ADR-014 が除去しようとした「どの文書が権威的か」という再発見の問題をまさに
  再導入する。
- 双方向バックリンクの議論は無意味: ADR-014 はそれ自身のマイルストーン行を
  持たないため、ADR-014 への amendment は正しく `Roadmap row:` 行を持たず
  #05 ドリフトコントラクトをトリガーしない。バックリンクを作成するためだけに
  新しい ADR-019 を強制することは、真の構造的決定を反映するのではなく <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  双方向成果物を製造することになる ── #07 と #08 の amendment による同じ異論の
  解決と同一。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->

**この反対案を再評価するトリガー条件:**

- 将来のマイルストーンが規約の *機械的な CI 強制* を genuinely 追加する場合
  (ファイル名が `NN-slug.md` 形式に適合するかどうかを静的に検証する新しい
  ディテクター) ── それは新しいディテクター + 新しい境界 + 新しいキーイングであり、
  ADR-017/ADR-018 識別基準の構造的な半分に当たり、独自の ADR を持つに値し、
  本 amendment の規約をその継承されたベースラインとする。Spec はこれを
  「#09 ではなく将来の可能性あるマイルストーン」と明示的にフラグしている。
- 隣接マイルストーン #10 (ディレクトリピン) が新しい ADR として解決される場合、
  #09 と #10 の形状対称性は両方を ADR にすることを支持する可能性がある ──
  ただし #10 の構造的内容が独自の ADR を正当化する場合のみ (識別基準が
  #09 に適用されるのと同じように #10 にも適用される)。
- 「Spec ファイル名 ADR」の発見しやすさが実際に問題になる場合 ──
  ADR-014 トレイルが長くなりすぎて著者が規約を見つけられなくなった場合に、
  専用 ADR-019 が正当化される可能性がある。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->

反対案は ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 の慣例に従い、
決定の最も深刻な異論の歴史的記録として本 amendment に残る。

元のステータス行 (`Accepted — 2026-05-15`) は変更しない; 本 amendment は
ADR-014 の既存の Spec 予約ルール決定のファイル名コンポーネント帰結明確化を
追記するものであり、決定を再開するものではない。

## Amendment — 2026-05-17 (spec/adr directory pin)

本 amendment は、この ADR 自身の 2026-05-16 **Spec 予約ルール** amendment が
すでに *使用している* が *名前付きディレクトリルールとして明記していない*
ディレクトリコンポーネントを規範化し、ADR オーサリング慣行がこれまですべての
ADR で使用してきた並列の `.claude/meta/adr/` ディレクトリをピンする。
`specs/10-spec-adr-directory-pinning.md` (Roadmap row #10) が権威的なスコープであり、
規約がカバーしなければならない内容 (Spec の正規 `specs/` ディレクトリ、ADR の正規
`.claude/meta/adr/` ディレクトリ、同一ディレクトリ EN/JA 兄弟規約、遡及適合) を
記述し、構造的な *どのように* を `architect` に委ねている (リスク R-01 (a)-(d)、R-02、R-03)。
本 amendment はその決定を記録する。これは **ADR-014 の既存の決定の帰結明確化**
であり ── 具体的には、すでに承認された 2026-05-16 Spec 予約 amendment の帰結明確化で
あり、その予約パス *まさに* `specs/NN-slug.md` のディレクトリコンポーネントを #10 が
規範として名付ける ── #09 amendment (同じパスのファイル名コンポーネントをピン) と
合成される。新しいディテクター、CI ワークフロー、コントラクト境界、キーイングルール、
またはファイル成果物は導入しない。

### The (b)/(c) decision — ADR-014 amendment, not new ADR-019, by the ADR-018 Alternative-B discriminator <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal; it is intentionally never created (see Counter-proposal below) -->

Spec の R-01 (b)/(c) は `architect` に明示的な選択肢 「ADR-014 amendment か新しい
ADR-019 か」を渡しており、ADR-018 の Alternative-B 識別基準を逐語的に適用するよう <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
指示している: *#10 は新しいディテクター + 新しい MECE コントラクト境界 + 新しい
キーイング/メカニズムを導入するか (⇒ 新しい ADR)、それとも既存 ADR のすでに認可
された決定の帰結明確化/拡張か (⇒ amendment)?* 条項ごとに誠実に適用する:

- **新しいディテクター? No.** Spec の Non-goals と Out of scope は CI ディレクトリ
  適合ディテクターを *明示的に禁じている* (「CI ディレクトリ適合チェックの追加。
  そのようなチェックを追加するかどうかは architect に延期された構造的決定 …
  #10 はドキュメント/規約記述マイルストーン; CI 強制は任意の帰結」; 「CI ディレクトリ
  適合チェックの追加 ── architect に延期された構造的決定」)。ADR-017 と ADR-018 は
  それぞれが新しいスクリプト + 新しいワークフロー (`check-roadmap-drift.sh` /
  `check-bilingual-parity.sh`) を導入したからこそ新 ADR 相当と自己分類した。
  #10 はスクリプトもワークフローも **ゼロ** 導入する ── #09 amendment (Non-goals が
  CI ファイル名ディテクターを禁じた)、#08 amendment (Non-goals が CI ワークフローを
  禁じた)、#07 amendment (ディテクターなし) と同一。
- **新しい MECE コントラクト境界? 新しいパーティションなし ── スコープ限定の
  記述のみ。** 境界の *記述* は必要 (Spec Goal「#09 と合成」、受け入れ基準 8、
  R-01 (d)、R-02) だが、#04/#05/#06 のディテクターファミリーコントラクトパーティションに
  4 番目のディテクターを追加しない。#10 がそのパーティションの *外側* に
  完全に位置することを記述する: #10 は、予約された `spec:` パスのプレフィックスが
  表すディレクトリと ADR がどこに存在するかについてのドキュメント/規約記述であり、
  #09 のファイル名スコープと MECE で、#04 のパス解決スコープと #05 の
  Roadmap 構造スコープに対してスコープ限定される。これは ADR-014 予約ルール帰結が
  どこに位置するかのスコープ限定であり、ADR-017 の不在宣言や ADR-018 の
  規約存在のような新しいキーイングルールではない。
- **新しいキーイング/メカニズム/ファイル成果物? No.** 免除キーイングルール、
  許可リスト対パターン選択、解析戦略、新しいファイル成果物、新しいスクリプトはない。
  `specs/` は 2026-05-16 Spec 予約 amendment がすべての予約された `spec:` リンクに
  義務付ける決定論的 `specs/NN-slug.md` パスのすでにあるディレクトリコンポーネントであり;
  `.claude/meta/adr/` はこれまでに作成されたすべての 18 個の ADR がすでに存在する
  ディレクトリである (検証済み: ADR-001 … ADR-018 + `.ja.md` 兄弟、すべて
  `.claude/meta/adr/` 下)。#10 はそれらのすでに使用されているディレクトリを
  ファイルに対して規範として名付ける; 第 2 のディレクトリスキームもメカニズムも追加しない。
- **既存の決定の帰結明確化? Yes、決定的に ── #09 amendment が直面しなかった
  1 つのインタラクションがあり、以下で明示的に推論する。** ADR-014 の 2026-05-16
  Spec 予約 amendment はすでに不変の行番号をキーとした予約パス方式として逐語的に
  `specs/NN-slug.md` を使用している; `specs/` ディレクトリはそのプレフィックスである。
  #10 の規約は、その既に認可されたパスのディレクトリコンポーネントの、名前付き
  規範ルールとしての記述であり、ちょうど #09 がそのファイル名コンポーネントを記述した
  ように。これは ADR-014 amendment と同一の構造形状 ── #09 amendment (同じ予約
  パスのファイル名コンポーネント)、#07 amendment (ADR-014 が事前フラグした暫定慣行
  を形式化)、#08 amendment (ADR-014 の Analyze 参照が検証しなければならない内容を
  強化) ── いずれも ADR-014 amendment で解決し、ADR-019 ではない。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->

**#09 との唯一の本物の相違点、そしてなぜそれが判定を覆さないか。** #09 の
ファイル名コンポーネントは他のいかなる CLAUDE.md セクションにも触れなかった ──
`specs/NN-slug.md` ファイル名はどこにも競合する散文がなかった。#10 のディレクトリ
ピンは CLAUDE.md の `## Document Templates` セクションと相互作用し、そのセクションは
**現行のテキストでレイアウトの強制を明示的に否認している**:「成果物をどこに置くかは
あなたが決める … テンプレートはレイアウトを強制しない ── テンプレートだけを強制する」、
説明的な `adr/en/` / `adr/ja/` 分割を伴う。*このリポジトリ* のために `specs/` と
`.claude/meta/adr/` をピンすることは、したがってその散文と単に無言で並存するのでは
なく; `## Document Templates` のスタンスを *変更している* と読まれる可能性がある。
両方の読みを真剣に受け止めた:

- **Reading 1 (真の構造的変更 ⇒ ADR-019):** <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  `## Document Templates` の「あなたが決める」ガイダンスは意図的な、
  フォーク向けの設計決定 (フォークは独自のレイアウトを選択する)。ディレクトリを
  ピンすることはこのリポジトリに対してそれを *逆転させる*; 表明された設計スタンスの
  逆転は新しい構造的決定であり、ADR-017/ADR-018 の構造的な半分であり、
  スタンドアロン ADR-019 を正当化する。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
- **Reading 2 (帰結明確化 ⇒ ADR-014 amendment、採択):**
  `## Document Templates` の「あなたが決める」ガイダンスと #10 のピンは、**正しく
  スコープされれば矛盾しない** ── 2 つの異なるオーディエンスを統治する。
  `## Document Templates` は *フォーク* に語りかける (「テンプレートはレイアウトを
  強制しない」); #10 のピンは *このリポジトリのドッグフーディング姿勢* に語りかける。
  `specs/` ディレクトリは ADR-014 自身の 2026-05-16 予約 amendment によって
  **このリポジトリに対してすでに義務付けられている** (すべての Roadmap 行の予約済み
  `spec:` リンクは `specs/NN-slug.md` ── ディレクトリはここでは自由な選択ではなく、
  ADR-014 が決定している)。#10 は `## Document Templates` が解除するディレクトリ
  制約を *導入* するのではなく; *このリポジトリのための ADR-014 の予約ルールが
  すでに固定したディレクトリを、規約として名付ける* ことをし、`adr/en/` / `adr/ja/`
  の例をフォークにスコープすることで `## Document Templates` のフォーク向け自由を
  明示的に保持する。正しくフレームされれば、`## Document Templates` の散文は
  *逆転していない* ── オーディエンスによって *分割されている* (フォーク = 自由;
  このリポジトリ = ADR-014 ピン)、そして #10 は ADR-014 の予約ルールがすでに
  決定したこのリポジトリ側を記述する。それは予約ルールの帰結明確化であり、
  #09 と同種である。

**判定: Reading 2。ADR-014 amendment。ADR-019 は作成しない。** <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
決定的な事実は `specs/` ディレクトリが **そもそもこのリポジトリに対して自由な選択
ではない** ── ADR-014 の 2026-05-16 予約 amendment がすでにすべての予約済み `spec:`
リンクを `specs/NN-slug.md` に固定している。#10 は「Spec の `## Document Templates`
フリー配置スタンスを逆転させている」はずがない、なぜならそのスタンスは *このリポジトリ
の Spec には一度も有効ではなかった* ── このリポジトリにおいて ADR-014 自体に
よってすでに上書きされていたから。#10 はその ADR-014 が決定したディレクトリに名前を
付け、長年の ADR ディレクトリ慣行をその並列として追加する; `## Document Templates`
編集は例がフォーク向けであることを明確にする *スコープ注記* であり、このリポジトリに
適用していたスタンスの逆転ではない。既存の ADR 決定がすでに固定したディレクトリに
名前を付け、既存の散文をそれが常に暗黙的に対象としていたオーディエンスにスコープする
スコープ明確化編集は、帰結明確化であり ── #09 amendment の条項ごとの適用がファイル名
コンポーネントについて結論づけたのと全く同じ。兄弟対称性の罠 (#05/#06 → ADR-017/
ADR-018、したがって #10 → ADR-019) は #09 と同一に逆転する: #05/#06 自身の <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
識別基準を #10 に適用すると **amendment** になる、なぜなら 3 つの構造的条項 (新しい
ディテクター、新しいパーティション、新しいキーイング/メカニズム) がすべて不在だからである。
Roadmap row #10 は `spec:` のみのまま維持される (マイルストーン → ADR は 0:1;
ADR-014 はそれ自身のマイルストーン行を持たないため、row #10 から ADR-014 への
`adr:` リンクを追加することは存在しないマイルストーン→ADR マッピングを主張することに
なる ── #07、#08、#09 amendment の行推論と同一)。

### The normative directory convention

規約は 2026-05-16 Spec 予約 amendment がすでに義務付ける `specs/NN-slug.md`
パスのディレクトリコンポーネントに名前を付け、ADR オーサリング慣行が常に使用して
きた ADR ディレクトリを加える。新しいパス方式は追加しない;
既存のものを名前付きルールとして記述する:

| ルール | 記述 | 明確化する出典 |
|---|---|---|
| 正規 Spec ディレクトリ | Spec ファイルはリポジトリルートの `specs/` に存在する。これはすべての Roadmap 行がすでに保持する `specs/NN-slug.md` 予約パスのディレクトリコンポーネントである; `product-manager` は行の予約済み `spec:` リンクにすでに固定されたディレクトリにファイルを作成する (行からパスをコピーし、ディレクトリを選択しない)。 | ADR-014 2026-05-16 Spec 予約 amendment (予約パスのプレフィックスが *まさに* `specs/`)。 |
| 正規 ADR ディレクトリ | ADR ファイルはリポジトリルートの `.claude/meta/adr/` に、3 桁ゼロパディング数値プレフィックス (`NNN-slug.md`) で存在する。これまでに作成されたすべての ADR (ADR-001 … ADR-018、+ `.ja.md` 兄弟) が準拠; `architect` は新しい ADR をそこに作成する。 | ADR オーサリング慣行 (既存の 18 個すべての ADR と遡及的に整合); #10 はデファクトのディレクトリを規範として名付ける。3 桁プレフィックスの *ファイル名* 形式は ADR オーサリング慣行であり、**#10 のスコープではない** (Spec Non-goal)。 |
| 同一ディレクトリ EN/JA 兄弟 | EN Spec とその JA 兄弟は `specs/NN-slug.md` と `specs/NN-slug.ja.md` として **同一の** `specs/` ディレクトリに共存する; ディレクトリは言語で **分割しない** (`specs/en/` や `specs/ja/` はない)。`## Document Templates` の `adr/en/` / `adr/ja/` 分割はフォーク **向けの** 説明的なもので、このリポジトリの規約ではない。ペアの見出しツリーパリティは #06 / ADR-018 が所有; 本規約は *同一場所配置* のみを記述し、パリティチェックを再定義または拡張しない。 <!-- ref-allow: specs/en/ and specs/ja/ are non-existing illustrative paths documenting what this convention does NOT use; their non-existence is the point --> | ADR-018 (パリティチェックがコンテンツパリティを所有; 本規約がその per-file-pair キーイング ── ADR-018 2026-05-17 amendment ── が前提とする同一ディレクトリ配置を所有)。 |
| `## Document Templates` オーディエンス スコープ | `## Document Templates` の「成果物をどこに置くかはあなたが決める … テンプレートはレイアウトを強制しない」ガイダンスは **フォーク向け**: フォークが独自のレイアウトを選択できることを伝える。このリポジトリのピンと **矛盾しない**、なぜならこのリポジトリの `specs/` ディレクトリはすでに ADR-014 が決定している (予約ルール) からであり、自由な選択ではない。`adr/en/`/`adr/ja/` の例はフォークに明示的にスコープされている。 | ADR-014 2026-05-16 Spec 予約 amendment (このリポジトリの Spec ディレクトリが自由でない理由) + Spec R-03。 |

本規約は **既存のすべての Spec および ADR ファイルと遡及的に整合** し
(`specs/01-*.md` … `specs/10-*.md` + `.ja.md` 兄弟はすべて `specs/` 下; ADR-001 …
ADR-018 + `.ja.md` 兄弟はすべて `.claude/meta/adr/` 下)、これが一括移動ではなく
規約 *記述* amendment であることを確認する ── #07 と #09 amendment が確立した
「すべての歴史的な成果物と遡及的に整合しており、動作変更ではない」プロパティと
全く同じ。

### (a) Documentation placement — the CLAUDE.md `## Document Templates` section, scoped, plus a one-line MECE pointer in the `## Roadmap` Rules block

#10 は *オーディエンス* において #09 と異なる: #09 は Spec オーサリングのみに
関係した (`product-manager`、すでに `## Roadmap` Rules ブロックを読むため、
1 つの Rules 箇条書きで十分だった)。#10 は Spec オーサリング (`product-manager`)
**と** ADR オーサリング (`architect`) の **両方** に関係する。配置決定は各ディレクトリ
規約をその著者がすでに読む場所に **追加ファイル読み取りゼロ** で配置し、同じルールの
第 2 の権威的ソースを作ることを回避しなければならない (ADR-014 が除去しようとした
「どの文書が権威的か」再発見)。決定、Spec の R-01 (a) 「追加ファイル読み取りなしに
オーサリングステップで出会う」基準に対して:

- **プライマリ単一ソース: CLAUDE.md の `## Document Templates` セクション、
  オーディエンス スコープで編集。** これが自然な単一ソースである、なぜなら
  `## Document Templates` は *すでに文書をどこに置くかについてのセクション* だからで
  ── すでに ADR と Spec のテンプレートに名前を付け、すでに配置について議論している
  (「あなたが決める」)。`product-manager` (Spec) と `architect` (ADR) の両方が
  オーサリングの一部としてこのセクションからテンプレートを解決する; ADR-014 の
  元のダウンストリームタスクはすでに `architect` を adr-template に、`product-manager`
  を spec-template にルーティングし、どちらも *ここ* で参照されている。両方のピンされた
  ディレクトリをすでに配置を統治するセクションに記述することで、各著者が **追加ファイル
  読み取りゼロ** でオーサリングステップにそのディレクトリ規約と出会う ──
  R-01 (a) 基準が *両方の* オーディエンスのために、*1 つの* ソースから構造的に満たされる。
  ディレクトリルールを他のどこかに置くこと (新しい `## Spec/ADR directory convention`
  見出し、または Rules ブロックのみ) は予算を新しいセクションで膨張させるか、
  ルールを 2 つの場所に分割する (Rules ブロックが Spec オーサリングを統治;
  `## Document Templates` がテンプレート/配置を統治) ── 2 ソース再発見を再導入する。
- **なぜ `## Roadmap` Rules ブロックをプライマリにしないか (#09 の選択)?**
  #09 の Rules ブロック配置は *ファイル名が Rules ブロックがすでに記述する予約
  `spec:` パスのプロパティだったから* 正しかった ── `product-manager` はそのブロックを
  Spec 作成のために読み、ファイル名はすでにそこにある予約ルール箇条書きの完成形である。
  しかし Rules ブロックは `architect` が ADR を作成するために **読まない** (ADR オーサリングは
  #04 Architecture ワークフローステップであり、Roadmap 行書き込みではない ── `architect`
  の Roadmap インタラクションは *`adr:` リンク追加* であり、書き込みオーナーシップで
  統治され、ディレクトリ選択ではない)。Rules ブロックを ADR ディレクトリソースにすると
  `architect` が ADR オーサリング時に通常は読まないセクションを読むことを強いる ──
  ADR オーサリングオーディエンスの R-01 (a) に失敗する追加ファイル/セクション読み取り。
  `## Document Templates` セクションは *両方の* 著者がすでに通過する唯一の場所であり、
  したがって正しい単一ソースである; これは #08 と #09 amendment が使用した
  配置-コントラクトオーナー-に-従う推論であり、*2 オーディエンス* コントラクトに適用したもの。
- **二次的、非権威的クロスリファレンス: `## Roadmap` Rules ブロックの 1 行。**
  Rules ブロックはすでに #09 ファイル名箇条書きを持つ (「#10 pins the directory;
  #09 pins the filename — MECE.」)。既存の #09 箇条書きの前方参照を誠実に保つため
  (すでに #10 に言及している)、#09 箇条書きは `## Document Templates` をディレクトリ
  ソースとして指す **1 つの短いクローズ** で拡張される ── ディレクトリルールを
  再記述するのではなく (それが第 2 のソースになる)。これはポインタであり、重複ではない:
  Rules ブロック読者に「ディレクトリ規約は `## Document Templates` にある」と伝え、
  単一ソースプロパティを保ちながら MECE 記述を Roadmap 側からも発見可能にする、
  ちょうど #09 amendment がその MECE 境界を「その箇条書きに」再記述したとおり。
- **CLAUDE.md 行予算ガイダンスを尊重する。** `## Document Templates` は認可された
  例外 `## Roadmap` セクション *ではない*、したがって編集は最小限でなければならない。
  決定は *既存の配置段落のスコープ書き換え* (正味新セクションなし、おおよそ
  正味中立の行数 ── 既存の 4 行「あなたが決める」段落を、フォーク/このリポジトリの
  分割と 2 つのピンされたディレクトリを同程度の長さで記述するよう書き換える) に加え、
  すでに存在する #09 Rules 箇条書きの 1 クローズ拡張。新しい `##` 見出しなし;
  予算は実質的に変わらない (下記判断 (c) が Skill の含意を扱う)。

### (c) Edit scope + claude-md-authoring Skill judgement

- **CLAUDE.md の編集が必要 ── 2 つの場所、両方最小限。** (1) `## Document
  Templates` セクションの配置段落は **その場で書き換えられる**: `specs/` を Spec の
  正規ディレクトリとして、`.claude/meta/adr/` を ADR の正規ディレクトリとして、
  *このリポジトリのドッグフーディング姿勢について* 記述; 既存の「成果物をどこに置くかは
  あなたが決める … テンプレートはレイアウトを強制しない」ガイダンスと `adr/en/` /
  `adr/ja/` の例を *フォーク* に明示的にスコープする; このリポジトリの同一ディレクトリ
  EN/JA 兄弟規約を記述。(2) `## Roadmap` の既存 #09 Rules 箇条書きが **1 つの
  クローズ** を獲得し、`## Document Templates` をディレクトリソースとして指す
  (ディレクトリルールは再記述しない)。他の CLAUDE.md セクションは変更しない。
- **`architect.md` への編集は不要。** `architect` はすでに `## Document Templates`
  から adr-template を解決し (ADR-014 の元のダウンストリームタスクが `architect` を
  そこにルーティング) #04 Architecture ワークフローステップを通じて。規約は `architect`
  がすでに読むセクションからすでに開く template のディレクトリに名前を付ける; 新しい
  プロンプト義務ではない。これは #09 amendment が `product-manager.md` について
  使用した推論と同一 (「規約は … `product-manager` がすでに所有するパスに名前を付ける
  … 新しいプロンプト義務ではない」) そして #07/#08 amendment が「エージェントプロンプトの
  編集は不要」と結論づけるために使用した推論でもある。
- **`product-manager.md` への編集は不要。** `product-manager` はすでに予約済み
  `specs/NN-slug.md` パスに Spec を作成する (ADR-014 予約ルール + #09 ファイル名
  amendment + #07 `☐→◐` トリガー)。ディレクトリはすでに予約されたパスのプレフィックス;
  `## Document Templates` でそれを規範として記述し、`product-manager` がすでに読む
  Rules ブロックからそこへポインタを追加することは新しいプロンプト義務を追加しない ──
  同じエージェントについての #09 の結論と同一。
- **spec/adr テンプレートへの編集は不要。** ディレクトリは *ファイルが作成される場所*
  のプロパティであり (Spec の場合は予約済み `spec:` パスのプレフィックス; ADR の場合は
  ADR オーサリング慣行)、`## Document Templates` と予約ルールによって統治される。
  テンプレートの *コンテンツ* (その `## References` `Roadmap row: #NN` バックリンク) は
  影響を受けない。テンプレートにディレクトリノートを追加すると同じルールのソースが
  2 つになる ── ADR-014 が除去しようとした「どの文書が権威的か」再発見問題まさにそれ、
  そして #09 amendment が spec-template 編集を拒否するために使用した同一推論。
  単一ソース: `## Document Templates`、Rules ブロックポインタを伴う。
- **claude-md-authoring Skill: #10 CLAUDE.md 編集に必要 ──
  これが #09 の判断 (c) からの真の逸脱である。** #09 の延期された編集は *既存の
  リストへの 1 箇条書きの追加* であり ── まさに「Routine small edits (… single bullet …)」
  カーブアウトの範囲内であり、Skill は *不要* だった。#10 の延期された編集は
  **`## Document Templates` セクションの既存の散文を書き換える** ── 定常配置記述の
  *意味* を変える (未修飾の「あなたが決める」からオーディエンス分割の「フォークが決める;
  このリポジトリはピンされている」へ)。既存のセクションの散文の意味を書き換えることは
  「typo、単一箇条書き、バージョンバンプ」のルーティン編集では **ない**; それは
  CLAUDE.md の `## CLAUDE.md authoring guidance` と ADR-007 が Skill の Pre/Post
  チェックリストと不変条件ルールを通じてルーティングする「significant restructuring」
  クラスである (Skill の 4 つの不変条件に対して `## Document Templates` 書き換えを
  検証しなければならない ── 特にセクションがコンパクション耐性を保ち、テンプレート
  レイアウト中立性についての不変条件が黙って違反されないことを)。**判断:
  claude-md-authoring Skill は #10 `## Document Templates` 書き換えに必要。**
  既存の #09 Rules 箇条書きの 1 クローズ拡張は、単独では、ルーティン単一行編集である;
  しかし同じ実装変更が `## Document Templates` の散文も書き換えるため、Skill が
  変更全体を統治する。これは #09 amendment の (c) の意図的な逆: #09 は *設計上*
  単一箇条書きとして ルーティン編集カーブアウトの範囲内に留まるよう設計された;
  #10 の `## Document Templates` インタラクションは単一箇条書きなしでは
  定常の「あなたが決める」散文をスコープ未設定のまま残せない (Spec が黙って解決を
  禁じる正確な R-03 の緊張)、したがって Skill が適用される。

### (d) MECE boundary statement — #10 (directory) vs #09 (filename) vs #04 vs #05 vs #11 vs `## Document Templates` free-placement vs ADR-014 reservation rule (R-01 (d), R-02)

境界は **各オーナーが所有するもの** で引かれており、将来のマイルストーン著者が
ディレクトリの懸念をファイル名ピンや、パス解決ディテクターや、Roadmap 構造ディテクターや、
検証ドメインガイダンスマイルストーンや、フォーク向け配置ガイダンスや、予約ルールに
誤ってルーティングできないよう、ここと実装者の箇条書きに再記述する:

| オーナー | 所有する問い | トリガーポイント |
|---|---|---|
| #04 `check-dangling-refs.sh` | 文書散文中のパス/参照は実際のファイル/ADR に **解決するか**? | コミット時 (CI) |
| #05 `check-roadmap-drift.sh` | **双方向 Roadmap インデックスコントラクト** は成立しており、すべてのステータスグリフは **整形式か**? | コミット時 (CI) |
| #09 (spec filename amendment) | Spec ファイルの **ファイル名形式は何か** (`NN-slug.md`、最小 2 桁、`.ja.md` 兄弟形式、`progress` 除外)? | ドキュメント/規約 (CI なし; 明示的に延期された任意の帰結) |
| #10 (本 amendment) | Spec および ADR ファイルは *このリポジトリ* において **どのディレクトリ** に存在するか (`specs/`、`.claude/meta/adr/`)、そして EN/JA 兄弟が同一場所配置か? | ドキュメント/規約 (#10 自身のスコープに CI なし) |
| #11 (verification-domain opt-in guidance) | 実装/設計 verification ドメインのオプトイン **トリガーガイダンス**。 | ドキュメント/規約 (予約済みだがファイル未作成の Roadmap row) <!-- ref-allow: #11 is a reserved-but-absent Roadmap row per the ADR-014 reservation rule; the MECE boundary must name it before its Spec is authored at pickup --> |
| `## Document Templates` フリー配置ガイダンス | **フォーク** が独自のドキュメントレイアウトを選択できること (テンプレートはそれを強制しない)。 | ドキュメント (フォーク向け; #10 のこのリポジトリピンと直交するオーディエンス) |
| ADR-014 予約ルール | すべての行が行作成時に予約済み `spec:` リンク `specs/NN-slug.md` を持つ *こと*、不変の行番号をキーとして。 | 行作成時 (プロセス) |

懸念はちょうど 1 つのオーナーにマッピングされる: *壊れた散文パス* は #04 (コミット時
解決); *不正なグリフまたは壊れた双方向 ADR リンク* は #05 (コミット時整合性);
*Spec ファイルの名前が何か* は #09; *Spec または ADR がこのリポジトリでどのディレクトリ
に存在するか* は #10; *verification ドメインのオプトイントリガーガイダンス* は #11;
*フォークが独自のレイアウトを選択できること* は `## Document Templates` フォーク向け
ガイダンス; *予約済み `spec:` リンクがそもそも存在すること* は ADR-014 予約ルール。
完全な正規 Spec パス `specs/NN-slug.md` は #10 のディレクトリスコープと #09 の
ファイル名スコープの **合成** であり: どちらも他方を包含せず、ディレクトリに不確かな
将来の著者は #10 を (いま `## Document Templates` に記述)、ファイル名に不確かな
著者は #09 を (The `## Roadmap` Rules 箇条書き) 読む。`## Document Templates` の
縫い目は明示的であり、このテーブルで最も鋭い縫い目: #10 とフォーク向けガイダンスは
**矛盾しない**、なぜなら **異なるオーディエンスに対処する** ── ガイダンスは *フォーク*
に自由だと伝える; #10 は *このリポジトリの* ピンされたディレクトリを記述し、それは
ADR-014 の予約ルールが Spec についてはすでに決定していた。オーディエンスによって
MECE であり、矛盾によってではない; `## Document Templates` 書き換えはその
オーディエンス分割を散文で明示的にし、R-03 が要求するとおり矛盾として読まれることを
防ぐ。

### Composability with ADR-014's reservation rule, #09, and #06/ADR-018 (no gap)

- **ADR-014 2026-05-16 Spec 予約 amendment。** #10 はその amendment がすでに義務付ける
  `specs/NN-slug.md` 予約パスのディレクトリコンポーネント (`specs/`) に名前を付ける;
  #09 はそのファイル名コンポーネントに名前を付けた。3 つはギャップなく合成可能:
  予約 amendment は *行作成時から予約済み `spec:` リンクが `specs/NN-slug.md` の
  形式で存在する* と言い; #10 は *ディレクトリプレフィックスはこのリポジトリに対して
  `specs/` にピンされている* と言い; #09 は *ピックアップ時に作成されるファイルは
  `NN-slug.md` の名前を使用する* と言う。第 2 のパス方式は導入しない。
- **#09 (spec filename amendment)。** #10 と #09 は構造上 MECE (ディレクトリ対
  ファイル名) であり、その CLAUDE.md の置き場所は意図的に異なり重複しない:
  #09 は `## Roadmap` Rules 箇条書きに存在する (そのオーディエンス `product-manager`
  がそこで読む); #10 の権威的記述は `## Document Templates` に存在する (その 2 つの
  オーディエンス `product-manager` と `architect` が両方ともオーサリング時に
  そこを通過する)。Rules 箇条書きの 1 クローズポインタが 2 つをつなぎ、どちらのルールも
  再記述せず ── ルールごとに単一ソース、クロスリファレンスされ、重複しない。
- **#06 / ADR-018 (bilingual parity)。** #10 は EN/JA 兄弟の *同一 `specs/`
  ディレクトリへの同一場所配置* を記述; ADR-018 の 2026-05-17 per-file-pair
  amendment はまさにその同一場所配置を *前提とする* (それは **同一の** ディレクトリで
  `<stem>.md` から `<stem>.ja.md` を導出する ── 言語分割ディレクトリはそのキーイングを
  壊す)。#10 は ADR-018 のキーイングがすでに依存している同一ディレクトリ規約を確認する;
  ADR-018 はペアの見出しツリー/全角括弧 *コンテンツ* パリティを所有する。
  重複なし ── 誤配置ディレクトリの欠陥は #10 の規約、見出し順序の欠陥は #06 のチェック。
  #10 はパリティルールを導入せず `check-bilingual-parity.sh` に触れない。

### Downstream implementer tasks (recorded for traceability, not performed by this amendment — implementation is a future session, per the #03/ADR-016 · #05/ADR-017 · #06/ADR-018 · #07/ADR-014-amendment · #08/ADR-014-amendment · #09/ADR-014-amendment two-session decision-then-implementation split)

- `.claude/CLAUDE.md` の `## Document Templates` セクション ── **既存の配置段落を
  その場で書き換える** (「You decide where to place the resulting documents …
  The template does not impose a layout — only the templates.」段落) で:
  (1) `specs/` が **このリポジトリのドッグフーディング姿勢において** 正規 Spec ディレクトリ、
  `.claude/meta/adr/` が正規 ADR ディレクトリであることを記述; (2) 既存の「成果物を
  どこに置くかはあなたが決める」ガイダンスと `adr/en/` / `adr/ja/` の例を **フォーク
  に明示的にスコープ** する (「派生プロジェクトは独自のレイアウトを選択できる; テンプレートは
  いずれも強制しない ── このリポジトリは `specs/` と `.claude/meta/adr/` を独自の
  規約としてピンする」); (3) このリポジトリの同一ディレクトリ EN/JA 兄弟規約を記述する
  (`specs/NN-slug.md` + `specs/NN-slug.ja.md` は同一の `specs/` ディレクトリに、
  `specs/en/` / `specs/ja/` ではなく)、見出しツリーパリティは #06 が所有することに
  言及。行数をおおよそ正味中立に保つ (追加ではなく書き換え)。**この編集は
  claude-md-authoring Skill によって統治される** (上記判断 (c) ── 既存の散文の
  意味を書き換える; Skill の Pre/Post チェックリストを実行し 4 つの不変条件を検証する、
  特に `## Document Templates` のコンパクション耐性と、テンプレートレイアウト中立性
  不変条件がオーディエンススコープによって黙って違反されないことを)。
- `.claude/CLAUDE.md` の `## Roadmap` **Rules** ブロック ── **既存の** #09 ファイル名
  箇条書き (「#10 pins the directory; #09 pins the filename — MECE.」で終わるもの) を
  `## Document Templates` をディレクトリ権威ソースとして指す **1 つの短いクローズ** で
  拡張する ── 例えば追記:「see `## Document Templates` for the pinned `specs/`
  and `.claude/meta/adr/` directories.」 Rules ブロックにディレクトリルールを **再記述
  しない** (それが禁じられた第 2 のソースを作成する); クローズはポインタのみ。この
  1 クローズ拡張は、単独では、ルーティン単一行編集だが、Skill が統治する
  `## Document Templates` 書き換えと同じ変更でリリースされる。
- **エージェントプロンプトの編集なし** (上記判断 (c))。実装者は
  `product-manager.md`、`architect.md`、`orchestrator.md`、`implementer.md`
  にディレクトリ規約の散文を追加してはならない;
  `## Document Templates` が単一ソース。`product-manager` の予約パスでの
  オーサリング動作は ADR-014 行+`spec:` 書き込みオーナーシップ、#09 ファイル名
  amendment、#07 の `☐→◐` ピックアップトリガーですでにカバーされている;
  `architect` の ADR オーサリングはすでに `## Document Templates` から adr-template
  を解決する。
- **spec/adr テンプレートの編集なし** (上記判断 (c))。テンプレートの `## References`
  `Roadmap row: #NN` 例は影響を受けない; ディレクトリは `## Document Templates` セクションが
  記述する予約パス / ADR オーサリング慣行のプロパティであり、テンプレートコンテンツでは
  ない。テンプレートにノートを追加すると同じルールのソースが 2 つになる。
- **CI ワークフローとスクリプトなし** (Spec Non-goals / Out of scope:
  「#10 はドキュメント/規約記述マイルストーン; CI 強制は任意の帰結であり、
  このマイルストーンの成果物ではない」; 「CI ディレクトリ適合チェックの追加 ──
  architect に延期された構造的決定」)。将来の機械的ディレクトリ適合チェックは
  可能性ある後のマイルストーンであり、**#10 ではない**、下記の反対案トリガー条件下で
  再評価される ── (d) MECE テーブルに従い #04/#05 のコミット時チェックとは異なる。
- **移動またはリネームなし。** 既存のすべての Spec ファイル
  (`specs/01-*.md` … `specs/10-*.md` + `.ja.md` 兄弟) とすべての ADR ファイル
  (`.claude/meta/adr/001-*.md` … `.claude/meta/adr/018-*.md` + `.ja.md` 兄弟)
  はすでにピンされたディレクトリに存在する; #10 は規約記述であり一括移動ではない
  (Spec Non-goals)。
- **Roadmap 行の変更なし。** Row #10 の `Design source` セルは `spec:` のみのまま ──
  これは ADR-014 amendment であり、ADR-014 はそれ自身のマイルストーン行を持たない
  ため、row #10 に `adr:` リンクは追加しない (マイルストーン → ADR は 0:1; #07、#08、
  #09 amendment の行推論と同一)。`product-manager` は #07 遷移マトリックスに従い
  step-6 quality gate 後に行グリフ `◐→☑` を反転; `architect` はここに `adr:` リンクを
  追加しない。
- 本 ADR の日本語版
  (`014-roadmap-index-single-entry-point.ja.md`) はミラーされた amendment を
  受け取る必要がある ── `technical-writer` タスクであり、本変更の対象ではない。
  **本 amendment は ADR-014 に一時的な EN/JA 見出し不一致を作り出す (EN は
  1 つの `##` レベル見出しとその `###` サブ見出しを獲得し; JA は本変更前に
  見出しパリティにあった) ── `technical-writer` のミラーが反映されるまで
  #06 bilingual-parity detector (`check-bilingual-parity.sh`) は ADR-014 EN/JA
  ペアで FAIL する。これは期待されるキューに入った `technical-writer` タスクであり、
  この EN amendment を省略する理由ではない**、まさに 2026-05-17 のステータス遷移
  (#07)、Analyze 行ガード (#08)、spec filename (#09) amendment が行ったとおり。

### Counter-proposal

深刻な反対案は **新しい ADR-019 ── spec/adr ディレクトリピンを ADR-014 amendment <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
ではなくスタンドアロン ADR として形式化する、なぜなら #10 は ADR-014 amendment より
むしろ `## Document Templates` のスタンスを *変更する* からである** である。
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 の慣例に従い、
却下された代替案を藁人形としてではなく真剣に記録する。議論:

1. Spec は `architect` に明示的な (b)/(c) 選択肢 (「ADR-014 amendment か新しい
   ADR-019 か」) を渡しており、構造的に並行した兄弟マイルストーン #05 と #06 は <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   どちらも延期された構造的質問の Spec を *新しい* ADR (017、018) で解決しており、
   amendment ではない。プロセスの対称性は #10 → ADR-019 を示唆する。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
2. **#09 が持たなかった ADR-019 への #10 の最も強力な主張:** #10 のピンは <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   既存の CLAUDE.md セクション (`## Document Templates`) の **意味を編集し**、
   未修飾の「テンプレートはレイアウトを強制しない」をオーディエンス分割ルールに変える。
   #09 は *追加* するだけだった; #10 は *定常の設計記述を書き換える*。既存の、
   意図的な設計スタンスの意味を変えることは、ADR-017/ADR-018 の「新しい構造的決定」
   の半分であり、帰結明確化ではない ── そしてそれはまさに、レビュアーが「ディレクトリピン
   ADR」として指し示せるファーストクラスの引用可能な ADR を正当化する種類の変更であり、
   長い ADR-014 トレイルに埋め込まれた 6 番目の amendment よりも。
3. ADR-019 はそれ自身の Roadmap バックリンク (`Roadmap row: #10`) を持ち、 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
   row は `adr:` リンクを獲得する ── #05/#06 が行使する同じ双方向コントラクトを
   #10 に与え、その兄弟と同じ成果物形状になる。

**反対案が採用されなかった理由:**

- 議論 2 の前提 ── 「#10 は `## Document Templates` のスタンスを *変更する*」 ──
  は精査すると偽である、そしてこれが決定的な点である。`## Document Templates` の
  「成果物をどこに置くかはあなたが決める」ガイダンスは **このリポジトリの Spec
  ファイルには一度も有効ではなかった**: ADR-014 自身の 2026-05-16 Spec 予約
  amendment がすでにすべての予約済み `spec:` リンクを `specs/NN-slug.md` に固定し、
  *#10 が存在する前に* このリポジトリの `specs/` ディレクトリを固定していた。#10 は
  このリポジトリの Spec に適用していたスタンスを逆転させない ── そのスタンスは、
  このリポジトリにおいて ADR-014 自体によってすでに上書きされていた。`## Document
  Templates` 書き換えは **スコープ明確化** (ガイダンスはフォーク向け; このリポジトリは
  ADR-014 ピン) であり、散文ですでに真のオーディエンス分割を明示的にする。
  既存の ADR 決定がすでに固定したディレクトリに名前を付け、定常の散文をそれが
  常に暗黙的に対象としていたオーディエンスにスコープすることは、帰結明確化である ──
  同じ予約パスのファイル名コンポーネントについての #09 の帰結明確化と、そして
  #07/#08 amendment の ADR-014 が事前フラグした慣行の形式化と、構造的に同一の形状。
- ADR-017 と ADR-018 は特定の、明記された識別基準に基づいて新 ADR に値すると
  自己分類した: それぞれが **新しいディテクター + 新しい MECE コントラクト境界 +
  新しい免除キーイングルール** を導入した。#10 はそれらを **いずれも** 導入しない ──
  Spec の Non-goals と Out of scope は新しい CI ディテクターまたはスクリプトを
  明示的に禁じている; MECE 記述はディテクターファミリー分割の外部に #10 を置く
  スコープ限定であり、その分割内の 4 番目のパーティションではない; そして免除キーイングも、
  許可リスト対パターン選択も、新しいファイル成果物も、新しいメカニズムも存在しない。
  兄弟対称性の議論は #07、#08、#09 と全く同じように精査で逆転する:
  #05/#06 自身の識別基準を #10 に適用すると「amendment」になる、なぜなら #05/#06
  にとって支配的だった構造的な半分が #10 には不在だからである。
- 発見しやすさは ADR-014 amendment の方が *良い*、悪くない: 「予約された `spec:`
  パスのプレフィックスはどのディレクトリか」を読者が探す正規の場所は、Roadmap、予約
  ルール、および `specs/NN-slug.md` パス方式自体を定義した ADR であり ── #09 の
  ファイル名明確化が存在するのと同じ ADR。別個の ADR-019 は予約パスコントラクトを <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  3 つの ADR に *分断* する (ADR-014 予約ルール + ADR-019 ディレクトリ + #09 amendment <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  ファイル名)、ADR-014 が除去しようとした「どの文書が権威的か」再発見をまさに再導入する。
  ディレクトリ明確化をファイル名明確化と予約ルールの隣、すべて ADR-014 に保つことは、
  ADR-014 が体現する単一ソース規律である。
- 双方向バックリンクの議論は無意味: ADR-014 はそれ自身のマイルストーン行を
  持たないため、それへの amendment は正しく `Roadmap row:` 行を持たず #05 ドリフト
  コントラクトをトリガーしない。バックリンクを作成するためだけに新しい ADR-019 を <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
  強制することは、真の構造的決定を反映するのではなく双方向成果物を製造することになる ──
  #07、#08、#09 amendment による同じ異論の解決と同一。
- claude-md-authoring Skill 要件 (判断 (c)) は新しい ADR を正当化する構造的決定の
  証拠では **ない**。Skill は CLAUDE.md 散文編集が *どのように実行されるか* を統治する
  (Pre/Post チェックリスト、不変条件検証); *決定が構造的かどうか* を再分類しない。
  ADR-007 は基礎となる決定が新しい ADR であるか amendment であるかに関わらず、
  重要な CLAUDE.md 散文変更を Skill を通じてルーティングする ── Skill 要件と
  ADR 対 amendment 分類は直交する軸。その実装がたまたま散文を書き換える帰結明確化は、
  *編集* のために Skill を必要とし、*決定* については amendment のまま。

**この反対案を再評価するトリガー条件:**

- 将来のマイルストーンがディレクトリ規約の *機械的な CI 強制* を genuinely 追加する
  場合 (すべての Spec が `specs/` 下に、すべての ADR が `.claude/meta/adr/` 下に、
  同一ディレクトリ EN/JA 兄弟を伴い存在するかを静的に検証する新しいディテクター) ──
  それは新しいディテクター + 新しい境界 + 新しいキーイングであり、ADR-017/ADR-018
  識別基準の構造的な半分であり、本 amendment の規約をその継承されたベースラインとする
  独自の ADR を持つに値する。Spec はこの CI チェックを「このマイルストーンの成果物ではなく、
  任意の帰結」と明示的にフラグしている。
- このリポジトリの `specs/` または `.claude/meta/adr/` ディレクトリ自体が再構成される
  場合 (例えば予約ルールが置き換えられる、または `specs/` がリネームされる、または
  ADR が `.claude/meta/` の外に移動する) ── 基礎となるパスメカニズムへの真の変更で
  あり、amendment によって拡張するのではなく所有する決定を再開する。
- `## Document Templates` フォーク向けガイダンスがフォークプロファイルごとに
  *異なるディレクトリルール* を必要とすることが判明し、CLAUDE.md の単一
  オーディエンススコープ記述と ADR-014 amendment がそれを表現できなくなる場合 ──
  その時点でプロファイルごとのディレクトリルールを持つ専用 ADR が正当化される可能性。
- ディレクトリ規約が `## Document Templates` のフリー配置ガイダンスと (オーディエンスに
  よって MECE で共存するのではなく) genuinely *矛盾する* と判明した場合 ── 例えば
  将来の決定がテンプレート *自体* (このリポジトリだけでなく) に `specs/` を義務付け、
  フォークの自由を除去する場合 ── これは設計スタンスの真の逆転であり、スコープ明確化ではなく、
  独自の ADR を正当化する。

反対案は ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 の慣例に従い、
決定の最も深刻な異論の歴史的記録として本 amendment に残る。

元のステータス行 (`Accepted — 2026-05-15`) は変更しない; 本 amendment は
ADR-014 の既存の Spec 予約ルール決定のディレクトリコンポーネント帰結明確化を
追記するものであり、決定を再開するものではない。

## Amendment — 2026-05-17 (verification-domain opt-in trigger guidance)

本 amendment は、`specs/11-verification-domain-opt-in-guidance.md` の
リスク R-01 が `architect` に委ねた構造的決定を記録する: デフォルト off の
`implementation` / `design` verification-layer ドメインに対するフォーク向け
プロジェクト採用トリガーガイダンスを *どこに* 配置するか、そしてその配置が
新しい ADR-019 を正当化するか帰結明確化として amendment で扱うか。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
`specs/11-…` (Roadmap row #11) が権威的なスコープであり、ガイダンスが
カバーしなければならない内容 (ドメインごとに具体的なプロジェクト特性トリガー
3 つ以上、`protocol.md` ファイルの変更単位ランタイムトリガーとは明示的に区別、
CI 強制なし、`.claude/verification.yml` のアクティブデフォルト変更なし) と
その 8 つの受け入れ基準を記述し、構造的な *どのように* (配置ファイル/セクション、
ADR 戦略、分割か単一か) を `architect` に委ねている (R-01 (a)-(d))。本 amendment は
その決定を記録する。これは **ADR-014 のすでに認可された MECE パーティションの
帰結明確化** であり ── 具体的には、2026-05-17 の spec/adr ディレクトリピン
amendment の §(d) MECE 境界テーブルの帰結明確化であり、**それは #11 の Spec が
存在する前に既に #11 の境界を名付け「documentation/convention」と分類している**。
これは ADR-010 の決定の明確化では *ない*: ADR-010 のデフォルト off スタンスは
逐語的に保持され変更されない (Spec 行 22、28、76、117; AC-5 行 60)。新しい
ディテクター、CI ワークフロー、コントラクト境界、キーイングルール、MECE
パーティション、またはファイル成果物は導入しない。

### The (b)/(c) decision — ADR-014 amendment, not new ADR-019, by the ADR-018 Alternative-B discriminator <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal; it is intentionally never created (see Counter-proposal below) -->

Spec の R-01 (b) は `architect` に明示的な選択肢 「新しい ADR-019 か ADR-010 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
amendment か (ADR-018 の Alternative-B 識別基準を適用)」を渡している。条項ごとに <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
誠実に、file:line 証拠とともに適用する ── ホスト候補は Spec の暫定的な
「ADR-010」から **ADR-014** に修正する。理由は最終条項に示す:

- **新しいディテクター? No.** Spec の Non-goals 行 26 (「フォークが有効化した
  ドメインを強制または監査する CI ディテクターまたはチェックの追加。新しい
  ディテクターは ADR-014:1800 の『documentation/convention』分類に違反する
  新しい MECE パーティションを作成する。これはスコープ外でありこのマイルストーンの
  帰結として提案してはならない」) と Out of scope 行 113 (「フォークの
  verification ドメイン設定を検査する CI ディテクター、監査チェック、または
  リンティングルールの追加」) はディテクターを #11 の成果物として *明示的に
  禁じている*。ADR-015 と ADR-017 はそれぞれ新しいスクリプト + 新しいワークフロー
  (`check-dangling-refs.sh` / `check-roadmap-drift.sh`) を導入したからこそ新
  ADR 相当と自己分類した; ADR-018 も同様 (`check-bilingual-parity.sh`)。
  #11 はスクリプトもワークフローも **ゼロ** 導入する ── #07 (ディテクターなし)、
  #08 (Non-goals が CI ワークフローを禁じた)、#09 (Non-goals が CI ファイル名
  ディテクターを禁じた)、#10 (Non-goals が CI ディレクトリディテクターを
  禁じた) amendment と同一。ADR-015/ADR-017/ADR-018 で支配的だった構造的な
  半分はここには存在しない。#11 は純粋な散文ガイダンスである。
- **新しい MECE パーティション/境界? No ── 境界はすでに存在し既に #11 を
  名付けている。** 決定的なチェック: ADR-014 の 2026-05-17 spec/adr
  ディレクトリピン amendment の §(d) MECE テーブル (本ファイル行 1800) は
  *すでに* 行 `| #11 (verification-domain opt-in guidance) | Opt-in trigger
  guidance for implementation/design verification domains. |
  documentation/convention (reserved-but-absent Roadmap row) |` を含み、
  行 1808 は *すでに*「*verification-domain opt-in trigger guidance* is
  #11's」を既存の documentation/convention パーティション内の独立した
  オーナーとして記述している。#11 は **行もパーティションも追加しない** ──
  ADR-014 が Spec オーサリング前に #11 のために予約した境界スロットを
  *埋める* のであり、(d) テーブル自身の `ref-allow` コメントが予期した通り
  (「#11 is a reserved-but-absent Roadmap row … the MECE boundary must
  name it before its Spec is authored at pickup」)。これは ADR-015 の
  absence-of-claim キーイングと ADR-018 の convention-presence キーイングの
  逆である: 新しいパーティションがないので新しいキーイングもない ── 事前宣言
  され事前分類されたスロットの populate のみ。
- **新しいキーイング/メカニズム/ファイル成果物? No.** 除外キーイングルール、
  allowlist 対 pattern の選択、パース戦略、新しいファイル、新しいスクリプト、
  agent-prompt の変更はない。成果物は既存の 2 ファイルに追記される
  ドキュメント散文である (Downstream implementer tasks 参照)。Spec
  Key-interaction 6 (行 80) は architect の決定を配置のみにスコープし、
  行 26 はあらゆるメカニズムを禁じる。
- **ADR-010 の決定を再開する? No ── スタンスを *説明* し、変更しない。**
  Spec 行 22 (「`.claude/verification.yml` のアクティブデフォルトを変更しない …
  デフォルト off は ADR-010 の認可されたスタンス; ガイダンスはスタンスを
  説明し、変更しない」)、行 28、行 76 (「ADR-010 … #11 はそのスタンスを
  変更しない。ADR-010 の決定や帰結を変更せずに opt-in 決定を informed に
  するドキュメントを追加する」)、行 117 (「ADR-010 の決定や帰結の変更 …
  デフォルト off スタンスは正しい」)、AC-5 (行 60: #11 出荷後も
  `.claude/verification.yml` の `implementation.enabled`/`design.enabled`
  は `false` のまま) がこれを明確にする。#11 は変更されない ADR-010 決定
  *の* 下流ドキュメントであり、それ *の* 変更ではない。
- **既存決定の帰結明確化? Yes ── 正しいホストは ADR-010 ではなく
  ADR-014。** Spec の R-01 は「ADR-010 amendment」を amendment 候補として
  暫定的に名付ける。識別基準を厳密に適用するとこれは修正される: ADR-010 の
  決定は *手付かず* (上記条項) なので、#11 は *ADR-010 の決定の*
  帰結明確化ではありえない ── 明確化される ADR-010 帰結は存在しない;
  スタンスは単に *引用* されるだけ。#11 が帰結明確化する対象は **ADR-014 の
  MECE パーティション** である: §(d) 境界テーブルはすでに #11 を
  「documentation/convention」と分類しスロットを予約しており、#11 は
  #07/#08/#09/#10 と構造的に同一である ── いずれも documentation/convention
  マイルストーンで、その構造的決定が ADR-014 amendment として記録されたのは、
  各々が ADR-014 がすでに所有する境界の帰結を *埋めるか明確化する* だけで、
  決定を再開しなかったからである。#11 を ADR-014 にホストすることで §(d)
  MECE テーブルとその所有 ADR が同居する (#11 を名付けるテーブルと #11 の
  スロットを埋める amendment が同一ファイルに存在); ADR-010 にホストすると
  MECE 簿記が 2 つの ADR に分割され利益がなく、存在しない ADR-010 決定帰結が
  明確化されているかのように誤って示唆する。ADR-014 が正しいホストである
  のは、ADR-018 が三方向コントラクトパーティションを 1 つの ADR に保つために
  用いたのと同じ簿記局所性の根拠による。

**結論。** トライアドは **満たされない** (新しいディテクターなし、新しい
MECE パーティションなし、新しいキーイングなし); ADR-010 の決定は **再開
されない**。#11 は *ADR-014 自身の §(d) MECE テーブルが #11 のために事前予約
したスロットを populate する* 帰結明確化である。新しい ADR-019 ではなく、 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
ADR-010 amendment でもなく、**ADR-014 amendment** として記録する ──
ADR-018 の Alternative B が論じ通し、#07/#08/#09/#10 amendment が適用したのと
同じ判断。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->

### The placement decision (R-01 (a), (c))

**単一の配置: `.claude/skills/verification-layer/SKILL.md` に新しい
`## Project adoption triggers` セクションを、既存の `## Configuration`
セクションの直後、`## When to invoke` の直前に追加する。** 分割しない;
`verification.yml.example` には置かない; `protocol.md` ファイルにも置かない。
Spec が surface した 3 候補 (Key-interaction 2、3、6) に対する根拠:

- **なぜ `verification.yml.example` ではなく SKILL.md か。** AC-6 (Spec
  行 62) はフォーク管理者が「採用ステップの一部でないファイルを読まずに」
  ガイダンスに遭遇することを要求する。採用ステップは CLAUDE.md
  `## Development Workflow` step 3 であり、すでに管理者を *verification-layer
  Skill* (`.claude/skills/verification-layer/SKILL.md`) と
  `.claude/verification.yml` に誘導している ── `verification.yml.example`
  には **誘導していない**。`verification.yml.example` はその行 2-8 ヘッダー
  自身により「DOCUMENTATION REFERENCE ONLY … never read by the
  verification layer」であり、採用ステップファイルではなく *フィールド
  リファレンス* である。決定ガイダンスをそこだけに置くと管理者が非採用
  ステップファイルを発見する必要が生じ (AC-6 不合格)、アクティブな
  `.claude/verification.yml` から drift する傾向もある (注釈付きコピーが
  2 つ)。アクティブな `.claude/verification.yml` は AC-5 とタスク
  (「`.claude/verification.yml` に触れるな」) により制約ロックされているため、
  ガイダンスはアクティブ config にも置けない。SKILL.md は採用ステップが
  すでに義務付けている唯一のファイルで *かつ* ここで書き込み可能なものである。
- **なぜ `## Configuration` に折り込まず隣接する新セクションか。** SKILL.md
  `## Configuration` (行 126-146) は「各 knob のデフォルトは何でなぜ非対称か」
  に答える。#11 は *隣接するが別個の* 質問「どのようなプロジェクトに対して
  二重コストの支払いが knob を flip する価値があるか」に答える。
  `## Project adoption triggers` を `## Configuration` (knob) と
  `## When to invoke` (変更単位ランタイムトリガー) の *間に* 置くことで
  3 つの質問が自然な読み順 ── *デフォルトは何か → プロジェクトはそれを
  変えるべきか → 変えたら Critic はいつ発火するか* ── に並び、管理者は
  config 決定のまさにその地点で採用ガイダンスを読む。追加ファイル参照は
  ゼロ (AC-6 はクロスリファレンスではなく隣接で満たされる)。
- **なぜ `protocol.md` ファイルではないか。** `implementation/protocol.md`
  と `design/protocol.md` の `## When to invoke` は、プロジェクトが既に
  opt-in した後の *変更単位* 質問 (「この特定の変更で Critic は spawn する
  か?」) に答える。AC-3/AC-4 (Spec 行 56、58) はプロジェクト採用ガイダンスが
  それらのセクションと *明確に区別され重複しない* ことを要求する。#11 の
  ガイダンスを変更単位トリガーと同じファイルに同居させることはまさに R-02
  のスコープクリープリスクである; SKILL.md (ドメインナビゲーターと共有
  invariant が存在する 1 つ上のレベル) に保つことで 2 つの質問を文言だけで
  なくファイルで構造的に分離する。新セクションは後続の変更単位質問のために
  読者を `protocol.md` の `## When to invoke` セクションへ *先へ* 誘導し
  (Spec Key-interaction 1)、その内容を再記述しない。

この配置は **単一の場所で自己完結** している (R-01 (c): 分割しない)。追加する
クロスリファレンスは *外向きポインタ* (「有効化後の変更単位トリガーは
`implementation/protocol.md` / `design/protocol.md` の `## When to invoke`
参照」) のみで、重複なしに Spec Key-interaction 1 を満たす (AC-4)。

### Downstream implementer tasks (performed in this same session — for #11 the two-session decision-then-implementation split used by #03/ADR-016 · #05/ADR-017 · #06/ADR-018 · #07/ADR-014-amendment · #08/ADR-014-amendment · #09/ADR-014-amendment · #10/ADR-014-amendment was deliberately collapsed: #11's implementation is a single prose-only SKILL.md section, fully enumerated below and verifiable against the Spec's eight ACs, requiring no separate review cycle; the task list is retained verbatim for traceability and as the precedent shape for milestones whose implementation *is* deferred)

implementer ステップ (Spec step 5) は機械的で、Spec の 8 つの AC に対して
検証可能である:

- `.claude/skills/verification-layer/SKILL.md` ── **新しい
  `## Project adoption triggers` セクションを 1 つ追加し、既存の
  `## Configuration` セクション (行 146 で終わる) の直後、`## When to
  invoke` (行 148) の直前に配置する。** セクションは散文として以下を含む
  (その中のどこにもディテクター/CI/強制の言葉なし ── AC-7、AC-8):
  1. *プロジェクト採用* 質問 (「このプロジェクトはそもそもドメインを
     有効化すべきか?」) を `protocol.md` `## When to invoke` セクションが
     所有する *変更単位* 質問 (「この変更で Critic は spawn するか?」) と
     区別する 1 文のフレーミング ── AC-3 を満たす。
  2. `implementation.enabled: true` の具体的プロジェクト特性トリガーを
     **3 つ以上** 名付ける `### implementation` サブセクション (Spec AC-1 /
     Goal 行 18 の例を逐語コピーせず参考に: 非自明なカスタムアルゴリズム;
     レビュアー多様性が限られた小規模チーム; Generator による部分的な
     test-oracle 所有)。「opt-in の価値を高めるシグナル」としてフレーム、
     ゲートではなく加法的 (Spec R-03 緩和、行 108) ── いずれも変更単位の
     「今 spawn するか?」トリガーではない (AC-1)。
  3. `design.enabled: true` の具体的プロジェクト特性トリガーを **3 つ以上**
     名付ける `### design` サブセクション (Spec AC-2 / Goal 行 19 の例:
     高い ADR ケイデンス; 長いアーキテクチャ可逆性ホライゾン; 複数の
     独立チームにまたがる下流コンシューマ)。同じ加法的フレーミング;
     いずれも変更単位トリガーではない (AC-2)。2 つのトリガーセットは
     可視的に区別され混同されてはならない (Spec User-story 行 2)。
  4. 末尾の 1 行 *外向きポインタ*: ドメインが有効化されたら変更単位
     ランタイムトリガーはそのドメインの `protocol.md` `## When to invoke`
     に存在する ── **リンクし、再記述しない** (AC-4 / Spec Key-interaction
     1 を満たす; 再記述は AC-4 不合格)。
  5. `.claude/verification.yml` のアクティブ値が変わるという言及なし;
     セクションはドキュメントのみ (AC-5 と一貫、レビュアーは手付かずの
     アクティブ config に対して検証する)。
- **`.claude/verification.yml` 編集なし** (タスク制約; Spec AC-5、Out of
  scope 行 112)。アクティブ config の `implementation.enabled: false` /
  `design.enabled: false` は逐語的に維持される。
- **`.claude/verification.yml.example` 編集なし。** 配置は SKILL.md
  単一場所 (上記配置決定); example ファイルも編集すると R-01 (c) が拒否する
  分割と drift する 2 つ目の注釈付きコピーが生じる。(将来の管理者が
  example の `implementation:`/`design:` コメントブロックに「SKILL.md
  `## Project adoption triggers` 参照」の 1 行ポインタを望む場合、それは
  任意の別個の非 #11 の nicety であり ── 配置単一ソースを保つため明示的に
  #11 の成果物では **ない**。)
- **`protocol.md` 編集なし。** `implementation/protocol.md` と
  `design/protocol.md` の変更単位 `## When to invoke` と `## Configuration`
  ブロックは正しくスコープ外 (Spec Non-goals 行 30、Out of scope 行 115)。
  #11 はそれらを *指す*; 変更しない。
- **CI ワークフローなし、スクリプトなし** (Spec Non-goals 行 26、Out of
  scope 行 113)。#11 は documentation/convention; 設定監査ディテクターは
  #11 の帰結として明示的に禁じられており、延期任意でもない (#09/#10 と
  異なり、Spec は「延期」ではなく端的に禁じる)。
- **agent-prompt 編集なし。** `product-manager.md`、`architect.md`、
  `orchestrator.md`、`implementer.md`、または Critic agent 散文の変更なし。
  SKILL.md が単一ソース; orchestrator/product-manager はそれを既存の
  `## Development Workflow` step 3 ルート (すでに verification-layer Skill を
  名付けている) 経由でポリシーコンテキストとして読む (Spec Target-users
  行 3 / User-story 行 4)。
- **Roadmap row 変更なし。** Row #11 の `Design source` セルは `spec:`
  のみのまま ── これは ADR-014 amendment であり、ADR-014 は自身の
  マイルストーン row を持たないので、row #11 に `adr:` リンクは追加しない
  (Milestone → ADR は 0:1; #07、#08、#09、#10 amendment の row 推論と同一)。
  `product-manager` が step-6 品質ゲート通過後に #07 遷移マトリクスに従い
  row グリフを `◐→☑` に flip する; `architect` はここで `adr:` リンクを
  追加しない。(ADR-014 の write-ownership により `architect` が `adr:`
  リンクを追加するのは *新しい* ADR が作成された場合のみ; row を所有しない
  ADR-014 への amendment は追加しない ── #07-#10 の前例。)
- 本 ADR の日本語版 (`014-roadmap-index-single-entry-point.ja.md`) は
  **この同一セッションで** ミラー amendment を受け取る (このタスクが
  編集する ADR の architect 所有 ADR JA 兄弟パリティ; レポート参照)。
  CLAUDE.md の日本語版 (存在する場合) と JA Spec 兄弟
  (`specs/11-…ja.md`) は `technical-writer` タスクのままで、この変更の
  一部では **ない**。EN↔JA ミラーが同一セッションで着地するため、#06
  bilingual-parity ディテクター (`check-bilingual-parity.sh`) は commit
  時に ADR-014 ペアで一致した見出しツリーを見る ── 本 amendment は
  transient FAIL を導入しない (#07-#10 amendment が JA ミラーを
  `technical-writer` に延期し transient FAIL を受容したのとは異なる;
  ここでのタスク制約は同一セッション ADR JA パリティを要求する)。

### MECE / no-detector / no-new-partition statement (Spec R-01 (d), AC-7, AC-8)

この配置は **新しい CI ディテクターなし**、**本ファイルの §(d) テーブル
(行 1800) と矛盾する新しい MECE パーティションなし** を導入する。#11 は
§(d) テーブルが #11 の Spec が存在する前に既に予約し分類した
`documentation/convention` スロットを *populate* する (行 1800 行; 行 1808
オーナー文); そのテーブルに行を追加せず、#04/#05/#06 のディテクター
ファミリーコントラクトパーティションに 4 つ目のディテクターを追加せず、
新しいキーイングもない。#11 (verification-domain プロジェクト採用ガイダンス、
SKILL.md 散文)、変更単位ランタイムトリガー (`implementation/protocol.md` /
`design/protocol.md` `## When to invoke`)、#04 (`check-dangling-refs.sh`
パス解決)、#05 (`check-roadmap-drift.sh` Roadmap 構造一貫性) の境界は
将来のマイルストーン作者に対して明確なまま: *プロジェクトレベルの
「このドメインを有効化すべきか?」* 質問は #11 の SKILL.md セクション;
*変更単位の「今 Critic が spawn するか?」* 質問は protocol ファイル;
*壊れた散文パス* は #04; *Roadmap-index/グリフ欠陥* は #05。二オーナー
曖昧性は作成されない。

### Counter-proposal

深刻な反対案は **ADR-014 を amend するのではなく新しい ADR-019 を作成する** <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
であり ── ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 の <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
慣例に従い、strawman としてではなく拒否された代替案を真剣に扱う歴史的記録
としてここに残す。論拠: #11 は最初の verification-layer *採用ガイダンス*
マイルストーンである; Skill にこれまで存在しなかった読者向け決定フレーム
ワーク概念 (変更単位トリガーとは区別される「プロジェクト特性トリガー」) を
導入する; 専用の ADR-019 はその概念に単一の引用可能なホームと独自の clean <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
な Counter-proposal スロットを与え、すでに長い ADR-014 の 7 番目の
amendment としてネストするより良い。

**反対案を採用しなかった理由:**

- 決定的な問題は **ADR-018 トライアドが満たされない** ことである。ADR-015、
  ADR-017、ADR-018 はそれぞれ新しいディテクター + 新しい MECE 境界 + 新しい
  キーイングを出荷したからこそ新 ADR 相当と自己分類した。#11 は 3 つの
  **いずれも** 出荷しない (上記条項、Spec 行証拠付き): Spec はディテクターを
  *禁じ* (行 26、113)、パーティションを *追加せず* (§(d) テーブルが既に
  #11 を名付ける)、キーイングを *導入しない* (散文のみ)。ECC 前例自身の
  具体的シグナルが欠如している; 新 ADR は Spec の R-01 が architect に適用
  するよう指示した識別基準と矛盾する。
- 「最初の採用ガイダンスマイルストーン」新規性論はやりすぎである: それに
  よれば #07 (最初の status-ownership)、#08 (最初の Analyze row-guard)、
  #09 (最初のファイル名ピン)、#10 (最初のディレクトリピン) もそれぞれ
  新 ADR を正当化したことになる。4 つすべてが ADR-014 amendment であった
  のはまさにトピックの新規性が識別基準ではない ── *新しい構造的
  メカニズム* がそうである ── からであり、4 つすべて (#11 同様) が
  ADR-014 がすでに所有する境界の帰結を明確化した。直前の 4 つの兄弟決定
  との一貫性が引用可能ホームの利便性を上回る。
- 「単一の引用可能なホーム」の利益は新 ADR なしで実現される: 本 amendment
  *が* その引用可能ホームであり、#11 を名付ける §(d) MECE テーブルと
  同居する ── テーブルとそのスロットを populate する決定を 1 ファイルに
  保つのは分割するより *良い* 簿記であり、ADR-018 が三方向コントラクト
  パーティションに用いたのと同じ局所性論である。

**この反対案を再評価するトリガー条件 (すなわち ADR-019 が正当化される <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal, intentionally never created -->
とき):**

- 将来のマイルストーンがフォークが有効化した verification ドメインを
  監査または強制する **CI ディテクター** を追加する (#11 の Spec が
  まさに禁じるもの) ── そのディテクター + その MECE 境界 + そのキーイングが
  トライアドを満たし独自の ADR を正当化する (ADR-014 amendment ではなく、
  #11 を遡及的に再分類するのでもない)。
- プロジェクト採用ガイダンスが散文を超える **新しい構造的規約** を要求
  すると判明する ── 例えば agent が Analyze 時にパースする機械可読な
  capability-to-domain マッピング ── メカニズムとキーイングルールを導入し
  トライアドを満たす。
- §(d) MECE テーブルが再構成され #11 の `documentation/convention`
  スロットがもはや存在しないか再描画され、本 amendment が populate する
  事前予約境界が除去される ── その時点で #11 のホームはパーティションと
  ともに再検討される。

反対案は ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 の
慣例に従い、決定の最も深刻な異論の歴史的記録として本 amendment に残る。

元のステータス行 (`Accepted — 2026-05-15`) は変更しない; 本 amendment は
ADR-014 自身の §(d) MECE テーブルが #11 のために事前予約したスロットを
populate する配置決定を記録するものであり、決定を再開するものではない
(ADR-010 の決定も再開せず、逐語的に維持する)。

## Amendment — 2026-05-20 (品質ゲートループ再エントリのロードマップ行アンカー)

本 amendment は 2026-05-17 の status-transition 所有権マトリクスの
`◐ in-progress → ☑ done` 行の失敗パス逆命題を閉じる。そのマトリクスは
**成功パス** (`product-manager` が所有する、step-6 品質ゲート **合格** 後の
`◐→☑`) を認可した。ゲート中に 1 つ以上の品質ゲートエージェントが
CRITICAL または HIGH の指摘を返す場合に何が起きるかは **述べていなかった** ――
実践的にはすべての先行マイルストーンが実施してきたにもかかわらず、いかなる
正式規則も名付けなかった fix-and-re-review ループ。
`specs/21-quality-gate-row-anchor.md` (ロードマップ行 #21) が権威あるスコープであり、
構造的な *how* を `architect` に委任する (Risk R-01 (a)-(d))。本 amendment は
その決定を記録する。これは **2026-05-17 の status-transition マトリクスの
帰結明確化** であり、新しい構造的決定ではない: マトリクスの `◐→☑` 行は
すでにゲート合格トリガーを述べており; #21 はゲートが *まだ* 合格していない
間に何が保持されるかを名付ける。新しいディテクター、境界、キーイング、
またはメカニズムは導入されない。本 ADR の 2026-05-16、2026-05-17 (×5)、
2026-05-20 (ADR-006)、2026-05-20 (ADR-011) の各 amendment が適用した
ECC 前例 ("帰結明確化は amendment に折り込む; 新 ADR 番号は新しい構造的
決定のために予約する" — ADR-015 §Context、ADR-017/ADR-018 Alternative B)
に従い、これは ADR-014 amendment であり、**ADR-023 ではない**。ADR-023 は作成されない; ロードマップ行 #21 は <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal; it is intentionally never created (see Counter-proposal below) -->
`(amended 2026-05-20)` アノテーション付きで ADR-014 への `adr:` リンクを取得し、
行 #19/#20 の amendment 引用形状を踏襲する一方、ADR-014 には独自のマイルストーン
行がなく、そのため #21 の `Roadmap row:` 行を持たない ── 行バックリンク
コントラクトは一方向 (行 → amendment) であり、対応するロードマップ行を
`spec:` のみで残した #07/#08/#09/#10/#11 の amendment 前例と整合する。

(#21 の行が本 amendment で `adr:` リンクを受け取るのは、Spec AC-9 が、
新 ADR が発行された場合に `adr:` リンクが ADR を指すことを明示的に要求するためであり、
明示的なロードマップ行帰属を持つ amendment は引用目的において行バインド ADR の
実質的等価物だからである。#07/#08/#09/#10/#11 の行が `adr:` リンクを受け取らなかったのは
それらの Spec がその受け入れ基準を述べなかったためであり; #21 の Spec は述べている。
コントラクト表面 ── "行は構造的解決の源を指す" ── は両方の形状で等価に満たされる。)

### Triad classification — 0/3, amendment-not-new-ADR

Spec は `architect` に ADR-018 Alternative-B トライアド識別子 (新しいコントラクト
境界 + 新しいキーイング/メカニズム + 新しい構造的アーティファクト ⇒ 新 ADR;
既存コントラクト内の帰結明確化 ⇒ amendment) を渡す。#21 に条項ごとに適用:

- **新しいコントラクト境界? いいえ。** 上記 2026-05-17 の #07 status-transition
  amendment (行 415-425) はすでに `◐→☑` トリガー条件を逐語的に確立している:
  "マイルストーンの Workflow step 6 品質ゲートが合格した後 … `product-manager`
  … がフリップを実行する; 他のロールはできない。" #21 の行アンカー不変条件
  (Spec AC-2) はその既述の成功条件の **論理的逆** である: ゲートがまだ
  合格していない間は (1 つ以上の CRITICAL/HIGH 指摘がオープン)、行遷移は
  起きない。これは既述のトリガーの帰結明確化であり、新しいコントラクト境界
  ではない。再エントリルーティング (Spec AC-1: `orchestrator` が修正を
  `implementer` にルーティングする) は、ADR-014 がすでに確立した Workflow
  コントラクトを持つロール ── `orchestrator` は Analyze/ルーティング権威 (#08
  amendment 行 716-760)、`implementer` は同じマイルストーンの Spec 内の修正を
  含む step-5 実装を所有する (ロール変更なし) ── にマップされる。
  新しいロール、新しい所有権概念、新しいコントラクト表面はない。
- **新しいキーイング / メカニズム? いいえ。** ループが管理されるメカニズムは
  #07 amendment がすでに所有する **同じ Status glyph セル** であり、誰がいつ
  書くかを文書化する同じ `## Roadmap` Rules ブロックである。Spec は
  "品質ゲートループコンプライアンスのための新しい CI ディテクターの追加" (非目標) と
  "一般的なワークフロー状態機械エンジンの設計" (非目標) を明示的に禁止する。
  Spec R-01 (d) は CI ディテクターの必要性を `architect` に委任する; 本 amendment
  の判断は **ディテクターなし** (下の §(d) 参照)。新しい YAML キー、新しい
  regex、新しいファイル形式、新しいショートサーキット、新しいディテクターはない。
  既存の `check-roadmap-drift.sh` (#05) glyph 値正確性チェックが Status セルへの
  唯一の自動タッチとして残る ── #05 に対する MECE 境界 (#07 Rules ブロック
  bullet がすでに述べた "no CI enforces #07") は #21 に対して変更なしで延長される。
- **新しい構造的アーティファクト? いいえ。** 新しいファイル、新しいディレクトリ、
  新しい CI ワークフロー、新しいエージェントロール、新しい Skill、新しいテンプレート、
  新しいワークフローステップはない (Spec 非目標: "品質ゲートループはすでに
  step 6 に暗示されている; #21 は新しいステップ番号ではなくそのステップ内の
  所有権とアンカー不変条件を名付ける")。配置先は #07 amendment が populate した
  CLAUDE.md の同じ `## Roadmap` Rules ブロックであり; アーティファクトは新しい
  セクション、テーブル、またはサブ見出しではなく 1 つの追加された Rules-block
  bullet である。Spec AC-7 は 7 つの正規ディテクターすべてを green と要求し;
  AC-8 は 8 つの正規テストスイートすべての合格を要求する ── 新しいディテクター/
  テストが正規セットに加わらないことの明示的な Spec 確認。

トライアド合計: **0/3**。ADR-018 Alternative-B (および同じ識別子を適用した
ADR-022 §1 / ADR-006 amendment 2026-05-20 / ADR-011 amendment 2026-05-20)
に従い、0-2/3 は新 ADR ではなく **既存 ADR の amendment** にルーティングされる。
ADR-022 の "new-ADR-vs-amendment" 推論は、トライアドが新 ADR を正当化するには
3/3 が必要と明示する; #21 の 0/3 はファミリー内で最強の amendment ケースである
(#19 の 1/3 および #20 の 1/3 より強い、なぜなら #21 は新しいコントラクト方向を
文字通り何も導入せず、本 ADR 自身の内部にすでにある 1 つの逆命題のみだから)。
新しい ADR-023 が <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->
検討され (Spec AC-6 はそれを OR の一方の枝として名指しする)、却下された: <!-- ref-allow: counterfactual reference; ADR-023 deliberately not issued per triad 0/3 outcome | expires: 2026-07-20 -->
解決を ADR-014 自身に折り込むことで、4 行の Status-Transition マトリクスと
その逆命題文 (行アンカー不変条件) が単一の真実の源に共置され、
#07/#08/#09/#10/#11 amendment 形状と正確に一致し、Roadmap メカニズム
コントラクトの 2 つの ADR への断片化を回避する ── #07 amendment 反対案の
行 599-607 が成功方向マトリクスの別個の ADR-019 を却下するために使用した
同じ推論。 <!-- ref-allow: ADR-019 is the deliberately-rejected counter-proposal for the #07 success-direction matrix; intentionally never created -->

### The row-anchor invariant and re-entry routing rule

正確に 2 つの補完的なステートメント、どちらも 2026-05-17 status-transition
マトリクスの `◐→☑` 行の帰結:

**行アンカー不変条件 (Spec AC-2 / AC-3)。** `◐ in-progress` のロードマップ行は、
1 つ以上の step-6 品質ゲートエージェント (`code-reviewer`、`linter`、
`security-reviewer`、`performance-engineer`) からの CRITICAL または HIGH の
指摘がオープンである間、`◐ in-progress` に留まる。いかなるアクターも
ループが進行中に `☑`、`✗`、または `☐` にフリップしない。`◐→☑` 遷移は、
そのマイルストーンに対してすべての品質ゲートエージェントが合格した **ときにのみ
1 度だけ** 発火する ── 出口条件であり、ループ中間アクションではない。
`◐→✗` 遷移は `orchestrator` が確認したドロップ決定 (マトリクス行 3、変更なし)
のみで発火する。

**再エントリルーティング (Spec AC-1)。** いずれかの品質ゲートエージェントが
1 つ以上の CRITICAL または HIGH の指摘を返す場合、**orchestrator** が名指しの
ルーティング所有者である: 修正タスクを `implementer` にルーティングし直し、
再レビューを開始する。他のエージェントが orchestrator のルーティングなしに
修正を自己割り当てしない; 品質ゲートエージェントが orchestrator のルーティング
なしに自己ループバックしない。`implementer` は同じ Spec に対して修正アクションを
所有し、`implementer` が修正完了を報告したとき同じ品質ゲートエージェントが
再レビューする。すべての CRITICAL/HIGH 指摘が解決されるまで (ゲート合格 ⇒
マトリクス行 2 に従う `◐→☑` に適格) またはマイルストーンがドロップされる
(`◐→✗` マトリクス行 3 に従う) まで、サイクルが続く。

**名付けられていなかった "ループ所有者" の曖昧性の解決 (Spec R-01 (a))。**
暫定プラクティスはルーティング所有者を暗黙にしていた。本 amendment は
それを **名指しのロール: `orchestrator`** に解決する。ADR-014 の #08 amendment が
Analyze ステップのプレディスパッチ (G1-G3 ガード) のためにすでに確立した
ルーティング権威。#08 に対する MECE 境界は精確: #08 は **初期ディスパッチ**
の **プレディスパッチ** 前提条件 (行は存在するか? Spec はディスク上にあるか?
progress ファイルは表面化されたか?) を管理する; #21 は品質ゲートエージェントが
すでに実装をレビューして指摘を返した後に発火する **ポストディスパッチ再ルーティング**
を管理する。同じルーティングロール、2 つの非重複トリガーポイント、
所有権のギャップなし (下の §(d) を参照して明示的な境界文を確認)。

**ADR-016 との結合可能性 (Spec AC-4)。** ADR-016 の `specs/NN-progress.md`
メカニズムは、`◐ in-progress` 中のセッションまたはコンパクション境界によって
トリガーされ、品質ゲートループラウンドによってではない。単一セッション内で
完了するループは progress ファイルを作成しない (境界を越えないため); セッション
終了時にループが進行中の場合は両方のメカニズムが起動する (ループが境界を越えて
続く; progress ファイルが再開エージェント向けにループ中間状態を捕捉する ──
Spec R-02 は `progress-template.md` の `## Notes` フィールドのループ状態を
記録するための自然な拡張を名付ける、これは step 5 での実装者詳細であり ADR 層
メカニズムではない)。2 つのメカニズムは異なるトリガーで動作し非重複である。

**2026-05-17 の #07 マトリクスとの結合可能性。** #21 の行アンカー不変条件は
マトリクス行 2 の成功トリガー条件の逆命題である: 一緒に `◐→☑` 境界の
完全な MECE 図を形成する。マトリクス行 2 は `◐→☑` が **いつ** 認可されるかを
述べ (ゲート合格); #21 は **いつ** 禁止されるかを述べる (ゲートはまだ合格
していない)。重複なし、ギャップなし。マトリクス行 3-4 (`◐→✗` / `☑→✗`) は
影響を受けない; #21 の不変条件はオープンループ中の `◐→☑` 方向のみに適用される。

### Documentation placement (Spec R-01 (a))

正式化された再エントリルールと行アンカー不変条件は、**CLAUDE.md の `## Roadmap`
Rules ブロック** に 1 つの追加された bullet として存在し、Development Workflow
セクションにも、エージェントプロンプトに複製されることもない。根拠 (#07/#09
amendment が適用した同じ 3 ステップ論拠、#21 に延長):

- Rules ブロックは **インデックス隣接かつコンパクション耐久性を持つ**: すべての
  エージェントがすべてのステップで読む Roadmap テーブルの直下に位置する
  (Invariant 2)、そのため `orchestrator` と `implementer` は再エントリルールと
  行アンカー不変条件に、修正をルーティングするかフリップを実行するまさにその
  ステップで、**追加のファイル読み込みゼロで** 遭遇する ── Spec の R-01 (a)
  受け入れ基準 ("step 6 を実行するエージェントが追加のファイル読み込みなしで
  遭遇するよう文書化")。
- **CLAUDE.md 行数ガイダンスを尊重する最も厳密な配置** である: Rules ブロックは
  Roadmap セクションの *内部* であり、それはすでに認可された行数例外 (本 ADR の
  2026-05-16 行数 amendment)。すでに免除されたセクションへの 1 つの追加
  bullet は他の場所でバジェットを消費しない; `## Development Workflow` step 6 に
  散文を追加すると非免除セクションを膨らませ、マトリクスをその逆命題から
  分断することにもなる (一方は Rules ブロック内、他方は Workflow 散文内) ──
  本 ADR が除去するために作成された "どのドキュメントが権威あるか" の
  再発見問題そのもの。
- **マトリクス隣接** である: 行アンカー不変条件は既存の #07 bullet の
  `◐→☑` 句の逆命題である。成功方向 bullet の 1 つ下に逆命題を置くことで、
  同じマトリクス行の 2 つの側面が共置され、#07 amendment が確立した
  "ロードマップセルをフリップできる者の単一の真実の源" 特性を満たす。

`orchestrator.md` Workflow step 散文へのルール配置が検討された (Spec R-01 (c)
代替); 却下: (i) ルールは 4 つのロール (`orchestrator` がルーティング、
`implementer` が修正、品質ゲートエージェントが再レビュー、`product-manager` が
*早まってフリップしない*) を制約する ── 1 つのロールのプロンプトに置くと、
4 つすべてにわたる複製 (ドリフト面) か、4 つのうち 3 つのロールが別のロールの
プロンプトを読んでルールを発見することが必要になる (常時可読不変条件に違反);
(ii) Rules ブロックと同じ方法でコンパクション耐久性を持たない (Invariant 2)、
セッションごとに再読み込みを強制する; (iii) #07/#08/#09/#10/#11 amendment が
同じ Roadmap メカニズムルールファミリーのために確立した規律を逆転させる ──
すべての先行 amendment がエージェントプロンプトではなく Rules ブロックに
ルールを配置した。

正確な 1-bullet 文言は下の `implementer` に渡す; #08 G1-G3 に対する MECE
境界 (Spec AC-5) と ADR-016 に対する MECE 境界 (Spec AC-4) は bullet 内で
再述されるので、将来のマイルストーン著者が再エントリの質問を #08 に、
progress ファイルの質問を #21 にルーティングしない。

### Spec R-01 (b)(c)(d) judgements recorded for the implementer

- **(b) Amendment vs new ADR:** ADR-014 amendment (トライアド 0/3、上記で決定)。
  ADR-023 なし。行 #21 Design-source セルは #19/#20 amendment 引用形状で <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->
  `adr:` リンクを取得:
  `<br>adr: \`.claude/meta/adr/014-roadmap-index-single-entry-point.md\` (amended 2026-05-20)`。
  これは Spec AC-6 の枝 (b) ("既存の ADR がそれらの質問に明示的に対処する
  amendment を受け取る") と AC-9 ("新しい ADR が発行された場合、`adr:` リンクが
  … `023-*.md` に解決する") を満たす ── `adr:` リンクは構造的解決を持つ ADR
  (ここでは修正された ADR-014) に解決し、それは AC-9 がエンコードする
  実質的コントラクトである。
- **(c) エージェントプロンプト影響:** **エージェントプロンプト編集不要。**
  再エントリルールはルーティングを ADR-014 の #08 amendment がすでに確立した
  ルーティングコントラクトを持つロール (`orchestrator` が Analyze ステップ
  ルーティングを所有する) に割り当てる。`implementer` はすでに Workflow step 5
  実装を所有し、同じマイルストーンの Spec 内の修正を含む ── ロール変更なし。
  4 つの品質ゲートエージェントはすでに step-6 レビューを所有する (`.claude/CLAUDE.md`
  §Development Workflow step 6、変更なし); 再レビューアクションは初期ディスパッチで
  実行するのと同じアクションであり、単に再ルーティングされた入力に対して。
  `product-manager` はすでに ADR-014 §Decision および #07 マトリクスに従って
  行書き込みを所有する; 行アンカー不変条件は `product-manager` がすでに唯一の
  所有者である書き込みの *いつ* (方法や誰ではない) を制約する。常時読み込み
  Rules ブロックにルールを記録する (プロンプトではなく) のは意図的な
  最小表面の選択であり、#07/#08/#09/#10/#11 amendment がエージェントプロンプトから
  変更を除外した一貫性と合致する。
- **(d) CI ディテクター必要性:** **ディテクターは不要。** 3 つの理由:
  1. **検出は存在しない監査ログインフラを要求する。** "CRITICAL/HIGH 指摘が
     オープンな間に `☑` にフリップされた行" インシデントは、CI が glyph を
     フリップしたコミットに対して品質ゲートエージェントの過去の指摘を
     読めるときにのみ検出可能。テンプレートにそのような監査ログはない;
     サブエージェントの指摘はエフェメラルなセッションアーティファクトであり、
     コミットされない。そのインフラを構築することは #21 のスコープをはるかに
     超える (Spec 非目標: "品質ゲートループコンプライアンスのための新しい CI
     ディテクターの追加 … 存在しないスコープ外の監査ログインフラを要求する")。
  2. **#05 はすでに glyph 値正確性を所有する (直交するチェック軸)。**
     `check-roadmap-drift.sh` は各 Status セルが 4 つの認可された glyph
     (☐ / ◐ / ☑ / ✗) のいずれかを保持することを検証する。それが Roadmap
     メカニズムが実行できる静的チェックである。#21 のプロセスルール (誰がいつ、
     どのゲート状態でフリップしたか) は動的であり #05 が所有する静的アーティファクト
     コントラクトの外にある。#07 amendment の Rules-block bullet はすでにこの
     MECE 境界を逐語的に述べている ("#05 は glyph *値* 正確性をチェックする;
     #07 は *誰が* いつフリップするかを管理する ── CI は #07 を強制しない");
     #21 の bullet は対称性のために再述された同じ境界を継承する。
  3. **プロセスディテクターはディテクターファミリーの規律にない。** 既存の
     7 つのディテクター (#04 dangling-refs、#05 drift、#06 bilingual-parity、
     ADR-022 ref-allow-expiry、#14 research-tier-auth、ECC-delegation-consistency、
     skill-invariants) はすべて **静的アーティファクトコントラクト** を強制する
     (ファイルが存在する / ポインタが解決する / 見出しシーケンスが一致する /
     glyph が 4 文字のいずれかである)。動的プロセスコンプライアンス (どのサブ
     エージェントレビューラウンド中に行をフリップしたか) を監査するディテクターを
     追加すると、新しいディテクターカテゴリを導入し、ファミリーの
     locality-of-behavior 規律を破る。Spec AC-7 は正規セットを 7 つに明示的に
     制限する; プロセスルールのための 8 番目のディテクターを追加すると
     Spec AC-7 が閉じるコントラクトを拡張する。

  この判断は #07 amendment のディテクターなし判断 (行 543-545: "CI ワークフロー
  なし (Spec 非目標; #07 はプロセス/文書割り当てであり自動チェックではない)")
  と対称であり、ファミリー内で最強のそのようなケースである (監査ログインフラ
  なしでは自動強制は理論的にも達成不可能)。

- **(d) claude-md-authoring Skill 必要性:** CLAUDE.md 編集の延期は
  **既存の `## Roadmap` Rules リストへの 1 bullet 追記** であり ── CLAUDE.md の
  `## CLAUDE.md authoring guidance` セクションの明示的なカーブアウト
  ("Routine small edits (typo, single bullet, version bump) do not need the Skill")
  による "ルーティン小規模編集 (…single bullet…)"。これは "重要な再構成"
  ではない (セクション追加/移動/分割なし、見出し変更なし、不変条件タッチなし)。
  **判断: #21 実装編集に対して claude-md-authoring Skill は不要。**
  (もし実装者が代わりにサブ見出しやテーブルを追加することを選択した場合、それは
  再構成に入り込み Skill が適用される ── しかしここでの設計は正確にルーティン
  編集カーブアウトの下に留まるための意図的な単一 bullet であり、#07/#09
  amendment を踏襲する。)

### MECE boundary statement against #07 / #08 / #04 / #05 / ADR-016 (Spec R-03, AC-4, AC-5)

再エントリルールは境界を再描画することなく既存のパーティションに適合する:

| 所有者 | 質問 | トリガーポイント |
|---|---|---|
| #07 (上記 amendment) | ロードマップ Status glyph をフリップできる者はだれか、いつ各遷移が発火するか? | 遷移イベント自体 (成功パス: ゲート合格; ドロップパス: orchestrator 確認ドロップ) |
| #21 (本 amendment) | ディスパッチと `◐→☑` フリップの **間** に 1 つ以上の品質ゲートエージェントが指摘を返す場合に何が保持されるか? | step-6 レビューが CRITICAL/HIGH 指摘を返した後、すべてのゲートエージェントが合格する前 |
| #08 (上記 amendment) | いずれかのサブエージェントが最初にディスパッチされるために満たされなければならない前提条件は何か? | orchestrator の Analyze ステップ、プレディスパッチ |
| #04 `check-dangling-refs.sh` | すべてのクロスリファレンスポインタが解決するか? | 静的アーティファクトスキャン、常時オン CI |
| #05 `check-roadmap-drift.sh` | 各 Status セルが認可された glyph 値であるか、双方向 Roadmap インデックスコントラクトは intact か? | 静的アーティファクトスキャン、常時オン CI |
| ADR-016 `specs/NN-progress.md` | インフライト状態はセッションまたはコンパクション境界を越えるか? | `◐` 中のセッション/コンパクション境界 |

欠陥はちょうど 1 つの所有者にマップする: 指摘後のルーティング決定の欠如 ⇒ #21;
glyph 文字ミスマッチ ⇒ #05; 壊れたポインタ ⇒ #04; プレディスパッチ前提条件
失敗 ⇒ #08; フリップ自体の所有権とタイミング ⇒ #07; クロスセッション状態
キャリー ⇒ ADR-016。Spec の AC-5 (#08 との境界) と AC-4 (ADR-016 との境界) は
尊重される: #08 のトリガーポイントはプレディスパッチ (G1-G3 はいずれかの
サブエージェントがタスクを受け取る **前** に発火する); #21 のトリガーポイントは
ポストレビュー (サブエージェントはすでに指摘を返している **後**)。同じ
`orchestrator` ロールが両方のルーティング決定を所有するが、トリガーポイントは
時間的に入力的に非重複である。

### Composability with #13 (ECC-absent degraded-review signal — Spec Key Interaction 4)

#13 は、対応する ECC `<lang>-reviewer` Skill がフォークに存在しない場合に
デグレードレビュー警告を発する ── 言語深度カバレッジは低減されるがレビューは
続行する。#21 の再エントリルールは指摘の **生成** ではなく **ルーティング** を
管理する。#13 が発火するとき、`code-reviewer` はメタレビューロールを引き続き
所有し指摘を返す (一部 CRITICAL/HIGH、一部は存在しない Skill によりダウングレード);
それらの指摘が届いたとき、#21 の再エントリルーティングは変更なく適用される ──
orchestrator は指摘が完全またはデグレードレビューから来たかどうかに関わらず
修正を `implementer` にルーティングする。2 つのマイルストーンは **非干渉**:
#13 は再エントリルーティングや行アンカー不変条件を変更しない; #21 は
デグレードレビューシグナルを変更しない。Spec Key Interaction 4 のステートメントは
逐語的に保持される。

### Downstream `implementer` tasks (performed in this same session — for #21 the two-session decision-then-implementation split used by #03/ADR-016 · #05/ADR-017 · #06/ADR-018 · #07/ADR-014-amendment · #08/ADR-014-amendment · #09/ADR-014-amendment · #10/ADR-014-amendment was deliberately collapsed; the rationale matches #11's collapse: #21's implementation is a single prose-only Rules-block bullet edit, fully enumerated below and verifiable against Spec AC-1 / AC-2 / AC-3 / AC-4 / AC-5 in one pass, requiring no separate review cycle; the task list is retained verbatim for traceability and as the precedent shape for milestones whose implementation *is* deferred)

- `.claude/CLAUDE.md` の `## Roadmap` **Rules** ブロック ── 既存の #07
  status-glyph-transitions bullet の後に 1 つの bullet を追記:
  *"品質ゲートループ再エントリ (#21): 行が `◐ in-progress` であり、いずれかの
  step-6 品質ゲートエージェント (code-reviewer、linter、security-reviewer、
  performance-engineer) からの 1 つ以上の CRITICAL/HIGH 指摘がオープンである間、
  `orchestrator` は修正タスクを `implementer` にルーティングし直し、行は
  ループ全期間 `◐` に留まる。`◐→☑` フリップは #07 に従い、そのマイルストーンの
  すべての品質ゲートエージェントが合格した後のみ発火する ── ループの出口条件であり、
  ループ中間アクションではない。ADR-016 progress ファイルはループがセッションまたは
  コンパクション境界を越える場合のみ適用される; インセッションループは
  progress ファイルを作成しない。#08 G1-G3 は初期ディスパッチ (プレディスパッチ) を
  管理する; #21 は品質ゲートエージェントが指摘を返した後の再エントリ (ポストレビュー)
  を管理する ── 非重複トリガー、同じ `orchestrator` ルーター。CI は #21 を
  強制しない (プロセスルール; #05 は glyph 値正確性を所有し、直交するチェック軸)。"*
  単一 bullet、サブ見出しなし、テーブルなし ── ルーティン編集カーブアウト内に
  留まる (claude-md-authoring Skill 起動不要)、正確に #07 amendment 形状。
- `.claude/CLAUDE.md` の `## Roadmap` テーブル行 #21 ── Design-source セルを
  `spec:` のみから以下に:
  `spec: \`specs/21-quality-gate-row-anchor.md\`<br>adr: \`.claude/meta/adr/014-roadmap-index-single-entry-point.md\` (amended 2026-05-20)`。
  これは ADR-014 の既存の書き込み所有権ルール ("architect が `adr:` リンクを
  追加する") に従う `architect` 書き込み; **本 amendment の同じ変更で** 実行され、
  行 #19/#20 のパターンを踏襲して新 ADR ではなく修正された ADR を指す。行の
  Status glyph は `product-manager` が Spec 著作時に `☐→◐` にフリップした
  (#07 amendment が義務付けたアトミックアクション); 本 amendment は glyph に
  触れずに同じ行の `adr:` リンクセルのみを追加する。`product-manager` は
  #07 amendment に従い、step-6 品質ゲートが合格し step 7-9 が完了した後、
  step 6 クローズアウトで `◐→☑` フリップを実行する。
- **エージェントプロンプト編集なし** (上記判断)。実装者は `orchestrator.md`、
  `implementer.md`、`code-reviewer.md`、`product-manager.md`、またはその他の
  エージェントファイルに再エントリルーティング散文を追加して **はならない**;
  Rules ブロックが単一の情報源である。
- **CI ワークフローなし、新ディテクターなし、新テストスイートなし** (上記判断;
  Spec 非目標と AC-7/AC-8)。既存の 7 つのディテクターと 8 つのテストスイートは
  変更なしに合格し続ける。
- **本 amendment では `progress-template.md` 編集なし。** Spec R-02 はセッション
  境界を越える品質ゲートループのループ状態を記録するためのテンプレートの
  `## Notes` フィールドの自然な拡張を識別する; それはその正確なシナリオで
  progress ファイルを著作する際の `implementer` step-5 詳細であり、本 amendment
  が実行するテンプレート変更ではない。現在のテンプレートはすでに自由形式の
  ノートを許可している; ループ状態を `## Notes` エントリとしてエンコードすることは
  既存の表面を変更なしで使用する。
- 本 ADR の日本語版 (`014-roadmap-index-single-entry-point.ja.md`) は
  鏡映 amendment を受け取らなければならず、CLAUDE.md の日本語版 (存在する場合) は
  鏡映 Rules-block bullet を受け取らなければならない ── `technical-writer` の
  タスクであり、本変更の一部ではない。**本 amendment は ADR-014 の JA/EN
  見出しの一時的なミスマッチを生じさせる (`technical-writer` が鏡映するまで);
  #06 bilingual-parity ディテクター (`check-bilingual-parity.sh`) は鏡映が
  着陸するまで ADR-014 で FAIL する。これは期待されるキューに入った
  `technical-writer` タスクであり、本 EN amendment を省略する理由ではない。**
  (同じ一時的状態が #07、#08、#09、#10、#11、#19、#20 の各 amendment で
  順次受け入れられた。)
- `specs/21-quality-gate-row-anchor.ja.md` はロードマップ #06 見出しツリー
  パリティ所有権に従い step 7 で `technical-writer` が著作する;
  本 amendment の一部ではない。
- `CHANGELOG.md` の `## [Unreleased]` 下の品質ゲートループ再エントリ
  正式化を記録するエントリは step 7 で `technical-writer` が著作する
  (Spec AC-10); 本 amendment の一部ではない。

### Counter-proposal

真剣な反対案は **新 ADR-023 ── 品質ゲートループ再エントリルールを ADR-014 <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->
amendment ではなくスタンドアロン ADR として正式化する** である。これは
ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 の、却下された
代替案をストローマンとしてではなく真剣に取り上げる慣例に従い記録する。
論拠:

1. Spec は `architect` に明示的な (b) 選択肢 ("新 ADR-023 が存在する … または <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->
   既存の ADR がそれらの質問に対処する amendment を受け取る") を渡す ──
   Spec AC-6 は ADR-023 を最初の枝として名指しし、#03 / #04 / #05 / #06 / <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->
   #12 / #13 が新 ADR を受け取ったマイルストーンとのパリティを示唆する。
2. orchestrator の失敗パスルーティングを制約する再エントリルーティングルールは
   第一級の引用可能なコントラクトである; 長い ADR-014 トレールの 7 番目の
   amendment として埋めることは、"品質ゲートループ ADR" として引用できる
   専用 ADR-023 より発見しにくくする。 <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->
3. 再エントリパスは複数の ADR と相互作用する (progress ファイル境界を介した
   ADR-016、`◐→☑` 逆命題を介した #07 マトリクス、ルーティングトリガー MECE
   境界を介した #08、デグレードレビュー互換性を介した #13)。スタンドアロン
   ADR は 4 方向境界ステートメントを明示的に所有でき、2400+ 行の ADR-014 に
   別のセクションを追記するよりよい。

**反対案を採用しなかった理由:**

- ADR-017、ADR-018、ADR-019、ADR-020、ADR-021、ADR-022 はそれぞれ ADR-018
  Alternative-B トライアドで 2/3 または 3/3 スコアで新 ADR 相当と自己分類した。
  #21 は **0/3** をスコアする ── ファミリー内で最強の amendment ケース (新しい
  コントラクト境界なし、新しいキーイング/メカニズムなし、新しい構造的アーティファクト
  なし)。兄弟対称性論拠は検査すると逆転する: #03/#04/#05/#06/#12/#13 が
  自身に使用した同じトライアド識別子を適用すると、#21 について "amendment"
  が出る、なぜなら彼らにとって支配的だった構造的半分が #21 では完全に
  不在だから ── ルールは ADR-014 自身がすでに述べる成功パストリガーの
  失敗パス逆命題 (まさにこれが延長する amendment 内) である。これは正確に
  #07/#08/#09/#10/#11 amendment が別の ADR-019 番号を拒否するために使用した
  推論であり、#19/#20 amendment が 1/3 で再適用した。
- 発見容易性は ADR-014 amendment として *より良く*、悪くない: 4 行の
  Status-Transition マトリクスとその逆命題文 (行アンカー不変条件) は 1 つの
  ファイルに属し、2 つにではない。"step 6 中のロードマップ行の Status を
  管理するものは何か" を読者が探す正規の場所は、Roadmap を定義し成功方向
  トリガーをすでに述べる ADR; 別個の ADR-023 はマトリクスを 2 つの ADR <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->
  に *断片化する* ── orchestrator は `◐→☑` の完全な図を知るために
  ADR-014 *と* ADR-023 の両方を読む必要があり、ADR-014 が除去するために <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->
  存在する "どのドキュメントが権威あるか" の再発見問題を再導入する。
- 双方向バックリンク論拠は新 ADR なしで満たされる: 本 amendment は
  `(amended 2026-05-20)` アノテーション付きで行 #21 の `adr:` リンクを
  #19/#20 形状で populate し、AC-9 が要求する引用表面を行に与える。
  ADR-014 には独自のマイルストーン行がないため、バックリンクは正しく
  一方向 (行 → amendment) であり、#07/#08/#09/#10/#11 の前例と整合する。
- 4 方向境界論拠は ADR-014 amendment として *より良く*、悪くない: #08
  (ルーティングトリガー MECE 境界パートナー) 自体が ADR-014 amendment であり、
  #07 マトリクス (成功方向パートナー) 自体が ADR-014 amendment である。
  ADR-014 に 4 方向境界を述べることで 4 つの境界パートナーすべてが 1 つの
  ファイルに保持される; 別個の ADR-023 では境界が ADR-014 の 3 つのセクションを <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->
  行範囲でクロス引用しなければならない ── 局所性論拠は amendment の方向に
  厳密に働く。

**この反対案を再評価するトリガー条件 (すなわち ADR-023 が正当化されるとき):** <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal, intentionally never created -->

- 将来のマイルストーンが品質ゲートループコンプライアンスを静的に監査する
  **CI ディテクター** を追加する ── 例えば各サブエージェントの指摘とそれに
  続くコミットを記録する監査ログメカニズム、および未解決の CRITICAL/HIGH
  指摘を古くするコミットより `◐→☑` フリップをフラグするディテクター。
  そのディテクター + #05 の glyph 値チェックに対する MECE 境界 + キーイング
  ルールはトライアドを満たし独自の ADR を正当化する (本 amendment のプロセス
  ルールをその継承ベースラインとして)。
- 品質ゲートループが process bullet を超える **新しい構造的メカニズム** を
  必要とすると判明する ── 例えば再エントリ時に orchestrator がパースする
  マシン読み取り可能なマイルストーンごとのゲート状態マニフェスト、または
  `◐` 内に名付けられたサブ状態を持つ品質ゲート状態機械。そのようなメカニズムは
  新しいキーイングルールと新しいアーティファクトを導入し、トライアドを満たす。
- 4 方向境界ステートメント (#21 vs #07、#08、#04、#05、ADR-016、#13) が
  フォークプロファイルごとに分岐した再エントリセマンティクスを必要とすると
  判明する (例えば 1 つ以上の品質ゲートエージェントをドロップするフォークが
  異なるルーティングルールを必要とする) ── その時点では ADR-014 の単一ルールが
  それを表現できず、専用 ADR のプロファイルごとルーティングマトリクスが
  正当化される。

反対案は ADR-012 / ADR-014 / ADR-015 / ADR-016 / ADR-017 / ADR-018 の
慣例に従い、決定の最も深刻な異論の歴史的記録として本 amendment に残る。

元のステータス行 (`Accepted — 2026-05-15`) は変更しない; 本 amendment は
2026-05-17 status-transition amendment が成功パスですでに認可した所有権ルールの
失敗パス逆命題を記録するものであり、決定を再開するものではない。
