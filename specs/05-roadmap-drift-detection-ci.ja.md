# Roadmap ドリフト検出 CI

## ステータス

Approved

**オーナー:** product-manager / implementer
**対象リリース:** template v3.7.0

## 問題

`CLAUDE.md` の Roadmap テーブルは双方向リンク契約 (ADR-014) を義務付けている: 各行の `spec:` および `adr:` セルは実在の成果物に解決しなければならず、Roadmap 行に逆参照する ADR はその行の `adr:` セルに反映されなければならない。この契約のどちらの方向も自動的に検証されていない。`adr:` セルにそのマイルストーンを逆参照しない ADR を記載した Roadmap 行や、`adr:` セルにその ADR を列挙していない行番号を `Roadmap row:` 逆参照に持つ ADR は、静かにインデックスを壊す。行のステータスグリフは手動編集によって非公認の文字に変更しても CI が失敗しない。#04 dangling-reference detector (マイルストーン #04、ADR-015) は文書の散文中の壊れた ADR/パス参照を検出するが、Roadmap 固有の双方向リンクおよびステータスグリフ契約は明示的にチェックしない — その Non-goals セクションが本マイルストーンを担当ディテクターとして明示的に指名している。

ADR-014 §Consequences → Negative はこのギャップを逐語的に認めている: 「Index↔reality のドリフト。Roadmap 行を更新せずに Spec または ADR を作成することができ、インデックスを陳腐化させる。本 ADR に自動化された強制手段はない。緩和策は将来の可能な … CI チェックに *委ねられている*。」本マイルストーンがその委ねられた緩和策である。

## ゴール

- Roadmap 行の `adr:` リンクが指す ADR ファイルが **ディスク上に存在する** が、その `## References` セクションにその行番号に一致する `Roadmap row: #NN` エントリが **ない** 行を検出する — ADR-014 双方向リンク契約の順方向。
- `.claude/meta/adr/` 配下の ADR の `## References` セクションに `Roadmap row: #NN` 逆参照行があり、Roadmap 行 `#NN` の `adr:` セルにその ADR ファイルへのリンクが **ない** ADR を検出する — 同契約の逆方向。
- Status セルに 4 つの公認値 (☐ / ◐ / ☑ / ✗) 以外のグリフを含む Roadmap 行を検出する。
- フォークごとの設定ステップなしに、`main` へのすべての push と pull request で自動的に実行する — ADR-015 の subject-matter-presence ルールから継承した always-on ポスチャーに一致する。
- 本マイルストーンが出荷される時点で、テンプレートリポジトリ自身の成果物がチェックを通過している。

## ゴール対象外

- Roadmap 行の `spec:` 予約リンクがディスク上のファイルに解決するかのチェック。予約済みリンク (`specs/NN-slug.md`) は Spec が作成される前でも設計上有効 (ADR-014 Spec 予約ルール)。そのカーブアウトは #04 ディテクターが所有する。
- 散文中の壊れた ADR-NNN テキスト参照や `.claude/` ルートのパス言及の検出 — これらは #04 のスコープ (ADR-015 §Decision point 1)。
- 任意の ADR が Roadmap 逆参照を **持たなければならない** ことの強制。多くの ADR (001–013) は Roadmap のドッグフード化より前のものであり、正当に `Roadmap row:` エントリを持たない。本ディテクターは *逆参照の主張が存在する場合の一貫性* をチェックし、*逆参照の普遍性* はチェックしない。
- いかなる不整合の自動修正 — ディテクターは報告するのみ。人間とエージェントが修正する。
- `workarounds/` レジストリファイル内の外部 URL または参照のチェック。
- Spec ファイルのテキストコンテンツと Roadmap 行の一行説明の照合 (意味的照合は機械的チェックではなく人間の判断)。

## 対象ユーザー

| ペルソナ | 説明 | 主なニーズ |
|---------|-------------|--------------|
| テンプレートメンテナー | Roadmap を更新するか ADR を作成する開発者 | `adr:` 更新漏れや逆参照漏れをエージェントを誤解させる前に検出する |
| エージェント (orchestrator) | Analyze ステップで設計成果物を特定するために Roadmap を読む | Roadmap の `adr:` リンクと ADR の `Roadmap row:` 逆参照が相互に一貫していると信頼する |
| エージェント (architect) | 新しい ADR を作る前に既存の `adr:` リンクを確認する | ファイルスキャンで再検証せずに Roadmap を健全なインデックスとして利用する |
| テンプレート採用者 | テンプレートをフォークして CI を継承する | 設定ステップなしに構造的に一貫した Roadmap のベースラインから始める |

