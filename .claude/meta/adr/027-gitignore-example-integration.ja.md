# ADR-027: `.gitignore.example` を `.gitignore` 内のコメントブロックに統合する

## Status

Accepted — 2026-05-21

## Context

ADR-001 (Developer Growth Mode、ADR-003 で Learning Mode にリネーム)、ADR-003、ADR-005 は、Learning Mode のプライバシー姿勢を文書化するために 2 ファイル分割パターンを採用した:

- `.gitignore` — `.claude/learn/knowledge/` と `.claude/learn/config.json` をデフォルトで ignore する。フォークがオプトインしない限り、すべてのフォークがこの姿勢を継承する。
- `.gitignore.example` — チームが共有ナレッジベースを持ちたい場合に、実際の `.gitignore` にコピーすべきオプトイン反転パターン (`!.claude/learn/knowledge/` ブロック) を文書化する。

2 ファイル分割は「クリーンなデフォルト `.gitignore`」と「チームが意識的にコピーすべき明示的オプトイン面」という両方の不変条件を満たすために選択された。両不変条件は `.claude/meta/scripts/check-learn-invariants.sh` と `.github/workflows/learn-invariants.yml` でチェックされている。

実運用で、この分割は摩擦を生んでいる:

1. **命名による誤解.** フォーク運用者 (2026-05-21) は `.gitignore.example` を「`.gitignore` の見本」(つまり、丸ごとコピーするサンプル) として解釈し、「既存の `.gitignore` に組み込むべきオプトイン反転の文書」とは見なさなかった。`.example` サフィックスは他で使われている慣習 (例: `.env.example` は丸ごとコピーするサンプル) と重なっている。
2. **1 つの姿勢に 2 つのファイル.** デフォルトとオプトイン文書を 2 つの別ファイルで保守するとサーフェスが倍増する: ADR、PRD、references、skills、README、CI workflow、invariant チェックスクリプト、payload manifest など、20+ ファイルが `.gitignore.example` を名前で参照している。各参照は同期負債である。
3. **発見可能性が低い、高くない.** オプトインを検討するチームは (a) `.gitignore.example` の存在を知り、(b) ファイルを開き、(c) 正しい行を `.gitignore` にコピーする必要がある。もし反転パターンが `.gitignore` 内のコメントブロックとして存在すれば、(a) と (b) が消える — `.gitignore` を編集している人は誰でもオプトイン経路を即座に目にする。

元の設計意図 (デフォルト ignore + オプトイン反転が許される唯一の形) は健全で、維持される。変わるのは **文書化手段** だ: 別ファイルから、その挙動を制御するファイル内のコメントブロックへ。

## Decision

`.gitignore.example` を `.gitignore` 内のコメントブロックに統合する。具体的に:

1. `.gitignore` に `## Optional: opt-in to a shared team knowledge base` コメントブロックを追加する (Learning Mode のデフォルト ignore 行直後)。ブロックは以下を含む:
   - 根拠 (1 段落) — なぜナレッジベースをデフォルトで gitignore するか。
   - 反転パターンをコメント行として記載 (`# !.claude/learn/knowledge/` と `# !.claude/learn/knowledge/**`) — チームがオプトインする際にアンコメントする。
   - トレードオフ注記 (1 段落) — ナレッジファイルを共有する際に予期すべきこと (修正履歴の可視性、シニア別エントリーの混在、心理的安全性への影響)。

2. `.gitignore.example` をリポジトリから **削除** する。

3. 全参照を **更新**:
   - `.claude/payload-manifest.txt` — `.gitignore.example` 行を削除。**順序の注記:** マニフェストエントリは、ファイルを削除する payload PR の **間** は残しておく必要がある。さもないと、`git diff --name-only` をマニフェストパターンと照合する payload-manifest gate が、その削除を off-manifest のパスとして拒否してしまう。マニフェストエントリの削除は、payload PR が merge された **後** に、develop のみで独立した commit として行う。これにより、マニフェストは最終状態を反映し、なおかつその状態を生み出した削除自体を禁じることはない。
   - `.github/workflows/learn-invariants.yml` — `paths:` トリガから `.gitignore.example` を削除。
   - `.claude/meta/scripts/check-learn-invariants.sh` — 「ファイル存在 + 反転ブロック」チェックを「`.gitignore` 内コメントブロック存在」チェックに置換。
   - `README.md` + `README.ja.md` — Project structure tree から `.gitignore.example` を削除。
   - ADR-001 (EN+JA)、ADR-003 (EN+JA)、ADR-005 (EN+JA) — 文書化手段が ADR-027 で supersede された旨の amendment を追記 (設計意図は維持)。
   - PRD `.claude/meta/prd/developer-learning-mode.md` (EN+JA) — FR-009 と受け入れ基準の文言を `.gitignore` 内コメントブロックに合わせて更新。
   - References `.claude/meta/references/domain-taxonomy.md`、`learning-mode-explained.md` (EN+JA)、`migration/v1-to-v2.md` (EN+JA) — 文中のポインタを更新。
   - Skill `.claude/skills/learn/SKILL.md` — オプトインポインタを更新。

