# `compliance.yml` をアクティブなデフォルトとして Commit する

## Status

Approved

**Owner:** product-manager
**Target release:** Roadmap 行 #20

## Problem

テンプレートは `.claude/compliance.yml.example` を出荷しますが、commit された
`.claude/compliance.yml` は存在しません。テンプレートを clone してすぐに法的露出のある
機能 (チャット、決済、PII 収集、データエクスポート) を含む作業を始める fork は、
fork メンテナーが ADR-011 を読んで Skill の使用を意図していても、compliance Skill の
アクティベーションが行われません。`.example` サフィックスは「いずれコピーしてください」
というシグナルであり、「今すぐ有効化できる状態です」ではありません。実際のコピー手順は
スキップしても目に見える失敗がなく、実行を促す通知もないため、省略しがちです。

ADR-011 §Decision は明示的に `default-off` を選択し、その根拠として次のように述べています:
「エンドユーザーリリースとは無関係な fork も含め、すべての fork にセッション開始前の
管轄宣言を強制する → default-off はテンプレートの役割を尊重し、オプトインはコンフィグ 1 行」。
これは ADR-011 執筆時点では妥当でした。しかし並列マイルストーン #19 (workaround tracking)
により、テンプレートレベルの規約が確立されています: CI/config scaffold がゼロ活動プロジェクト
に対して安全なデフォルト状態であることが確認されたら、fork メンテナーが手動コピー手順なしに
実際のカバレッジを得られるよう、`.example` ではなく commit された状態で出荷します。

compliance のケースは workaround tracking と決定的に異なる点があります: ADR-011 Invariant 5
(「プロジェクト宣言の管轄、推測不可」) により、テンプレートは fork を代表して
`enabled: true` と `target_jurisdictions:` リストが入力された `.claude/compliance.yml` を
正当に commit することができません。それはテンプレートがどの法的管轄が適用されるかを
推測することであり、まさに Invariant 5 が禁じていることです。`.example` ファイルは
`JP` がコメント解除された状態で出荷されており、例示的なデフォルトとして適切ですが、
commit されたファイルはすべての fork が日本法のもとで運営されると主張してはなりません。

マイルストーン #20 はそのため、`enabled: false` (かつ `target_jurisdictions:` が
明確にドキュメント化されたオプトインステップ) で `.claude/compliance.yml` を commit することが、
Invariant 5 に違反せずに fork 時の意義ある改善を達成するかを評価し、architect の設計決定
(新 ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> または ADR-011 amendment) が正しいと判断した結果を実現します。

## Goals

- テンプレートは `.claude/compliance.yml` を commit して git で追跡し、compliance Skill を
  使用したい fork メンテナーの手動コピー手順を排除します。
- Skill を有効化する fork メンテナーは、`.example` ファイルを見つけてコピーする作業も含めず
  に、`target_jurisdictions:` という単一の明確にドキュメント化されたアサーションステップのみを
  実施します。
- compliance Skill の 6 つの invariant はこのマイルストーンによって損なわれません。
  特に Invariant 5 (管轄推測の禁止) は commit されたファイル自身のコメントによって強制されます。
- `.claude/compliance.yml.example` は commit されたアクティブ config と並ぶ完全注釈付き
  リファレンスとして保持されます。
- 7 つの標準検出器とその 8 つのテストスイートが、このマイルストーンの変更後に EXIT=0 でパスします。

## Non-goals

- **実装メカニズムは ADR-023 に委ねます。** <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> このマイルストーンの達成方法 — `enabled: false` で
  新しい `.claude/compliance.yml` を commit する、ADR-011 §Decision の「default-off」表現を改訂する、
  後継 ADR-023 を発行する、あるいは別の構造的アプローチを取る <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> — は architect の判断です。
  Spec は観測可能な結果のみを定義します。
- **commit されたファイルに `target_jurisdictions:` を入力しません。** compliance Skill の
  Invariant 5 はテンプレートがいかなる fork に対して法的管轄を主張することを禁じています。
  commit された `.claude/compliance.yml` は宣言要件をドキュメント化しなければなりませんが、
  fork を代表して管轄を事前入力してはなりません。これはマイルストーン #19 (workaround tracking —
  類似の運用者アサーション障壁がない) との中心的な差異です。