## ユーザーストーリー

| 〜として | 〜したい | 〜ために |
|---------|--------------|------------|
| テンプレートメンテナー | Roadmap 行に `adr:` リンクを追加しながら ADR に `Roadmap row: #NN` 逆参照を追加し忘れたとき CI 失敗を得る | 片側だけの参照をエージェントが辿る前に逆参照漏れを検出する |
| エージェント (orchestrator) | Roadmap の `adr:` リンクが双方向に一貫していることを知りながら読む | Roadmap 行を認識しない ADR に誘導されないようにする |
| テンプレートメンテナー | ADR が `Roadmap row: #NN` 逆参照を持つが行 `#NN` がその ADR を列挙していないとき CI 失敗を得る | エージェントが Roadmap を読む前に陳腐化した ADR 逆参照を検出する |
| テンプレートメンテナー | Roadmap の Status セルに非公認のグリフが含まれるとき CI 失敗を得る | 4 グリフ契約を破る手動編集を即座に検出する |

## 受け入れ基準

- **Given** Roadmap 行の `Design source` 列に `adr:` リンク (例: `adr: .claude/meta/adr/015-foo.md`) がある **when** ディテクターが実行される **then** 名前付きの ADR ファイルがディスク上に存在するがその `## References` セクションに行番号に一致する `Roadmap row: #NN` エントリがない場合に失敗する。 <!-- ref-allow: fictional example path illustrating the acceptance criterion, not a real reference -->
- **Given** `.claude/meta/adr/` 配下のファイルの `## References` セクションに `Roadmap row: #NN` 行がある **when** ディテクターが実行される **then** `CLAUDE.md` の Roadmap テーブルの行 `#NN` にその ADR ファイルへの `adr:` リンクがない場合に失敗する。
- **Given** Roadmap 行の Status セルに ☐、◐、☑、✗ 以外の文字が含まれている **when** ディテクターが実行される **then** 行番号と見つかった無効なグリフを示すメッセージとともに失敗する。
- **Given** Roadmap 行の `adr:` リンクがディスク上に存在しないパスを指している **when** ディテクターが実行される **then** 失敗する — 存在しない `adr:` ターゲットは (`spec:` リンクとは異なり) 予約ルールのカーブアウトに一切含まれず、常に壊れた参照である。
- **Given** ADR に `Roadmap row:` 逆参照が一切ない **when** ディテクターが実行される **then** 失敗しない — 逆参照がないことは Roadmap ドッグフード化前の ADR やロードマップ機構自体の設計決定を記録した ADR にとって有効である。
- **Given** 本マイルストーンが出荷される時点のテンプレートリポジトリ自身の成果物 **when** ディテクターが実行される **then** すべてのチェックが通過する — テンプレートを自身のベースラインとして確立する。
- **Given** Roadmap `adr:` リンクを追加するが対応する ADR 逆参照がない `main` への push または pull request **when** ワークフローが実行される **then** `roadmap-drift-check` という名前の CI ジョブが失敗し、サマリー出力に行番号と具体的な不整合が示される。
- **Given** フォークごとの設定変数や設定ファイルなしにワークフローファイルが存在する **when** 派生リポジトリの CI が実行される **then** 追加のセットアップなしにチェックが自動的に実行される (ADR-015 から継承した always-on デフォルト)。
- **Given** スキャン対象のいずれかのファイルの行に `<!-- ref-allow: -->` コメントがある **when** ディテクターが実行される **then** その行のバリデーションをスキップする — #04 のエスケープハッチをこのディテクターが変更なしに再利用する。

## 主なインタラクション

