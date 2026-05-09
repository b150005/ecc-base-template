# ADR-010: 検証レイヤの一般化

## ステータス

Accepted — 2026-05-07

## 背景

ADR-008 は **研究検証レイヤ** を導入し、強く狭い哲学を確立した: Generator
(`docs-researcher`) と Critic (`research-critic`) が異なるツールファミリー
で動作し、Critic は **一次情報のみ** — 公式ドキュメント、ベンダー GitHub、
RFC、MDN — を引用してよく、二次情報 (ブログ、Q&A サイト、AI サマリ) は
決して引用しない。これは適用された 1 つのワークフロー (下流の意思決定に
影響する外部リサーチ) で、計測可能な品質向上をもたらした。

しかし、テンプレートが日常的に生み出す成果物のうち 3 種類は、依然として
単一作者の経路を通っている:

1. **実装。** `implementer` がコードを書く。`code-reviewer`,
   `security-reviewer`, linter が検査するが、いずれも同じツールファミリー
   (Read / Grep / Bash) と同じ証拠基盤 (diff) を共有する。対抗実装も、
   挙動差分も、敵対的な設計プローブもない。微妙に間違った選択がすべての
   レビューアを通過しうる — 全員が同じ表面しか見ていないからだ。

2. **アーキテクチャ判断。** `architect` が ADR を書く。「検討した代替案」
   の表は、決定を選んだ同じエージェントが埋める。却下された代替案を真剣に
   再現するに足る構造的な圧力がない。

3. **knowledge エントリ (Learning Mode)。** `.claude/skills/learn/preamble.md`
   §11 は `.claude/learn/knowledge/` 配下の knowledge ファイルすべてに対し
   一次情報引用を必須としている。今これを強制しているのは「エージェントが
   指示に従うこと」だけ。CI ゲートはない。二次情報リンクが一度静かに
   マージされると、以降のあらゆるセッションで循環参照の種になる。

ADR-008 はパターンを既に証明している。一般化のコストは実在する — 検証
ラウンドごとにモデル時間とオーケストレーションが追加で必要 — が、ユーザは
このトレードオフを明示的に受け入れている (「トークン消費は気にしない、
品質と精度を優先」)。残る問いは **やりすぎずにどこまで一般化するか** だ。

## 決定

ADR-008 の Generator-vs-Critic、一次情報限定の哲学を、独立に default-off
の 3 ドメインを持つ単一の **検証レイヤ** 抽象に一般化する。共通の不変条件:

- Generator が成果物を生成 (research note、実装、ADR エントリ、knowledge
  ファイル)。
- Critic が **異なるツールファミリー** と **実行可能な範囲で重ならない
  証拠基盤** で再導出または再チェック。
- Critic は **一次情報のみ** 引用してよい。二次情報は常に失格事由。
- 各ドメインは独立した `enabled: true|false` スイッチ。**default-off** で
  出荷。`.claude/verification.yml.example` を single source of truth と
  し、`.claude/research-verification.yml.example` を置き換える。

3 ドメイン:

### 1. `research:` (既存 — ADR-008 から変更なし)

Generator = `docs-researcher`、Critic = `research-critic`。ツールファミリー
を ADR-008 通り分離。本 ADR では同じセマンティクスのまま新ファイルに統合。
ADR-008 は本ドメインの正本として残り、ADR-010 はそれを収めるのみ。

### 2. `implementation:` (新規)

Generator = `implementer` (既存エージェント、変更なし)。Critic = 新エージェ
ント定義 `adversarial-implementer`。Critic は diff の行単位レビューを
**しない** (それは `code-reviewer` の仕事)。代わりに、**同じ acceptance
criteria** を意図的に異なるアプローチで実装し、両方に対してテストスイート
を走らせ、**挙動の差分** を報告する: どのテスト出力が異なるか、各実装が
どのエッジケースを扱うか、どのパフォーマンスプロファイルを見せるか。出力は
`verification-review.md` というアーティファクトであり、コード変更ではない。
差分をどう扱うかは PR 作成者が決める。

**「異なるアプローチ」の範囲に対する制約。** Critic が導入してよい差分は
順位付けされており、有意味な挙動差分が得られる **最も低い** 段階を選ばな
ければならない:

1. **異なる制御フローまたはデータ構造** (デフォルト、常に許可) — 同じ
   言語、同じ依存セット、異なるアルゴリズムまたは形状。
2. **同一ライブラリ内での異なるイディオム** — 同じ API 表面、別の呼び出し
   パターン。
3. **異なるライブラリ** — 以下を **両方** 満たす場合のみ許可:
   (a) ユーザがタスク・spec・既存 ADR で特定ライブラリを明示指定して
   **いない**、かつ (b) 代替ライブラリが既にプロジェクトのマニフェスト
   (`package.json`, `pubspec.yaml`, `go.mod` など) に宣言済み、または
   標準ライブラリの等価物である。
