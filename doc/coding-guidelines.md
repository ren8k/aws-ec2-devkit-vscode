# コーディングガイドラインと開発環境の設定

VSCode を利用すれば、チーム内でリンターとフォーマッターの設定などを容易に統一することができる。特に、複数のエンジニアによるチーム開発において、リポジトリ内部でコーディングの一貫性を保つことは、可動性や品質の向上，チームメンバー間のコミュニケーション円滑化（認識・解釈齟齬の低下），引き継ぎ工数の削減の観点で重要である。

本リポジトリでは，上記を実現するために，Dev Containers内で以下のツール・設定ファイルの共通利用を前提としている．

- Linter: Flake8
- Formatter: Black
- Type Hints: Mypy
- VSCode extensions
- VSCode setting.json

## Linter

## Formatter

## Type Hints

## VSCode extensions

## setting.json


https://github.com/Azure/mlops-starter-sklearn/blob/main/docs/coding-guidelines.md#formatter



コード品質を改善するために本リポジトリで利用するツールの概要や機械学習システムへの導入方法を記載します。

概念
複数のエンジニアによるチーム開発において、プロジェクトまたはリポジトリ全体で一貫性を保つことは解釈の違いを減らすことや可読性の向上、引継ぎの工数を減らす観点で重要です。 これらを実現するために、Linter やテキスト解析・整形ツールを使用する方法があります。

本リポジトリでは、次のツールの活用を推奨します。