1. `implementer` が `.claude/meta/scripts/check-dangling-refs.sh` (#04 から確立された再利用可能なパターン) の構造に従って `.claude/meta/scripts/check-roadmap-drift.sh` を作成する: `set -euo pipefail`、`git rev-parse` によるリポジトリルート解決、`pass`/`warn`/`fail_check` ヘルパー、`fail=0` アキュムレーター、`exit "$fail"`。スクリプトは `CLAUDE.md` から Roadmap テーブルを解析して行番号と `adr:` セル値を抽出し、各 ADR の `## References` セクションに一致する `Roadmap row: #NN` エントリがあるかをクロスチェックする — そしてすべての ADR 逆参照に対してその逆も行う。 <!-- ref-allow: .claude/meta/scripts/check-roadmap-drift.sh is the deliverable artifact this milestone authorizes; it does not exist yet at Spec authoring time -->
2. `implementer` が `.github/workflows/dangling-ref-check.yml` の構造に従って `.github/workflows/roadmap-drift-check.yml` を作成する: `.claude/CLAUDE.md`、`.claude/meta/adr/`、スクリプト/ワークフロー自体にパス指定した `main` への `on: push/pull_request`、`bash .claude/meta/scripts/check-roadmap-drift.sh` を実行する単一 `check` ジョブ、`permissions: contents: read`、`timeout-minutes: 5`。 <!-- ref-allow: .claude/meta/scripts/check-roadmap-drift.sh is the deliverable artifact this milestone authorizes; it does not exist yet at Spec authoring time -->
3. スクリプトは Non-goal カーブアウトをヘッダーブロックに明示的に文書化する: `Roadmap row:` 逆参照のない ADR は免除される。`spec:` 予約済みリンクは #04 ディテクターに固有のカーブアウトを持つ。このスクリプトのスコープは `adr:` ↔ 逆参照の双方向性とステータスグリフの整形式のみである。
4. pre-Roadmap ADR や Roadmap-mechanism ADR を逆参照を持つべき ADR と正当に区別するための正確なキーイングロジック — および Roadmap テーブル行と ADR `## References` セクションを抽出するための正確な regex またはパース戦略 — は architect に委ねる (ADR-017 または既存 ADR への amendment)。Spec は *何を* (逆参照が存在する場合の双方向一貫性) を述べ、ADR は構造的な *どのように* を記録する。 <!-- ref-allow: ADR-017 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->
5. 本マイルストーンではエージェントプロンプトの変更は不要。ディテクターは CI レイヤーのみである。

## メトリクス

- **先行指標:** テンプレート自身の `main` ブランチで、マイルストーン出荷直後に CI ジョブ `roadmap-drift-check` が通過する。
- **先行指標:** テンプレート自身の成果物に出荷時点で `<!-- ref-allow: -->` 抑制がゼロ (テンプレートの成果物は一貫しているべきであり、エスケープハッチは派生リポジトリの先行参照用に存在する)。
- **遅行指標:** 「エージェントが Roadmap の陳腐化した `adr:` リンクを辿ってその行を認識しない ADR に至る」インシデントの減少 (チームが追跡する場合はセッションのトランスクリプトで観察可能。本マイルストーンのハードなメトリックゲートではない)。

## リスクとオープンクエスチョン

### リスク R-01: Roadmap テーブルのパースによる偽陽性

**説明。** `CLAUDE.md` の Roadmap テーブルは Markdown であり、`grep`/`awk` や単純な regex でパースすると複数行の `Design source` セル (例: 複数の `adr:` リンクに `<br>` を使う行) を誤パースする可能性がある。単純なパーサーは行の ADR 参照すべてを抽出できないかもしれない。

**architect に渡す緩和制約。** ADR はパース戦略を指定しなければならない — 行単位のgreedy マッチ、複数行ブロックパーサー、または構造化抽出アプローチのいずれを使うか。Spec の受け入れ基準は検出する *何を* を述べ、architect はミスキーを避けるために *どのように* テーブルをパースするかを決定する。これが ADR-017 に委ねられた主要な構造的キーイング決定である。 <!-- ref-allow: ADR-017 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->

### リスク R-02: 再議論なしに継承されるポスチャー

**説明。** ADR-015 §Decision point 3 は明示的に述べている: 「#05/#06 を default-off として扱うことは subject-matter-presence ルール (Roadmap ドリフトと EN/JA パリティも always-present な構造的契約である) と矛盾するため、ルールはそれらのポスチャーも決定する。」本マイルストーンの always-on ポスチャーは **継承** されたものであり、新しい決定ではない。ここで継承として文書化することで、将来のレビュアーが確立した決定を読まずに再議論することを防ぐ。

**本 Spec の記述:** 本マイルストーンの CI ポスチャーは always-on であり、ADR-015 が確立した subject-matter-presence ルールを継承する。新しいポスチャー決定は不要であり、適切でもない。ルールは拘束力を持つ。

### リスク R-03: #04 ディテクターとのスコープ重複

**説明。** #04 dangling-reference detector は文書の散文スコープで壊れた `adr:` パス参照 (存在しないファイルへのポインター) を検出する。このディテクターは、両方のファイルが存在していても *双方向リンクの不整合* を検出する。狭い重複がある: 存在しない ADR ファイルへの Roadmap `adr:` リンクは両方のディテクターに検出される。

**緩和策。** 重複は許容される — 単一の壊れたリンクが 2 つの CI 失敗を生じることは 1 つよりも強いシグナルであり、2 つのチェックは異なる概念オーナーに対応する (#04 ディテクターは「ファイルが存在するか?」を所有し、このディテクターは「双方向契約が満たされているか?」を所有する)。重複が偽陽性の源になる場合、architect はスクリプトヘッダーにこれを文書化すべきである。

### リスク R-04: ADR-017 前方参照 <!-- ref-allow: ADR-017 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->

**説明。** 本 Spec は ADR-017 を構造的キーイングのための forthcoming architect 決定として指名している。ADR-017 は Spec 作成時点では存在せず、このファイル内の `<!-- ref-allow: -->` マーカーがそれらの行に対する #04 ディテクターの偽陽性を抑制している。

**注意:** `<!-- ref-allow: -->` 抑制は本 Spec ファイル (`specs/05-roadmap-drift-detection-ci.md`) のみに存在し、`specs/03-cross-session-progress-persistence.md` が ADR-016 に対して設定した先例に従っている。`CLAUDE.md` には現れない (常時読まれる単一成果物での `ref-allow` 抑制を制限する ADR-015 の amendment に違反することになる)。

## スコープ対象外

- 検出されたドリフトの自動修正 — ディテクターは報告のみ。
- すべての ADR が Roadmap 逆参照を持つことの強制 — 逆参照がないことは pre-Roadmap および Roadmap-mechanism ADR にとって有効。
- `spec:` 予約済みリンクのディスク存在確認 — これは #04 ディテクターの ADR-014 予約カーブアウトドメイン。
- 双方向パリティの検証 — これはマイルストーン #06。
- `workarounds/` レジストリファイル内の参照のチェック。
- GitHub Actions 以外の CI プロバイダーへのチェックの移植。

## 参照

- ADR-014 (Roadmap index as single entry point) — 本ディテクターが強制する双方向 `adr:` ↔ `Roadmap row:` 契約を確立する。§Consequences → Negative が本マイルストーンを委ねられた緩和策として指名する。Spec 予約ルールのカーブアウト (Amendment 2026-05-16) は本ディテクターのスコープ外
- ADR-015 (Dangling-reference detector — always-on、subject-matter-keyed CI posture) — §Decision point 3 が本マイルストーンの always-on ポスチャーを継承 (新決定ではない) として固定する (#05 を明示的に指名)。§Decision point 1 は本ディテクターが複製せずに補完する #04 スコープ境界を定義する
- `specs/04-dangling-reference-detector.md` — 本マイルストーンがモデルとする構造的兄弟。#04 の Non-goals セクションが #05 を Roadmap ドリフトの担当ディテクターとして明示的に指名する
- `.claude/meta/scripts/check-dangling-refs.sh` — 本マイルストーンのスクリプトが従う再利用可能なスクリプトパターン (#04)
- `.github/workflows/dangling-ref-check.yml` — 本マイルストーンのワークフローが従う再利用可能なワークフローパターン (#04)
- ADR-017 — 双方向チェックの構造的キーイングとテーブルパース戦略の forthcoming architect 決定 (本マイルストーンが実装に移行する際に作成される) <!-- ref-allow: ADR-017 is the forthcoming architect decision for this milestone's structural keying, to be authored when implementation begins -->
- Roadmap row: #05
