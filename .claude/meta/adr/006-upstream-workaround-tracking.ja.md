# ADR-006: Upstream ワークアラウンド追跡 — ライブラリ・フレームワーク起因問題のライフサイクル管理

> 英語版: [006-upstream-workaround-tracking.md](./006-upstream-workaround-tracking.md)(原文・Source of Truth)

## ステータス

Accepted — 2026-05-06; Amended — 2026-05-20 (Roadmap #19): デフォルト `enabled` 値を `false` から `true` に変更。下記 §改訂 — 2026-05-20 (default-on への移行) を参照。原則 1 のシングルスイッチ形態は保持され、変更されるのはスイッチのデフォルト値のみ。

## 背景

派生プロジェクトで不具合が起きたとき、原因は自リポにあるか、あるいは依存
ライブラリ・フレームワーク (upstream) 側にあるかのどちらかです。本テンプ
レートは Development Workflow の step 0 に「Research & Reuse」を据えてお
り、その結果、依存側が原因として疑われる頻度は構造的に高くなります。に
もかかわらず、テンプレートには「upstream 起因と疑った/確定したあと、ど
うするか」を定めた仕組みがありません。4 エージェントによる協議
(architect / docs-researcher / devops-engineer / technical-writer) で、
以下のギャップが特定されました。

1. **切り分けプロトコルのギャップ**: 「自リポ起因か upstream 起因か」を
   決める責務がどの agent にもありません。implementer も code-reviewer
   も症状には触れますが、切り分け判断の所有者が不在です。
2. **upstream Issue 検索のギャップ**: `docs-researcher` はドキュメント
   検索向けの freshness-safe ガイドラインを持つ一方、Issue Tracker 検索
   向けの規約は未定義で、重複起票・stale な検索結果のリスクが高いまま
   です。
3. **Workaround 記録のギャップ**: Workaround を実装した後、upstream
   Issue URL・影響バージョン範囲・検証手順・削除トリガーを記録する
   テンプレート資産がなく、原因より長く残る傾向があります。
4. **削除トリガーのギャップ**: upstream のパッチがリリースされても、
   既存 Workaround が削除可能になったことを CI が検知しません。
   Dependabot は version bump を発行するだけで、ローカル Workaround と
   は連動しません。

累積的な影響として、Workaround は失効機構のないまま技術的負債として静
かに溜まります — テンプレートの「explicit > implicit」アーキテクチャ
原則がまさに防ごうとしているパターンです。

## 決定

**default-off / opt-in** の Upstream ワークアラウンド追跡レイヤーを導
入します。責務は既存 agent (新設なし) に分配し、各 Workaround は
`workarounds/NNN-*.md` の単一ファイルとして記録し、言語非依存の薄い CI
足場を提供します。派生プロジェクトは Workaround の数が手動追跡の限界
に達した時点で有効化します。

### 原則

1. **default-off、シングルスイッチ**: 有効化は `.github/workaround-tracker.yml`
   の `enabled: true` への 1 箇所変更のみ。ワークフロー側に外すべき
   `if: false` は存在せず、各ジョブが config を読んで短絡終了します。
   「片方だけ有効化して気付かない」を構造的に防ぎます。
2. **意思決定 (ADR) と追跡 (レジストリ) を分離**: 「Workaround を採用
   するか」の判断は、それがアーキテクチャを変更する場合 (例: upstream
   をフォークして内製管理) のみプロジェクトの ADR ストリームに残します。
   「どんな Workaround が、どの Issue 用に、どのバージョンまで存在する
   か」はレジストリエントリ `workarounds/NNN-*.md` に記載します。両者
   は相互参照しますが、内容を重複させません。
3. **コードマーカーは行レベル、レジストリはそれ以外を全て**: ソース
   コード内の構造化コメントマーカー
   (`WORKAROUND-UPSTREAM(<owner>/<repo>#<issue>, fixed=>=<version>)`)
   は upstream Issue と期待修正バージョンを行レベルで識別します。
   パッケージ識別子・セキュリティ影響・検証手順・CHANGELOG マッピング
   はレジストリエントリに置きます。CI は両者を相互参照し、片方だけで
   は不十分です。
4. **切り分けは規約化されたプロトコル、ヒューリスティックではない**:
   「自リポ vs upstream」の切り分けは 3 ステップ (最小再現 → 依存固定
   再現 → known issues 検索) のプロトコルです。`orchestrator` が起動
   し、`docs-researcher` が実行します。
5. **言語非依存な CI スコープのみ**: 出荷するワークフローは `git grep`
   によるマーカー検出、`yq` (`ubuntu-latest` プリインストール) による
   YAML パース、`gh pr comment` による Dependabot 注釈のみ。
   ecosystem ごとの lockfile パースが必要なバージョン比較ロジックは
   **意図的に出荷しません**。派生プロジェクトはスタックを確定してから
   追加します。
6. **Learning Mode と直交**: 追跡は本番運用の関心事、Learning Mode は
   default-off の学習関心事です。Workaround レコードが
   `dependency-management` ドメインの参考資料になることはあり得ます (片
   方向参照のみ) が、追跡レイヤーは Learning Mode の有効/無効に関係な
   く機能します。

### 責務分担 (既存 agent への割り付け)

| ステップ | 担当 |
|---|---|
| 切り分けトリアージ起点 — 「自リポか upstream か」 | `orchestrator` |
| 切り分け 3 ステップ (最小再現 / 依存固定再現 / known issues 検索) | `docs-researcher` |
| Workaround 採用判断 (アーキテクチャ的に重要な場合) | `architect` |
| コードマーカー設置と構造化コメント | `implementer` |
| マーカーの構造妥当性レビュー | `code-reviewer` |
| CI 足場 + Dependabot 連携 | `devops-engineer` |
| レジストリ保守 + 削除時の CHANGELOG マッピング | `technical-writer` |

該当する 7 agent には `.claude/agents/` 配下のファイルに短い節を追記
し、単独 agent 呼び出し時にも責務が見つかるようにしています。

### 必須ワークアラウンドレコードフィールド

CI 足場が要求する YAML front-matter のフィールドです。「必須」列は CI
パーサが実際に読む値を反映しています。

| フィールド | 必須 | 補足 |
|---|---|---|
| `id` | 必須 | 数値、ゼロパディング (例: `001`) |
| `status` | 必須 | `active` / `resolved` / `superseded` — マーカー整合チェックで使用 |
| `upstream.package` | 必須 | manifest 上のパッケージ名。Dependabot 連携で使用。許容文字: `[A-Za-z0-9@/_.+:-]+` (`:` は Maven の `groupId:artifactId` に対応) |
| `upstream.ecosystem` | 必須 | `npm` / `pypi` / `go` / `crates` / `maven` / `pub` / `swift` / `other` のいずれか |
| `upstream.issue_url` | 必須 | upstream Issue または PR の permalink。CI が `<owner>/<repo>#<n>` を抽出してマーカーと相互参照 |
| `affected_versions` | 必須 | semver range (例: `>=2.1.0 <2.3.0`) |
| `verification_steps` | 必須 (本文) | 削除後に正常性を確認する最小手順 |
| `security_impact` | 必須 | `none` / `low` / `medium` / `high` のいずれか |
| `expected_fix_version` | 任意 | upstream マイルストーンが公開されている場合 |
| `expires_on` | 任意 | `YYYY-MM-DD`。CI が陳腐化を検知 |
| `user_impact` | 任意 | 削除時の CHANGELOG カテゴリ判定に使用 — 下記参照 |

### 削除時の CHANGELOG マッピング

Workaround が `status: resolved` に遷移したとき、`technical-writer` は
`user_impact` を Keep a Changelog 1.1.0 に従って CHANGELOG セクション
にマッピングします。

| `user_impact` | CHANGELOG での扱い |
|---|---|
| `internal` | **CHANGELOG には記載しない**。Keep a Changelog 1.1.0 はファイルをユーザー視点の変更のために予約しており、内部のみの削除は記載対象外 |
| `changed` | `### Changed` にエントリ追加 |
| `fixed` | `### Fixed` にエントリ追加 |

別途内部リリースログを管理しているプロジェクトは内部削除をそちらに記
録できますが、ユーザー向けの `CHANGELOG.md` は Keep a Changelog に厳
密に従います。

### 削除検知戦略

`docs-researcher` の評価による:

主要シグナルは **依存ライブラリのバージョン比較** (現在インストールさ
れているバージョンを `affected_versions` と比較)。CHANGELOG パースは
補助、GitHub Issue の `closed` イベントは backport パターンにより信頼
性が低いため検知の根拠としません。

テンプレートが出荷する CI 足場は言語非依存の部分のみ実行します:
`WORKAROUND-UPSTREAM` マーカーを grep し、active レジストリエントリ
と相互参照し、参照パッケージに触れる Dependabot PR に冪等な (sticky)
コメントを付与するだけです。バージョン範囲の充足判定は、派生プロジェ
クトが ecosystem 固有のジョブ (自身の lockfile を読む) を追加するこ
とに委ねます。

### 提供成果物

| パス | 目的 |
|---|---|
| `.claude/templates/workaround-template.md` | Workaround レジストリエントリのテンプレート (YAML front-matter + 本文) |
| `.github/workflows/workaround-check.yml` | 再利用可能 CI 足場 (config でゲート) |
| `.github/workaround-tracker.yml` | 設定ファイル (`enabled: false` 既定) |
| `.claude/meta/references/upstream-workaround-tracking.md` | 詳細解説 (切り分けプロトコルと Issue Tracker 検索ガイドラインを含む) |
| 7 agent ファイル (`orchestrator`, `docs-researcher`, `architect`, `implementer`, `code-reviewer`, `devops-engineer`, `technical-writer`) の更新 | エージェント責務追加 |
| `.claude/CLAUDE.md`, `README.md`, `README.ja.md` の更新 | ワークフロー step 追加 + 発見可能性 |

### 範囲外 (意図的に)

- ecosystem ごとの lockfile パーサ
- Workaround 検出のための CodeQL クエリ
- upstream Issue Tracker との双方向同期
- `expires_on` 経過時の Issue 自動作成 (派生プロジェクトの判断に委ねる。
  CI 足場は PR コメント付与までを行うが Issue 作成は行わない)
- **`dependabot-annotate` 以外のジョブを `pull_request_target` に切り
  替えること**。`dependabot-annotate` は Dependabot で
  `pull-requests: write` を得る唯一の手段が `pull_request_target` で
  あるため使用しますが、`github.actor == 'dependabot[bot]'` と
  `pull_request.head.repo.full_name == github.repository` でゲート
  され、PR head のコードを **チェックアウトしません**。他のジョブに
  `pull_request_target` を追加したり、上記ゲートを緩和することは典型
  的な落とし穴であり禁止です。

## 帰結

### ポジティブ

- upstream Workaround のライフサイクル全体 (疑い → 削除) が可視化される
- シングルスイッチ opt-in (`enabled: true`) により「片方だけ有効化し
  て CI が動かない」サイレント失敗モードを構造的に排除
- 新 agent を導入しない — 既存 7 agent に責務を分散し、チームサイズを
  維持
- コードマーカーとレジストリの分離により、機械的 CI チェックが行レベ
  ル (Issue 識別) とレジストリレベル (パッケージ識別、検証、セキュリ
  ティ) で source of truth を持ちつつ、コメントを理解するために YAML
  を読まなくてよい
- マーカー ↔ レジストリの双方向相互参照により、両方向の drift (マー
  カーがあるがエントリがない / active エントリがあるがマーカーがない)
  を検出

### ネガティブ

- テンプレート内部の参照ドキュメントとテンプレートファイルが増え、派生
  プロジェクトが読むかもしれない表面積が拡大する
- CI 足場は意図的に不完全 (バージョン比較なし) で、turn-key 解を期待す
  る adopter を混乱させる可能性がある。ギャップを明示的に文書化するこ
  とで緩和
- `dependabot-annotate` は高リスクトリガーである `pull_request_target`
  を使用する。付随するゲート (actor / 同一リポ / PR head 非チェック
  アウト) は必須であり、緩和してはならない
- マーカーとレジストリエントリが意味的に乖離するリスク (例: Workaround
  コードが進化したが `verification_steps` が更新されない)。CI 足場が
  検出するのは構造的 drift のみ

### 中立

- テンプレートのバイリンガル方針 (英語 source / 日本語訳) は ADR-006
  (`.md` + `.ja.md`) と README 節には適用されますが、以下には **適用
  しません**:
  - Workaround レジストリエントリ (エンジニアは英語の upstream Issue
    を直接読むため、変動の早いコンテンツでの翻訳乖離を回避)
  - `.claude/meta/references/upstream-workaround-tracking.md`。これ
    は意図的な例外で、`.claude/meta/references/domain-taxonomy.md`
    (これも英語のみ) と整合します。読者層は英語の upstream コンテン
    ツを既に読むエンジニア/agent であり、bilingual 保守は変動の早い
    内容に追いつかないためです
- ADR テンプレートは **改修しない**。Workaround レコードは異なるライフ
  サイクルの別資産で、ADR の「決定であって状態ではない」性質を曇らせない
  ため

## 検討した代替案

| 代替案 | 利点 | 欠点 | 採用しなかった理由 |
|---|---|---|---|
| `adr-template.md` に「Workaround」節を追加 | テンプレート 1 つで保守 | 不変の決定と可変の状態を混在させる。ADR は状態変化に伴う書き換えを想定しない | architect / technical-writer がライフサイクル不一致を理由に却下 |
| コードマーカーのみ (レジストリなし) | 最大限の簡潔さ | 構造化されていない grep 専用データ。複数行コンテキスト (検証手順、セキュリティ影響) を持てない。非エンジニアには検索困難 | technical-writer が発見可能性の低さで却下 |
| レジストリのみ (マーカーなし) | source of truth が 1 つ | 「全マーカーにレジストリエントリが存在する」を CI で検証するためにレジストリを round-trip しなければならない。レビュアーはコメントを理解するためにレジストリ参照が必要 | レビュー作業性で却下 |
| default-on の CI ワークフロー | 採用率が高い | Workaround ゼロのプロジェクトに保守コストを強要。テンプレート既存の default-off 規約と矛盾 | devops-engineer が作業性と規約整合性で却下。**2026-05-20 Roadmap #19 で再評価: この代替案が選択された。** テンプレートの並列 CI scaffold (#01 `verification.yml`、forthcoming #20 `compliance.yml`) が default-active 規約を確立し、具体的な検証 (Spec AC-3) が空の `workarounds/` インベントリで CI ノイズゼロを確認したことにより、コスト/ベネフィットの計算が変わった。「workaround ゼロのプロジェクトへの保守コスト」という当初の異議は無効化された。下記 §改訂 — 2026-05-20 (default-on への移行) を参照。 |
| 二重スイッチ (workflow `if: false` + config `enabled: false`) | 二重防御 | 両者の drift がサイレント失敗モードになる (片方だけ有効化)。オンボーディング負荷も倍 | Round 1 レビューで fail-unsafe 性が指摘され却下 |
| ecosystem ごとのバージョン比較ジョブを出荷 (TS/Go/Python など) | adopter にとって turn-key | バージョンとツーリングが陳腐化する。`ci-base.yml` が言語セットアップを含めない理由と同じ | `ci-base.yml` の言語非依存スタンスと同じ理由で却下 |

## 参照

- ADR-005 — テンプレ内部 vs 派生プロジェクト層の分離原則。本 ADR は同
  じ分割原則に従う
- `.claude/agents/docs-researcher.md` — Search Guidelines。本 ADR で
  Issue Tracker 検索向けに拡張する
- `.github/workflows/security.yml` — `if: false` default-off の前例
  (本 ADR は Principle 1 の理由から異なる機構 (シングル config スイッ
  チ) を採用するが、family resemblance は意図的)
- 初版実装に対するマルチエージェントレビューが、最終形 (シングル
  スイッチ opt-in、8 フィールド必須スキーマ、`pull_request_target`
  規律、`internal` → CHANGELOG 不記載、リファレンス文書のバイリン
  ガル例外) で対処された問題を顕在化させた。findings は上記の
  §決定 と §検討した代替案 に統合済みで、別途のレビューログはコ
  ミットしない。
- Roadmap 行: #19 (この ADR の 2026-05-20 改訂がそのマイルストーンで決定した default-on 移行を記録する。
  下記 §改訂 — 2026-05-20 を参照)

