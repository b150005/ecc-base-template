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

## Developer Growth Mode

Developer Growth Mode はテンプレートの中核機能であるオプトイン方式の学習レイヤです。有効化すると、15 エージェントからなるチームが、実機能を実装しながらドメイン別に整理された知識ベースを拡充していきます。正式な仕様は、以下の 3 つのドキュメントに定めています。

| ドキュメント | 説明 |
|-------------|------|
| [PRD: Developer Growth Mode](prd/developer-growth-mode.md) | プロダクト要件、ユーザーセグメント、機能要件・非機能要件、受け入れ基準 |
| [ADR-001: Developer Growth Mode](adr/001-developer-growth-mode.md) | アーキテクチャ上の判断 — Skill によるトグル、拡充プロトコル、プライバシー方針、19 ドメインの分類体系 |
| [ドメインの分類体系](growth/domain-taxonomy.md) | 19 ドメインの正典リスト、エージェント別の担当対応表、エージェントが書くノートの実例 |
