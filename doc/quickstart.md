# クイックスタート

本リポジトリでは，Windows 上の PC から，AWS EC2 へリモート接続し，Dev Containers を利用して深層学習，LLM ソフトウェア開発を効率よく行えるようにするための手順を示す．
なお，所属するチームにクラウドネイティブな開発手法を導入することを目的としており，python コーディングにおける linter, formatter や setting json, VSCode extension なども共通のものを利用するようにしている．

## 前提

Windows 上には VScode は install されているものとする．

## 手順

1. AWS CLI のインストールと設定
2. SSM Session Manager plugin のインストール
3. ローカルの VSCode に extension をインストール
4. cloudformation で，EC2 を構築
5. `./setup/get_aws_keypair/get_key_linux.sh`を実行し，秘密鍵をダウンロード（4 の出力を利用）
6. `/.ssh/config_linux`を自身の`.ssh/config`にコピーし，インスタンス ID や秘密鍵のパスを設定（4 の出力を利用）
7. VSCode から Remote SSH 接続し，EC2 インスタンスにログイン
8. EC2 インスタンスに extension をインストール後，Dev Containers の構築

## 手順の各ステップの詳細

### 1. AWS CLI のインストールと設定

### 2. SSM Session Manager plugin のインストール

### 3. ローカルの VSCode に extension をインストール

### 4. Cloudformation で，EC2 を構築

- VPC とサブネットの ID をユーザー側で記述する必要あり
  - default vpc のパブリックサブネット等を選択すれば良い
- 必要なロールとかは実行のたびに作成される
- SG ではインバウンドは全てシャットアウト

### 5. 秘密鍵をダウンロード

### 6. `.ssh/config`の設定

### 7. VSCode から EC2 インスタンスにログイン

### 8. EC2 インスタンスに extension をインストール後，Dev Containers の構築

1. AWS CLI のインストールと設定
2. SSM Session Manager plugin のインストール
3. `./setup/vscode/vscode_settings.json`を実行し，VSCode に extension をインストール
4. `./setup/cf-template/cf-ec2.yaml`を利用し，cloudformation で，EC2 を構築
5. `./setup/get_aws_keypair/get_key_linux.sh`を実行し，秘密鍵をダウンロード（4 の出力を利用）
6. `/.ssh/config_linux`を自身の`.ssh/config`にコピーし，インスタンス ID や秘密鍵のパスを設定（4 の出力を利用）
7. VSCode から Remote SSH 接続し，EC2 インスタンスにログイン
8. EC2 インスタンスに extension をインストール後，Dev Containers の構築

## 運用

- 開発開始時には，VSCode の extension `AWS Remote Development`経由で各々の EC2 インスタンスを起動し，VSCode からログインする
- 切り忘れ防止のために，夜 12 時には lambda で全 EC2 インスタンスを停止させるようにする
  - lambda の構築方法は後述する # TODO

## その他

チーム開発において VSCode を利用するメリットは，linter や formatter をチームで共通化できる上，IDE の設定や利用する extension なども共通化することができることである．これにより，チームメンバ間での利用するツールやコーディング上の認識齟齬は低減され，利便性の高い extension によって，開発効率が向上すると考えられる．
以下に各項目について解説する．

### linter

### formatter

### setting json

### extension