## 改訂 — 2026-05-20 (default-on への移行)

この改訂は `.github/workaround-tracker.yml` の `enabled` のデフォルト値を `false` から `true` に変更します。
Roadmap マイルストーン #19 (「Workaround tracking default-on」) の設計決定を記録し、
ADR-006 整合性の問題を文書で対処することを求める Spec AC-5 要件を解決します。
改訂は原則 1 の**シングルスイッチ**形態を保持します — 設定フラグはまだ 1 つで、ワークフローファイルに
外すべき第 2 の `if: false` はなく — スイッチの**デフォルト値のみを変更**します。
すでに `enabled: false` を設定した fork の grandfather プロパティは intact です:
その明示的な値は引き続き新しいテンプレートデフォルトを上回ります。

### 三項分類 — 1/3、改訂であって新 ADR でない

Spec は `architect` に ADR-018 Alternative-B 三項識別器
(新しい契約境界 + 新しいキーイング/メカニズム + 新しい構造的成果物 ⇒ 新 ADR;
既存の契約内の結果明確化/値変更 ⇒ 改訂) を渡します。#19 に各条項を適用すると:

- **新しい契約境界か? Yes。** 原則 1 のテキストはデフォルト方向として default-off を契約のデフォルトとして固定し、
  元の Alternatives テーブルは記録された根拠で「default-on CI ワークフロー」を却下していました。
  そのデフォルト方向を逆転させることは、変更されない契約内の値の調整ではなく、契約レベルの変更です。