4. `.claude/meta/CHANGELOG.legacy.md` の歴史的参照は **保持** する (過去の状態を記述しているため書き換えない)。

ADR-001 Decision 4 (「ナレッジファイルはデフォルトで gitignore される; オプトインが唯一の共有手段」) と ADR-003 Decision 6 (Learning Mode の gitignore 姿勢) の設計意図は **変更されない**。ADR-005 のパスマッピング結果は維持される。

## Consequences

### Positive

- **1 ファイル、1 姿勢.** `.gitignore` を読む人は Learning Mode のプライバシーストーリー全体 (デフォルト + オプトイン経路) を 2 ファイル目を開かずに目にする。
- **命名が誠実.** `.gitignore` は ignore を制御するファイルであり、オプトイン反転は運用者が既に見る場所にある。`.example` サフィックスを誤読する余地がない。
- **同期負債削減.** 文書化手段を参照するファイル数が 20+ から ~5 に減る (本 PR 後: `.gitignore`、ADR-027、invariant チェックスクリプト、workflow、CHANGELOG エントリ)。
- **発見可能性向上.** オプトインを検討するチームは、デフォルトと同じ画面で経路を目にする — 別ファイルを探す必要なし。

### Negative

- **`.gitignore` が長くなる.** 約 20 行のコメント (根拠 + コメント化された反転 + トレードオフ注記) が追加される。これは一度きりの追加で、運用者が既に読む単一の場所に存在する。
- **1 PR の移行コスト.** 20+ ファイルの `.gitignore.example` 参照を更新する必要がある。コストは一度だけ; 将来の保守はシンプルになる。
- **`.gitignore` 内のハードコード知識.** Learning Mode ランタイムパスのレイアウトが変わると (例: `.claude/learn/knowledge/` → 他のパス)、`.gitignore` 内のコメントブロックも更新が必要。これはデフォルト ignore 行についても既に真であり、新規の露出面は小さい。

### Neutral

- ADR-001 / ADR-003 / ADR-005 は決定文言を保持; **文書化手段** 節のみが supersede される。設計意図 (デフォルト ignore + オプトイン反転が唯一の共有経路) は不変。
- `check-learn-invariants.sh` の Check 3 ロジックは形が変わる (ファイル存在 + 2 ファイル目の反転チェックではなく、デフォルト ignore + 同ファイル内オプトインコメントブロックチェックに)。保護されている不変条件は同じ。
- `learn-invariants.yml` workflow は `.gitignore.example` の変更ではトリガされなくなる (ファイル自体が存在しない)。`.gitignore` 自体のトリガは不変。

## Alternatives considered

| 代替案 | 利点 | 欠点 | 採用しなかった理由 |
|---|---|---|---|
| **A. `.gitignore.example` を現状維持** | 移行コストゼロ; 「どこかにコピーすべき」 という明示的アフォーダンスを維持 | 命名による誤解継続; 20+ ファイルが二重ファイル方式と結合; 人間工学的摩擦が継続 | 摩擦は実在しユーザフィードバックで文書化されている; 現状維持は同じ議論を繰り返すことを意味する |
| **B. `.gitignore.example` を `gitignore-share-opt-in.md` にリネーム** | 誠実なファイル名; ファイル分離を維持; C より小さなスコープ | 依然 2 ファイル; 20+ 参照の更新が必要; markdown 拡張子はシェルコメント風の内容を持つファイルの `git diff` 人間工学を悪化させる | 命名問題は解くが 2 ファイル管理問題は解かない |
| **C. より広い Learning Mode オプトイン化 / footprint 削減マイルストーンに送る** | 関連する関心事をバンドル | ユーザ可視の摩擦を無期限に延期する; Learning Mode footprint 削減は別スコープ・別タイミング判断 | 統合は単独でランドするのに十分軽量; 結合は利得なしに修正を遅らせる |

## References

- `.claude/meta/adr/001-developer-growth-mode.md` — Decision 4 の文書化手段を部分 supersede (意図は維持)。
- `.claude/meta/adr/003-learning-mode-relocate-and-rename.md` — Decision 6 の文書化手段を部分 supersede (意図は維持)。
- `.claude/meta/adr/005-template-restructure.md` — `.gitignore` / `.gitignore.example` に関する Consequences 注記が本 ADR で supersede される。
- `.claude/meta/prd/developer-learning-mode.md` — FR-009 文言更新は本判断から派生する。
- `.claude/meta/scripts/check-learn-invariants.sh` — Check 3 ロジック更新は本判断から派生する。
- `.github/workflows/learn-invariants.yml` — `paths:` トリガ更新は本判断から派生する。
- ユーザフィードバック (2026-05-21) 二重ファイル命名について。
- Roadmap 行: (なし — これは #23 設計衛生の後続作業であり、それ自体のマイルストーンではない)
