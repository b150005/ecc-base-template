# マイルストーン進捗レコードテンプレート

## このテンプレートの使い方

1. このファイルは、**1 つの `◐ in-progress` Roadmap マイルストーンの
   進行中の状態** を記録するものです。再開するセッションやエージェントが
   1 回の決定論的な読み込みで回復できるよう設計されています。
   このファイルは **セッションまたはコンパクション境界がマイルストーンの
   `◐` 期間中に発生した場合にのみ作成/更新されます** ── `☐ → ◐` の
   遷移時や、オペレーターのコマンドによって作成されることはありません。
   1 回の中断なしのセッションで `☐ → ☑` まで完了するマイルストーンは
   このファイルを作成しません (不要なときはゼロの手間)。
2. このファイルを `specs/NN-progress.md` にコピーしてください。`NN` は
   **安定した再利用されない Roadmap 行番号** です (ADR-014 の
   予約ルールが `specs/NN-slug.md` に使うものと同じキー)。
   マイルストーン #03 のレコードは `specs/03-progress.md` です。
   パスは行番号の純粋関数であるため、再開者は Roadmap 行を読んだ後
   `specs/NN-progress.md` を直接開けます ── `ls`、`git log`、
   スキャンは不要です。
3. YAML フロントマターと 3 つの本文セクションを記入してください。
   **以下に示す形式のフロントマターブロックをそのまま使用してください ──
   ファイルを `---` のみの行で始め、キーを貼り付け、`---` のみの行で
   終わらせてください。コードフェンスで囲まないでください。** 以下の
   例はあくまで表示のためにコードフェンス内に示しています。実際の
   ファイルには素の YAML を含めてください。
4. 実際の `specs/NN-progress.md` をコミットする前に、この
   「このテンプレートの使い方」ブロックを削除してください。
5. このレコードは **git-tracked** であり、.gitignore されません ──
   マイルストーン単位の状態はプロジェクト知識であり、同じフォークの
   複数のオペレーター間で共有でき、誤って削除された場合は git 履歴
   から復元可能です。
6. マイルストーンが `◐ → ☑` (または `◐ → ✗`) に遷移するとき、
   Roadmap グリフをフリップするエージェントは **完了を記録する変更と
   同じ変更の中で `specs/NN-progress.md` を削除します**。`☑`/`✗` の
   行に進捗レコードが残っている場合は検出可能な陳腐化状態です
   (グリフミラーのバックストップ)。

このレコードは規約により **英語のみ** です (upstream ワークアラウンド
レジストリと同じ対象読者 ── 進行中の作業を再開するエンジニアと
エージェント。更新頻度の高い一時的な状態に翻訳のドリフトは発生させません)。

グローバルな `/save-session` ↔ `/resume-session` コマンド
(ユーザーホーム `~/.claude/session-data/`、プロジェクト非依存、
セッション単位) を置き換えるものではなく、それらと **組み合わせて使います**。
スコープの分担: `/save-session` は「このセッションで何をしていたか」に答え、
このレコードは「マイルストーン #NN の進行中の状態は何か」に答えます。
それぞれを独立して使用できます。

---

### フロントマター (ファイルの先頭にそのまま貼り付ける)

```yaml
---
roadmap_row: 3                       # integer; the stable Roadmap row number
milestone: "Cross-session milestone progress persistence"   # the row's one-liner
status_glyph: "◐"                    # MUST mirror the Roadmap glyph; a mismatch ⇒ this record is stale
workflow_step: 4                     # integer 1–9 per ## Development Workflow; the current step
last_updated: 2026-05-16             # YYYY-MM-DD; date this record was last written
head_sha: 6caa258                    # git HEAD short SHA at write time (staleness pin)
spec_exists: true                    # true once specs/NN-slug.md exists on disk (US-001 (c))
adr_links: []   # [] if no ADR yet, else the ADR path(s)
---
```

フィールドの説明:

- `workflow_step` は `## Development Workflow` ステップの整数です
  (1 イシュー分析、2 製品企画、3 リサーチ & 再利用、
  4 アーキテクチャ、5 実装、6 品質ゲート、7 ドキュメント、
  8 リリース、9 コミット)。再開者は既知の 9 ステップパイプラインに
  直接マッピングでき、再トレースは不要です。
- `status_glyph` は Roadmap 行のグリフと一致しなければなりません。
  Roadmap グリフが権威的です (ADR-014)。このレコードはそれを上書き
  しません。一致しない場合、レコードは定義上陳腐化しています。
- `head_sha` は陳腐化ピンです。再開者はそれを現在の `HEAD` と比較します:
  一致 ⇒ 最高鮮度。乖離 ⇒ このレコードを *進捗の下限* として読み、
  `git log <head_sha>..HEAD` で有界なデルタを照合します ──
  全履歴の再導出ではありません。
- `last_updated` は人間向けの粗い鮮度シグナルであり、
  SHA ピンの副次的指標です。
- `started` フィールドは意図的に **存在しません** ── `◐` グリフと
  Roadmap がすでに「作業が開始された」を示しており、ここで重複させると
  インデックスコンテンツになるためです。

## Done

完了した `## Development Workflow` ステップを 1 つずつ箇条書きにして、
生成した成果物の名前を記載してください。スキャンしやすいように簡潔に ──
これはハンドルであり、散文ではありません。

- Step 2 (Product Planning) — `specs/NN-slug.md` authored
- Step 4 (Architecture) — ADR-0NN written and Accepted

## Next concrete action

再開者が取る次の単一のアクションを 1 文で記述してください。
計画ではなく ── *次の* ステップのみです (パイプラインが残りを担います)。

[例: 「Step 5: implement the detector per ADR-0NN Decision, TDD.」]

## Notes / why work stopped

自由記述。なぜ境界に達したか、Done/Next セクションが伝えない情報で
再開者が必要とするものを記載してください。

[例: 「Compaction boundary at step 4; ADR Accepted, implementation deferred.」]