- **新しいキーイング/メカニズムか? No。** `enabled` YAML フィールド、`yq -r '.enabled // false'` 読み取りパターン、
  3 つのジョブそれぞれの `if: steps.cfg.outputs.enabled == 'true'` 短絡はバイト単位で変更されません (Spec AC-2)。
  新しい YAML キー、新しい正規表現、新しい短絡構文はありません。
  `pull_request_target` 規律 (この ADR の Out of scope、最終箇条) は変更なしに保持されます。
  `annotate_dependabot_prs: false` (AC-9) と `fail_on_marker_drift: false` (AC-10) は保守的な opt-in デフォルトのまま。
- **新しい構造的成果物か? No。** 新しいファイル、新しいディレクトリ、新しい CI ワークフロー、
  新しい検出器、新しいテストスイートはありません。Spec AC-4 はテンプレート本体で `workarounds/` ディレクトリが
  存在しないことを要求します。Spec AC-6/AC-7 は既存の 7 つの検出器と 8 つのテストスイートが
  変更なしにパスすることを要求します。

三項合計: **1/3**。ADR-018 Alternative-B (および同じ識別器の ADR-022 §1 適用) により、
1-2/3 は**既存 ADR の改訂**に向かい、新 ADR ではありません。ADR-022 の「新 ADR vs. 改訂」の理由付けは
三項が 3/3 で発火して新 ADR を正当化することを明示的に述べており、#19 の 1/3 は反対のケースです。
新 ADR-023 は検討されたが却下された (Spec AC-5 はその名前を使用): <!-- ref-allow: counterfactual reference; ADR-023 deliberately not issued per triad 1/3 outcome | expires: 2026-06-20 -->
ADR-006 自体に解決策を組み込むことで、歴史的記録と新しい決定を単一の source of truth に同居させ、
ADR-014 の改訂形態に一致し (ADR-014 は 2026-05-16 に新 ADR 番号を生成せずに 2 つの改訂を受けた)、
将来の読者が調整する必要のある 2 つの ADR に原則 1 のポリシーが分断されることを回避します。

