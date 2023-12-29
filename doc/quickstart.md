# クイックスタート

本リポジトリでは，Windows・Linux上の PC（ローカルのVSCode IDE） からAWS EC2 へリモート接続し，VSCode Dev Containers を利用して深層学習やLLM ソフトウェア開発を効率よく行えるようにするための手順を示す．
なお，本リポジトリはチーム開発時に，所属チームへクラウドネイティブで効率的な開発手法を導入することを目的としており，python コーディングにおける linter, formatter や vscode setting json, VSCode extension なども共通のものを利用するようにしている．

## 前提

Windows，Linux上には VScode は install されているものとする．加え，AWSユーザーは作成済みであり，Administrator相当の権限を保持していることを想定している．なお，手順書中では，Windowsでのセットアップ手順に主眼を起き記述している．（Linuxでも同様の手順で実行可能．）

## 手順

1. AWS CLI のインストールとセットアップ
2. SSM Session Manager plugin のインストール
3. ローカルの VSCode に extension をインストール
4. CloudFormation で，EC2 を構築
5. 秘密鍵をダウンロードし，`.ssh/config`を設定
6. VSCode から Remote SSH 接続し，EC2 インスタンスにログイン
7. EC2 インスタンスに extension をインストール後，Dev Containers の構築

## 手順の各ステップの詳細

### 1. AWS CLI のインストールとセットアップ

公式ドキュメント[^1] [^2]を参考に，AWS CLI をインストール，セットアップする．

- [Windows 用の AWS CLI MSI インストーラ (64 ビット)](https://awscli.amazonaws.com/AWSCLIV2.msi) をダウンロードして実行する
- インストール後，`aws --version`でバージョンが表示されれば OK
- `aws configure`を実行し，AWS CLI の設定を行う
```
AWS Access Key ID [None]: IAM ユーザーの作成時にダウンロードした csv ファイルに記載
AWS Secret Access Key [None]: IAM ユーザーの作成時にダウンロードした csv ファイルに記載
Default region name [None]: ap-northeast-1
Default output format [None]: json
```
- Zscalerなどの社内プロキシを利用している場合は，`.aws/config`に以下を追記する．例えば，Zscalerを利用している場合は，以下のようにCA 証明書のフルパスを記述する．CA 証明書のエクスポート方法は後述するので，必要があれば適宜参考にされたい．．

```
ca_bundle = C:\path\to\zscalar_root_cacert.cer
```

<details>
<summary>※Zscaler CA 証明書のエクスポート方法</summary>
<br/>

公式ドキュメント[^3]を参考に，エクスポートする．

- コンピュータ証明書の管理 > 信頼されたルート証明機関 > 証明書
- Zscalar Root CA を左クリック > すべてのタスク > エクスポート
  - 証明書のエクスポートウィザードで、次へ > Base 64 encoded X.509 を選択して次へ
  - 参照 > ディレクトリ・ファイル名を入力（ここではファイル名を`zscalar_root_cacert.cer`とする）> 次へ > 完了 > OK

</details>
<br/>

### 2. SSM Session Manager plugin のインストール

公式ドキュメント[^4]を参考に，SSM Session Manager plugin をインストールする．
- [Session Manager プラグインのインストーラ](https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe)をダウンロードし実行する

### 3. ローカルの VSCode に extension をインストール

`./setup/vscode/vscode_local_setup_win.bat`を実行し，VSCodeのextensionを一括インストールする．Linux の場合は，`./setup/vscode/vscode_local_setup_linux.sh`を実行する．本バッチファイル，またはshellの実行により，以下のextensionがインストールされる．

- vscode-remote-extensionpack: VSCodeでリモート開発を行うためのextension
- aws-toolkit-vscode: AWSの各種サービスをVSCodeから操作するためのextension
- ec2-farm: AWSアカウント内のEC2インスタンスの状態を確認し，起動・停止・再起動を行うためのextension

### 4. CloudFormation で EC2 を構築

`./setup/cf-template/cf-ec2.yaml`（cfテンプレート）を利用し，CloudFormation で EC2 を構築する．以下にcfテンプレートの簡易説明を行う．CloudFormation の詳細な実行方法は後述しているので，必要があれば適宜参考にされたい．

- VPC とサブネットの ID をユーザー側で記述する必要がある
  - default vpc のパブリックサブネット等を選択すれば良い
- EC2へのリモートアクセス・開発に必要と想定されるポリシーをアタッチしたロールは自動作成される．以下のポリシーをアタッチしている．
  - AmazonSSMManagedInstanceCore
  - AmazonS3FullAccess
  - AWSCodeCommitFullAccess
  - EC2InstanceProfileForImageBuilderECRContainerBuilds
  - AmazonSageMakerFullAccess
  - SecretsManagerReadWrite
  - AWSLambda_FullAccess
- セキュリティグループも自動作成しており，インバウンドは全てシャットアウトしている
- ssh 接続で利用する Key Pair を作成している
- EC2インスタンス作成時，以下を自動実行している
  - gitのアップグレード
  - aws cli のアップグレード
  - condaの初期設定
  - 再起動
- CloudFormationの出力部には，インスタンス ID と Key ID を出力している
  - 後述の shell で利用する

<details>
<summary>※CloudFormation 実行手順</summary>
<br/>

- [CloudFormationコンソール](https://console.aws.amazon.com/cloudformation/)を開き，スタックの作成を押下
- テンプレートの指定 > テンプレートファイルのアップロード > ファイルの選択で上記で作成したyamlファイルを指定し，次へを押下
  - `./setup/cf-template/cf-ec2.yaml`をuploadする．
- 任意のスタック名を入力後，以下のパラメータを設定する
  - EC2InstanceType: インスタンスタイプ．デフォルトはg4dn.xlarge
  - VolumeSize: ボリュームサイズ．デフォルトは100GB
  - ImageId: AMIのID．デフォルトはDeep Learning AMI GPU PyTorch 2.0.1のID
  - VPCId: 利用するVPCのID（デフォルトVPCのID等で問題ない）
  - SubnetID: 利用するパブリックサブネットのID（デフォルトVPCのパブリックサブネットID等で問題ない）
  
- 適切なIAM Roleをアタッチし，次へを押下（一時的にAdmin roleで実施しても良いかもしれない）
- 作成されるまで30秒~1分ほど待つ

</details>
<br/>

### 5. 秘密鍵をダウンロードし，`.ssh/config`を設定

### 6. VSCode から EC2 インスタンスにログイン

check_vm_env.sh とかで確認可能．

### 7. EC2 インスタンスに extension をインストール後，Dev Containers の構築

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
  - 特定のインスタンスは除外可能にできるようにする（運用サーバー等）
  - lambda の構築方法は後述する # TODO

## その他

チーム開発において VSCode を利用するメリットは，linter や formatter をチームで共通化できる上，IDE の設定や利用する extension なども共通化することができることである．これにより，チームメンバ間での利用するツールやコーディング上の認識齟齬は低減され，利便性の高い extension によって，開発効率が向上すると考えられる．
以下に各項目について解説する．

### linter

### formatter

### setting json

### extension



## 参考
[^1]:[AWS CLI の最新バージョンを使用してインストールまたは更新を行う](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-install.html)
[^2]:[AWS CLI をセットアップする](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-quickstart.html)
[^3]:[CA証明書のエクスポート](https://help.zscaler.com/ja/deception/exporting-root-ca-certificate-active-directory-certificate-service)
[^4]:[Windows での Session Manager プラグインのインストール](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/install-plugin-windows.html)
