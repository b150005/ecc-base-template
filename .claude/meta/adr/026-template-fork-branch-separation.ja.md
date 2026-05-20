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
