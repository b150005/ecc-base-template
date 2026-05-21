# ADR-028: テンプレートペイロードから `.devcontainer/` スカフォールドを削除する

## Status

Accepted — 2026-05-21

## Context

`main` ペイロードには、フォーク向けデフォルトとして役に立っていない 2 つの
残置資産がある:

1. **`.devcontainer/devcontainer.json`** — 3.6 KB のファイルだが、意味のある
   キー (`image`、`features`、`customizations.vscode.extensions`、
   ライフサイクルコマンド、`forwardPorts`、`remoteEnv`) はすべてコメント
   アウトされている。実際に有効な行は `"name": "Project Dev Container"` と
   `"remoteUser": "vscode"` の 2 行のみ。ヘッダコメントは
   `See .claude/meta/references/devcontainer.md` を参照するよう案内している
   が、当該ファイルは `main` にも `develop` にも存在しない (`main` には
   references ディレクトリ自体が無く、`develop` 側でもレガシー参照ファイル
   は保持されなかった)。スカフォールドは v3.0.0 (`c25140d`、
   `feat!: v3.0.0 — restructure for template-repository UX`) で ADR 無しに
   導入された。spec からの参照も無い。`develop` のペイロードマニフェスト
   では「フォーク再利用可能な開発環境スカフォールド」と記載されているが、
   この再利用可能性は仮定でしかない: 本気で Dev Containers を使いたい
   フォークは base image を選び、features を有効化し、extensions を pin
   する必要がある — そのいずれも、テンプレートがフレームワーク不問である
   ためスカフォールド側であえて指定していない。スカフォールドが再利用可能
   であるところの目的 (フォークに「ここで Dev Containers を使えますよ」と
   示すこと) は、README で Dev Containers に言及するだけで達成されており、
   ファイル本体は「`.devcontainer/devcontainer.json` を追加したければ追加
   してください」という 1 文以上の情報を提供していない。

2. **`main:.claude/settings.json`** に dead hook 参照が残っている。コミット
   `b9256c7` (2026-05-21、`refactor(template): remove develop-only skills,
   hooks, output-styles from main (Roadmap #23)`) は AC-2 クリーンアップの
   一環として `main` から `.claude/hooks/coaching-context.sh` を削除した
   が、`settings.json` の `hooks.UserPromptSubmit` ブロック (このフックを
   登録している) は更新し忘れた。同ブロックは依然として
   `"$CLAUDE_PROJECT_DIR"/.claude/hooks/coaching-context.sh` を指しており、
   このファイルは `main` に存在しない。フォーク利用者が Claude Code を
   起動するたびに、セッション最初のユーザープロンプトでフック解決警告が
   表示される。

両者を 1 つの ADR にまとめる理由は、修正が同一の PR セットに収まり、かつ
ADR-026 の「`main` はフォーク向けクリーンペイロード」という原則を共有して
いるためだ: `main` 上の項目はフォークにとって load-bearing であるか、
そうでなければ置かれるべきではない。

## Decision

1. `main` と `develop` の両方から `.devcontainer/` を **削除** する。
2. `main:.claude/settings.json` から `hooks.UserPromptSubmit` ブロックを
   **削除** し、`"hooks": {}` をフォーク向けの拡張ポイントとして文書化
   された状態で残す。`develop` の `settings.json` は **変更しない** —
   `develop` 側では `coaching-context.sh` が存在するため、メンテナ向け
   Learning Mode コーチング動作がこのフックに依存している。

ADR-026 の 2026-05-21 改訂は、`main` と `develop` で `settings.json` が
正当に異なりうることを既に確立している (`main` は `.gitkeep` のみ、
`develop` は完全な workflows セットを持つのと同じパターン)。本 ADR は
その分岐の 2 例目を記録する。

## Consequences

### Positive

- **`main` から dead ref が消える.** フォーク利用者はセッション開始時に
  フック解決警告を見なくなる。クリーンなフォークで `find .devcontainer`
  と `grep coaching-context settings.json` の両方が空を返す。
- **正直なペイロード.** `main` はもはや、README で註釈を付け `init.sh`
  で言及する必要のある空スカフォールドを同梱しない。ファイル削除により
  3 つの下流面 (README ツリー行、README.ja ツリー行、`init.sh` 次手順
  ステップ 4) が同時に消える — これらは空ファイルを指すためだけに存在
  していた。
- **payload-manifest の表面積が縮小.** `.devcontainer/**` glob とその
  セクションヘッダが `.claude/payload-manifest.txt` から取り除かれ、
  メンテナが正確に保つべき「これは何のためか」文書が 1 行少なくなる。
- **settings.json の分岐が偶発的ではなく load-bearing になる.**
  `develop` のフックブロックは存在するファイルを指し、`main` の空フック
  ブロックは bad ref 無しに拡張ポイントを公開する。分岐は (本 ADR で)
  文書化され、バグ予備軍ではなくなる。

### Negative

- **Dev Containers を採用するフォークは自前で書く必要が出る.** スカ
  フォールドをアンコメントして Dev Containers を有効化したいフォーク
  は、ファイルをゼロから書くことになる。緩和策: base image (例:
  `mcr.microsoft.com/devcontainers/typescript-node:20`) から動作する
  `devcontainer.json` を書くのは 10 行程度であり、フォークがエコシス
  テムを選んだ時点でいずれにせよ行う作業だった — 削除したスカフォー
  ルドはコメントアウトされたヒント以上の価値を提供していなかった。
