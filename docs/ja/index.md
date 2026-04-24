> このドキュメントは `docs/en/index.md` の日本語訳です。英語版が原文 (Source of Truth) です。

# ドキュメント

## バイリンガル規約

このプロジェクトでは、ドキュメントを2つの言語で管理しています。

- **英語** (`docs/en/`) — 原文 (Source of Truth)。すべての変更はここから始まります。
- **日本語** (`docs/ja/`) — 日本語話者のための翻訳版です。

Claude Code はコンテキストウィンドウの使用量を最小限にするため、英語のドキュメントのみを読み込みます。人間のコントリビューターはどちらの言語でも参照できます。

## ドキュメント一覧

| ドキュメント | 説明 |
|-------------|------|
| [ECC 概要](ecc-overview.md) | Everything Claude Code とは何か、どのように機能するか |
| [TDD ワークフロー](tdd-workflow.md) | ECC エージェントによるテスト駆動開発の方法論 |
| [CI/CD パイプライン](ci-cd-pipeline.md) | GitHub Actions ワークフローと自動化 |
| [DevContainer](devcontainer.md) | 開発コンテナのセットアップとカスタマイズ |
| [GitHub の機能](github-features.md) | CODEOWNERS、Dependabot、テンプレート、Actions、ブランチ保護 |
| [テンプレート利用ガイド](template-usage.md) | このテンプレートからプロジェクトを作成する方法 |
| [ADR テンプレート](adr/000-template.md) | アーキテクチャ決定記録のフォーマット |

## Developer Learning Mode

Developer Learning Mode はテンプレートの中核機能であるオプトイン方式の学習レイヤです (v2.0.0 で "Developer Growth Mode" から改名されました。詳細は [ADR-003](adr/003-learning-mode-relocate-and-rename.md) を参照してください)。有効化すると、15 エージェントからなるチームが、実機能を実装しながらドメイン別に整理された知識ベースを拡充していきます。正式な仕様は、以下のドキュメントに定めています。

| ドキュメント | 説明 |
|-------------|------|
| [Learning Mode 解説](learning-mode-explained.md) | 学習者向け解説: モードを有効化するとどう変わるか、知識ベースがどう蓄積されるか、`learn/knowledge/` ファイルの読み方 |
| [PRD: Developer Learning Mode](prd/developer-learning-mode.md) | プロダクト要件、ユーザーセグメント、機能要件・非機能要件、受け入れ基準 |
| [ADR-001: Developer Growth Mode](adr/001-developer-growth-mode.md) | アーキテクチャ上の判断 — Skill によるトグル、拡充プロトコル、プライバシー方針、19 ドメインの分類体系 (ADR-003 により一部更新) |
| [ADR-002: Growth Domains の配置](adr/002-growth-domains-location.md) | ドメイン宣言をフロントマターではなくエージェントプロンプト本文に置く理由 (セクションマーカーは ADR-003 で `## Learning Domains` に改名) |
| [ADR-003: 再配置と改名](adr/003-learning-mode-relocate-and-rename.md) | v2.0.0 の破壊的変更: "Growth Mode" → "Learning Mode" への改名、`.claude/growth/` → `learn/` への移設、"notes" → "knowledge" への用語変更、lazy-materialize |
| [ADR-004: コーチングピラー](adr/004-coaching-pillar.md) | v2.1.0 コーチングピラー: 6 つのコーチスタイル（`default` と 5 つの能動モード — hints・socratic・pair・review-only・silent）を Output Styles 互換フォーマットで実装し、Learning Mode の設定状態から dispatch |
| [ドメインの分類体系](learn/domain-taxonomy.md) | 19 ドメインの正典リスト、エージェント別の担当対応表、エージェントが書く知識エントリの実例 |
| [v1 → v2 移行ガイド](migration/v1-to-v2.md) | v2.0.0 より前に Developer Growth Mode を有効化していた fork 向けのアップグレード手順 |
