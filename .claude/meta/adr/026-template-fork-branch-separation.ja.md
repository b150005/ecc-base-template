# ADR-026: テンプレート/フォーク ブランチ分離戦略

## Status

Accepted — 2026-05-21

## Context

Phase A (Roadmap #22、2026-05-20 にリリース済み) で `CLAUDE.md` から揮発性の状態を排除し、Roadmap インデックスを `.claude/ROADMAP.md` に移設した。残された課題は次のとおりである: GitHub で "Use this template" をクリックする全てのフォーク利用者は依然として 38 件の Spec、46 件の ADR、2 件の PRD、`.claude/meta/scripts/` 配下の 15 件のテンプレート内部スクリプト、そして 8 件のテンプレート内部 CI ワークフローを継承してしまう。このペイロードは下流プロジェクトにとってノイズである — 時には敵対的なノイズですらある — そして「テンプレート開発の履歴」と「フォーク用スターターキット」を混同させてしまう。単一ブランチのリポジトリでは両方の利用者層に同時に応えられない。GitHub のテンプレートリポジトリ機能は新規リポジトリに **デフォルトブランチ** のみをコピーする (docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository) ため、これに乗っかれば綺麗な分離プリミティブが得られる。

## Decision

二ブランチモデルを採用する。`main` を **フォーク用クリーンペイロード** とする: 下流プロジェクトが初日に必要とするファイルのみ (templates、agents、skills、hooks、settings、README、CHANGELOG、CLAUDE.md スケルトン、そしてフォーク再利用可能な 4 件の CI ワークフロー: ci-base.yml、security.yml、coverage-gate.yml、workaround-check.yml)。`develop` を **テンプレート開発ブランチ** とし、Spec、ADR、PRD、`.claude/meta/`、`.claude/ROADMAP.md`、そして 8 件のテンプレート内部 CI ワークフロー (bilingual-parity-check、dangling-ref-check、docs-freshness、ecc-delegation-consistency-check、learn-invariants、research-tier-auth-check、roadmap-drift-check、skill-invariants) を保持する。`main` を GitHub のデフォルトブランチに設定し、"Use this template" ボタンがペイロードのみをコピーするようにする。テンプレート開発作業は `develop` (または `develop` から派生したフィーチャーブランチ) で行い、ペイロード許可リストで diff を制約するゲート付き `develop → main` マージで `main` に取り込む。許可リストは `develop` 上の新規 CI ワークフロー `payload-manifest-check.yml` で強制する。同ワークフローは、`base` が `main` であり、かつ diff がテンプレート内部 glob 集合に一致するパスに触れている PR を全て失敗させる。

## Consequences

### Positive

- "Use this template" はテンプレート内部ノイズを含まないクリーンなリポジトリを生成する。
- payload-manifest ワークフローがフォーク可視スコープに関する唯一の機械的な真実の源になる; ドリフトは静かには取り込まれ得ない。
- テンプレート開発の反復 (新規 ADR、Spec、meta スクリプト) はもはやフォーク履歴を汚染しない。

### Negative

- 長期維持される 2 本のブランチが発生する; 一部の変更 (例: Spec も伴う新規 agent の追加) はマージの両側で協調したコミットを要求する。
- #23 以前の `main` から作成された既存フォークは旧ペイロードを抱えたままになる; クリーンアップへは手動でオプトインしなければならない。

### Neutral

- 両ブランチに存在するパス (agents、skills、hooks) について CI マトリクスが倍化する。
- ロールバック手順: `main` を切替前 SHA (タグ `pre-phase-b`) に revert し、デフォルトブランチを戻す — `develop` は影響を受けない。

## Alternatives considered

| 代替案 | 利点 | 欠点 | 採用しなかった理由 |
|---|---|---|---|
| ADR-014 に "fork-clean" 節を amend で追加 | ADR が 1 件減る | ADR-014 がキーとするのは *Roadmap インデックスの所在* であってブランチトポロジではない — 直交する契約 | triad 3 軸全てで不合格 |
| `.gitattributes export-ignore` のみ | ブランチ分割が不要 | `git archive` にしか効かず、テンプレートボタンによるクローンには無効 | プリミティブを間違えている — GitHub テンプレートクローンはブランチコピーである |
| テンプレート開発用リポジトリを分離 | 隔離度は最も高い | PR の相互参照を失い、インフラが倍化する | 現在の規模ではコストが利益を上回る |

## References

- `.claude/meta/adr/014-roadmap-index-single-entry-point.md` — Roadmap インデックスの所在 (テンプレート内部状態の移設先行例)
- `.claude/meta/adr/018-bilingual-parity-detector.md` — CI 強制の構造的 invariant (payload-manifest ゲートの先行例)
- GitHub Docs: docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository (デフォルトブランチ コピーの挙動)
- GitHub Docs: docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/managing-a-branch-protection-rule (複数ブランチモデルにおけるブランチ保護)
- `specs/22-claude-md-invariant-refactor.md` — Phase A (このブランチ分割を可能にした invariant 限定リファクタリングの先行例)
- `specs/23-template-fork-branch-separation.md` — 本マイルストーンで authoring 中の Spec (product-manager が並行ドラフト)
- Roadmap 行: #23

## 改訂 2026-05-21

**きっかけ.** Roadmap #23 実装キックオフ中のユーザーによる明確化 (2026-05-21): GitHub ワークフローはフォークごとのオプトイン関心事であり、テンプレートが所有するデフォルトではない。フォークは CI スキャフォールディングを望むかどうかで大きく分岐する(組織レベルの再利用可能ワークフローを持つフォーク、エアギャップ CI を対象とするフォーク、異なるランナースタックを採用するフォークなど)。そのため、「最小限の」4ワークフローベースラインですら `main` に搭載すれば、すべての下流ユーザーに対してテンプレートが求めていない選択を強制することになる。

**Decision の改訂.** `main` は **ワークフローを0件** 保持する。以前に規定した4つのフォーク再利用可能ワークフロー(`ci-base.yml`、`security.yml`、`coverage-gate.yml`、`workaround-check.yml`)を `main` ペイロードから削除する。`develop` からのコピーまたは独自作成によって CI を採用することをフォークに思い出させるプレースホルダーとして、`.github/workflows/.gitkeep` を1件残す。空フォルダーそのものがアフォーダンスである。同じ「leaner main」原則を `.claude/meta/scripts/` にも適用する: `main` 上では `init.sh`(フォーク向けブートストラップスクリプト)のみを残し、そのディレクトリ配下の他のスクリプトはすべてテンプレート内部として `develop` に置く。5件の孤立トラッカー設定(`.github/coverage-tracker.yml`、`.github/docs-freshness-tracker.yml`、`.github/ecc-delegation-tracker.yml`、`.github/research-tier-auth-tracker.yml`、`.github/workaround-tracker.yml`) — 対応するワークフローが `develop` にしか存在しない意味で孤立している — も同じ理由で `main` から削除する: フォークがオプトインしていない振る舞いを設定するファイルをフォークに押しつけるべきではない。

**解消された緊張関係.** 元の Decision は暗黙的に `coverage-gate.yml` が `.claude/meta/scripts/coverage-threshold.sh`(ゲートの閾値ローダー)に対してランタイム依存を持ち続けることを要求していた。この依存関係は、ワークフローが1件のメタスクリプトを再導入しなければ実行できないため、Spec AC-2 の invariant(「`.claude/meta/` は `main` に存在しない」)と矛盾していた。ワークフローを `main` から削除することで依存関係がきれいに消える: `coverage-threshold.sh` とその兄弟メタスクリプトは本来あるべき `develop` に留まり、`coverage-gate.yml` はフォークが積極的に必要とする場合に `develop` ブランチ経由(またはコピー&ペースト)で利用できる。例外もカーブアウトも不要 — AC-2 の invariant は記述どおりに成立する。

### Consequences の追補

**Negative.** CI スキャフォールディング(lint、test、セキュリティスキャン、カバレッジゲート、workaround トラッカー)を必要とするフォークは、`develop` からワークフローをコピーするか独自に作成することでオプトインしなければならない。`main` 上の `.github/workflows/.gitkeep` プレースホルダーは、フォークユーザーにこの層の存在と意図的な空状態を知らせるアフォーダンスである。これがないと、新鮮なテンプレートクローンには `.github/workflows/` ディレクトリ自体が存在しないため、省略が意図的ではなく偶発的に見える。

**Neutral.** `main` のブランチ保護は依然として `payload-manifest-check` を必須とする(Spec の AC-12 に基づく)。そのワークフローは PR の head ref(`develop` または `develop` から派生したフィーチャーブランチ)上で実行され、ワークフローファイルが実際に存在する場所で動く。`main` 側のワークフロー不在はゲートを壊さない: GitHub は必須ステータスチェックを base ブランチのファイルツリーではなく PR の head コミットに対して評価するためである。強制メカニズムは leaner-main の決定に影響を受けない。

**Spec の対応.** Spec の AC-2 / AC-4 / AC-5 が要件側に対応する改訂を反映している: AC-2 は `.claude/meta/` の不在を再確認する(スクリプト依存のカーブアウトが不要となり、より明確になった)。AC-4 は `.github/workflows/.gitkeep` をそのディレクトリ配下で唯一期待されるペイロードとして列挙する。AC-5 は `main` 上の CI 不在を明示し、フォーク CI が完全なオプトイン制であることを述べる。

## 改訂 2026-05-21 (二回目)

**きっかけ.** AC-6 / AC-12 の検証中に実証的に発覚: GitHub Actions は `pull_request` ワークフローファイルを **PR の head ref** から解決し、base ref からは解決しない。上記の元の「Neutral」Consequence では「`payload-manifest-check.yml` は `develop` にのみ存在できる。なぜなら『`main` のブランチ保護は依然として `payload-manifest-check` を必須とする… そのワークフローは PR の head ref で実行される(`develop` または `develop` 派生フィーチャーブランチ)』ためである」と主張していた。しかしこれが成立するのは、head ref が *ワークフローファイルを含む* PR に限られる。`main` から作成したフィーチャーブランチ(ペイロード更新をランディングさせる標準的なチェリーピックフロー)には main のファイルツリーしかない — ワークフローファイルは存在しない — ため、チェックはトリガーされない。テスト PR #10(head: main 派生フィーチャーブランチ、head にワークフローファイルなし)で確認: 128秒後に外部の GitGuardian ステータスのみが投稿され、`payload-manifest-check` は一度もトリガーされず、必須チェックのルールセットが永遠に未満足のまま残った。

**Decision の改訂.** `main` は **1件の** ワークフローを保持する: `.github/workflows/payload-manifest-check.yml`。これは「`main` にフォーク向けワークフロー0件」に対する唯一の意図的な例外であり — テンプレート内部インフラ(境界強制ゲート)であってフォーク CI ではない。「フォーク CI はオプトイン制」という意図は以下の理由で保たれる:

1. デュアルチェックアウトパターンを使用する: `develop` ブランチのチェックアウトを試み、canonical な場所(`.claude/payload-manifest.txt` on `develop`)からマニフェストを取得する。
2. `develop` ブランチが存在しない場合に Notice を出して gracefully スキップし(結論: SUCCESS)、leaner-main パターンをオプトインしていないフォークのデフォルト状態となる。ワークフローファイルを削除したフォークは挙動の変化なし、残すフォークはすべての PR で no-op の SUCCESS を受ける。
3. アクティブ時は、各変更パスをマニフェストの glob パターンと照合し、不一致があると PR の必須ステータスチェックを失敗させる。

`develop` 上の `.claude/payload-manifest.txt` は `.github/workflows/payload-manifest-check.yml` を許可済みペイロードパスとして列挙するようになった。これによりワークフロー自体を変更する将来の PR がランディングできる。マニフェストは `develop` 上で単一のソースとして維持され、`main` 上のワークフローがランタイムにそこから取得する。

**解消された緊張関係.** ワークフローを develop のみに置くことで十分であるという元の「Neutral」の主張は誤りであった — ワークフローファイルを `main` に移設することで修正された(フォークが gracefully スキップするチェックアウトパターンにより、フォークのコスト不要 invariant は維持される)。leaner-main の意図(「フォーク CI はオプトイン制」)は、このファイルがフォークスキャフォールディング CI ではなくテンプレート強制インフラであるため、生き残る。

**本改訂で同時修正.** 元のワークフローの sed パイプラインが `**`(再帰 glob)を `*`(単一セグメント)として変換しており、`.claude/agents/nested/foo.md` のようなネストパスのマッチが壊れていた。プレースホルダー保護アプローチ(`**` → マーカー → 単一 `*` 置換 → マーカーを `.*` に復元)で置き換え、ネストケースを含む20パスでユニットテスト済み。

### Consequences の追補 (二回目)

**Negative.** `main` はワークフローファイルを1件出荷する。ワークフローをゼロにしたいフォークは `.github/workflows/payload-manifest-check.yml` を削除する必要がある(`develop` が存在しない場合にスキップするため残しても無害)。フォークメンテナーにとっては `git rm` 一行である。

**Positive.** AC-12 ルールセット強制が実際に機能する。エンドツーエンドで検証済み:
- 正常テスト(PR #11 / マージ `d287480`): ペイロードのみの diff → チェック SUCCESS → マージアンブロック。
- 異常テスト(PR #12、マージせずクローズ): `specs/test-manifest-negative.md` を含む diff → チェック FAILURE、問題のパスがエラーメッセージに表示 → ルールセットによりマージブロック。
- 両チェックとも約6秒で完了。

**Neutral.** フォーク CI オプトイン制の意図に変更なし: フォークは依然としてフォーク CI スキャフォールディングのアフォーダンスとして `.gitkeep` を受け取る。出荷される唯一のワークフローはフォークにとって no-op なテンプレートインフラである。

**Spec の対応.** `specs/23-template-fork-branch-separation.md` が改訂 2026-05-21 (二回目) を反映し、AC-4 の表現を改訂している。

## 改訂 2026-05-21 (三回目)

**きっかけ.** ユーザーからのフィードバック (2026-05-21): 二回目の改訂で確立した「`develop` 不在時の graceful-skip」保証は *正しさ*(フォーク PR が失敗しない)はカバーしたが、*不可視性* はカバーしていなかった。ワークフローファイルを継承したフォークは、依然として毎 PR で Actions タブに「Payload Manifest Check」エントリを目にし(skipped または 6秒で SUCCESS)、課金対象のランナー起動時間を消費し、cognitive tax を支払う: ワークフローの目的は ADR-026 を読まなければ不透明である。一回目改訂 (2026-05-21) で確立した「フォーク CI はオプトイン制」の原則が精神的に侵害されている — フォークユーザーはオプトイン面を受け取るのではなく、`git rm` で逆オプトアウトしなければならない。

**Decision の改訂.** 直交する2層による多層防御:

1. **ジョブレベル リポジトリガード.** `payload-manifest-check` ジョブに `if: github.repository == 'b150005/ecc-base-template'` を追加する。upstream 以外のリポジトリでは、ジョブはランナー割り当て前に `skipped` と評価される — 0 runner minutes、0 Actions 課金、Actions タブには skip マーカー以外のノイズなし。何もしないフォークはワークフローファイルを目にするが、それが実行されることは決してない。
2. **`init.sh` の対話的削除.** `.claude/meta/scripts/init.sh` にプロンプトを追加する(「Remove template-internal payload-manifest-check.yml? (y/N)」)。`init.sh` を実行するフォークユーザーは物理的にファイルを削除できる。`--non-interactive` モードはファイルを保持する(安全な no-op)、`--dry-run` モードは意図された削除を書き込まずに表示する。

2層は直交している: 層 (1) は `init.sh` を走らせないユーザーを保護し、層 (2) は走らせるユーザーにクリーンアップ手段を提供する。両者が組み合わさることで、ワークフローは「オプトアウト」から「デフォルトで無視可能、リクエストに応じて削除可能」へと変換される。

**解消された緊張関係.** 二回目改訂の graceful-skip メカニズムは正しさを保ったが、一回目改訂 (2026-05-21) のフォーク デフォルトクリーン UX の意図を保てていなかった。層 (1) はランタイムの可視性を一回目改訂の意図に再整合させ、層 (2) はフォーク カスタマイズのストーリーを `init.sh` の人間工学的サーフェスに再整合させる。

**容認したトレードオフ.** ハードコードされた `b150005/ecc-base-template` ガードは、upstream リポジトリがリネームされたり、アカウント/組織間で転送されたりすると fail-silent になる — upstream 自体が静かにチェックを実行しなくなる。緩和策: (a) 二回目改訂の graceful-skip が二層目防御として残る、(b) ワークフローファイル内のインラインコメントがリネーム依存を明示する。リスクは upstream 限定(フォークは影響を受けない)。リネームは計画的かつ低頻度な操作であり、ガード更新はその際の機械的手順の一つに過ぎない。

### Consequences の追補 (三回目)

**Positive.** フォークユーザーはデフォルトでこのワークフローによる Actions タブのノイズをゼロにできる。`init.sh` を走らせるユーザーはさらに物理削除を選択できる。graceful-skip フォールバックは、ガードが見逃す可能性のあるパス(レガシーフォーク、名前衝突リポジトリ)に対しても残る。

**Negative.** upstream リポジトリ名はワークフロー内にハードコードされており、リネームには1行編集が必要(インラインコメントで明示)。init.sh のプロンプトはフォークユーザーにとって追加の対話質問が1つ増える(`--non-interactive` モードでファイルを静かに保持することで緩和)。

**Neutral.** AC-2, AC-4, AC-12 の結果に変更なし。AC-6 の検証はフォークコンテキストチェック(非 upstream リポジトリでジョブが `skipped` と評価される)を追加する。

**Spec の対応.** `specs/23-template-fork-branch-separation.md` が改訂 2026-05-21 (三回目) を反映し、AC-6 の検証手順を改訂する。
