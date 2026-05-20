# Workaround Tracking Default-On

## Status

Approved

**Owner:** product-manager
**Target release:** Roadmap 行 #19

## Problem

テンプレートは `.github/workaround-tracker.yml` を `enabled: false` で出荷します。テンプレートを
clone してすぐに upstream workaround を蓄積し始めた fork は、メンテナーが設定スイッチを切り替えるまで
CI シグナルを得られません。これは特に、最初の workaround がフォーク直後ではなく数週間後に現れるプロジェクトで
忘れがちなステップです。その結果、追跡レイヤーがディスク上に存在しながら黙って何もせず、
実際には追跡がアクティブでないにも関わらずメンテナーに「管理された workaround がない」という
誤った安心感を与えます。

ADR-006 の原則 1 は、次の根拠で意図的に default-off を選択していました: 「オフのままでもペナルティはない。
workaround ゼロのプロジェクトは CI ノイズもゼロになる。」これは ADR-006 執筆時点では妥当でした。
しかしテンプレートの関連マイルストーン (#01 と forthcoming #20) は一貫した前例を確立しています: 
CI scaffold がそのデフォルト状態で空のインベントリに対して安全であることが確認されたら、
fork が手動アクティベーション不要で実際の保護を継承できるよう、デフォルトでアクティブな状態で出荷します。
workaround がゼロのプロジェクトで workaround tracking をアクティブにするコストはまさにゼロです
(3 つのジョブすべてが空の入力で短絡終了します)。オフのままにするコストは、
ADR-006 を十分に読んでスイッチを切り替えなかったメンテナーには追跡レイヤー全体が見えなくなることです。

マイルストーン #19 は、`.github/workaround-tracker.yml` の `enabled` のデフォルトを `false` から `true` に
移行すべきかを評価し、architect の ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> が
テンプレートの全体的な default-active 規約と整合していると判断した結果を実現します。

## Goals

- テンプレートは、workaround tracking を使用したい fork メンテナーに手動アクティベーション不要の状態で出荷します。
- #19 後のテンプレートから clone した fork がすぐに PR ワークフローを適用したとき、
  設定変更なしに `workaround-check.yml` の CI カバレッジを受けます。
- `workaround-check.yml` の短絡ロジック (3 つのジョブすべてが `steps.cfg.outputs.enabled == 'true'` でゲート)
  は、使用されるデフォルト config 値にかかわらず、正しく変更されません。
- このマイルストーン出荷後、テンプレート本体に `workarounds/` ディレクトリが存在しないことを確認し、
  実際の workaround エントリが導入されないことを確認します。
- 7 つの標準検出器とその 8 つのテストスイートが、このマイルストーンの変更後に EXIT=0 でパスします。

## Non-goals

- **実装メカニズムは ADR-023 に委ねます。** <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> このマイルストーンの達成方法 — `.github/workaround-tracker.yml` の
  `enabled: false` を `enabled: true` に編集する、ADR-006 原則 1 を改訂する、
  後継 ADR-023 を発行する、あるいは別の構造的アプローチを取る <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> — は architect の判断です。
  Spec は観測可能な結果のみを定義します。
- **本 Spec による ADR-006 原則 1 の改訂はありません。** ADR-006 原則 1
  (「default-off、シングルスイッチ」) が維持されるか、改訂されるか、上書きされるかは ADR-023 で解決します。<!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  本 Spec は予断を持ちません。
- **`workaround-check.yml` の短絡ロジックの変更はありません。** 3 つのジョブの
  `steps.cfg.outputs.enabled == 'true'` によるゲートは正しく、セキュリティ上の根拠があり
  (`dependabot-annotate` ジョブの `pull_request_target` ゲートは load-bearing)、スコープ外です。
  他のジョブへの `pull_request_target` 追加を禁止する ADR-006 Out-of-scope は変更されません。
- **`.github/workaround-tracker.yml` の `expires_on` / `expiry_warning_days` の変更はありません。**
  これらのフィールドは upstream workaround レジストリエントリを管理し、CI 除外マーカーは管理しません。
  ADR-006 のメカニズムであり、#18 で導入された ADR-022 ref-allow 有効期限メカニズムとは
  カテゴリ的に別物です。#19 はいずれのフィールドも変更しません。
- **`workarounds/` にリアルな workaround エントリを追加しません。** テンプレート本体には
  実際の workaround レジストリファイルを出荷しません。ディレクトリは存在しない状態のままであることが期待されます。
- **#16–#18 との MECE 分離。** #16 は ADR-001 Status 語彙修正を所有し、#17 は
  ADR-002/003/004 正規化と CHANGELOG 同期を所有し、#18 は CI 除外 (ref-allow) 有効期限ライフサイクルを所有します。
  #19 は workaround-tracker の default-on 移行のみを所有します。
- **#20 との MECE 分離。** Roadmap #20 (「`compliance.yml` をアクティブなデフォルトとして commit」) は
  同じ default-active パターンを compliance scaffold に適用します。#19 と #20 は構造的に並列ですが
  重複しません: #19 は `.github/workaround-tracker.yml` を対象とし、#20 は `.claude/compliance.yml` を対象とします。
  一方の実装が他方の実装を構成しません。
- **Spec 執筆時点での CHANGELOG 編集はありません。** technical-writer は開発ワークフローの
  step 7 で CHANGELOG エントリを追加します。Spec 執筆時ではありません。
- **本 Spec による JA sibling の執筆はありません。** `specs/19-workaround-tracking-default-on.ja.md` <!-- ref-allow: JA sibling authored by technical-writer at step 7; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  は technical-writer が step 7 で執筆します。heading-tree parity は Roadmap #06 が管轄します。
- **Spec 執筆時点での `.claude/CLAUDE.md` `### Upstream workaround lifecycle` セクション更新はありません。**
  そのセクションの「ships default-off」という表現は #19 後の状態を反映するために更新が必要な場合があります。
  変更の可否と方法は ADR-023 の設計スコープの一部です <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> であり、
  technical-writer が step 7 に実装します。Spec 執筆時ではありません。

## User stories

| 立場 | したいこと | 目的 |
|------|-----------|------|
| fork メンテナー | テンプレートを clone してすぐに workaround tracking が CI でアクティブになってほしい | ADR-006 を読んで CI カバレッジが始まる前に設定スイッチを発見して切り替える必要がない |
| workaround を追加する implementer | 設定を有効化せずに `WORKAROUND-UPSTREAM` マーカーとレジストリエントリを置きたい | CI scaffold が最初の PR でマーカー/レジストリの整合性をすでに検証している |
| PR を検証する code-reviewer | プロジェクトのセットアップ前提なしで marker-consistency ジョブが実行されているのを見たい | 設定がアクティブ化されているかチェックするのではなく CI フィードバックを頼りにできる |
| テンプレートメンテナー | workaround ゼロのプロジェクトが default-on でゼロの CI ノイズを生成することを確認したい | 新しい fork でのフォールスポジティブ失敗のリスクなくデフォルトを自信を持って推奨できる |

## Acceptance criteria

- **AC-1 — 出荷テンプレートのデフォルト `enabled` 値:**
  #19 後のテンプレートが与えられたとき、`.github/workaround-tracker.yml` を変更せずに fork を作成すると、
  `enabled` フィールドが `true` になる (またはワークフローが `true` と解釈するデフォルトで欠如している)。
  正確なメカニズム (フィールド編集 vs. フォールバックロジック) は ADR-023 が決定します。<!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->

- **AC-2 — CI 短絡ロジック変更なし:**
  今日の `workaround-check.yml` (3 つのジョブ、それぞれ `steps.cfg.outputs.enabled == 'true'` でゲート)
  が与えられたとき、このマイルストーンが出荷されると、短絡ロジックはバイト単位で変更されません。
  新しい `if:` 句は追加されず、既存のゲートは削除されません。
  `dependabot-annotate` ジョブの `pull_request_target` ゲート (`github.actor == 'dependabot[bot]'` および
  `pull_request.head.repo.full_name == github.repository`) は変更なしに保持されます。

- **AC-3 — 空インベントリでの CI ノイズゼロ:**
  `enabled: true` (#19 デフォルト) で `workarounds/` にファイルがない (テンプレートの出荷状態) fork が与えられたとき、
  PR で `workaround-check.yml` が実行されると、`marker-consistency` ジョブが終了コード 0 で完了し、
  `Markers found: 0` と `Active registry entries: 0` を示すステップサマリーを生成します。
  フォールスポジティブ失敗は発生しません。

- **AC-4 — テンプレート本体から `workarounds/` が存在しない:**
  #19 コミットが与えられたとき、リポジトリルートで `ls workarounds/` を実行すると、
  ディレクトリが存在しない (または Git 規約上必要な場合は `.gitkeep` のみ含む) ことが確認されます。
  リアルなレジストリエントリファイルは存在しません。

- **AC-5 — ADR-006 整合性が文書で対処されている:**
  このマイルストーンと ADR-006 原則 1 (「default-off、シングルスイッチ」) との潜在的な競合が与えられたとき、
  architect が設計ステップを完了すると、(a) 新しい ADR-023 <!-- ref-allow: counterfactual reference in OR-condition; architect may choose path (a) ADR-023 or (b) ADR-006 amendment | expires: 2026-06-20 --> が存在し
  ADR-006 原則 1 が維持されるか、改訂されるか、上書きされるかを明示的に対処し根拠を記録するか、あるいは
  (b) ADR-006 自体が改訂を受けて原則 1 を明示的に対処 (維持/改訂/上書き) し根拠を記録する、
  のいずれかになります。Spec は architect がどちらの経路を取るかを規定しません。
  AC-5 は (a) または (b) のいずれかがディスク上に存在しその解決策を含む場合に満たされます。
  architect は経路を決定するために ADR-018 Alternative-B 三項識別器を適用します。

- **AC-6 — 7 つの標準検出器すべてが EXIT=0:**
  7 つの標準検出器 (`check-bilingual-parity.sh`、`check-dangling-refs.sh`、
  `check-ecc-delegation-consistency.sh`、`check-roadmap-drift.sh`、`check-ref-allow-expiry.sh`、
  `check-research-tier-auth.sh`、`check-skill-invariants.sh`) が与えられたとき、
  それぞれが #19 後のリポジトリ状態に対して実行されると、すべてがコード 0 で終了します。
  このマイルストーンが 8 番目の検出器を導入する場合、Spec はそれを収容し AC-6 はそれを含むように拡張されます。

- **AC-7 — 8 つの標準テストスイートすべてがパス:**
  8 つの標準テストスイート (`test-check-bilingual-parity.sh`、`test-check-dangling-refs.sh`、
  `test-check-ecc-delegation-consistency.sh`、`test-check-ref-allow-expiry.sh`、
  `test-check-roadmap-drift.sh`、`test-check-research-tier-auth.sh`、`test-check-skill-invariants.sh`、
  および CI ベースランナー) が与えられたとき、それぞれが #19 後のリポジトリ状態に対して実行されると、
  既存のテストロジックを変更せずにすべてがパスします。
  このマイルストーンが 9 番目のテストスイートを導入する場合、AC-7 はそれを含むように拡張されます。

- **AC-8 — Roadmap 行 #19 が出荷状態を反映している:** <!-- ref-allow: .claude/meta/adr/023-*.md is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  #19 コミットが与えられたとき、`.claude/CLAUDE.md` を読むと、Roadmap 行 #19 が `☑ done` を示し、
  `spec:` リンクが `specs/19-workaround-tracking-default-on.md` に解決し、
  ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> が発行された場合は `adr:` リンクが `.claude/meta/adr/023-*.md` に解決します。

- **AC-9 — `annotate_dependabot_prs: false` デフォルトへのリグレッションなし:**
  #19 後の `.github/workaround-tracker.yml` が与えられたとき、`annotate_dependabot_prs` を検査すると、
  その値は `false` のままです。`dependabot-annotate` ジョブはコアトラッキング上のオプトインオーバーレイであり、
  そのデフォルトはこのマイルストーンで変更されません。

- **AC-10 — `fail_on_marker_drift: false` デフォルトへのリグレッションなし:**
  #19 後の `.github/workaround-tracker.yml` が与えられたとき、`fail_on_marker_drift` を検査すると、
  その値は `false` のままです。drift はパイプライン失敗ではなくステップサマリーで警告として報告され、
  新しい fork に対する ADR-006 の保守的なデフォルトが維持されます。

- **AC-11 — CHANGELOG エントリが存在する:**
  step 7 後の #19 状態が与えられたとき、`CHANGELOG.md` を読むと、`## [Unreleased]` の下の
  `### Changed` または `### Added` エントリが workaround tracking の default-on 移行を記録しています。
  technical-writer はこのエントリを step 7 で執筆します。

- **AC-12 — JA sibling の heading-tree parity:**
  step 7 後の #19 状態が与えられたとき、`specs/19-workaround-tracking-default-on.ja.md` <!-- ref-allow: JA sibling authored by technical-writer at step 7; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  を読むと、その heading ツリーが EN Spec の heading ツリーと完全に一致します
  (Roadmap #06 の parity 所有権に従う)。technical-writer はこのファイルを step 7 で執筆します。

## Key interactions

- **product-manager:** 本 Spec を執筆 (現ステップ)。Spec 執筆と同時に Roadmap #19 を
  `☐ todo` から `◐ in-progress` に切り替えます。
- **architect:** ADR-018 Alternative-B 三項識別器 (新しい契約境界 + 新しいキーイング/メカニズム + 新しい構造的成果物)
  を適用して ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> が正当化されるか、ADR-006 との関係を決定します。
  architect の決定が AC-1 と AC-5 を管轄します。ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> が発行された場合、
  architect は Roadmap 行 #19 に `adr:` リンクを追加します。
- **implementer:** 各 AC を逐語的な契約として扱います。ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> が指示する
  ファイルのみを変更します。リアルな workaround エントリは追加しません (AC-4)。
  短絡ロジックは変更しません (AC-2)。すべての標準検出器とテストスイートを実行して AC-6 と AC-7 を検証します。
- **code-reviewer:** AC-2 (短絡ロジック変更なし)、AC-3 (空インベントリでのノイズゼロ)、AC-4 (レジストリエントリなし)、
  および AC-9/AC-10 (保守的なオプトインデフォルトの維持) を実際のファイルに対して独立して検証します。
- **technical-writer:** step 7 で — (a) CHANGELOG エントリを 1 件追加 (AC-11)、
  (b) `specs/19-workaround-tracking-default-on.ja.md` を執筆 (AC-12)、<!-- ref-allow: JA sibling authored by technical-writer at step 7; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  (c) `.claude/CLAUDE.md` の `### Upstream workaround lifecycle` セクション (「ships default-off」) が
  #19 後の状態に一致するよう更新が必要か確認し、必要であれば更新します
  (この編集は step 7 でのスコープ内であり、Spec 執筆時ではありません)。

## Metrics

- **Leading:** 実装後のすべての 7 つ (または 8 つ) の標準検出器からの EXIT=0。
  `make check` または同等の CI 実行で測定。実装時に直ちに検証可能。
- **Leading:** 既存のテストロジックを変更せずにすべての 8 つ (または 9 つ) の標準テストスイートがパスする。
  実装時に測定可能。
- **Lagging:** fork 後 6 ヶ月時点で workaround tracking がアクティブでない新しくフォークされたプロジェクトの減少
  (定性的観察、CI では強制しない)。default-on は「スイッチを切り替え忘れた」失敗クラスを
  完全に排除することが期待されます。

## Risks and open questions

- **ADR-006 原則 1 の競合。** ADR-006 は「default-on CI ワークフロー」を代替案として明示的に検討し
  「workaround ゼロのプロジェクトに保守コストを課す。テンプレート既存の default-off 規約と矛盾する」として却下しました。
  この理由付けは、並列 scaffold (#01、#20) が一貫してアクティブな状態で出荷するテンプレートには
  当てはまらない場合があります。architect の ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> は、
  テンプレートレベルの default-active 規約が機能レベルの default-off 原則 1 を上書きするかどうか、
  あるいは原則 1 が維持され別のメカニズム (例: config フィールド変更ではなくワークフローのフォールバックロジック)
  でデフォルトが達成されるかを対処する必要があります。これが ADR-023 の主要な未解決の質問です。<!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
- **fork 更新パス。** #19 より前にテンプレートをフォークし `enabled` を一度も変更していないプロジェクトは、
  設定に `enabled: false` があります。default-on への変更は新しい fork またはアップストリームの変更を
  プルした fork にのみ影響します。既存の fork は自動的に更新されません。これは正しい動作
  (強制的な混乱なし) ですが、technical-writer はこれを CHANGELOG エントリに注記すべきです。
- **`annotate_dependabot_prs` の相互作用。** `dependabot-annotate` ジョブは高リスクトリガーの
  `pull_request_target` を使用します。ジョブはすでに `annotate_dependabot_prs: false` の背後にゲートされています (AC-9)。
  `annotate_dependabot_prs` を変更せずに `enabled` を `true` に変更すると、アノテーションジョブは
  依然として実行されません。これは意図されたレイヤード有効化モデルであり、CHANGELOG エントリに文書化すべきです。
- **`fail_on_marker_drift` の相互作用。** tracking がアクティブで空のレジストリがある場合、
  orphan-marker 数は 0 で orphan-entry 数も 0 です。ただし、fork が `WORKAROUND-UPSTREAM` マーカーを
  レジストリエントリなしに誤って追加した場合、`fail_on_marker_drift: false` は不一致が報告されますが
  ビルドを壊しません。AC-10 はこの保守的なデフォルトを保持します。

## Out of scope

- ADR-006 原則 1 の改訂または上書き (architect による、ADR-023 経由)。<!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
- `workaround-check.yml` の短絡ロジックまたはトリガーの変更。
- `pull_request_target` の他のジョブへの拡張 (ADR-006 Out of scope、禁止)。
- `workaround-tracker.yml` の `expires_on` / `expiry_warning_days` フィールド変更
  (これらはレジストリエントリフィールドであり、このマイルストーンのスコープとは別)。
- `workarounds/` のリアルな workaround レジストリエントリ (テンプレート本体は空のまま)。
- Spec 執筆時の CHANGELOG 編集 (step 7 の technical-writer が行う)。
- Spec 執筆時の JA sibling 執筆 (step 7 の technical-writer が行う)。
- Spec 執筆時の `.claude/CLAUDE.md` `### Upstream workaround lifecycle` セクションのテキスト更新
  (ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> の結果を踏まえた step 7 の technical-writer による実施、Spec 執筆時ではない)。
- #20 (「`compliance.yml` をアクティブなデフォルトとして commit」) — 構造的に並列だが別マイルストーン。

## References

- Roadmap 行: #19
- `.claude/meta/adr/006-upstream-workaround-tracking.md` — ADR-006。原則 1
  (「default-off、シングルスイッチ」) と却下された代替案「default-on CI ワークフロー」が
  このマイルストーンが ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> 経由で解決する主要な緊張関係です。
- `.github/workaround-tracker.yml` — `enabled: false` で出荷されている現在の設定
- `.github/workflows/workaround-check.yml` — 3 ジョブ CI scaffold。短絡ロジックと
  `dependabot-annotate` セキュリティゲートは load-bearing
- `specs/01-ship-verification-yml-committed.md` — CI scaffold をデフォルトでアクティブに
  出荷する前例 (#01 マイルストーン)
- `specs/20-ship-compliance-yml-committed.md` <!-- ref-allow: specs/20-ship-compliance-yml-committed.md is reserved (Roadmap row #20) but not yet authored; forward reference | expires: 2026-06-20 --> — 構造的に並列な forthcoming
  マイルストーン (#20)。Non-goals に MECE 境界を記載
- `.claude/meta/adr/014-roadmap-index-single-entry-point.md` — Spec 予約規則と 1:1 マイルストーン ↔ Spec マッピング
- `.claude/meta/references/upstream-workaround-tracking.md` — 日常利用の詳細。「Default-off opt-in (single switch)」節