### 元の「default-on CI ワークフロー」却下がもはや成立しない理由

2026-05-06 の Alternatives テーブルは「default-on CI ワークフロー」を 2 つの理由で却下しました。
現在利用可能な具体的な証拠に対してここで再検討します:

1. **「workaround ゼロのプロジェクトに保守コストを課す。」**
   Spec AC-3 は逆を経験的に検証します: `enabled: true` で `workarounds/` にファイルがない場合、
   `marker-consistency` ジョブは終了コード 0 で完了し `Markers found: 0` と
   `Active registry entries: 0` を示すステップサマリーを生成します。
   フォールスポジティブ失敗も保守作業もなく — ジョブは実行されて何も報告しません。
   元の懸念は空インベントリ境界で発生しない保守コストを想定していました。
   短絡がすでにそれを吸収しています。
2. **「テンプレート既存の default-off 規約と矛盾する。」**
   規約自体が変化しました。Roadmap マイルストーン #01 (`research.enabled: true` でコミットされたデフォルトとしての
   `verification.yml`) が 2026 年に出荷し、デフォルト状態が空インベントリに対して安全であることが確認された
   CI scaffold が fork が手動アクティベーションなしで実際の保護を継承できるようデフォルトでアクティブに
   出荷されるという前例を確立しました。forthcoming マイルストーン #20 (`compliance.yml` をアクティブなデフォルトとして) は
   同じパターンを拡張します。#01 と #20 が opt-in CI scaffold ファミリーの default-active 規約を確立することで、
   workaround-tracker の default-off 位置は現在**外れ値**となっており、デフォルトではありません。
   2026-05-06 の「既存の default-off 規約」はもはやテンプレートの実際のスタンスを説明していません。

