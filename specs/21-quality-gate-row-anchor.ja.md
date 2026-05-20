# 品質ゲートループ再エントリのロードマップ行アンカー

## Status

Approved

**Owner:** product-manager / implementer
**Target release:** template v3.10.0

## Problem

Development Workflow (`.claude/CLAUDE.md` §Development Workflow step 6) は、
code-reviewer、linter、security-reviewer、performance-engineer が各マイルストーンの
実装を検証してから進めることができると規定している。これらのエージェントの 1 つ以上が
CRITICAL または HIGH の指摘を返す場合、期待される対応は: `implementer` が問題を修正し、
品質ゲートエージェントが再びレビューすることである。このループはすべての指摘が解決されるか
マイルストーンがドロップされるまで続く。

このループは現在 **非公式で文書化されていない暫定プラクティス** である。正式化された
ワークフローに 3 つのギャップが存在する:

1. **ループ再エントリの名前付き所有者がない。** CRITICAL または HIGH の指摘が
   返された場合、どのロールが fix-and-re-review サイクルを開始するかを宣言するルールが
   ない。orchestrator、implementer、または品質ゲートエージェントのそれぞれが
   もっともらしく行動するかもしれない ── 名前付きルールなしで、各セッションは
   コンテキスト読み取りから正しい所有者を再導出しなければならない。