4. **プロジェクトに存在しないライブラリやランタイム** — 人間の明示的な
   承認なしに行ってはならない。Critic は代わりに **verification-blocked
   ノート** を出力し、何を使おうとしたか、何が必要だったか (CLI ツール、
   Docker イメージ、SDK、ライセンス) を記述する。PR 作成者は、追加を承認
   するか、検証ギャップを受け入れるか、環境を手動で用意するかを選べる。

ユーザが特定のライブラリを明示的に要求した場合 (「Prisma ではなく Drizzle
を使って」)、そのタスクでは段階 3 と 4 は恒久的に対象外。Critic は段階
1〜2 で動作し、その旨をレビューのヘッダに明記する。

**環境の安全性。** Critic は検証の一環として、システムレベルのツールを
インストールしたり、Docker イメージを pull したり、バイナリを取得したり、
プロジェクトの依存マニフェストを変更したりしては **ならない**。代替候補
にこれらが必要なら、Critic は代わりに blocked-note を出力する。これに
より、検証ステップが学習者のマシンで再現可能なまま、予期せぬ副作用も
発生しない。

Critic は外部 claim (フレームワーク docs、RFC、言語仕様) について一次情報
のみ引用しなければならない。両実装が観測可能なすべての挙動で一致する場合、
Critic はそれを明示的に述べる — 沈黙は許容されない。

### 3. `design:` (新規)

Generator = `architect`、Critic = 新エージェント定義
`architecture-critic`。`Status: Proposed` のあらゆる ADR に対し、Critic は
**1 つの具体的な対抗提案** を生成しなければならない: 却下された代替案を
真剣に扱う形で、同じ制約・異なる決定・完全な「Consequences」セクション。
Critic は ベンダーや技術固有の claim について一次情報のみ引用。出力は
ADR ドラフトに `## Counter-proposal` セクションとして `Status: Proposed`
の下に追記。architect (および人間レビューア) が ADR を改訂するか、対抗案を
採用するか、もしくは元の選択が勝つ理由を文書化するかを決める。ADR が
`Accepted` に進んだ後も、対抗提案は「真剣に検討された」歴史的記録として
残る。

### 知識引用規律の強制 (横断的)

新しい CI ワークフローが `learn-invariants.yml` を拡張し、
**citation-discipline check** を追加: `.claude/learn/knowledge/*.md` および
あらゆる ADR / spec ファイル内のリンクを、ドメインブロックリスト
(`stackoverflow.com`, `qiita.com`, `zenn.dev`, `medium.com`, `dev.to`,
`reddit.com`, `*.blog.*`, 一般的な AI サマリドメイン) と照合。ブロック
リストは `.claude/skills/research-verification/checklist.md` (single source
of truth、既存) に住み、CI スクリプトはそこを読む。マッチしたらジョブを
失敗させる。本チェックは **default-on** — 1 回あたりのコストがほぼ無く、
load-bearing な不変条件を守るため。

## 結果

### ポジティブ

- ADR-008 の品質向上が、学習者が最も多く生成する 2 種類の成果物 (コードと
  設計判断) に拡大する。
- すべての `Proposed` ADR が真剣な対抗提案と共に出荷されるので、「検討した
  代替案」の表が形式的でなくなる。
- 実装の選択に対し、diff レビュー型のエージェントが構造的に行えない挙動
  差分のサニティチェックが入る。
- knowledge ファイルに対して一次情報規律が機械的に強制される — 二次情報が
  静かに蓄積されて循環参照になることがなくなる。

### ネガティブ

- 1 件あたりのコストが大幅に上がる。特に `implementation` ドメインは実装
  全体を 2 回走らせる (Generator と Critic で 1 回ずつ)。ユーザはこの
  トレードオフを受け入れている。ドメインを default-off で出荷するので、
  非学習用途のフォークは何も払わない。
- 2 つの新エージェント定義 (`adversarial-implementer`,
  `architecture-critic`) で学習者が理解すべき表面積が増える。ADR-009 の
  `description` 書き換えがトリガー条件を明示することで緩和。
- ADR の対抗提案が長さとレビュー負荷を増やす。学習用テンプレートでは
  長期の意思決定品質が ADR の簡潔さより重要なので、これを受け入れる。
- citation-discipline CI が、フラグ付きドメイン上にホストされた正当な
  リンク (セキュリティアドバイザリ、RFC ミラー等) で false positive を
  出す可能性。緩和策: `<!-- cite-allow: <reason> -->` のインライン
  エスケープコメント、控えめに使用。

### 中立

- `.claude/research-verification.yml.example` は
  `.claude/verification.yml.example` にリネーム。旧ファイル名は supersede
  されたものとして文書化。コピー済みの既存フォークは再同期するまで動作継続。
- 3 ドメインが 1 設定ファイルに収まるのは 3 個別ファイルより発見しやすい
  が、若干硬い。硬さを受け入れる。
- `adversarial-implementer` の環境変更禁止 Hard rule は prompt level で
  強制し、runtime の `permissions.deny` gate は導入しない。これは検討
  済みで保留 (Alternatives considered の該当行参照)。再評価のトリガー
  条件は同行に記録されている。

## 検討した代替案