- **運用者アサーションなしに commit されたファイルに `enabled: true` を設定しません。**
  compliance Skill の有効化には fork メンテナーによる `target_jurisdictions:` の宣言が必要です。
  リストが入力されていない状態で `enabled: true` を commit すると、Skill はすべてのセッション開始時に
  拒否応答を出し、現状より積極的に悪化します。`enabled: false` と `enabled: true` (構造化された
  運用者アサーションワークフロー付き) のどちらが正しいかは architect の判断であり、この Spec の判断ではありません。
- **本 Spec による ADR-011 の 6 つの invariant の改訂はありません。** invariant の表現変更の可否は
  ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> または ADR-011 amendment が解決します。本 Spec は予断を持ちません。
- **Spec 執筆時点での compliance Skill の `SKILL.md` 変更はありません。** Invariant 4
  (「Default-off、プロジェクトごとのオプトイン」) の表現が #20 後の状態を反映するために
  更新が必要かどうかは ADR-023 の設計 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  スコープの一部であり、Spec 執筆時ではなく step 5 で実装されます。
- **Spec 執筆時点での `.claude/CLAUDE.md` §6a セクションテキストの更新はありません。**
  そのセクションの「default-off」という表現は #20 後の状態を反映するために更新が必要な場合があります。
  変更の可否と方法は ADR-023 の設計スコープ <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> の一部であり、Spec 執筆時ではなく
  technical-writer が step 7 で実装します。
- **#19 および #21 との MECE 分離。** #19 は workaround-tracker の default-on 移行
  (`.github/workaround-tracker.yml`) を所有し、#20 は compliance config の commit
  (`.claude/compliance.yml`) を所有し、#21 は quality-gate ループ再エントリーアンカー
  (Roadmap 行) を所有します。これら 3 つのマイルストーンは構造的に関連していますが重複しません:
  一方の実装が他方の実装を構成しません。
- **Spec 執筆時点での CHANGELOG 編集はありません。** technical-writer は開発ワークフローの
  step 7 で CHANGELOG エントリを追加します。Spec 執筆時ではありません。
- **本 Spec による JA sibling の執筆はありません。** `specs/20-ship-compliance-yml-committed.ja.md` <!-- ref-allow: JA sibling authored by technical-writer at step 7; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  は technical-writer が step 7 で執筆します。heading-tree parity は Roadmap #06 が管轄します。

## User stories

| 立場 | したいこと | 目的 |
|------|-----------|------|
| fork メンテナー (compliance 意識あり) | fork 時にテンプレートに `.claude/compliance.yml` が commit されているのを確認したい | `.example` ファイルを探してコピーする必要なく、すでに存在するファイルを 1 つ編集するだけで compliance Skill を有効化できる |
| fork メンテナー (compliance 意識なし) | commit された `.claude/compliance.yml` をデフォルト状態のままにしておきたい | compliance Skill が非アクティブのままで、その存在を知らなくても余計なノイズが発生しない |
| security-reviewer | commit されたファイルのコメントが管轄アサーション要件を明確にしていることを確認したい | ADR-011 を読まなくても config レイヤーで Invariant 5 がドキュメント化されていることを確認できる |
| テンプレートメンテナー | 管轄を宣言していない commit されたファイルを持つ新しい fork がゼロの Skill アクティベーションノイズを生成することを確認したい | 管轄を宣言していない fork でのフォールスポジティブ出力のリスクなく commit された config を自信を持って出荷できる |

## Acceptance criteria

- **AC-1 — `.claude/compliance.yml` がテンプレートに存在し commit されている:**
  #20 後のテンプレートが与えられたとき、手動セットアップ手順なしに fork を作成すると、
  `.claude/compliance.yml` がそのパスに存在し git で追跡されます。fork メンテナーは
  `.example` ファイルをコピーする必要がありません。

- **AC-2 — config レイヤーで Invariant 5 がドキュメント化されている:**
  commit された `.claude/compliance.yml` が与えられたとき、fork メンテナーがファイルを読むと、
  `target_jurisdictions:` フィールドに (a) 運用者アサーション要件と (b) リストが空または
  欠如している場合に Skill が実行を拒否するという事実を説明するインラインコメントが付いています。
  ファイルは fork を代表していかなる管轄コードも事前入力してはなりません。