元の却下は 2026-05-06 時点では妥当でした (#01 の前例はなく、AC-3 の検証は実施されていなかった)。
2026-05-20 時点では成立しません。

### この改訂が変更すること

| 項目 | 変更前 (2026-05-06) | 変更後 (2026-05-20) |
|---|---|---|
| `.github/workaround-tracker.yml` のデフォルト `enabled` | `false` | `true` |
| 原則 1 の形態 | シングルスイッチ、default-off | シングルスイッチ、**default-on** |
| 既存 fork のオーバーライド (`enabled: false` がすでにコミット済み) | 尊重される | 尊重される (自動移行なし) |
| `annotate_dependabot_prs` デフォルト | `false` | `false` (変更なし; Spec AC-9) |
| `fail_on_marker_drift` デフォルト | `false` | `false` (変更なし; Spec AC-10) |
| `expires_on` / `expiry_warning_days` のセマンティクス | ADR-006 に従う | ADR-006 に従う (変更なし; Spec Non-goals) |
| ワークフロー短絡ロジック | `enabled` フラグに従う | `enabled` フラグに従う (バイト単位で変更なし; Spec AC-2) |
| `pull_request_target` 規律 | `dependabot-annotate` ジョブに制限 | `dependabot-annotate` ジョブに制限 (変更なし; Out of scope 最終箇条) |

### 原則 1 — 改訂テキスト

元の原則 1:

> **default-off、シングルスイッチ。** 有効化は `.github/workaround-tracker.yml` の
> `enabled: true` への 1 箇所変更のみ。

改訂された原則 1 (2026-05-20 以降有効):

> **default-on、シングルスイッチ。** 無効化は `.github/workaround-tracker.yml` の
> `enabled: false` への 1 箇所変更のみ。ワークフロー自体にはまだ外すべき第 2 の `if: false` はなく
> — すべてのジョブが config を読んで無効時に短絡します。非アクティブのままにしたい fork
> (例: workaround インベントリがゼロで使用予定のないテンプレートの早期採用者) は
> シングルスイッチをオフにします。元の 2026-05-06 の文言に対する非対称性は意図的で、
> 反転したデフォルトを反映しています。

「シングルスイッチ、外すべき第 2 のトグルなし」というプロパティ — 原則 1 の load-bearing な
失敗モード防止 — は変更なしに保持されます。変わるのはデフォルトの極性のみです。

### この改訂のスコープ

- 決定 §原則 1 は上記の通り改訂されます。他の原則 (2 〜 6) は変更されません。
- 検討した代替案テーブル — 「default-on CI ワークフロー」行に「2026-05-20 Roadmap #19 で再評価」
  の注記が追加されます。歴史的な却下テキストは並べて逐語的に保持されます。
- ステータス行に `Amended — 2026-05-20` の表記が追加されます。
- Out of scope は変更されません: `dependabot-annotate` 以外のジョブへの `pull_request_target`
  拡張禁止は intact で保持されます。
- 必須ワークアラウンドレコードフィールド、CHANGELOG マッピング、削除検知戦略、提供成果物の各節は変更されません。
- 日本語版 (`006-upstream-workaround-tracking.ja.md`) は step 7 に `technical-writer` が
  Roadmap #06 heading-tree parity 所有権に従って同等の改訂を受けます。
- `.claude/CLAUDE.md` の `### Upstream workaround lifecycle` セクション (「ships **default-off**」) は
  この改訂ではなく step 7 に `technical-writer` が #19 後の状態を反映して更新します。

### `implementer` への実装指示

architect レベルで記録された上記の決定: **`.github/workaround-tracker.yml` を編集して
`enabled` のリテラル値を `false` から `true` に変更する**。代替メカニズム (ワークフローの
`yq -r '.enabled // false'` フォールバックを `// true` に変更して `enabled` を欠如させる) は
2 つの理由で**却下**されました:

1. **明示的 > 暗示的。** この ADR-006 自体の原則 5 (「言語非依存な CI スコープのみ」) は
   可視な動作に基づきます。より広いテンプレートの `## Architecture Principles` テーブル
   (`.claude/CLAUDE.md`) には「explicit over implicit」が含まれます。config ファイルを読むユーザーは
   ファイルでアクティブなデフォルトを確認できるはずです。フォールバック駆動のデフォルトは
   ユーザーがワークフローを読まない限りアクティブな状態を不可視にします。
2. **最小ブラスト半径。** AC-2 はワークフロー短絡ロジックがバイト単位で変更なしであることを要求します。
   config ファイルのみを編集することでその制約を最大限に尊重します。ワークフローの `// false`
   フォールバックを変更するとワークフローファイルに触れ、config ファイルの意図と一致した状態を
   保つべき第 2 のサイトを作成します。

implementer は `.github/workaround-tracker.yml` の行 12 を `enabled: false` から `enabled: true` に編集します。
付随するヘッダーコメント (「Master switch for the workaround-check.yml workflow.」) は変更なしで保持されます。
#19 後の default-on 状態に言及するオプションの 1 行の明確化を追加することは可能ですが、
この改訂では必須ではありません。ワークフローファイルの編集は不要です。
