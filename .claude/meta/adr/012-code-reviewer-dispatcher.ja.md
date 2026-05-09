# ADR-012: code-reviewer を ECC 言語別 reviewer への dispatcher 化する

## ステータス

Accepted — 2026-05-09

## 背景

本テンプレートの `code-reviewer` エージェントは、これまで汎用的な
エコシステム検出型レビュー ── `.claude/CLAUDE.md` とプロジェクト
マニフェストを読み取り、言語非依存のチェックリスト (関数長、ファイル
サイズ、エラーハンドリング、ハードコード秘密情報など) と、テンプレ
独自の cross-cutting 検査 (CLAUDE.md authoring、upstream-workaround
マーカ、Learning Mode 契約) を適用 ── を行ってきた。

ECC はユーザーレベル (`~/.claude/agents/`) に 9 つの言語別 reviewer
エージェントを提供している: `typescript-reviewer`, `python-reviewer`,
`go-reviewer`, `rust-reviewer`, `cpp-reviewer`, `java-reviewer`,
`kotlin-reviewer`, `flutter-reviewer` (Dart), `csharp-reviewer`。これらは
idiom、型システムの footgun、async の正しさ、フレームワーク固有の
アンチパターンなど、汎用 reviewer では構造的に弱くなる領域で実質的に
深い。

README `## Prerequisites` 節と ADR-011 のフレーミングに従い、本
テンプレートは ECC をユーザーレベルで導入済みであることを前提として
いる。したがって、プロジェクトレベルの汎用 `code-reviewer` は、
ユーザーレベルの ECC reviewer を **shadow** することになる (Claude
Code は名前衝突時にプロジェクトエージェントをユーザーエージェントより
優先する)。結果として、任意の単一エコシステムについて、ECC 単体で
得られたであろうレビューより厳密に弱いレビューが生成される。

本テンプレートの value-add は言語の深さではありえない ── その
領域は ECC のスペシャリストに既に取られている。value-add は
テンプレート内部の cross-cutting レイヤである:
ADR conformance (ADR-006/007/008/010/011)、upstream-workaround
マーカ (ADR-006)、CLAUDE.md / agent-prompt 構造 (ADR-007)、
verification-layer ハンドオフ (ADR-008/010)、compliance-checklist
Skill トリガー (ADR-011、有効化時)。

本 ADR は v3.6.0 リリースサイクルで行った決定と、内部レビュー時に
提起された真剣な反対提案を記録するものである。

## 決定

`.claude/agents/code-reviewer.md` を **meta-reviewer / dispatcher**
にリファクタする:

- プロジェクトマニフェストファイルからエコシステムを検出する
  (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`,
  `CMakeLists.txt`, `pom.xml`, `build.gradle{.kts}`, `pubspec.yaml`,
  `*.csproj`)。
- 言語固有の深さは、該当する ECC reviewer に委譲する。
- 言語に関わらず、テンプレ独自の cross-cutting 検査を上に重ねる。
- 委譲結果を 3 ケース (succeeded / attempted-failed / not-attempted)
  に分け、それぞれを明示的にレポートする ── ECC レイヤが欠けている
  ことが毎回のレビューレポートで可視化され、静かにスキップされる
  ことはない。
- 委譲が試みられなかった場合のみ、元の汎用チェックリストにフォール
  バックする。
- 多言語 diff の場合、該当する各 ECC reviewer に並列に委譲し、結果を
  集約する。

エージェント数は 18 のまま据え置く。`code-reviewer` のプロンプトのみが
変わる。

## 結果

### Positive

- 任意の単一エコシステムについて、レビュー深度が ECC スペシャリスト
  レベルにアップグレードされる ── テンプレートにエージェントを追加
  することなく。
- テンプレ独自の cross-cutting レイヤ (ADR conformance、workaround
  マーカ、claude-md-authoring、verification-layer、compliance-checklist
  トリガー) が、1 つのローカルエージェントの明確な責務になる ──
  汎用 reviewer に混在させるよりクリーンな分離。
- `code-reviewer` のプロンプトがより誠実になる: その仕事が
  *調整 + cross-cutting 検査* であり、言語の深さではないことを文書化
  する。
- ECC を導入したフォークは、従来より厳密に良いレビューを得る。ECC を
  導入しないフォークも、これまでの汎用 reviewer と比較してリグレッ
  ションは無い (フォールバック経路が旧チェックリストを保持する)。

### Negative

- テンプレートが完全なレビュー深度のために **ECC への明示的な依存**
  を持つことになる。ECC を導入しないフォークは、永続的に低い
  レビュー品質で動作することになり、README はそれを述べる必要がある
  (本リリースで `## Prerequisites` 節を追加し、述べている)。
- 言語固有レイヤのレビュー出力が **オペレータ環境によって変動** する。
  cross-cutting レイヤは再現可能だが、言語固有レイヤはオペレータが
  どの ECC バージョンを導入しているかに依存する。これは再現性の
  実質的な損失であり、verdict 行に委譲結果のケースを明記することで
  部分的に緩和する。
- dispatcher ロジックは、orchestrator と人間レビュアーが理解すべき
  新しい形のエージェントである。3 ケースの委譲結果ルールはエージェント
  ファイル内に文書化されているが、学ぶべき概念が 1 つ増える。
- ECC reviewer との契約は **バージョン固定されていない**。ECC が
  `typescript-reviewer` をリネームしたり、プロンプト契約を実質的に
  変更したりした場合、dispatcher の委譲表は静かに stale になる。
  対象エージェントの存在確認の CI チェックは無い。

### Neutral

- 旧汎用 reviewer のロジックは、フォールバック経路として残存する。
  削除はしていない。capability を再編しただけである。
- これは ECC へ名指しでハンドオフする、テンプレート初のエージェント
  である。今後のエージェントは本パターンに従いうる。本 ADR がその
  前例を確立する。

## 検討した代替案

| 代替案 | 利点 | 欠点 | 採用しなかった理由 |
|---|---|---|---|
| **A: プロジェクトの `code-reviewer` を削除し、ECC の `code-reviewer` に完全に委ねる** | 最大の単純さ、dispatcher ロジック不要 | テンプレ独自の cross-cutting 検査 (ADR conformance、workaround マーカ、claude-md-authoring、verification-layer ハンドオフ、compliance-checklist トリガー) を失う ── ECC の `code-reviewer` はこれらを知らないし、置き換えられない | cross-cutting 検査こそテンプレートの貢献である。ローカルエージェントを削除すると、それを捨てることになる |
| **B: `.claude/agents/` 配下に言語別 reviewer (`typescript-reviewer.md`, `python-reviewer.md` 等) を追加する** | テンプレートが自己完結する、ECC の有無に関わらずレビュー再現可能、reviewer プロンプトがテンプレートと共にバージョン固定、隠れた外部契約が無い | 同期メカニズムなしに ECC reviewer から徐々にドリフトする、メンテナンス表面が増える (初期 3 つ以上)、両方を運用するユーザにとってコンテンツが重複 | 後述「反対提案」を参照 ── 本代替案は内部レビューで `architecture-critic` が提起したもので、本リリースでは採用しなかったが真剣な選択肢として記録する |
| **C: `code-reviewer` は汎用のままとし、orchestrator のハンドオフロジックに「ECC へ委譲」を埋め込む** | `code-reviewer.md` の変更不要 | dispatcher 動作を、それを実行するエージェントではなく orchestrator のプロンプトに隠す、監査困難、orchestrator が言語別ルーティングで肥大化する | 振る舞いの局所性は本件の設計価値である。仕事を行うエージェントが、それを記述するプロンプトを所有すべき |
| **D: 現状維持 ── プロジェクトレベルの汎用 reviewer を残し、ECC を shadow することを受容** | 作業ゼロ | レビューのたびに ECC のスペシャリスト深度を浪費する、汎用 reviewer は任意の単一エコシステムについて厳密に弱い、ECC を導入したユーザが恩恵を受けない | テンプレートが ECC を前提にする目的そのものは、ECC を活用することにある |

## 反対提案

本決定の verification-layer / design domain レビュー時に (ADR-010 に
従い `architecture-critic` を Critic として)、代替案 B ──
**`.claude/agents/` 配下に言語別 reviewer を追加する** ── が、
却下された代替案を真剣に取り上げる反対提案として生成された。
反対提案の論点:

1. 学習用テンプレートは自己完結すべきである。フォークは ECC を
   決して導入しないかもしれない。ECC が無い時に「汎用フォール
   バック」へ静かに degrade する dispatcher は、テンプレートの
   レビュー深度がリポジトリ外のレイヤに依存することをフォークに
   教えてしまう ── 良くない教訓であり、隠れた結合である。
2. レビューの再現性。dispatcher は、オペレータのマシンに導入
   されている ECC バージョンによって異なる出力を生む。これは
   テンプレートの再現性ポスチャ (ピン留めテンプレート、ADR 駆動の
   決定、明示的な依存関係) に違反する。
3. dispatcher は隠れた契約である。「導入されている ECC reviewer に
   何でも委譲」することは、unversioned で unpinned な外部表面に
   依存することを意味する。ECC が `typescript-reviewer` をリネーム
   したり、プロンプト契約を変更したりすると、すべてのフォークが
   静かに壊れる。
4. リポジトリ内 reviewer は fork 可能で監査可能である。
   `.claude/agents/typescript-reviewer.md` ファイルは diff 可能、
   バージョン管理可能、ADR から参照可能、フォーク単位でチューニング
   可能である。ECC への委譲はそれができない。
5. cross-cutting 検査は既にローカルにある。idiom 検査もローカルに
   置く限界コストは、split-brain なレビュー表面のコストと比べて
   小さい。

**本リリースで反対提案を採用しなかった理由**:

- メンテナンスコストは現実的かつ継続的である。**学習用テンプレート**
  ── その主要価値は構造であり、言語カバレッジではない ── で 9 つの
  言語別 reviewer プロンプトを維持することは、テンプレートを ECC の
  消費者ではなく ECC の競合に変えてしまう。dispatcher の契約が
  unversioned であるという反対提案の指摘は正しいが、応答は *dispatcher
  を強化する* (フォーク時に ECC エージェント存在の CI チェック、ECC
  バージョン pin の README 案内) ことであり、*ECC のカタログを
  ローカルに再実装する* ことではない。
- 反対提案が論じる「自己完結」プロパティは既に部分的に放棄されて
  いる: 本テンプレートは Claude Code 自体、オプションの Skill、
  Anthropic API アクセスに依存している。ECC をその一覧に加えるのは
  文書化された選択であり、隠れた結合ではない。本リリースで追加した
  README `## Prerequisites` 節が ECC 依存を明示しており、「隠れた
  結合」の懸念に直接応答する。
- 再現性は *本番成果物* の懸念事項である。本テンプレートは
  リリース成果物ではなくレビューを生成するものであり、verdict 行に
  委譲結果のケースを記す注記が監査トレイルになる。ECC バージョンは
  オペレータの状態であり、テンプレートの状態ではない。

**反対提案を再評価するトリガー条件**:

- ECC が `*-reviewer` エージェントのプロンプト契約に後方互換性のない
  変更を行ったとき。
- 名指しした ECC reviewer のうち 2 つ以上が、文書化された移行経路
  なしに消失またはリネームされたとき。
- 活用されているフォークが、ECC のカバーしない言語の reviewer を
  必要としたとき (dispatcher の汎用チェックリストへのフォールバック
  は残存するが、フォークは独自 reviewer プロンプトの出荷を望むかも
  しれない)。
- テンプレートのユーザベースが、意図的に ECC を導入しないオペレータ
  方向へシフトしたとき ── その時点で「自己完結」プロパティが再び
  load-bearing になる。

ADR-010 の design-domain プロトコルに従い、反対提案は真剣に検討
されたものの記録として本 ADR に永続的に残す。

## 参照

- ADR-007 (CLAUDE.md Authoring Skill) — dispatcher のローカルレイヤが
  強制する cross-cutting authoring invariant を定義。
- ADR-008 (Research Verification Layer) — dispatcher のローカルレイヤが
  強制する verification-layer ハンドオフ検査を定義。
- ADR-010 (Verification Layer Generalization) — 上記反対提案を生成した
  design-domain Critic プロトコルを定義。
- ADR-011 (Compliance Checklist Skill) — dispatcher のローカルレイヤに
  compliance-checklist トリガー行を追加。
- `.claude/agents/code-reviewer.md` — 本 ADR が合理化するエージェント
  プロンプト。
- README.md `## Prerequisites` (および `README.ja.md ## 前提条件`) ──
  この dispatcher が依拠する「ECC をユーザーレベルに導入済み」の
  文書化された前提。
- ECC ユーザーレベル reviewer カタログ:
  `~/.claude/agents/typescript-reviewer.md`, `python-reviewer.md`,
  `go-reviewer.md`, `rust-reviewer.md`, `cpp-reviewer.md`,
  `java-reviewer.md`, `kotlin-reviewer.md`, `flutter-reviewer.md`,
  `csharp-reviewer.md` — 委譲先。
