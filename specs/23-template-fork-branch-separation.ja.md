# テンプレート / フォーク構造分離

> 英語版: [23-template-fork-branch-separation.md](./23-template-fork-branch-separation.md)(原文・Source of Truth)

## ステータス

Approved

## 改訂 2026-05-21

**きっかけ:** Roadmap #23 の実装中にユーザーからフォーク CI オーナーシップ境界について明確化を受けた。元の仕様書は、テンプレート `main` ブランチが4つのフォーク再利用可能な CI ワークフロー(`ci-base.yml`、`security.yml`、`coverage-gate.yml`、`workaround-check.yml`)を保持するという前提に立っていた。改訂後の方針では、フォーク CI は完全にオプトイン制とする: フォークは `develop` からワークフローをコピーするか、独自に作成する。テンプレート `main` はワークフローを **ゼロ** 件保持する設計とする。

**元の仕様書からの変更点:**

- AC-2 の「`main` に存在しない」リストを拡張し、`.github/workflows/*.yml` の全ファイル、`.github/` 配下の5つのトラッカー YAML、および `init.sh` を除く `.claude/meta/scripts/` サブツリーを明示的に追加した。
- AC-4 のワークフローインベントリを改訂: 以前は keep-on-main だった4ワークフロー(`ci-base`、`security`、`coverage-gate`、`workaround-check`)を `main` から削除する。`.github/workflows/` フォルダーは `.gitkeep` ファイルを置いて保持する。これにより、コントリビューターがフォルダーが意図的に空であることに気づかずワークフローファイルを誤って追加してしまうことを防ぐ。
- AC-5 を改訂: `main` 上でのワークフロー個別の実行検証は不要(検証すべきワークフローが存在しない)。フォーク CI は `develop` からのコピーまたは独自作成によるオプトイン制とする。
- **設計上の競合を解消:** 元の設計では `coverage-gate.yml`(threshold を `main` に強制する予定)と `coverage-threshold.sh`(同じ値を管理する develop-only メタスクリプト)の間に潜在的な競合が生じていた。`coverage-gate.yml` を `main` から削除することで、その競合を完全に解消した。

ADR-026 の改訂 2026-05-21 を参照。

## 改訂 2026-05-21 (二回目)

**きっかけ:** AC-6 / AC-12 の検証中に発覚。GitHub Actions は `pull_request` ワークフローファイルを **PR の head ref** から解決し、base ref からは解決しない。main 派生のフィーチャーブランチは main のファイルツリーしか持たないため、`develop` にしか存在しない `payload-manifest-check` ワークフローは main 宛 PR でトリガーされない — 必須ステータスチェックが永遠に満たされず、すべての main 宛 PR がブロックされてしまう。

**変更点:**

- AC-4 の表現を改訂: `main` は `.github/workflows/.gitkeep` に加えて **`.github/workflows/payload-manifest-check.yml`** を保持する — テンプレート内部の強制ワークフローとして `main` に搭載される唯一のワークフロー(0件ではなく1件)。その他の CI はフォークオプトイン制のままであり(元の意図を維持 — フォーク CI スキャフォールディングはオプトイン制で `.gitkeep` のみとして出荷される)。
- 出荷されるワークフローはデュアルチェックアウトパターンを使用する: マニフェストを取得するために `develop` ブランチのチェックアウトを試み、`develop` ブランチが存在しない場合(フォーク)は Notice を出して gracefully スキップする(結論: SUCCESS)。これによりワークフローはフォーク CI に対して無害となる — フォーク上でのコストは実質ゼロで、テンプレートリポジトリでのみ実質的に動作する。
- AC-2 の `.github/workflows/*.yml` エントリを明確化: 不在リストから `.gitkeep` および `payload-manifest-check.yml` を除外する(この2ファイルはペイロードであり、他のワークフロー YAML はすべて不在のまま)。
- `develop` 上の `.claude/payload-manifest.txt` を拡張し、`.github/workflows/payload-manifest-check.yml` を許可する(ワークフロー自体を変更する将来の PR がランディングできるようにするため)。

**検証済み:**

