# コーディングガイドラインと開発環境の設定

VSCode を利用すれば，チーム内でリンターとフォーマッターの設定などを容易に統一することができる．特に，複数のエンジニアによるチーム開発において，リポジトリ内部でコーディングの一貫性を保つことは，可動性や品質の向上，チームメンバー間のコミュニケーション円滑化（認識・解釈齟齬の低下），引き継ぎ工数の削減の観点で重要である．

本リポジトリでは，上記を実現するために，Dev Containers 内で以下のツール・設定ファイルの共通利用を前提としている．なお，`./.devcontainer/devcontainer.json`ではデフォルトで以下を利用するための設定が記述されている．

- Linter
- Formatter
- Type Hints
- VSCode Extensions
- settings.json

## Linter

Linter は，ソースコードを分析し，構文エラーやコーディングスタイルの問題，バグの可能性がある箇所を特定するツールである．本リポジトリでは，Python の Linter として Flake8 を利用している．[Flake8](https://flake8.pycqa.org/en/latest/#) は，Python コードの静的解析ツールである．次の３つのツールのラッパーであり，単一のスクリプトを起動することですべてのツールを実行する．

- PyFlakes: コードに論理的なエラーが無いかを確認
- pep8: コードがコーディング規約([PEP8](https://pep8.readthedocs.io/en/latest/))に準じているかを確認
- Ned Batchelder’s McCabe script: 循環的複雑度の確認

## Formatter

Formatter は，ソースコードのフォーマットを整理し，一貫したスタイルでコードを自動整形するツールである．本リポジトリでは，Python の Formatter として Black を利用している．[Black](https://black.readthedocs.io/en/stable/index.html) は一貫性，一般性，可読性及び git 差分の削減を追求した Formatter ツールである．

## Type Hints

Type Hints は，特に静的型付け言語において，変数や関数の戻り値の型を指定するための構文である．本リポジトリでは，Python の Type Hints のチェックツールとして mypy を利用している．[mypy](https://mypy.readthedocs.io/en/stable/) は型アノテーションに基づきコードのバグを検知するツールである．

## VSCode extensions

VSCode Extensions は，VSCode の機能を拡張するプラグインで，各種プログラミング言語のサポート，コードのデバッグ，リファクタリング，テキスト編集の強化，外部ツールの統合が可能である．本リポジトリでは，以下の VSCode Extensions を利用している．

### python

- ms-python.python
- ms-python.vscode-pylance
- ms-python.black-formatter
- ms-python.flake8
- ms-python.isort
- ms-python.mypy-type-checker
- donjayamanne.python-extension-pack

### jupyter

- ms-toolsai.jupyter
- ms-toolsai.jupyter-keymap
- ms-toolsai.jupyter-renderers

### git

- mhutchie.git-graph
- eamodio.gitlens
- donjayamanne.git-extension-pack

### markdown

- yzhang.markdown-all-in-one
- shd101wyy.markdown-preview-enhanced

### shell

- mads-hartmann.bash-ide-vscode
- timonwong.shellcheck
- foxundermoon.shell-format

### visibility

- mechatroner.rainbow-csv
- GrapeCity.gc-excelviewer
- janisdd.vscode-edit-csv
- monokai.theme-monokai-pro-vscode
- vscode-icons-team.vscode-icons
- MS-CEINTL.vscode-language-pack-ja

### others

- github.copilot
- github.copilot-chat
- aws-toolkit-vscode

## setting.json

settings.json は，VSCode の設定ファイルで，エディタの挙動や見た目，拡張機能の設定などをカスタマイズできる．本リポジトリでは，以下の設定を利用している．（`./.devcontainer/devcontainer.json`に記載がある．）

```json
{
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "/bin/bash"
    }
  },
  // python
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.organizeImports": "explicit"
    }
  },
  "python.defaultInterpreterPath": "/opt/conda/bin/python",
  "isort.args": ["--profile", "black"],
  "flake8.args": ["--max-line-length=88", "--ignore=E203,W503,W504"],
  "mypy-type-checker.args": [
    "--ignore-missing-imports",
    "--disallow-untyped-defs"
  ],
  "python.analysis.inlayHints.functionReturnTypes": true,
  "python.analysis.inlayHints.variableTypes": true,
  // visibility
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": "active",
  "[markdown]": {
    "editor.wordWrap": "bounded"
  }
}
```

## 参考

[mlops-starter-sklearn/docs/coding-guidelines.md](https://github.com/Azure/mlops-starter-sklearn/blob/main/docs/coding-guidelines.md)
