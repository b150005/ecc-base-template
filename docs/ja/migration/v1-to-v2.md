> このドキュメントは `docs/en/migration/v1-to-v2.md` の日本語訳です。英語版が原文（Source of Truth）です。

# マイグレーションガイド: v1.x から v2.0.0 へ

> 対象読者: ecc-base-template v1.x を元に作成されたフォークのメンテナーのうち、v2.0.0 へのアップグレードを予定している方。

## 変更点の概要

v2.0.0 は [ADR-003](../adr/003-learning-mode-relocate-and-rename.md) を根拠とする破壊的変更リリースです。3 つの独立した欠陥がまとめて修正されました。

1. 出力に用いていた `notes`（ノート）という用語が `knowledge`（ナレッジ）に置き換えられました。アーティファクトの実際の形状 — 非公式な走り書きではなく、ドメイン単位で整理された参照資料 — に合わせた変更です。
2. 機能ディレクトリが `.claude/growth/` からリポジトリルートの `learn/` に移動しました。ハーネス設定とプロジェクトアーティファクトの境界が回復しました。
3. 事前シードされていた 19 個のプレースホルダーファイルが廃止されました。`learn/knowledge/` はインストール時には空であり、ファイルはドメインごとに最初の教示機会が発生したときに作成されます（遅延マテリアライゼーション）。

これに伴い、機能の傘名称も改名されました。**Developer Growth Mode** は **Developer Learning Mode** に、Skill コマンドは `/growth` から `/learn` に変更されています。

## パスの移行対照表

v1.x と v2.0.0 のあいだで変更されたパスを以下に示します。

| v1.x のパス | v2.0.0 のパス |
|---|---|
| `.claude/growth/` | `learn/` |
| `.claude/growth/config.json` | `learn/config.json` |
| `.claude/growth/preamble.md` | `learn/preamble.md` |
| `.claude/growth/notes/<domain>.md` | `learn/knowledge/<domain>.md` |
| `.claude/skills/growth/SKILL.md` | `.claude/skills/learn/SKILL.md` |
| `docs/en/growth/` | `docs/en/learn/` |
| `docs/en/growth/domain-taxonomy.md` | `docs/en/learn/domain-taxonomy.md` |
| `docs/ja/growth/` | `docs/ja/learn/` |
| `docs/ja/growth/domain-taxonomy.md` | `docs/ja/learn/domain-taxonomy.md` |
| `docs/en/growth-mode-explained.md` | `docs/en/learning-mode-explained.md` |
| `docs/ja/growth-mode-explained.md` | `docs/ja/learning-mode-explained.md` |
| `docs/en/prd/developer-growth-mode.md` | `docs/en/prd/developer-learning-mode.md` |
| `docs/ja/prd/developer-growth-mode.md` | `docs/ja/prd/developer-learning-mode.md` |
| `scripts/check-growth-invariants.sh` | `scripts/check-learn-invariants.sh` |

v2.0.0 で新たに追加されたパス（v1.x には相当するものがありません）:

| 新しいパス | 用途 |
|---|---|
| `docs/en/migration/v1-to-v2.md` | 英語原文（このドキュメント） |
| `docs/ja/migration/v1-to-v2.md` | 本ファイル（日本語訳） |
| `docs/en/learn/examples/<domain>.md` | 19 件の Meridian ベース正典ドメイン例（読み取り専用参照） |
| `docs/en/adr/003-learning-mode-relocate-and-rename.md` | v2.0.0 の決定を記録した ADR |

## Learning Mode を一度も有効化していないフォーク

`/growth on`（v1.x コマンド）または `/learn on`（v2.0.0 コマンド）を一度も実行したことがない場合、ナレッジファイルも `config.json` も存在しません。マイグレーションはドキュメントのみです。

1. v2.0.0 のテンプレート変更をフォークに取り込んでください。
2. `.gitignore` に `learn/knowledge/` と `learn/config.json` が記載されていることを確認してください。`learn/knowledge/` ディレクトリ自体はまだディスク上に存在しません — [ADR-003 §4](../adr/003-learning-mode-relocate-and-rename.md) の lazy-materialize 不変式により、`/learn on` 後の最初の教育モーメントで初めて作成されます。
3. 以上で完了です。機能はデフォルトで OFF のままです。

## Learning Mode を有効化してナレッジを蓄積しているフォーク

`learn/config.json`（v1.x では `.claude/growth/config.json`）が存在し、保持したいナレッジファイルがある場合は、以下の手順に従ってください。