- 正常テスト: ペイロードのみの変更を含む PR → `payload-manifest-check` = SUCCESS、マージアンブロック(PR #11、マージコミット `d287480`)。
- 異常テスト: `specs/test-manifest-negative.md`(マニフェスト未記載)を含む PR → `payload-manifest-check` = FAILURE、エラーメッセージに問題のパスが表示、ルールセットによりマージブロック(PR #12、マージせずクローズ)。 <!-- ref-allow: specs/test-manifest-negative.md was a transient test file in PR #12 (closed without merge); intentional historical reference for verification trace -->
- 両チェックとも約6秒で完了。

**本改訂で同時修正:** ワークフロー元来の sed ベース glob パターンが `**` を `*`(単一セグメント)として扱っていたため、置換順序の問題で再帰的なパスのマッチが壊れていた。プレースホルダー保護アプローチ(`**` → `__GG_RECURSIVE__` → 単一 `*` 置換 → `.*` に復元)で修正し、ネスト glob ケースを含む20パスでユニットテスト済み。

ADR-026 の改訂 2026-05-21 (二回目) を参照。

## 改訂 2026-05-21 (三回目)

**きっかけ:** 二回目改訂の graceful-skip は正しさを保ったが不可視性は保たなかった、というユーザーフィードバック — フォークは依然として Actions タブにエントリを目にし、ランナー起動コストを支払い、オプトインしていない不透明なワークフローに対する cognitive tax を支払っていた。

**変更点:**

- AC-6 の検証をフォークコンテキスト模擬で拡張: upstream `b150005/ecc-base-template` 以外のリポジトリでは、ジョブレベル `if: github.repository == 'b150005/ecc-base-template'` ガードのおかげで `payload-manifest-check` ジョブが `skipped` と評価される(0 runner minutes、Actions タブには skip マーカー以外のノイズなし)。
- `.claude/meta/scripts/init.sh` に `.github/workflows/payload-manifest-check.yml` の削除を提案する対話プロンプトを追加。`--non-interactive` と `--dry-run` モードは尊重される(静かに保持 / 書き込みなしでプレビュー)。
- ワークフローのヘッダコメントが両層を文書化し、upstream リネーム依存を明示する。

**検証済み:**

- 層 (1): upstream の PR ではジョブが評価される(実行される)。フォークの PR(非 upstream リポジトリ、またはローカルリプレイで `github.repository` コンテキストを編集することで模擬)では `skipped` と評価される。
- 層 (2): `bash .claude/meta/scripts/init.sh --dry-run` で削除プロンプトが表示され、`y` 回答で `[dry-run] would remove .github/workflows/payload-manifest-check.yml` が出力される。`--non-interactive` モードでは `keeping (non-interactive mode; safe no-op on forks)` を出力する。

ADR-026 の改訂 2026-05-21 (三回目) を参照。

**責任者:** product-manager / implementer
**目標リリース:** template v3.12.0

## 課題

現在のテンプレートリポジトリは単一の `main` ブランチを使用しており、フォーク再利用可能なペイロード(エージェントプロンプト、ワークフロー、設定)と、テンプレート内部の開発インフラ(ADR、仕様書、ラーニングモードの足場、CI メタスクリプト)が混在しています。チームがテンプレートをフォークすると、プロジェクトに不要なファイルが100件以上引き継がれ、手動で削除する必要があります。これはフォーク体験の摩擦を高め、今後のテンプレートアップグレードをより煩雑にします。なぜなら、ペイロードの変更とテンプレート内部の履歴が絡み合っているからです。`main` をクリーンに保つ構造的な保証はなく、新しい内部アーティファクトが追加されるたびに、フォーク手順に手動パージ手順を追加する必要があります。

## ゴール

- **G1 — ペイロードのみの `main`.** `main` にはフォーク再利用可能なペイロードのみを格納する: エージェント定義、フォーク向けワークフロー、設定、テンプレート。テンプレート内部の開発アーティファクト(ADR、仕様書、CI メタスクリプト、ラーニングモード)は `develop` にのみ存在する。
- **G2 — `develop` をテンプレート開発ブランチとする.** すべてのテンプレート内部作業(ロードマップ行の作成、ADR 作成、仕様書作成、品質ゲート作業、CI メタスクリプト更新)は `develop` で行う。ペイロードの変更はマージまたはチェリーピックのプロトコルを経て `develop` → `main` へ流れる。
- **G3 — 検証済みペイロード境界.** `develop` 上の CI ワークフロー(`payload-manifest-check.yml`)が、`main` にマージされる、または提案されるすべてのファイルが承認済みペイロードマニフェストに含まれることを検証する。`main` を対象とする PR はこのチェックなしではマージできない。
- **G4 — クリーンなフォーク体験.** `main` をフォークするチームは、フォーク関連のファイルのみを取得し、テンプレート内部アーティファクトを削除する必要がない。
- **G5 — ワークフローインベントリの正確な分類.** 各 GitHub Actions ワークフローは keep-on-main または develop-only として明示的に分類され、分類は ADR-026 に文書化される。

## 非ゴール

- 旧単一ブランチ `main` から派生した既存フォークの移行。この仕様書はテンプレートリポジトリ自体を対象とする。フォーク移行のガイダンスは後続ミルストーンに延期。
- `develop` から `main` への自動チェリーピックツール。v1 のプロトコルは手動(レビュー手順を含む PR または git cherry-pick)。
- `init.sh` の縮小は、`develop` のみの初期化ステップ(ペイロードフォークには不要)を除去する範囲に留める。より深い `init.sh` 再設計は後続ミルストーンに延期。
- `main` 上でエージェントチームワークフロー全体を再実行すること。品質ゲート、ADR 作成、ロードマップ管理はすべて `develop` で行う。
- エージェントチームワークフロー手順(例: ADR より前に仕様書が存在すること)を強制する CI チェックの追加。ペイロードマニフェストチェックは構造的なものであり、プロセス指向ではない。

## ユーザーストーリー

| [ペルソナ]として               | [行動]を                                                       | [成果]のためにやりたい                                           |
|------------------------------|---------------------------------------------------------------|---------------------------------------------------------------|
| テンプレートをフォークするチーム | `main` をフォークしてフォーク関連ファイルのみを取得             | テンプレート内部ファイルの削除に時間を費やさないようにしたい       |
| テンプレートメンテナー          | ADR と仕様書を `develop` 上で作業する                           | 手動パージ手順なしに `main` をクリーンに保ちたい                 |
| テンプレートメンテナー          | CI が非ペイロードファイルの `main` 到達をブロックする           | 境界が文書化だけでなく強制されるようにしたい                     |
| フォークメンテナー              | テンプレート `main` から更新をプルする                          | 内部ノイズではなくペイロードの変更のみを受け取りたい             |
| devops-engineer               | どのワークフローが `main` に残るか明確なリストを見る            | ブランチ保護ルールを正しく設定できるようにしたい                 |

## 受け入れ基準

**AC-1.** テンプレートリポジトリに `develop` ブランチが存在し、開発作業のデフォルトブランチとして設定されている。`main` はフォーク用デフォルト(`git clone` および GitHub の「Use this template」が参照するブランチ)のまま。検証方法: `git branch -r` に `origin/develop` が含まれる。リポジトリのデフォルトブランチ設定は ADR-026 の Decision に従う。

**AC-2.** すべてのテンプレート内部アーティファクトが `develop` に存在し、`main` には存在しない。具体的に: `specs/`, `.claude/meta/`, `.claude/ROADMAP.md`, `.claude/learn/`, `.claude/output-styles/`, `.claude/skills/`, `.claude/hooks/`, <!-- ref-allow: .claude/learn/ is intentionally absent (opt-in/default-off per ADR-015 amendment) -->
`workarounds/`(空でない場合)、`.github/workflows/*.yml`(全ワークフローファイル — `main` は設計上ワークフローを保持しない。フォルダー自体は `.gitkeep` を置いて保持する)、`.github/coverage-tracker.yml`、`.github/docs-freshness-tracker.yml`、`.github/ecc-delegation-tracker.yml`、`.github/research-tier-auth-tracker.yml`、`.github/workaround-tracker.yml`、および `init.sh` 以外の `.claude/meta/scripts/` エントリ(具体的には全 `check-*.sh`、`test-check-*.sh` スクリプトおよび `lib/` サブディレクトリ)が `main` に存在しない。検証方法: `git ls-tree --name-only main` にそれらのパスが含まれない。`git ls-tree -r --name-only main .github/workflows/` が `.github/workflows/.gitkeep` のみを返す。

**AC-3.** ペイロードマニフェストファイルが `develop` 上の `.claude/payload-manifest.txt` に存在する。`main` で許可されるすべてのファイルおよびディレクトリが1行ずつ列挙されている。検証方法: ファイルが少なくとも1エントリを持って存在し、現在の keep-on-main ファイルがすべて記載されている。 <!-- ref-allow: payload-manifest.txt is created in Phase B implementation - forward reference -->

**AC-4.** ワークフローインベントリが以下のように分類され、ADR-026 の分類(2026-05-21 の改訂を含む)と一致している:

- **`main` に残す**(0ワークフロー — フォルダーは `.gitkeep` で保持):
  - *(なし — フォーク CI はオプトイン制。フォークは `develop` からワークフローをコピーするか、独自に作成する)*
- **`develop` に残し、`main` 宛 PR に対して実行する**(1強制ワークフロー):
  - `.github/workflows/payload-manifest-check.yml`
- **develop-only**(`main` に存在しないテンプレート内部8ワークフロー):
  - `.github/workflows/bilingual-parity-check.yml`
  - `.github/workflows/dangling-ref-check.yml`
  - `.github/workflows/docs-freshness.yml`
  - `.github/workflows/ecc-delegation-consistency-check.yml`
  - `.github/workflows/learn-invariants.yml`
  - `.github/workflows/research-tier-auth-check.yml`
  - `.github/workflows/roadmap-drift-check.yml`
  - `.github/workflows/skill-invariants.yml`

以前は keep-on-main だった4ワークフロー(`ci-base.yml`、`security.yml`、`coverage-gate.yml`、`workaround-check.yml`)はテンプレート `main` から削除される。これらを必要とするフォークは `develop` からコピーするか独自に作成する。

検証方法: `git ls-tree -r --name-only main .github/workflows/` が `.github/workflows/.gitkeep` のみを返す(`main` 上に `.yml` ファイルはゼロ件)。

**AC-5.** `main` は設計上ワークフローを保持しない。フォーク CI は完全にオプトイン制である。CI が必要なフォーク(例: `ci-base.yml`、`security.yml`、`coverage-gate.yml`、`workaround-check.yml`)は `develop` から対象のワークフローファイルをコピーするか、独自に作成する — コピーも独自作成も、有効なフォークに必須ではない。`main` 上でのワークフロー個別の実行検証は不要(検証すべきワークフローが存在しない)。検証方法: `git ls-tree -r --name-only main .github/workflows/` が `.github/workflows/.gitkeep` のみを返す。

**AC-6.** `.github/workflows/payload-manifest-check.yml` が `develop` 上に存在し、`base: main` の `pull_request` でトリガーされ、PR の diff に `.claude/payload-manifest.txt` に記載されていないファイルが含まれる場合に非ゼロで終了する。検証方法: develop-only パスを含むテスト PR を `main` に開くとチェックが失敗し、ペイロードパスのみを含む PR はパスする。**フォークコンテキストの検証(改訂 2026-05-21 三回目に基づく):** 非 upstream リポジトリでは、ジョブレベル `if: github.repository == 'b150005/ecc-base-template'` ガードによって `payload-manifest-check` ジョブが `skipped` と評価される(ランナー割り当てなし、Actions タブには skip マーカー以外のエントリなし)。 <!-- ref-allow: payload-manifest.txt is created in Phase B implementation - forward reference -->

**AC-7.** `main` 上の `CLAUDE.md` はペイロード向けに縮小されたバージョンである。エージェントチームテーブル、ドキュメントテンプレートセクション、開発ワークフロー概要、テスト要件、コード品質標準、このファイルを拡張するセクションを保持する。`## Developer Learning Mode`, `## Subagent dispatch contract`, `## Worktree advisory protocol`, `## Roadmap`, `## Plan-First & Learning-Aware Defaults` セクションは含まない(これらは develop-only のガイダンス)。検証方法: `git show main:.claude/CLAUDE.md` に文字列 `## Developer Learning Mode` が含まれない。

**AC-8.** `.github/workflows/payload-manifest-check.yml` はテンプレートが採用する `<purpose>-check.yml` ファイル名規約(`dangling-ref-check.yml`, `bilingual-parity-check.yml` 等と一致)に従う。検証方法: ファイルが `develop` 上で正確に `.github/workflows/payload-manifest-check.yml` という名前である。

**AC-9.** `develop` 上の `init.sh` が develop-only パスを参照するステップ(例: `specs/` や `.claude/meta/` を変更するステップ)を除去するよう更新されている。`main` 上のフォーク向け `init.sh` は、develop-only パスを参照せずにフォークチームのペイロードのみのセットアップをガイドする。検証方法: `bash -n init.sh` がパスし(構文エラーなし)、スクリプトが `.claude/meta/` や `specs/` パスを参照しない。

**AC-10.** `main` 上の `README.md` が2ブランチモデルを説明するよう更新されている: `main` = フォークペイロード、`develop` = テンプレート開発。「フォーク」セクションでチームが `main` をフォークすべきことを説明し、「テンプレートへの貢献」セクションで PR が `develop` を対象にすべきことを説明する。検証方法: `git show main:README.md | grep -q 'develop'` が0で終了する。

**AC-11.** ロードマップ行 #23 のステータスが、品質ゲートパス後に `develop` 上で `☑` に切り替わる。`main` には `ROADMAP.md` が存在しない(develop-only アーティファクト)。検証方法: `git ls-tree --name-only main .claude/` に `ROADMAP.md` が含まれない。`git show develop:.claude/ROADMAP.md | grep '| 23 |'` が `☑ done` を表示する。

**AC-12.** テンプレートリポジトリのブランチ保護ルールが更新され、`main` への PR に `payload-manifest-check` ステータスチェックのパスが必須となる。検証方法: リポジトリ Settings > Branches > `main` 保護ルールに `payload-manifest-check` が必須ステータスチェックとして記載されている。

## 主要なインタラクション

1. **テンプレートメンテナーが新しい ADR または仕様書を作成する.** 作業はすべて `develop` 上で行われる。ADR と仕様書のファイルはそれぞれ `.claude/meta/adr/` と `specs/` に作成される。これらのパスは develop-only であり、`main` には流れない。

2. **テンプレートメンテナーがエージェントプロンプトを更新する.** エージェントファイルは `.claude/agents/` にあり、ペイロードマニフェストに含まれ、両ブランチに存在する。メンテナーは `develop` で編集し、`main` を対象とした PR を開く。`develop` 上の `payload-manifest-check` ワークフローが PR の diff を検証し、変更されたファイルがすべてマニフェストに含まれているため、チェックがパスし PR がマージされる。

3. **チームがテンプレートをフォークする.** `main` からフォークする。ペイロードマニフェストファイルのみを受け取る。`init.sh` を実行すると、develop-only パスを参照せずにプロジェクト固有のセットアップをガイドされる。

4. **フォークメンテナーがテンプレートの更新をプルする.** テンプレートリポジトリをリモートとして追加し、`main` をフェッチし、ペイロードデルタをマージまたはチェリーピックする。`main` には develop-only の履歴が含まれないため、diff は小さく競合が発生しにくい。

## メトリクス

- **先行指標:** ブランチ分離マイルストーン完了時の `main` 上のファイル数(目標: `wc -l .claude/payload-manifest.txt` の値と一致)。 <!-- ref-allow: payload-manifest.txt is created in Phase B implementation - forward reference -->
- **先行指標:** `main` 宛 PR に対する `payload-manifest-check` のパス率(目標: ブランチ分離ランディングから2週間以内に100%)。
- **遅行指標:** v3.12.0 リリース後にフォークユーザーからの「テンプレート内部削除」に関するissueまたは質問の削減(目標: 最初の60日間でそのようなissueがゼロ)。

## リスクと未解決の問い

- **マージプロトコルの複雑さ.** `develop` から `main` への手動チェリーピック / PR フローは規律が必要。メンテナーが忘れると `main` が `develop` より古くなる。緩和策: `develop` 上の `payload-manifest-check` CI が、develop-only ファイルを導入する PR を高速に失敗させるため、境界が自己強制される。
- **`docs-freshness.yml` の再分類.** このワークフローは当初 keep-on-main の候補だったが、スナップショットファイルが `.claude/` 内(`main` には存在しない)に置かれているため develop-only に再分類された。再分類は ADR-026 に記録される。フォークが鮮度チェックを必要とする場合は、独自のワークフローを追加する。
- **未解決の問い:** `main` はペイロード向け変更のみを追跡する独自の最小限 `CHANGELOG.md` を持つべきか。ADR-026 の Decision に延期。v1 のデフォルトは独立した `main` 用 CHANGELOG なし。

## スコープ外

- 既存フォークの新ブランチモデルへの移行。
- `develop` → `main` への自動チェリーピックツール。
- `init.sh` の深い再設計(develop-only ステップの除去のみが対象)。
- ペイロードマニフェストエディター UI またはジェネレータースクリプトの追加(v1 ではマニフェストはテンプレートメンテナーが手動で管理)。
- `develop` 上のエージェントチームワークフロー順序の CI 強制。

## 参考

- `.claude/meta/adr/026-template-fork-branch-separation.md` — このマイルストーンのアーキテクチャ決定記録(ブランチモデル、ペイロードマニフェストスキーマ、ワークフローインベントリ分類、ADR-026 の Decision)。
- `.claude/ROADMAP.md` — ロードマップ行: #23