- **スカフォールドを既に拡張していたフォーク** はテンプレ同期で
  conflict にあたる (フォーク側に非空 `.devcontainer/` がある状態で、
  upstream 側が削除を pull で持ち込む)。緩和策: ファイルを実質的に
  変更したフォークは定義上自分のコピーを保持しているので、pull 時の
  upstream 削除を拒否すればよい — これはローカルが実質的に変更した
  ファイルに対する `git merge` の標準的な振る舞いである。

### Neutral

- README.md と README.ja.md からは `.devcontainer/` のツリー行が消える。
  周辺の罫線文字は再確認する (該当行は末尾エントリではないため、
  単純な行削除で済む — `├─`/`└─` の置換は不要)。
- `.claude/meta/scripts/init.sh` からは「Customize
  `.devcontainer/devcontainer.json` for your stack」の次手順が消える。
  番号付きリストは再採番される (旧 4 が消え、旧 5/6/7 が新 4/5/6 に
  なる)。
- `.claude/payload-manifest.txt` から `.devcontainer/**` エントリと
  そのセクションヘッダが消える。他の許可パスは影響を受けない。
- settings.json 修正は専用 ADR ではなく CHANGELOG の `### Fixed` で
  記録する — これは回帰系のバグ (元のクリーンアップコミットが 1
  ファイルを取りこぼした) であり、設計上の判断は ADR-026 から完全に
  継承される。

## Alternatives considered

| 代替案 | 長所 | 短所 | 採用しなかった理由 |
|---|---|---|---|
| **A. `.devcontainer/` を残し、1 つのエコシステム (例: Node 20) を実体化する** | そのエコシステムを狙うフォークは実際の出発点を得る | フレームワーク不問の原則 (`main` ペイロードは言語を事前選択してはならない) に反する。当該エコシステム以外のフォークを排除する。エコシステム選択自体が、テンプレートに根拠の無い新たな設計判断になる | テンプレートの価値はスタックに対して無色である点にあり、特定エコシステムを焼き付けるのは現状の空スカフォールドより悪化する |
| **B. `.devcontainer/` を `develop` のみに残す (リファレンスとして)** | メンテナが参照できる場所にファイルを保つ | フォークは `develop` を見ない。「リファレンス」聴衆は README に同梱の `mcr.microsoft.com/devcontainers/...` イメージ提案コメントブロックで既に満たされている。v3.0.0 で導入されて以降、このファイルをリファレンスとして必要としたメンテナは存在しない | 実問題を解決しない。聴衆無しの branch divergence を増やすだけ |
| **C. settings.json の dead ref のみ修正し、`.devcontainer/` は残す** | 影響範囲が小さい。hook バグは真の回帰、一方 `.devcontainer/` 削除は判断問題 | 同じアンチパターン (フォークペイロード内の orphan/dead アイテム) の 2 インスタンスを「今直す」「永遠に先送り」に二分する。AC-2 クリーンアップ (PR #17) が既に「`main` 上の低価値アイテムは出す」というパターンを確立している | レビューコスト上のメリット無しに、クリーンなクリーンアップを半端な対応に分割する |
| **D. `.devcontainer/devcontainer.json` を `init.sh` の削除プロンプト対象に追加する** | スカフォールドを欲しいユーザーには残す。オプトアウトで削除可能 | init.sh の削除プロンプトは、フォークが削除したい可能性のあるファイル (例: 単言語プロジェクト向けの二言語ファイル) を対象とする。`.devcontainer/` はその基準を満たさない: スカフォールドが空なので、オプトアウトする対象 (価値) が存在しない | オプトアウト機構は、対象資産が残存時に価値を持つことを前提とする。これは前提を満たさない |

## References

- `.claude/meta/adr/026-template-fork-branch-separation.md` — 本 ADR が
  適用する「`main` はフォーク向けクリーンペイロード」原則を確立し、
  `settings.json` のようなファイルにおける `main`/`develop` 分岐の
  正当性を文書化する。
- `specs/23-template-fork-branch-separation.md` — Spec AC-2
  (「`.claude/meta/` は `main` に存在しない」) と、PR #17 が実行した
  より広いペイロードクリーンアップ根拠。
- コミット `c25140d` (`feat!: v3.0.0 — restructure for template-repository UX`) — `.devcontainer/devcontainer.json` の初出 (ADR は提出されなかった)。
- コミット `b9256c7` (`refactor(template): remove develop-only skills, hooks, output-styles from main (Roadmap #23)`) — `main` から `coaching-context.sh` を削除したが `settings.json` を取りこぼした。
- PR #17 (`chore(main): remove orphan template-internal files (AC-2 cleanup)`) — 本 ADR が継承する先行クリーンアップ。
- ADR-027 (`Integrate .gitignore.example into .gitignore as a comment block`) — 低価値ペイロードファイルを、それが文書化していた内容を運用者が既に見る場所に統合することで削除した直近の先例。
- ロードマップ行: (なし — 本件は #23 からの follow-on クリーンアップで、独自のマイルストーンではない)