- **AC-3 — commit されたデフォルト状態でのゼロ Skill アクティベーションノイズ:**
  commit された `.claude/compliance.yml` のデフォルト状態 (管轄未宣言) の fork が与えられたとき、
  エージェントセッションが実行され機能検出トリガーが発火すると、compliance Skill は
  (a) アクティブにならない (commit されたファイルの `enabled: false` の場合) か、
  (b) 管轄の宣言を運用者に求める単一行の拒否を発する (`enabled: true` だが
  `target_jurisdictions:` が空の場合) のいずれかです。いずれの場合も推測した管轄に対して
  compliance チェックリストを生成しません。正確なメカニズムは ADR-023 が決定します。<!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->

- **AC-4 — `.claude/compliance.yml.example` が保持されている:**
  #20 の commit が与えられたとき、`ls .claude/compliance.yml.example` を実行すると、
  ファイルが存在します。`.example` はすべての完全注釈付きフィールド (コメントアウトされた管轄、
  `operator_attestations`、`reverification_days` を含む) を保持し、ヘッダーコメントで
  ドキュメント専用であり、アクティブ config ではないことが明示されています。

- **AC-5 — ADR-011 整合性が文書で対処されている:**
  このマイルストーンと ADR-011 §Decision (「shipped default-off … opt-in で作成; デフォルトでは存在しない」)
  との潜在的な競合が与えられたとき、architect が設計ステップを完了すると、(a) 新しい ADR-023 <!-- ref-allow: counterfactual reference in OR-condition; architect may choose path (a) ADR-023 or (b) ADR-011 amendment | expires: 2026-06-20 --> が存在し
  ADR-011 §Decision の「デフォルトでは存在しない」条項が維持されるか、改訂されるか、上書きされるかを
  明示的に対処し根拠を記録するか、あるいは (b) ADR-011 自体が改訂を受けてこの条項を明示的に対処
  (維持/改訂/上書き) し根拠を記録する、のいずれかになります。Spec は architect がどちらの経路を
  取るかを規定しません。AC-5 は (a) または (b) のいずれかがディスク上に存在しその解決策を含む
  場合に満たされます。architect は経路を決定するために ADR-018 Alternative-B 三項識別器を適用します。

- **AC-6 — 6 つの compliance Skill invariant が保存されている:**
  commit された `.claude/compliance.yml` と compliance Skill の `SKILL.md` が与えられたとき、
  `target_jurisdictions:` を宣言して `enabled: true` を設定した fork で Skill が呼び出されると、
  6 つの invariant すべて (否定的適用性主張の禁止; 一次資料引用のみ; PII パス拒否; Skill 内部
  ロジックの default-off; プロジェクト宣言の管轄必須; 機能検出、名前マッチングなし) が損なわれずに
  維持されます。このマイルストーンはいかなる invariant も弱めません。

- **AC-7 — 7 つの標準検出器すべてが EXIT=0:**
  7 つの標準検出器 (`check-bilingual-parity.sh`、`check-dangling-refs.sh`、
  `check-ecc-delegation-consistency.sh`、`check-roadmap-drift.sh`、`check-ref-allow-expiry.sh`、
  `check-research-tier-auth.sh`、`check-skill-invariants.sh`) が与えられたとき、
  それぞれが #20 後のリポジトリ状態に対して実行されると、すべてがコード 0 で終了します。
  このマイルストーンが 8 番目の検出器を導入する場合、Spec はそれを収容し AC-7 はそれを含むように拡張されます。

- **AC-8 — 8 つの標準テストスイートすべてがパス:**
  8 つの標準テストスイート (`test-check-bilingual-parity.sh`、`test-check-dangling-refs.sh`、
  `test-check-ecc-delegation-consistency.sh`、`test-check-ref-allow-expiry.sh`、
  `test-check-roadmap-drift.sh`、`test-check-research-tier-auth.sh`、`test-check-skill-invariants.sh`、
  および CI ベースランナー) が与えられたとき、それぞれが #20 後のリポジトリ状態に対して実行されると、
  既存のテストロジックを変更せずにすべてがパスします。
  このマイルストーンが 9 番目のテストスイートを導入する場合、AC-8 はそれを含むように拡張されます。

- **AC-9 — Roadmap 行 #20 が出荷状態を反映している:** <!-- ref-allow: .claude/meta/adr/023-*.md is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  #20 の commit が与えられたとき、`.claude/CLAUDE.md` を読むと、Roadmap 行 #20 が `☑ done` を示し、
  `spec:` リンクが `specs/20-ship-compliance-yml-committed.md` に解決し、ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> が発行された場合は
  `adr:` リンクが `.claude/meta/adr/023-*.md` に解決します。