| 代替案 | 利点 | 欠点 | 採用しなかった理由 |
|---|---|---|---|
| ADR-008 を狭く保ち、ドメインを増やさない | 最低コスト、最低リスク | 最も生成量の多いコードと設計に検証レイヤの恩恵が届かない | ユーザは品質/精度をコストより明示的に優先 |
| 単一の巨大 Critic が research/code/design を全部レビュー | エージェント保守先が 1 つで済む | 「異なるツールファミリー / 重ならない証拠基盤」という ADR-008 の品質の源泉が失われる | ADR-008 の不変条件を静かに退行させる |
| `implementation` と `design` ドメインを default-on にする | 品質圧力が最大 | 非学習用途でフォークしたユーザを驚かせる、同意なしに実装コストを倍にする | default-off がテンプレートの役割を尊重、opt-in は設定 1 行 |
| citation-discipline も default-off | 他ドメインと対称 | citation-discipline は CI 1 回あたりほぼ無コスト、かつ失敗モード (二次情報の静かな蓄積) が深刻 | コスト/リスクの非対称性が非対称デフォルトを正当化 |
| Critic が必要に応じてツールをインストールしつつ任意の代替ライブラリを選べるようにする | 挙動差分の信号が最大 | 学習者マシンでの再現性が壊れる、ユーザの明示的なライブラリ指定を無視する、Docker や SDK やライセンスへのコミットを同意なく持ち込む | 上記 4 段階のランキングに制約、段階 4 は人間の承認必須 |
| `adversarial-implementer` の環境安全契約を `permissions.deny` で強制 (`Bash(apt*)`、`Bash(docker pull*)`、`Edit(package.json)` 等をブロック) | Hard rule が prompt テキストではなく runtime gate になる — Critic に Docker イメージのインストールを指示する prompt-injection に対して堅牢 | `permissions.deny` はセッション全体に適用されるため、正規の `implementer` ワークフローも同じコマンドを失う。エージェント単位のスコープに戻すには deny を marker `verification:implementation` で toggle するカスタム Hook、または別セッションプロファイルが必要で、残存リスクの規模に対して仕掛けが過剰になる。脅威モデルは「攻撃者が Claude が読むテキスト (PR description、issue 本文) を仕込める」かつ「Plan Mode (ADR-009 で default-on) がその試みを表面化できない」の両方を仮定する — 学習用テンプレの典型的な利用面では両方とも起こりにくい | 2026-05-08 評価、**保留** (却下ではない)。再評価のトリガー: (a) implementation ドメインが default-on に変更される、(b) `adversarial-implementer` が外部 PR の webhook で無人実行されるようになる、(c) `settings.local.json` でパワーユーザ理由により Plan Mode が無効化される |

## 参考

- ADR-008 (Research Verification Layer) — 本 ADR が一般化する哲学とプロト
  コル。ADR-008 は `research` ドメインの正本として残り、ADR-010 は統合
  設定を収める。
- ADR-001, ADR-004 (Learning Mode, Coaching Pillar) — knowledge 引用規律は
  knowledge pillar の load-bearing な不変条件を守る。
- ADR-009 (Plan-First Defaults) — 並行で起票。そこでの `description` 書き
  換えが、新 Critic エージェントを orchestrator から発見可能にする。
- `.claude/skills/research-verification/checklist.md` — 二次情報ブロック
  リストの single source of truth、CI チェックと research ドメインで共有。

## Amendment — 2026-05-09 (ADR-013 による)

ADR-013 は `.claude/skills/verification-layer/SKILL.md` の invariant 3
(primary-source-only citation) に対する verification-layer 全体の
拡張として、**Tier 1.5 — 発令する規制当局の公式解釈ガイダンス** を
追加した。Tier 1.5 allowlist は ADR-013 層で閉じて固定されており、
EDPB Guidelines、PPC ガイドライン/Q&A/通達、CPPA Regulations、
Apple Privacy Manifest 仕様、Google Play SDK Index ドキュメントを
許容する。同一項目で Tier 1 引用と併記する場合に限り、かつ検討中の
トピックが委任規制当局ドメインと交わる場合に限る。

本変更は verification-layer の 3 ドメイン (`research`、
`implementation`、`design`) に一様に適用される:

- `research` Critic (`research-critic`) — ADR-008 amendment を参照。
- `implementation` Critic (`adversarial-implementer`) — レビュー対象
  実装が委任規制当局ドメインと交わる場合 (例: Apple §3.1
  entitlements 下の payment flow、GDPR 第 35 条 DPIA 下の PII
  パイプライン)、代替実装選択を支持する引用に同じルールが適用
  される。
- `design` Critic (`architecture-critic`) — レビュー対象 ADR が
  委任規制当局ドメインと交わる場合、反対提案を支持する引用に
  同じルールが適用される。

ADR-010 の元の Decision テキストと 4 段階ランキングは変更されない。
Tier 1.5 は引用 allowlist への狭く閉じた拡張である。各ドメインの
protocol、severity vocabulary、opt-in 設定モデルは変更しない。

closed allowlist、ペアリングルール、権威下限、古いガイダンスの
取り扱い、再評価トリガーは ADR-013 を参照。