### ステップ 1: config ファイルを移動する

```bash
git mv .claude/growth/config.json learn/config.json
```

### ステップ 2: 蓄積されたナレッジファイルを移動する

各ドメインファイルを `.claude/growth/notes/` から `learn/knowledge/` に移動します。次のコマンドで一括して移動できます。

```bash
git mv .claude/growth/notes learn/knowledge
```

`.claude/growth/notes/` 配下にカスタムのディレクトリ構造がある場合は、`git mv` コマンドを適宜調整してください。

### ステップ 3: 空になった growth ディレクトリを削除する

```bash
git rm -r .claude/growth/
```

フォーク内で `.claude/growth/preamble.md` をカスタマイズしていた場合は、古いファイルを破棄する前に v2.0.0 の `learn/preamble.md` を確認してください。v2.0.0 のプリアンブルは新しいパスと用語を反映しています。カスタマイズ内容は再適用が必要な場合があります。

### ステップ 4: .gitignore を更新する

`.claude/growth/notes/` を無視していた既存のエントリを `learn/knowledge/` を無視するエントリに置き換えてください。

```
# 古いエントリ（削除）
.claude/growth/notes/

# 新しいエントリ（追加）
learn/knowledge/
```

ナレッジファイルをコミットする選択をしていた場合（gitignore をオプトアウトしていた場合）は、オプトインエントリも更新してください。

```
# 古いエントリ（削除）
!.claude/growth/notes/

# 新しいエントリ（追加）
!learn/knowledge/
```

### ステップ 5: コミット済みナレッジファイルの用語を置換する

コミット済みのナレッジファイルがある場合、古い用語の出現箇所を置換してください。二重置換を防ぐために、以下の順序で適用してください。

| 置換前 | 置換後 |
|---|---|
| `## Growth: notebook diff` | `## Learning: knowledge diff` |
| `## Growth: taught this session` | `## Learning: taught this session` |
| `.claude/growth/notes/` | `learn/knowledge/` |
| `.claude/growth/` | `learn/` |
| `notes/`（パスの構成要素として） | `knowledge/` |
| `notebook` | `knowledge` |
| `Growth Mode` | `Learning Mode` |
| `Growth Domains` | `Learning Domains` |
| `/growth` | `/learn` |

エディターのプロジェクト全体の検索・置換機能、または一連の `sed` コマンドで適用できます。自動化スクリプトは提供していません。マイグレーションは機械的な作業であり、影響を受けるフォークの数は限られているためです。

### ステップ 6: CLAUDE.md を更新する（カスタマイズしている場合）

フォークの `CLAUDE.md` で `.claude/growth/` を参照している箇所を `learn/` に更新してください。v2.0.0 テンプレートの `CLAUDE.md` から更新済みのブロックを取り込み、カスタマイズ内容をマージしてください。

### ステップ 7: エージェントプロンプトを更新する

Learning Mode に対応している各エージェントプロンプトには「Developer Learning Mode contract」セクションが含まれています。v1.x ではこれらが `.claude/growth/config.json` および `.claude/growth/notes/` を参照していました。v2.0.0 のエージェントファイルを取り込むか、ステップ 5 の対照表に従ってパスを置換してください。

エージェントプロンプト内のセクションマーカー `## Growth Domains` も `## Learning Domains` に変更されています。CI スクリプト `check-learn-invariants.sh` は新しいマーカーを anchor として使用します。古いマーカーを持つカスタムエージェントがある場合は、CI を実行する前に更新してください。

## マイグレーションの検証

上記の手順を完了したら、CI 不変条件スクリプトを実行してフォークの整合性を確認してください。

```bash
bash scripts/check-learn-invariants.sh
```

スクリプトは以下の 3 点を検査します。

1. `/learn` Skill が `disable-model-invocation: true` を持つこと。
2. `## Learning Domains` を宣言しているすべてのエージェントに、`learn/config.json` を読み込むガード分岐のテキストが含まれていること。
3. `learn/knowledge/` が `.gitignore`（または `.gitignore.example`）に記載されていること。

3 つのチェックがすべてパスしてからマージしてください。

## 機能を有効化したことがないフォークのまとめ

v2.0.0 を取り込んでください。観察できる変更は、リポジトリルートに `learn/` が存在すること（`knowledge/` サブディレクトリが空で gitignore されている）、および Skill コマンドが `/growth` から `/learn` に変わることだけです。蓄積されたコンテンツは存在しないためリスクはなく、マイグレーションの作業は不要です。
