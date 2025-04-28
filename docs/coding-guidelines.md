# コーディングガイドラインと開発環境の設定

VSCode を利用すれば，チーム内で Linter と Formatter の設定などを容易に統一することができる．特に，複数のエンジニアによるチーム開発において，リポジトリ内部でコーディングの一貫性を保つことは，可動性や品質の向上，チームメンバー間のコミュニケーション円滑化（認識・解釈齟齬の低下），引き継ぎ工数の削減の観点で重要である．

本リポジトリでは，上記を実現するために，Dev Containers 内で以下のツール・設定ファイルの共通利用を前提としている．なお，`./.devcontainer/devcontainer.json`ではデフォルトで以下を利用するための設定が記述されている．

- Python package manager
- Linter
- Formatter
- Type Hints
- pre-commit
- VSCode Extensions
- settings.json

## Python package manager

Python package manager は，Python ライブラリやパッケージのインストール，バージョン管理，依存関係の管理を行うためのツールである．本リポジトリでは，[uv](https://docs.astral.sh/uv/) を利用している．uv は，Rust で実装された Python のバージョンおよび Python パッケージを管理できるツールであり，pipenv や conda などの既存のツールと比べ，高速に実行できる．

## Linter

Linter は，ソースコードを分析し，構文エラーやコーディングスタイルの問題，バグの可能性がある箇所を特定するツールである．本リポジトリでは，Python の Linter として [Ruff](https://docs.astral.sh/ruff/) を利用している．Ruff は，Rust で実装された Linter 兼 Formatte であり，Flake8 などの既存の Linter と比べ高速に実行できる．

## Formatter

Formatter は，ソースコードのフォーマットを整理し，一貫したスタイルでコードを自動整形するツールである．本リポジトリでは，Python の Formatter として [Ruff](https://docs.astral.sh/ruff/) を利用している．

## Type Hints

Type Hints は，特に静的型付け言語において，変数や関数の戻り値の型を指定するための構文である．本リポジトリでは，Python の Type Hints のチェックツールとして [mypy](https://mypy.readthedocs.io/en/stable/) を利用している．mypy は型アノテーションに基づきコードのバグを検知するツールである．

## pre-commit

pre-commit は，Git のコミット前に自動的にコードのフォーマットや Lint チェックを実行するためのツールである．本リポジトリでは，以下の .pre-commit-config.yaml を利用し，以下の内容を実行している．

- uv lock ファイルが更新されているか
- Ruff による Lint，Format チェック
- mypy による Type チェック

```yaml
repos:
  - repo: https://github.com/astral-sh/uv-pre-commit
    rev: 0.6.17
    hooks:
      - id: uv-lock
        description: "Ensures that the uv.lock file is up-to-date"

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.11.7
    hooks:
      - id: ruff
        description: "Runs Ruff for Python code linting and static analysis"
        types_or: [python, pyi, jupyter]
        args: [--fix, --exit-non-zero-on-fix, --config=pyproject.toml]
      - id: ruff-format
        description: "Formats Python code using Ruff formatter"
        types_or: [python, pyi, jupyter]
        args: [--config=pyproject.toml]

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.15.0
    hooks:
      - id: mypy
        description: "Performs type checking using mypy"
        types_or: [python, pyi, jupyter]
        args: [--config-file=pyproject.toml]
```

## VSCode extensions

VSCode Extensions は，VSCode の機能を拡張するプラグインで，各種プログラミング言語のサポート，コードのデバッグ，リファクタリング，テキスト編集の強化，外部ツールの統合が可能である．本リポジトリでは，以下の VSCode Extensions を利用している．

### python

- ms-python.python
- ms-python.vscode-pylance
- charliermarsh.ruff
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
- amazonwebservices.amazon-q-vscode
- saoudrizwan.claude-dev

## setting.json

settings.json は，VSCode の設定ファイルで，エディタの挙動や見た目，拡張機能の設定などをカスタマイズできる．本リポジトリでは，以下の設定を利用し，Python コードの保存時に自動で Ruff や mypy を実行している．（`./.devcontainer/devcontainer.json`に記載がある．）

```json
{
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "/bin/bash"
    }
  },
  // notebook
  "notebook.formatOnSave.enabled": true,
  "notebook.codeActionsOnSave": {
    "notebook.source.fixAll": "explicit",
    "notebook.source.organizeImports": "explicit"
  },
  // python
  "[python]": {
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "charliermarsh.ruff",
    "editor.codeActionsOnSave": {
      "source.fixAll": "explicit", // fix lint violations on-save
      "source.organizeImports": "explicit" // organize imports on-save
    }
  },
  "mypy-type-checker.args": ["--config=${workspaceFolder}/pyproject.toml"],
  "python.defaultInterpreterPath": "./.venv/bin/python",
  "python.analysis.typeCheckingMode": "basic",
  "python.analysis.inlayHints.functionReturnTypes": true,
  "python.analysis.inlayHints.variableTypes": true,
  "python.analysis.completeFunctionParens": true,
  // visibility
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": "active",
  // markdown
  "[markdown]": {
    "editor.wordWrap": "bounded",
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  }
}
```

## 参考

[mlops-starter-sklearn/docs/coding-guidelines.md](https://github.com/Azure/mlops-starter-sklearn/blob/main/docs/coding-guidelines.md)

[Python Coding Best Practices for Researchers](https://cyberagentailab.github.io/BestPracticesForPythonCoding/)
