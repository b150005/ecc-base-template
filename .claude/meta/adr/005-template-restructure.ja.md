# ADR-005: テンプレートリポジトリのリストラクチャ — 利用者レイヤー vs テンプレレイヤー

> 英語版: [005-template-restructure.md](./005-template-restructure.md)(原文・Source of Truth)

## ステータス

Accepted — 2026-04-25

## コンテキスト

ecc-base-template は GitHub テンプレートリポジトリです。利用者にとっての価値は、
フォークして新しいリポジトリを最初に開いた瞬間に何が見えるかで決まります。
v2.2.0 までのリポジトリのトップレベル構成は、性質の異なる 2 種類のコンテンツを
混在させていました:

1. **利用者レイヤー** — フォーク先のプロジェクトが所有・編集するもの: `README`、
   `.env.example`、`.gitignore`、`LICENSE`、プロジェクト固有のエージェント定義。
2. **テンプレレイヤー** — テンプレ自身の機構を動かすために同梱されるもの:
   Learning Mode の `preamble.md`、不変条件チェック CI スクリプト、テンプレ自身の
   ADR、PRD、マイグレーションガイド、ワークドエグザンプル集、解説ドキュメント。

両者がルート直下、`docs/`、`learn/`、`scripts/`、`docs/en/adr/` に同居しており、
利用者にとって以下のような実害がありました:

- `docs/en/adr/001..004` が ADR の番号空間を占有していた。利用者が自分の
  `001-my-first-decision.md` を書こうとすると衝突するか、「`005-...` が自分の
  最初の ADR」という混乱した状態を受け入れるしかなかった。
- `prd/` という略語はディレクトリ名だけでは意味が伝わらなかった。「ディレクトリ名で
  意味を表す」という方針が、不可解な命名のせいで台無しになっていた。
- `learn/preamble.md` と `scripts/check-learn-invariants.sh` が、利用者が自分の
  用途で使いたいかもしれない 2 つのディレクトリ名(特に `scripts/`)を予約していた。
- 21 KB の `CHANGELOG.md` と README 冒頭の `v2.1.0 — Coaching Pillar:` バナーにより、
  フォーク直後のリポジトリがテンプレートの宣伝物のように見えてしまっていた。
- テンプレ自身の `docs/en/learn/examples/` (英語約 19 ファイル + 同数の日本語訳) が、
  利用者が著したい `docs/` のすぐ横に居座っていた。

この ADR の目的は、過去に公開されたあらゆるパスを破壊するコストを払ってでも、
こうした混在を構造的に不可能にすることです。

## 決定

二層構造を採用し、**ルート直下の可視ディレクトリを 0 個とし、テンプレ内部の
すべての成果物を `.claude/` 配下に置く**ことを明示的なルールとします。

### 原則

1. **利用者レイヤーは最小かつ自明**。`Use this template` の後、利用者には
   `README.md`、`README.ja.md`、`CHANGELOG.md`、`LICENSE`、`.env.example`、
   `.gitignore`、`.gitignore.example`、`.gitattributes`、および 3 つのドット始まり
   ディレクトリ(`.claude/`、`.github/`、`.devcontainer/`)のみが見えます。
2. **テンプレレイヤーは `.claude/` 内に隠す**。Learning Mode の機構、テンプレ内部
   の ADR、テンプレの PRD、ワークドエグザンプル、マイグレーションガイド、不変条件
   チェックスクリプトはすべて `.claude/` 配下に移動します。`.claude/` を開かない
   利用者は決してこれらを目にしません。
3. **二言語規約は `filename.md` + `filename.ja.md`**。従来の `docs/en/` + `docs/ja/`
   は docs 中心のサイトには合理的でしたが、テンプレ内部リファレンスには余計な
   オーバーヘッドでした。
4. **テンプレートはフィクスチャではない**。`adr-template.md` と `spec-template.md`
   は `.claude/templates/` に置かれ、利用者が好きなディレクトリ(`adr/`、
   `docs/adr/`、`adr/en/` など)にコピーする想定です。テンプレートが ADR ディレクトリを
   要求することはありません。
5. **Learning Mode のランタイム状態はルート `learn/` ではなく `.claude/learn/`**。
   これにより、`learn/` を製品側の概念(教育アプリなど)に使いたい利用者と
   衝突しません。

### マッピング

| v2.x のパス | v3.0 のパス |
|---|---|
| `learn/preamble.md` | `.claude/skills/learn/preamble.md` |
| `learn/config.json`(ランタイム) | `.claude/learn/config.json`(ランタイム) |
| `learn/knowledge/`(ランタイム) | `.claude/learn/knowledge/`(ランタイム) |
| `scripts/check-learn-invariants.sh` | `.claude/meta/scripts/check-learn-invariants.sh` |
| `docs/en/adr/000-template.md` | `.claude/templates/adr-template.md` (+ `.ja.md`) |
| `docs/en/adr/001..004-*.md` | `.claude/meta/adr/*.md` (+ `.ja.md`) |
| `docs/en/prd/developer-learning-mode.md` | `.claude/meta/prd/developer-learning-mode.md` (+ `.ja.md`) |
| `docs/en/learn/domain-taxonomy.md` | `.claude/meta/references/domain-taxonomy.md` |
| `docs/en/learn/examples/*.md` | `.claude/meta/references/examples/*.md` (+ `*.ja.md`) |
| `docs/en/migration/v1-to-v2.md` | `.claude/meta/references/migration/v1-to-v2.md` (+ `.ja.md`) |
| `docs/en/learning-mode-explained.md` | `.claude/meta/references/learning-mode-explained.md` (+ `.ja.md`) |
| `docs/en/{ci-cd-pipeline,devcontainer,ecc-overview,github-features,tdd-workflow,template-usage}.md` | `.claude/meta/references/<同名>.md` (+ `.ja.md`) |
| `docs/en/index.md`、`docs/ja/index.md` | 削除(v3 ではランディングページなし) |
| `CHANGELOG.md`(v2.2.0 までのテンプレ履歴) | `.claude/meta/CHANGELOG.legacy.md`(参照用に保持) |
| `CHANGELOG.md`(新規) | `## [Unreleased]` から開始 — 利用者の changelog として意図 |

