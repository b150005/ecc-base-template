# フォーク時における init.sh の Roadmap プレースホルダー削除

## Status

Approved

**Owner:** product-manager
**Target release:** 次のマイナーリリース — このリポジトリにはバージョン管理リリースサイクルはありません

## Problem

ecc-base-template をフォークすると、`.claude/CLAUDE.md` にはテンプレート自身の開発用の dogfooding 行 21 件 (#01–#21) で構成された `## Roadmap` セクションと、テンプレート内部の `specs/NN-slug.md` 予約規約を説明する `**Spec reservation rule:**` 段落が含まれた状態で配布されます。これらの行や予約規約段落はいずれも、派生プロジェクトの Roadmap には属しません。フォークの `product-manager` は、21 行を引き継ぐのではなく、空の Roadmap を所有してゼロから育てるべきです。テーブル内のほとんどの `specs/NN-slug.md` パスはテンプレートリポジトリにある実在ファイルであり、フォークが `specs/` ディレクトリの内容を削除した瞬間にダングリング参照となります。`## Extending This File` の項目 6 には "Fill the Roadmap section as you plan milestones" と記載されており、空の状態から始めることを意図していますが、`init.sh` はこれを自動化していません。フォーク所有者は現在、行を手動で削除する (手間がかかりエラーが起きやすい) か、継承した行をそのまま放置する (関係のない履歴で Roadmap インデックスが汚染される) かのどちらかを選択しています。

## Goals

- `init.sh` が初期化時にフォークの `## Roadmap` セクションから 21 件のテンプレート dogfooding 行と `**Spec reservation rule:**` 段落を削除する。
- 削除後の `## Roadmap` セクションが整形式であること: CI スクリプトが フォークに残されている場合、#04 ダングリング参照検出器と #05 Roadmap ドリフト検出器を通過する。
- 削除処理は既存の `has_placeholder` センチネル (`[YOUR PROJECT NAME]` が存在すること) でゲートされており、このテンプレートリポジトリ自身の Roadmap は決して変更されない。
- 削除処理はべき等である: プレースホルダーがすでに置換されたフォークで `init.sh` を再実行しても Roadmap が破損しない。
- `--dry-run` はファイルに書き込まずに変更内容を表示する (他の `init.sh` ミューテーションとの一貫性)。

## Non-goals

- `README.md`、`README.ja.md`、または `.claude/CLAUDE.md` 以外のファイルは変更しない。
- テンプレートリポジトリ自身の Roadmap は変更しない (`has_placeholder` ゲートで保護)。
- 既存の検出器 (#04、#05、#06) の動作を変更したり、新しい CI 検出器を追加したりしない — 削除後の CLAUDE.md は既存のルールをそのまま満たすだけでよい。
- `specs/` ディレクトリや Spec ファイルは削除しない; CLAUDE.md のみを編集する。
- `**Rules:**` ブロック (テーブルに続く複数箇条書きのブロック) は削除しない — これらのルールはあらゆる Roadmap に対する汎用ガバナンスであり、すべてのフォークに属する。
- `## Roadmap` 見出し自体やイントロ文は削除しない — セクションは残し、テンプレート固有のコンテンツを空にするだけ。
- Roadmap 専用の別センチネルは導入しない; 既存の `has_placeholder` ゲートが唯一の判別子である (Key Interactions 参照)。
- フォークが CI 検出器ワークフロー (`.github/workflows/`) を保持するか削除するかは決定しない — それはフォーク所有者の選択であり、このクリーンアップとは直交する。
- アーキテクトが ADR-018 トライアドを満たすと判断しない限り、新しい ADR は追加しない。設計上、これは init.sh の既存ミューテーションスコープの直接的な拡張である。

## User stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| テンプレートをフォークした開発者 | `init.sh` を一度実行して空のきれいな Roadmap を得る | 自分のマイルストーンを計画する前に無関係な 21 行を手動で削除しなくてよい |
| すでに初期化済みのフォークで init.sh を再実行する開発者 | "Roadmap already customized — skipping" と表示される | 再実行で Roadmap が破損しない |
| コミット前に変更をプレビューしたい開発者 | `--dry-run` を使用する | 書き込み前に init.sh が変更する内容を確認できる |

## Acceptance criteria

以下の基準はスクリプトの動作とファイル内容に対して直接検証できるように記述されており、テストスイートのアサーションのみに依存しません。

1. **新規フォークでクリーンアップが実行される。**
   `[YOUR PROJECT NAME]` を含む CLAUDE.md (has_placeholder=1) が与えられた場合、`init.sh` を (非 dry-run で) 実行すると:
   a. `## Roadmap` セクションの結果として得られる CLAUDE.md から 21 件のデータ行 (`| 01 |` から `| 21 |`) がすべて除去されている。
   b. `**Spec reservation rule:**` 段落 (`**Spec reservation rule:**` で始まりテーブルヘッダー前の空行の前で終わるブロック) が除去されている。
   c. `## Roadmap` セクション見出しが残っている。
   d. イントロ文 ("Single entry point mapping…" で始まる) が残っている。
   e. テーブルヘッダー行 (`| # | Milestone | Status | Design source |`) とセパレータ行 (`|---|-----------|--------|---------------|`) が残っている。
   f. テーブルにプレースホルダーデータ行がちょうど 1 件存在する:
      `| — | [Add your first milestone here] | ☐ todo | (none yet) |`
   g. `**Rules:**` ブロック (テーブルに続く複数箇条書きリスト) が変更なしで残っている。

2. **削除後の CLAUDE.md が #05 グリフ整形式チェックを通過する。**
   基準 1f で挿入されたプレースホルダー行において `☐ todo` グリフが 4 グリフ契約 (☐/◐/☑/✗) を満たし、ドリフト検出器 (`check-roadmap-drift.sh`) がその行に対して FAIL を出力しない。

3. **削除後の CLAUDE.md が #04 ダングリング参照チェックを通過する。**
   基準 1f で挿入されたプレースホルダー行において `(none yet)` デザインソースセルに `spec:` または `adr:` リンクトークンが含まれないため、ダングリング参照検出器 (`check-dangling-refs.sh`) がその行に起因する FAIL を出力しない。

4. **プレースホルダーがすでに消えている場合はクリーンアップをスキップする (べき等性 / 再実行安全性)。**
   `[YOUR PROJECT NAME]` がすでに置換された CLAUDE.md (has_placeholder=0) が与えられた場合、`init.sh` を再実行すると:
   a. `## Roadmap` セクションがバイト単位で変化しない。
   b. `ok "… already customized — skipping"` にマッチする行 (または同等のスキップシグナル) が表示され、既存の About This Project スキップパスと一貫している。

5. **`--dry-run` の一貫性。**
   新規フォークの CLAUDE.md (has_placeholder=1) が与えられた場合、`init.sh --dry-run` を実行すると:
   a. `.claude/CLAUDE.md` のバイトが変化しない。
   b. Roadmap セクションがクリーンアップされることを説明する `[dry-run]` メッセージが表示され、About クリーンアップで使用される `[dry-run] would replace the placeholder block…` スタイルと対応している。

6. **テンプレートリポジトリの保護。**
   HEAD の実際のテンプレートリポジトリ (`## About This Project` に `[YOUR PROJECT NAME]` というリテラルプレースホルダーテキストがある) が与えられた場合、Roadmap クリーンアップパスが入力される (has_placeholder=1)。したがって、`init.sh` をテンプレート自体に対して実行すると、テンプレートリポジトリの Roadmap 行 (21 件すべて) が削除される。これは正しく意図された動作である: テンプレートリポジトリは開発中に "dogfood" チェックとして `init.sh` を一度だけ実行することが想定されており、本番環境での実行は想定していない。`has_placeholder` ゲートが判別子として文書化されている — init が完了した (プレースホルダーが置換された) リポジトリはいずれも Roadmap をそのまま保持する。

   **AC-6 の実装上の注意:** 上記の説明は意図的な設計であり欠陥ではない。テンプレートリポジトリ自身の CI は `init.sh` を自体に対して実行しない。日常の開発においてテンプレート自身の Roadmap を保護するのは、`init.sh` がテンプレートリポジトリの CI パイプラインで呼び出されることなく、フォーク後に人間が一度だけ実行することを意図しているという事実による。

7. **成功時の `ok` メッセージ。**
   クリーンアップが実行されて変更を書き込む場合、`ok "Updated .claude/CLAUDE.md (Roadmap section cleaned)"` にマッチする行 (または同等の `[OK]` プレフィックス付きメッセージ) が stdout に出力される。

8. **awk 実装制約。**
   Roadmap クリーンアップは、About This Project ブロックの置換と一貫した方法で、`awk` (または同等の単一 sed/awk パス) によるCLAUDE.md のミューテーションとして実装しなければならない — ファイルを読み書きするバッシュのライン単位ループは使用しない。これにより操作がアトミック (テンポラリファイル + mv) であり、部分書き込みに対して安全であることが保証される。

## Key interactions

### センチネルの決定: `has_placeholder` ゲート (Roadmap 専用センチネルなし)

Roadmap クリーンアップは既存の `has_placeholder` フラグ (`[YOUR PROJECT NAME]` が CLAUDE.md に存在すること) でゲートされています。根拠:

- 新規フォークは `## About This Project` にプレースホルダーを持ち、かつ `## Roadmap` に 21 件の dogfooding 行を持ちます。どちらも未初期化状態を示します。
- `init.sh` を完了したフォークはプレースホルダーを持たず、かつ既にクリーンアップされた Roadmap を持ちます。どちらも初期化後の状態です。
- `init.sh` が唯一のミューテーションパスであると仮定した場合、プレースホルダーは消えているが Roadmap にまだ 21 件のテンプレート行がある (またはその逆) という有効な中間状態は存在しません。
- Roadmap 専用の別センチネル (例: Roadmap セクション内のコメントマーカー) を追加しても安全マージンが増えるわけではなく、複雑さが増すだけです。

Roadmap クリーンアップは既存の About This Project 置換とともに `if [[ $has_placeholder -eq 1 ]]; then` ブロック内の第 2 ミューテーションとして追加されます。

### CI 検出器との互換性

`check-roadmap-drift.sh` (#05) パーサーは `## Roadmap` を見出しとしてキーにし、パイプ区切りデータ行 (`| <digits> |` にマッチするセル) をスキャンします。プレースホルダー行 `| — | [Add your first milestone here] | ☐ todo | (none yet) |` は `#` セルにエムダッシュを使用しており、`[0-9]+` にマッチしないため、ドリフト検出器の行パーサーからは見えません。`☐ todo` グリフは人間が読むために存在しますが、行は双方向リンク一貫性のスキャン対象ではありません。これは正しい動作です: 検証する `spec:` または `adr:` クレームが存在しないためです。

`check-dangling-refs.sh` (#04) チェック 2 は CLAUDE.md を `specs/` および `.claude/` をルートとするパス文字列でスキャンします。プレースホルダー行には `(none yet)` が含まれておりパストークンがないため、ダングリング参照は発生しません。

セクションに残される `**Rules:**` ブロックには `specs/NN-slug.md` と `specs/NN-progress.md` がメタ構文プレースホルダーとして含まれていますが、これらは check-dangling-refs.sh の `specs/NN-*` スキップパターンにマッチし、テンプレートリポジトリで既に正しく処理されています。

### init.sh 内での処理順序

Roadmap クリーンアップは About This Project の置換 (現在のスクリプトのステップ 2) の後、`.env` のコピー (ステップ 3) の前に実行されます。どちらのミューテーションも同じファイル (CLAUDE.md) を対象としており、別々の awk パスで順番に実行する (About を先に、次に Roadmap) のが最も安全なアプローチです。ロジックが読みやすく保たれるのであれば、単一の結合 awk パスを使用することもできます — 実装者が決定します。

### `--dry-run` の動作

`--dry-run=1` の場合、Roadmap クリーンアップを説明する `[dry-run]` メッセージ (例: `[dry-run] would clean up the ## Roadmap section (remove 21 template rows and Spec reservation rule paragraph)`) を表示します。CLAUDE.md は変更しません。これは既存の About の dry-run メッセージパターンとまったく同じスタイルです。

## Metrics

- **Leading:** 新規フォークの CLAUDE.md に対して `init.sh --dry-run` を実行した際の出力に Roadmap クリーンアップの説明行が含まれる。
- **Lagging:** フォークユーザーから初期化後に Roadmap に ecc-base-template の 21 件の dogfooding 行が残っていると報告する GitHub Issue や PR コメントがゼロ件。

## Risks and open questions

- **リスク: awk セクション境界。** awk パスは `## Roadmap` セクションの開始と終了を正確に識別しなければなりません。終了は次の `## ` 見出しとして定義されます。これは About This Project ブロックで使用されているものと同じ境界検出パターンです — 実装はその実績あるアプローチを再利用できます。
- **リスク: Roadmap セクションの順序変更。** 将来の CLAUDE.md 編集で `## Roadmap` がテーブルを含む別の `## ` セクションの後に移動した場合でも、awk パーサー (`^## Roadmap$` 見出しにキー) は影響を受けません — 見出しのマッチが明示的であるためです。
- **未解決の質問: 結合 vs. 逐次 awk パス。** 実装者は効率のために About と Roadmap のミューテーションを単一の awk パスに統合することも、明確さのために逐次パスとして維持することも選択できます。どちらも受け入れ可能です; Spec はこれを規定しません。
- **未解決の質問: プレースホルダー行の正確な文言。** AC はこれを指定しています: `| — | [Add your first milestone here] | ☐ todo | (none yet) |`。実装者は `☐ todo` グリフが存在し、デザインソースセルに `spec:` または `adr:` トークンが含まれない限り、文言を若干調整することができます (例: エムダッシュ `—` vs. リテラルダッシュ `-`)。

## Out of scope

- フォーク内の `specs/` ディレクトリのクリーンアップ (ファイルは残る; CLAUDE.md のみを編集)。
- `.claude/meta/adr/` ディレクトリのクリーンアップ (履歴 ADR ファイルは残る)。
- About This Project と Roadmap 以外の CLAUDE.md のセクションの自動化。
- `init.sh` が正常に実行されたことを確認する新しい CI ワークフローの追加。
- `init.sh` 実行前にフォークが `.claude/CLAUDE.md` を完全に削除した場合の処理 (CLAUDE.md が存在しない場合に終了する既存の事前チェックですでに処理済み)。

## References

- Roadmap 行: #15
- `init.sh` フォーク後初期化スクリプト: `.claude/meta/scripts/init.sh`
- Roadmap ドリフト検出器: `.claude/meta/scripts/check-roadmap-drift.sh`
- ダングリング参照検出器: `.claude/meta/scripts/check-dangling-refs.sh`
- ADR-014 (Roadmap インデックス、単一エントリポイント): `.claude/meta/adr/014-roadmap-index-single-entry-point.md`
- ADR-015 (ダングリング参照検出器): `.claude/meta/adr/015-dangling-reference-detector.md`
- ADR-017 (Roadmap ドリフト検出器): `.claude/meta/adr/017-roadmap-drift-detector.md`