2. **ループ期間中の行アンカー不変条件がない。** レビュー下のマイルストーンの
   ロードマップ行は品質ゲートループを通じて `◐ in-progress` に留まらなければならない。
   ADR-014 の Status-Transition マトリクス (マイルストーン #07 で正式化されたように) は
   "そのマイルストーンのすべての品質ゲートエージェントが合格する" を条件に `◐→☑` を
   定義する。述べられていないのは逆命題: 行はループが進行中に `☑` ──または他の
   ステータスに── フリップしてはならず、ループは新しいマイルストーンや新しい行では
   なく同じマイルストーンの `◐` 作業の継続として理解される。

3. **ADR-016 に対する MECE 境界がない。** ADR-016 (クロスセッション progress 永続化、
   マイルストーン #03) は `specs/NN-progress.md` を、セッションまたはコンパクション境界
   を越えながら `◐` の状態を生き延びるアーティファクトとして定義する。単一セッション内で
   完了する品質ゲートループは `specs/NN-progress.md` エントリを必要としない。セッション
   境界を越える品質ゲートループは必要とする。この境界は現在暗黙であり; どのルールも
   それを明示的に名付けていない。

orchestrator の Analyze ガード (マイルストーン #08、G1-G3) は **初期ディスパッチ** の
前提条件を対処する: ロードマップ行が存在すること、実装ディスパッチのために `spec:` ファイルが
ディスク上にあること、`◐` 行に対して `specs/NN-progress.md` の欠如が表面化されること。
G1-G3 は **再エントリ** ケースを対処しない: 品質ゲートエージェントが指摘を返し、orchestrator が
`implementer` にルーティングし直さなければならず、元のロードマップ行へのループアンカーが
維持されなければならない。

暫定プラクティスは存在し一貫している ── `implementer` が修正、`code-reviewer` が再レビュー、
行が `◐` に留まる ── しかしそれは文書化されておらず、名前付きでもなく、したがって
step 6 を初めて実行するエージェントには見えない。#21 が提案する正式化はその
プラクティスの文書化であり、動作変更ではない。

## Goals

- 品質ゲートループ再エントリの所有者を名付ける: step 6 から CRITICAL または HIGH の
  指摘を受けたときに修正タスクを `implementer` にルーティングし直し再レビューを開始する
  ロール。
- 行アンカー不変条件を明示的に述べる: レビュー下のマイルストーンのロードマップ行は
  品質ゲートループの全期間 `◐ in-progress` に留まる; ループが終了するまで行遷移は
  行われない (すべての指摘が解決 → `◐→☑`; マイルストーンがドロップ → `◐→✗`)。
- 品質ゲートループ (インセッション反復) と ADR-016 の `specs/NN-progress.md` メカニズム
  (クロスセッション状態永続化) の MECE 境界を定義する: 2 つのメカニズムは競合せず
  補完的であり、いずれかが他方を包含しない。
- #08 の G1-G3 (初期ディスパッチのプレディスパッチガード) に対する MECE 境界を述べる:
  G1-G3 はいずれかのサブエージェントがディスパッチされる前の条件をガードする; #21 の
  再エントリルールは品質ゲートエージェントが進行中の `◐ in-progress` マイルストーン中に
  指摘を返す場合のルーティングと行アンカー動作を管理する。
- 正式化がマイルストーン全体で既に実施された暫定プラクティスを成文化することを確認する
  ── 文書化/所有権割り当てであり、新しいポリシーではない。

## Non-goals

- **4 つの認可された glyph 値 (☐ / ◐ / ☑ / ✗) の変更。** ADR-014 がそれらを所有する;
  本マイルストーンはそれらを変更しない。
- **新しいワークフローステップの追加。** 品質ゲートループはすでに step 6 に暗示されている;
  #21 は新しいステップ番号ではなくそのステップ内の所有権とアンカー不変条件を名付ける。
- **4 つの品質ゲートエージェントのロール割り当ての変更** (code-reviewer、linter、
  security-reviewer、performance-engineer)。それらのロールは確立されており変更されない。
- **品質ゲートループコンプライアンスのための新しい CI ディテクターの追加。** ループ再エントリ
  ルールはプロセス/所有権割り当てであり; 与えられた再レビューが正しい所有者によって
  トリガーされたかを機械的に検証することは存在せずスコープ外の監査ログインフラを必要とする。
  CI ディテクターが正当化されるかは architect に委任される (Risk R-01 参照)。
- **一般的なワークフロー状態機械エンジンの設計。** #07 非目標の前例: #21 は新しい自動化
  レイヤーではなく既存のワークフロー内の所有権を割り当てる。
- **再エントリルールの派生リポジトリエージェント設定への翻訳。** それは #07 と #08 と
  同様、フォーク維持者の責任である。
- **コンプライアンスチェック (step 6a) のトリガーまたは所有権の変更。** マイルストーン
  #20 が step 6a を定義した; #21 はそれを変更しない。

## User stories

| As a... | I want to... | So that... |
|---|---|---|
| orchestrator | 品質ゲートエージェントが CRITICAL または HIGH の指摘を返すときにどのロールにルーティングしなければならないかを知る | CRITICAL/HIGH 指摘を未対処にしたり修正タスクを複数のエージェントに同時に曖昧にルーティングしない |
| implementer | orchestrator によって再ルーティングされたときに修正タスクを所有し、ロードマップ行がその間 `◐` に留まることを知る | 新しいマイルストーンを作成したり行アンカーを失うことなく同じ Spec に対して修正を実装する |
| code-reviewer | 同じロードマップ行への再レビューリクエストが新しいレビューコンテキストではなくループ継続であることを知る | 新鮮スタートレビューではなく同じマイルストーンの AC と先行指摘履歴を適用して修正を評価する |
| product-manager | 行アンカー不変条件が CRITICAL/HIGH 指摘が残る間 `◐→☑` のフリップを保護することを知る | `☑ done` glyph が部分的またはループ中断レビューではなくクローズされた品質ゲートを確実に示す |
| template maintainer | 再エントリ所有権と行アンカー不変条件を単一の名前付きルールで見つける | 先行セッションのトランスクリプトではなくルールを指すことでコードレビューにループ規律を強制する |

## Acceptance criteria

- **AC-1 — 再エントリ所有者の名付け:**
  ロードマップ行が `◐ in-progress` にある **とき**、いずれかの品質ゲートエージェント
  (code-reviewer、linter、security-reviewer、または performance-engineer) が 1 つ以上の
  CRITICAL または HIGH の指摘を返す **場合**、ルールが orchestrator が修正タスクを
  `implementer` にルーティングし直し、`implementer` が修正アクションを所有することを
  指定する **なら** 満たされる。orchestrator のルーティングなしに他のエージェントが
  修正を自己割り当てしない。

- **AC-2 — 行アンカー不変条件の述べ:**
  アクティブな品質ゲートレビュー下にある `◐ in-progress` のロードマップ行が **あり**、
  品質ゲートループが進行中 (fix-and-re-review の 1 つ以上のラウンドが発生したか発生中)
  **の場合**、ロードマップ行がループの全期間 `◐ in-progress` に留まる; ループが
  進行中の間いかなるアクターも行を `☑`、`✗`、または `☐` にフリップしない **なら** 満たされる。
  行は (#07 AC-2 に従い) そのマイルストーンのすべての品質ゲートエージェントが合格した
  ときのみ `☑ done` にフリップされ; (#07 AC-3/AC-4 に従い) ドロップ決定が行われた
  ときのみ `✗ dropped` にフリップされる。

- **AC-3 — #07 AC-2 との互換性 (◐→☑ ゲート条件):**
  #07 で定義された `◐→☑` 条件 ("そのマイルストーンのすべての品質ゲートエージェントが
  合格する") が **あり**、正式化された再エントリルールが適用される **場合**、2 つのルールが
  一貫している: 再エントリルールはすべての CRITICAL/HIGH 指摘が解決されるまでループを
  続けることを要求することで早まった `◐→☑` を防ぐ; `◐→☑` フリップはループの
  **出口条件** であり、ループ中間アクションではない **なら** 満たされる。

- **AC-4 — ADR-016 progress ファイルとの MECE 境界の述べ:**
  品質ゲートループが単一セッション内で実行されていて **あり**、セッションまたは
  コンパクション境界を越えない **場合**、品質ゲートループラウンドが発生しただけで
  `specs/NN-progress.md` は作成されない; progress ファイルはクロスセッション永続化
  (ADR-016 に従い) のために予約される **なら** 満たされる。品質ゲートループが
  セッションまたはコンパクション境界を越えていて **あり**、マイルストーンがその
  境界で `◐ in-progress` のまま **の場合**、ADR-016 境界トリガーが適用される:
  `specs/NN-progress.md` がその境界で `product-manager` または `implementer` によって
  作成 (または更新) され、ループの現在状態をカバーする。2 つのメカニズムは異なる
  トリガーで動作し非重複である **なら** 満たされる。

- **AC-5 — #08 G1-G3 (プレディスパッチガード) との MECE 境界の述べ:**
  orchestrator の G1-G3 ガード (マイルストーン #08) が **初期ディスパッチ** の
  プレディスパッチ前提条件を管理している **とき**、品質ゲートエージェントが進行中の
  `◐` マイルストーン中に指摘を返す **場合**、再エントリルーティング (本マイルストーン)
  が適用可能なルールであり G1-G3 ではない。G1-G3 はディスパッチが始まる前に行、
  Spec、progress ファイルが存在するかをチェックする; #21 の再エントリルールは
  品質ゲートエージェントがすでに実装を受け取りレビューした後に何が起きるかを管理する。
  2 つのルールはトリガーポイントにおいて非重複である **なら** 満たされる。

- **AC-6 — 構造的決定の書面による文書化:**
  architect に委任された構造的質問が **あり** (Risk R-01 参照)、architect が
  設計ステップを完了する **場合**、(a) 新しい ADR-023 が存在し再エントリ所有権 <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal; ADR-014 amended 2026-05-20 was chosen instead (triad 0/3 outcome) -->
  割り当て、行アンカー不変条件、配置、エージェントプロンプト影響を文書化する; または
  (b) 既存の ADR (ADR-014 または ADR-007 または他) がそれらの質問に明示的に対処する
  amendment を受け取る **なら** 満たされる。Spec は architect が取る道を規定しない;
  AC-6 は (a) または (b) のいずれかがディスクに存在し構造的解決を含むときに満たされる。
  architect は ADR-018 Alternative-B トライアド識別子を適用する。

- **AC-7 — 7 つの正規ディテクターすべて EXIT=0:**
  7 つの正規ディテクター (`check-bilingual-parity.sh`、`check-dangling-refs.sh`、
  `check-ecc-delegation-consistency.sh`、`check-roadmap-drift.sh`、
  `check-ref-allow-expiry.sh`、`check-research-tier-auth.sh`、
  `check-skill-invariants.sh`) が **あり**、各々がポスト #21 リポジトリ状態に対して
  実行される **場合**、7 つすべてがコード 0 で終了する **なら** 満たされる。
  本マイルストーンが 8 番目のディテクターを導入する場合、AC-7 はそれを含むよう拡張される。

- **AC-8 — 8 つの正規テストスイートすべての合格:**
  8 つの正規テストスイート (`test-check-bilingual-parity.sh`、
  `test-check-dangling-refs.sh`、`test-check-ecc-delegation-consistency.sh`、
  `test-check-ref-allow-expiry.sh`、`test-check-roadmap-drift.sh`、
  `test-check-research-tier-auth.sh`、`test-coverage-threshold.sh`、
  `test-init-sh-roadmap-cleanup.sh`) が **あり**、各々がポスト #21 リポジトリ状態に
  対して実行される **場合**、既存のテストロジックを変更せずに 8 つすべてが合格する
  **なら** 満たされる。本マイルストーンが 9 番目のテストスイートを導入する場合、
  AC-8 はそれを含むよう拡張される。

- **AC-9 — ロードマップ行 #21 が出荷状態を反映:**
  ポスト #21 コミット **があり**、`.claude/CLAUDE.md` が読まれる **場合**、ロードマップ
  行 #21 が `☑ done` を示し、`spec:` リンクが `specs/21-quality-gate-row-anchor.md`
  に解決し、新しい ADR が発行された場合 `adr:` リンクが `.claude/meta/adr/023-*.md`
  に解決する **なら** 満たされる。

- **AC-10 — CHANGELOG エントリの存在:**
  step 7 後のポスト #21 状態 **があり**、`CHANGELOG.md` が読まれる **場合**、
  `## [Unreleased]` 下のエントリが品質ゲートループ再エントリの正式化を記録する。
  technical-writer が step 7 でこのエントリを著作する **なら** 満たされる。

- **AC-11 — JA sibling 見出しツリーパリティ:**
  step 7 後のポスト #21 状態 **があり**、`specs/21-quality-gate-row-anchor.ja.md`
  が読まれる **場合**、その見出しツリーが EN Spec の見出しツリーと正確に一致する
  (ロードマップ #06 パリティ所有権に従い)。technical-writer が step 7 でこのファイルを
  著作する **なら** 満たされる。

## Key interactions

1. **#07 との相互作用 (ロードマップ status-transition 所有権)。** #07 はすべての
   ゲートエージェントが合格した後に `◐→☑` フリップを品質ゲートクローズアウトアクターに
   割り当てる。#21 の行アンカー不変条件 (AC-2) は補完的なルールである: ループが
   進行中に行が `☑` にフリップしてはならない。2 つのルールは一緒に完全な MECE 図を
   形成する: #07 は `◐→☑` がいつ認可されるかを述べ; #21 はいつ禁止されるかを述べる。
   重複なし、ギャップなし。

2. **ADR-016 との相互作用 (クロスセッション progress 永続化)。** ADR-016 は
   `specs/NN-progress.md` をクロスセッション状態キャリアとして定義し、`◐` マイルストーンが
   セッションまたはコンパクション境界を越えるときに境界トリガーされる。品質ゲートループは
   インセッション反復メカニズムである。AC-4 は MECE 境界を正式化する: ループは
   progress ファイルを作成しない; 境界トリガーがそれを作成する。セッション境界を
   またぐ品質ゲートループは両方を起動する ── ループが続き、progress ファイルが
   再開オペレーター/エージェント向けにループ中間状態を捕捉する。2 つのメカニズムは
   結合可能であり競合しない。

3. **#08 との相互作用 (Orchestrator Analyze 行ガード、G1-G3)。** G1-G3 は
   マイルストーンに対してサブエージェントがタスクを受け取る前に発火するプレディスパッチ
   ガードである。AC-5 は MECE 境界を正式化する: G1-G3 は初期ディスパッチ時に発火する;
   #21 の再エントリルールは品質ゲートエージェントがすでにレビューして指摘を返した後に
   発火する。トリガーポイントは非重複。G1-G3 がすべて合格してマイルストーンがディスパッチ
   されると、G1-G3 はそのロールを完了した; #21 はそのマイルストーンが必要とする可能性のある
   後続の品質ゲートループラウンドを管理する。

4. **#13 との相互作用 (ECC 不在デグレードレビューシグナル)。** マイルストーン #13 は
   ECC `<lang>-reviewer` Skill が不在の場合のシグナルを定義した: code-reviewer は
   デグレードレビュー警告を発し、言語深度カバレッジが低減されていることを人間レビュアーに
   知らせる。#21 の再エントリルールは ECC Skill が存在するかどうかに関わらず適用される ──
   ループ所有権と行アンカー不変条件はデグレードと完全カバレッジ両方の状態で保持される。
   #13 は再エントリルーティングや行アンカー不変条件を変更しない; #21 はデグレードレビュー
   シグナルを変更しない。2 つのマイルストーンは非干渉。

5. **構造的 HOW は architect に委任。** 再エントリルールが `orchestrator.md` Workflow-step
   散文、CLAUDE.md ロードマップ Rules bullet、新しい名前付きセクション、または組み合わせに
   置かれるか; これが新しい ADR-023 または既存の ADR の amendment か <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal; ADR-014 amended 2026-05-20 was chosen instead (triad 0/3 outcome) -->
   (ADR-014、ADR-007、または他); エージェントプロンプトが直接編集を必要とするか、
   もしそうならどのエージェントが影響を受けるか; 結果の CLAUDE.md 編集に
   claude-md-authoring Skill の Pre/Post チェックリストが適用されるか; および CI ディテクター
   が品質ゲートループコンプライアンスに正当化されるか (事前に決定された結果ではなく
   architect の設計質問として扱われる) ── すべては architect の forthcoming 決定に
   委任される (Risk R-01 参照)。

## Metrics

- **Leading:** 本マイルストーン出荷後、品質ゲートエージェントが CRITICAL または HIGH の
  指摘を返した後のすべての orchestrator ルーティング決定が再エントリ所有者を明示的に
  名付け行アンカー不変条件を参照する ── 本マイルストーン以降のセッショントランスクリプトで
  検証可能。
- **Leading:** 本マイルストーン以降、テンプレート自身のロードマップで "CRITICAL または HIGH
  の指摘が残る間に `☑` にフリップされた行" インシデントがゼロ。
- **Lagging:** マイルストーンごとの "どのロールがこれを修正すべきか?" 再導出コストの削減、
  エージェントが先行セッションのトランスクリプトから推論するのではなくルールを引用して
  再レビューサイクルを開始するときに観察可能。

## Risks and open questions

### Risk R-01: Structural decision deferred to architect — re-entry rule placement, ADR strategy, agent-prompt impact, CI detector necessity

**説明。** 本 Spec は割り当てられなければならない *何を* (再エントリ所有者、行アンカー
不変条件、ADR-016 と #08 に対する MECE 境界) と適合する正式化の受け入れ基準を述べる。
構造的な *どのように* を明示的に委任する: 再エントリルールが orchestrator.md Workflow-step
散文、CLAUDE.md ロードマップ Rules bullet、新しい名前付きセクション、または組み合わせに
存在するか; これが新しい ADR-023 または既存の ADR (ADR-014、ADR-007、または他) の <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal; ADR-014 amended 2026-05-20 was chosen instead (triad 0/3 outcome) -->
amendment を要求するか ── architect は ADR-018 Alternative-B トライアド識別子 (新しい
コントラクト境界 / 新しいキーイング / 新しい MECE 境界 => 新 ADR; 既存の Decision の
帰結明確化 => amendment) を適用する; `orchestrator.md`、`implementer.md`、または他の
エージェントプロンプトが直接編集を必要とするか; claude-md-authoring Skill の Pre/Post
チェックリストが結果の CLAUDE.md 編集に適用されるか; および CI ディテクターが品質ゲート
ループコンプライアンスに正当化されるか (architect の設計質問として扱われ、
事前に決定された結果ではない)。このパターンは `specs/07-roadmap-status-transitions.md`
と `specs/08-orchestrator-row-guard.md` の R-01 を踏襲する。

**architect に渡す軽減制約。** architect の forthcoming 決定は指定しなければならない:
(a) 再エントリ所有権ルールと行アンカー不変条件が step 6 を実行するエージェントが
追加のファイル読み込みなしで遭遇するよう文書化される場所、(b) これが新しい ADR-023 か <!-- ref-allow: ADR-023 is the deliberately-rejected counter-proposal; ADR-014 amended 2026-05-20 was chosen instead (triad 0/3 outcome) -->
amendment か (Alternative-B 識別子適用)、(c) どのエージェントプロンプトが編集を
必要とし、選択された配置での #07 と #08 に対する MECE 境界、および (d) CI ディテクターが
正当化されるか。その決定が存在するまで、暫定プラクティス (orchestrator が修正のために
`implementer` にルーティングし; `implementer` が修正し; 品質ゲートエージェントが
再レビューし; 行が `◐` に留まる) がステップ 6 が書かれてから続いてきたとおりに
運用ルールとして残る。

**注意:** architect の forthcoming 決定を参照する `<!-- ref-allow: -->` 抑制は本 Spec
ファイル (`specs/21-quality-gate-row-anchor.md`) にのみ存在し、`specs/07-roadmap-status-transitions.md`
と `specs/08-orchestrator-row-guard.md` が設定した前例に従う。それらは `.claude/CLAUDE.md`
には **現れない**。

### Risk R-02: ADR-016 progress file — overlap risk with quality-gate loop state

**説明。** セッションが終了するときに進行中の品質ゲートループは、インループ状態を記述する
`specs/21-progress.md` を生成するかもしれない (例えば "2 回目の code-reviewer <!-- ref-allow: hypothetical progress file; only exists if loop crosses session boundary per ADR-016 | expires: 2026-07-20 -->
再レビューが保留中")。再開エージェントは "このループラウンドが progress ファイルを
持つ理由だ" と "別のブロッキングイベントが境界を引き起こした" を区別しなければならない。
progress ファイルがループ状態 (現在のラウンド番号、どの指摘がオープンのまま、
どのエージェントがクリアした) を明示的に述べない場合、再開エージェントはループを
ラウンド 1 から再起動し、努力を無駄にしたりすでにクリアされた項目を再レビューするかもしれない。

**軽減。** progress ファイルテンプレート (`.claude/templates/progress-template.md`) は
`## Notes` 下にループ状態フィールドを含むべき (例えば "Quality gate: round N、
pending agents: X、Y")。これは `implementer` が progress ファイルを著作する step 5
で解決する実装詳細; Spec 変更を必要としない。AC-4 が MECE トリガー境界を不変条件として
確立する; テンプレート拡張はその不変条件の自然な実装である。

### Risk R-03: Overlap with #08 G1–G3 at the MECE boundary

**説明。** 将来のマイルストーン著者が G1-G3 (missing-progress-file フォールバックを含む)
を読み、すべての品質ゲートルーティング懸念がすでにカバーされていると結論するかもしれない。
初期ディスパッチ (G1-G3) と再エントリルーティング (#21) の MECE 境界が両方のルールセットに
明確に述べられていない場合、境界は時間とともに侵食するかもしれない ── 特に両方が `◐ in-progress`
マイルストーン中の orchestrator のルーティング動作に関するため。

**軽減。** AC-5 と Key Interaction 3 が境界を明示的に述べる。#21 のルールに対する
architect の配置決定は、補完的な関係を将来の読者が両方の Spec をクロス読みすることなく
見えるようにするために #08 ガードを明示的に参照すべき。この境界ステートメントは
architect に渡す制約であり、Spec 層の設計決定ではない。

## Out of scope

- 4 つの認可された glyph 値の変更 (ADR-014 がそれらを所有する)。
- 品質ゲートループ強制のための新しい CI ワークフローファイルの追加 (architect 決定;
  Risk R-01 参照)。
- コンプライアンスチェック step (6a) のトリガーまたは所有権の変更 (マイルストーン
  #20 がそれを所有する)。
- ECC 不在デグレードレビューシグナルの変更 (マイルストーン #13 がそれを所有する)。
- 再エントリルールの派生リポジトリ orchestrator 設定への翻訳 (派生リポジトリの
  technical-writer がフォーク時に担当)。
- Spec 著作時の CHANGELOG 編集 (step 7 で technical-writer が担当)。
- Spec 著作時の JA sibling 著作 (step 7 で technical-writer が担当)。
- #07 (ロードマップ status-transition 所有権) — 完了; Key Interactions に
  MECE 境界が記載。
- #08 (Orchestrator Analyze 行ガード) — 完了; Key Interactions に MECE 境界が記載。
- #20 (`.claude/compliance.yml` のアクティブデフォルトとしてのコミット) — 完了;
  MECE 境界確認済み: #19/#20 が設定ファイルコミットを所有; #21 が品質ゲートループ
  プロセス正式化を所有。

## References

- ロードマップ行: #21
- `.claude/meta/adr/014-roadmap-index-single-entry-point.md` — §Decision
  Status-Transition マトリクス (Status = `◐` は in-progress 中; `◐→☑` は品質ゲート
  合格後のみ); §Consequences → Negative ("a formal status-transition state machine
  is not part of this ADR") — 本マイルストーンが再エントリパスのために部分的に閉じる
  ギャップ
- `.claude/meta/adr/016-cross-session-progress-persistence.md` — 境界トリガー
  progress ファイルメカニズム; #21 のインセッションループとの MECE 境界が AC-4 で
  正式化
- `specs/07-roadmap-status-transitions.md` — `◐→☑` フリップ所有権を品質ゲート
  クローズアウトアクターに割り当て; #21 の行アンカー不変条件 (AC-2) は早まったフリップへの
  補完的な禁止
- `specs/08-orchestrator-row-guard.md` — 初期ディスパッチの G1-G3 プレディスパッチ
  ガード; #21 は品質ゲートエージェントが指摘を返した後の再エントリルーティングを管理;
  AC-5 と Key Interaction 3 で MECE 境界が正式化
- `specs/13-ecc-absent-signal.md` — ECC 不在フォークのデグレードレビューシグナル;
  Key Interaction 4 に従い #21 の再エントリルールと非干渉
- `.claude/agents/orchestrator.md` Workflow step 6 — 本 Spec の再エントリルールが
  注釈する品質ゲートステップ; 本 Spec が正式化する暫定プラクティスはすでに
  step 6 の記述に暗示されている