新規成果物:

- `.claude/meta/scripts/init.sh` — フォーク後の初期化スクリプト
- `.claude/meta/CHANGELOG.md` — テンプレ自身の継続的な changelog
- `.claude/templates/spec-template.md` (+ `.ja.md`) — 機能仕様書用

ファイル移動ではないが、コードベース全体で発生したパス文字列の書き換え:

- 全 15 件の `.claude/agents/*.md` の末尾 `## Developer Learning Mode contract`
  セクションが `learn/config.json`、`learn/preamble.md`、`../../docs/en/adr/00X-*.md`
  ではなく `.claude/learn/config.json`、`.claude/skills/learn/preamble.md`、
  `../meta/adr/00X-*.md` を参照するように更新。
- `.claude/skills/learn/SKILL.md` と `.claude/skills/learn/preamble.md` 内のすべての
  内部パス文字列を v3 のレイアウトに更新。
- `.github/workflows/learn-invariants.yml` の `paths:` トリガと `run:` 起動が
  `.claude/learn/**` と `.claude/meta/scripts/check-learn-invariants.sh` を指すように更新。
- `.claude/meta/scripts/check-learn-invariants.sh` の `repo_root` を
  `git rev-parse --show-toplevel`(相対パスフォールバックあり)で解決するよう変更。
  スクリプトがリポジトリルートから 3 階層深くなったため。
- `.gitignore` と `.gitignore.example` の Learning Mode 関連エントリは
  `.claude/learn/knowledge/` と `.claude/learn/config.json` を指す。

## 帰結

### ポジティブ

- 利用者の最初の ADR は、彼らが選んだディレクトリの `001-*.md` になる。番号衝突も
  なく、強制的に継承する必要のあるディレクトリもない。
- `docs/` は完全に利用者の名前空間。`docs/` に MkDocs や Docusaurus を置きたい
  プロジェクトと、テンプレ側が競合することはなくなる。
- `scripts/` も同様に利用者のもの。
- フォーク直後のリポジトリは、`v2.1.0 Coaching Pillar` リリースバナーではなく
  テンプレートを説明する `README.md` を最初に見せる。
- `.claude/meta/` が「ここにあるすべてはテンプレ自身の事情。テンプレの上流
  追従が不要なら削除してよい」という明確な契約になる。

### ネガティブ

- v2.x のパスへの外部リンクはすべて壊れる。`CHANGELOG.legacy.md` は履歴を保存して
  いるが、`docs/en/adr/001-developer-growth-mode.md` を参照していた PR や Issue は
  実質 404 を指すことになる。利用者は明示的にこのコストを受け入れた — この ADR は
  後方互換を維持しようとしない。
- v2.x からアップグレードする利用者は、リストラクチャを手動でマージする(非自明)
  か、v3 から再テンプレートしてプロジェクト固有コンテンツを移植する必要がある。
  自動マイグレーション経路はない。テンプレートは in-place アップグレードを意図して
  いない。
- Learning Mode の不変条件チェックは利用者が訪れない可能性のあるディレクトリに
  置かれた。CI ワークフローは「Learning Mode を使う予定がなければ
  `.github/workflows/learn-invariants.yml` と `.claude/meta/` の両方を削除すべし」と
  明示している。

### 中立

- 全ファイルを `.claude/` 配下にまとめる規約は、`.claude/` の肥大化を意味する。
  `.claude/` は既に Claude Code 自身の機構の慣習なので、ここにテンプレ内部の
  メタ情報を加えても既存のメンタルモデルに合致するため、許容できる。
- 二言語規約が `docs/en/` + `docs/ja/` から単一ディレクトリ内の `*.md` + `*.ja.md`
  に変わった。これは既存の `README.md` / `README.ja.md` パターンに合致し、
  クロスリンクを単純化する。

## 検討した代替案

| 代替案 | 採用しなかった理由 |
|---|---|
| `docs/` をルートに残し、テンプレ ADR に `template-` プレフィックスを付ける(例: `template-001-*.md`) | 利用者の ADR 番号空間を解放しない。テンプレの解説とエグザンプルが利用者の `docs/` と競合する |
| `learn -> .claude/learn` のシンボリックリンクをルートに残して後方互換維持 | 旧パスは保てるがクリーンなルートという目標が失われる。Windows や一部 CI ランナーでシンボリックリンク関連のエッジケースが発生する |
| `learn/` と `scripts/` のみ移動し、`docs/` はそのまま | 中途半端。`docs/en/adr/` 衝突と `prd/` 命名の問題が未解決のまま残る |
| 完全フラットなルート(`docs/` 不可視、`CHANGELOG.md` なし、`README.md` + `LICENSE` のみ) | やりすぎ。`CHANGELOG.md` のルート配置は SemVer の標準的な成果物として利用者が期待する。隠すと混乱が増える |

## 参考

- [PRD: Developer Learning Mode](../prd/developer-learning-mode.md)
- [ADR-001: Developer Growth Mode](001-developer-growth-mode.md)
- [ADR-003: Learning Mode の改名と再配置](003-learning-mode-relocate-and-rename.md)
- [ADR-004: コーチングピラー](004-coaching-pillar.md)
- v3.0.0 計画セッション(2026-04-25)で記録されたユーザーの発言:
  「ルート直下の可視ディレクトリは0にするのが望ましいです。」