- **AC-10 — CHANGELOG エントリが存在する:**
  step 7 後の #20 状態が与えられたとき、`CHANGELOG.md` を読むと、`## [Unreleased]` の下の
  `### Changed` または `### Added` エントリが compliance config の commit を記録しています。
  technical-writer はこのエントリを step 7 で執筆します。

- **AC-11 — JA sibling の heading-tree parity:**
  step 7 後の #20 状態が与えられたとき、`specs/20-ship-compliance-yml-committed.ja.md` <!-- ref-allow: JA sibling authored by technical-writer at step 7; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  を読むと、その heading ツリーが EN Spec の heading ツリーと完全に一致します
  (Roadmap #06 の parity 所有権に従う)。technical-writer はこのファイルを step 7 で執筆します。

## Key interactions

- **product-manager:** 本 Spec を執筆 (現ステップ)。Spec 執筆と同時に Roadmap #20 を
  `☐ todo` から `◐ in-progress` に切り替えます。
- **architect:** ADR-018 Alternative-B 三項識別器 (新しい契約境界 — commit されたファイル vs.
  存在しないファイル; 同じキーイング/メカニズム — シングル config トグル; 構造的な問題 — ADR-011
  §Decision の「デフォルトでは存在しない」条項が正式な改訂を必要とするか) を適用して ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  が正当化されるか、ADR-011 が改訂を受けるかを決定します。architect の決定が AC-3 と AC-5 を管轄します。
  ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> が発行された場合、architect は Roadmap 行 #20 に `adr:` リンクを追加します。
- **implementer:** 各 AC を逐語的な契約として扱います。ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> が指示する
  メカニズムに従って `.claude/compliance.yml` を commit します。fork を代表して `target_jurisdictions:`
  を事前入力しません (AC-2)。デフォルト config 状態の fork に対してゼロノイズ (AC-3) を検証します。
  すべての標準検出器とテストスイートを実行して AC-7 と AC-8 を検証します。
- **code-reviewer:** AC-2 (config レイヤーで Invariant 5 がドキュメント化されている)、AC-3
  (デフォルト状態でのゼロノイズ)、AC-4 (`.example` が保持されている)、AC-6 (6 つの invariant
  が保存されている) を実際のファイルに対して独立して検証します。
- **technical-writer:** step 7 で — (a) CHANGELOG エントリを 1 件追加 (AC-10)、
  (b) `specs/20-ship-compliance-yml-committed.ja.md` を執筆 (AC-11)、<!-- ref-allow: JA sibling authored by technical-writer at step 7; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  (c) `.claude/CLAUDE.md` の §6a (「default-off」表現) が #20 後の状態に一致するよう更新が必要か確認し、
  必要であれば更新します (この編集は step 7 でのスコープ内であり、Spec 執筆時ではありません)。

## Metrics

- **Leading:** 実装後のすべての 7 つ (または 8 つ) の標準検出器からの EXIT=0。
  `make check` または同等の CI 実行で測定。実装時に直ちに検証可能。
- **Leading:** 既存のテストロジックを変更せずにすべての 8 つ (または 9 つ) の標準テストスイートがパスする。
  実装時に測定可能。
- **Lagging:** 週 1 後に compliance config ファイルが欠如している新しくフォークされたプロジェクトの減少
  (定性的観察)。commit されたファイルによって、compliance Skill の使用を意図している fork での
  「`.example` のコピーを忘れた」失敗クラスが完全に排除されることが期待されます。

## Risks and open questions

- **ADR-011 §Decision「デフォルトでは存在しない」との競合。** ADR-011 §Neutral Consequences は次のように述べています:
  「新しい config ファイル `.claude/compliance.yml` が `.claude/verification.yml.example` と並ぶ
  ドメイン固有のオプトイン config に加わります。この 2 つのファイルは sibling であり、どちらも
  default-off でシングルトグルです。」並列の `verification.yml` はすでに存在しません — マイルストーン #01
  で commit された状態で出荷されました。対称性の議論が成立するなら、`enabled: false` で
  `compliance.yml` を commit することは一貫しています。しかし ADR-011 は compliance config を
  「デフォルトでは存在しない」(単に「デフォルトでは無効」ではなく) に保つことを明示的に選択し、
  その選択は §Consequences ではなく §Decision に現れています。architect の ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  または ADR-011 amendment は、「存在しない」vs「commit されているが無効」が安全レベルで意味のある
  区別かどうか、あるいは純粋に手続き上のものかどうかを対処しなければなりません。これが
  ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> の主要な未解決の質問です。
- **`SKILL.md` の Invariant 4 の表現。** SKILL.md は現在「この Skill は **default-off** で出荷します」
  と述べています。commit されたファイルが「存在しない」から「`enabled: false` で commit されている」
  に移行する場合、invariant テキストは正確 (Skill は依然として default-off) かもしれないし、
  限定が必要かもしれません。architect が SKILL.md の編集を必要とするか決定します。
- **`.example` での管轄の曖昧さ。** `.example` ファイルは `target_jurisdictions:` の `JP` が
  コメント解除された状態で出荷されます。fork メンテナーが誤って commit されたファイルを別の場所に
  コピーしてコメントを読まずにアクティブにした場合、意図せず JP 管轄を宣言する可能性があります。
  commit されたファイルのインラインコメントと technical-writer の CHANGELOG エントリが
  運用者アサーション要件を明示する必要があります。これはドキュメントリスクであり、Skill 安全性リスクではありません
  (Invariant 5 は依然として空リストでの Skill 実行を防止します)。
- **fork 更新パス。** #20 より前にテンプレートをフォークしたプロジェクトは自動的に commit されたファイルを
  受け取りません。CHANGELOG エントリは、既存の fork がアップストリームの変更を pull するか、
  `.claude/compliance.yml.example` を `.claude/compliance.yml` に手動コピーすることで commit された
  ファイルを採用できることを注記すべきです。

## Out of scope

- ADR-011 §Decision「デフォルトでは存在しない」の改訂または上書き
  (architect による、ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> または ADR-011 amendment 経由)。
- fork を代表した commit されたファイルへの `target_jurisdictions:` の入力
  (Invariant 5 により禁止; 各 fork の運用者アサーションに属する)。
- 6 つの compliance Skill invariant の修正 (SKILL.md はこのマイルストーンで読み取り専用;
  architect が invariant の変更を管轄)。
- Skill の MVP セット (JP、EU、US-CA、platform) への新しい管轄の追加
  — 垂直固有の規制は ECC Skills に委任されたまま。
- Spec 執筆時の CHANGELOG 編集 (step 7 の technical-writer が行う)。
- Spec 執筆時の JA sibling 執筆 (step 7 の technical-writer が行う)。
- Spec 執筆時の `.claude/CLAUDE.md` §6a セクションテキストの更新
  (ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 --> の結果を踏まえた step 7 の technical-writer による実施、Spec 執筆時ではない)。
- #19 (「Workaround tracking default-on」) — 完了; Non-goals に MECE 境界を記載。
- #21 (「Quality-gate loop re-entry anchored to Roadmap row」) — 別マイルストーン;
  Non-goals に MECE 境界を記載。

## References

- Roadmap 行: #20
- `.claude/meta/adr/011-compliance-checklist-skill.md` — ADR-011; §Decision の「デフォルトでは存在しない」
  条項と却下された代替案「Skill を default-on にする」がこのマイルストーンが ADR-023 <!-- ref-allow: ADR-023 is the architect-authored ADR for this milestone; does not exist at Spec-authoring time | expires: 2026-06-20 -->
  経由で解決する主要な緊張関係です。
- `.claude/compliance.yml.example` — アクティブ config コンテンツの現在のソース;
  ドキュメント専用リファレンスとして保持 (AC-4)
- `.claude/skills/compliance-checklist/SKILL.md` — 6 つの invariant; Invariant 5
  (管轄宣言必須、推測不可) が AC-2 と AC-3 を管轄する中心的な制約
- `specs/01-ship-verification-yml-committed.md` — 以前 `.example` のみだった config scaffold を
  commit する前例 (マイルストーン #01)
- `specs/19-workaround-tracking-default-on.md` — default-on 移行の構造的並列例;
  Non-goals に MECE 境界を記載。AC-5 の OR 条件パターンはこの Spec の AC-5 を正確に反映
- `.claude/meta/adr/014-roadmap-index-single-entry-point.md` — Spec 予約規則と
  1:1 マイルストーン ↔ Spec マッピング
