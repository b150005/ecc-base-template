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
