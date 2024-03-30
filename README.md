# VSCode Dev Containers を利用した AWS EC2 上での開発環境構築手順<!-- omit in toc -->

本リポジトリでは，Windows・Linux PC 上の Visual Studio Code IDE (VSCode) から AWS EC2 へリモート接続し，VSCode Dev Containers を利用して深層学習や LLM ソフトウェア開発を効率良く行えるようにするための手順を示す．
なお，本リポジトリはチーム開発時に，所属チームへクラウドネイティブで効率的な開発手法を導入することを目的としており，python コーディングにおける linter, formatter や VSCode extension，setting.json なども共通のものを利用するようにしている．

## TL;DR <!-- omit in toc -->

以下の Tips を整理し，手順書としてまとめた．また，最小限の手順で済むよう，bat ファイルや shell スクリプトを用意している．

- SSM 経由で VSCode から EC2 にセキュアに SSH 接続する方法
- チーム開発時の IDE として VSCode を利用し，Flake8，Black，Mypy を共通的に利用する方法
- AWS Deep Learning Containers Images をベースに Dev Containers 上で開発するための方法

## 目次<!-- omit in toc -->

- [背景と課題](#背景と課題)
- [目的](#目的)
- [解決方法](#解決方法)
- [オリジナリティ](#オリジナリティ)
- [前提](#前提)
- [手順](#手順)
- [手順の各ステップの詳細](#手順の各ステップの詳細)
  - [1. AWS CLI のインストールとセットアップ](#1-aws-cli-のインストールとセットアップ)
  - [2. SSM Session Manager plugin のインストール](#2-ssm-session-manager-plugin-のインストール)
  - [3. ローカルの VSCode に extension をインストール](#3-ローカルの-vscode-に-extension-をインストール)
  - [4. CloudFormation で EC2 を構築](#4-cloudformation-で-ec2-を構築)
    - [構築するリソース](#構築するリソース)
    - [EC2 の環境について](#ec2-の環境について)
    - [cf テンプレートの簡易説明](#cf-テンプレートの簡易説明)
  - [5. SSH の設定](#5-ssh-の設定)
  - [6. VSCode から EC2 インスタンスにログイン](#6-vscode-から-ec2-インスタンスにログイン)
  - [7. EC2 インスタンスに VSCode extension をインストール](#7-ec2-インスタンスに-vscode-extension-をインストール)
  - [8. Dev Containers と AWS Deep Learning Containers Images を利用したコンテナの構築](#8-dev-containers-と-aws-deep-learning-containers-images-を利用したコンテナの構築)
- [その他](#その他)
  - [インスタンスの起動・停止](#インスタンスの起動停止)
  - [コーディングガイドラインと開発環境の設定](#コーディングガイドラインと開発環境の設定)
  - [チームでの EC2 の運用・管理](#チームでの-ec2-の運用管理)
  - [その他 Tips](#その他-tips)
- [参考](#参考)

## 背景と課題

AWS 上で開発する際，社内プロキシ等が原因で VSCode から容易に Remote SSH できず，開発 IDE として VSCode を利用できない事例を多数見てきた．これにより，チーム開発時に，各メンバが異なる IDE（異なる Linter, Formatter）を利用する結果，チームとしての開発効率が低下してしまう．

一方，AWS Cloud9 のようなクラウドネイティブ IDE を利用してチーム開発を行うことで，開発 IDE を統一することは可能である．しかし，Cloud9 ベースの開発の場合，Linter の設定を自由に行えないため，コード内のバグ原因などの見落としが発生し，結果的に開発効率が悪くなる．加えて，Git コマンド，Docker コマンド，Linux 基盤の深い知見を求められるため，新規参画者には敷居が高く，即時参画には時間を要してしまう問題がある．(cloud9 ではデフォルトで pylint (formatter)を利用できるが，その設定などは煩雑で，手動で開発者が各々行う必要がある．)

## 目的

チーム開発で VSCode を利用し，Linter・Formatter を統一することで，チームとしてのコーディングスタイルの統一化，コードの可動性向上，無駄な Git Commit の削減を狙う．また，初学者には敷居の高い docker コマンドや Git コマンドを利用せずに，容易にコンテナ上での開発や，GUI ベースの Git 運用をできるようにし，効率良く DevOps を回せるようにする．これにより，開発者の開発効率の向上・新規参画者への引き継ぎ工数を最小化することができる．

## 解決方法

ローカル PC 上の VSCode から，VSCode Remote SSH で，SSM Session Manager Plugin 経由で EC2 インスタンスにログインできるようにする．また，VSCode Dev Containers を利用し，開発環境（コンテナ，Linter，Formatter，IDE の設定）を共通化する．

<img src="./img/vscode-ssm-ec2.png" width="500">

## オリジナリティ

[AWS Deep Learning Containers Images](https://github.com/aws/deep-learning-containers/blob/master/available_images.md)をベースに，VSCode Dev Containers を利用して，VSCode 上での開発を可能にしている．これにより，SageMaker Pipeline の開発や SageMaker Training Job の実行のみならず，深層学習，SageMaker Jumpstart 等で提供されていない FM の実行のための環境を迅速に構築することができる．

## 前提

Windows，Linux 上には VSCode は install されているものとする．加え，AWS ユーザーは作成済みであり，Administrator 相当の権限を保持していることを想定している．なお，手順書中では，Windows でのセットアップに主眼を起き記述している．（Linux でも同様の手順で実施可能．）

## 手順

- [1. AWS CLI のインストールとセットアップ](#1-aws-cli-のインストールとセットアップ)
- [2. SSM Session Manager plugin のインストール](#2-ssm-session-manager-plugin-のインストール)
- [3. ローカルの VSCode に extension をインストール](#3-ローカルの-vscode-に-extension-をインストール)
- [4. CloudFormation で EC2 を構築](#4-cloudformation-で-ec2-を構築)
- [5. SSH の設定](#5-ssh-の設定)
- [6. VSCode から EC2 インスタンスにログイン](#6-vscode-から-ec2-インスタンスにログイン)
- [7. EC2 インスタンスに VSCode extension をインストール](#7-ec2-インスタンスに-vscode-extension-をインストール)
- [8. Dev Containers と AWS Deep Learning Containers Images を利用したコンテナの構築](#8-dev-containers-と-aws-deep-learning-containers-images-を利用したコンテナの構築)

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

- Zscaler などの社内プロキシを利用している場合は，`.aws/config`に以下を追記する．例えば，Zscaler を利用している場合は，以下のように CA 証明書のフルパスを記述する．CA 証明書のエクスポート方法は後述するので，必要があれば適宜参照されたい．

```
ca_bundle = C:\path\to\zscalar_root_cacert.cer
```

<details>
<summary>※Zscaler CA 証明書のエクスポート方法</summary>
<br/>

公式ドキュメント[^3]を参考に，エクスポートする．

- コンピュータ証明書の管理 > 信頼されたルート証明機関 > 証明書
- Zscalar Root CA を左クリック > すべてのタスク > エクスポート
  - 証明書のエクスポートウィザードで，次へ > Base 64 encoded X.509 を選択して次へ
  - 参照 > ディレクトリ・ファイル名を入力（ここではファイル名を`zscalar_root_cacert.cer`とする）> 次へ > 完了 > OK

</details>
<br/>

### 2. SSM Session Manager plugin のインストール

公式ドキュメント[^4]を参考に，SSM Session Manager plugin をインストールする．

- [Session Manager プラグインのインストーラ](https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe)をダウンロードし実行する

### 3. ローカルの VSCode に extension をインストール

[`./setup/vscode/vscode_local_setup_win.bat`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/setup/vscode/vscode_local_setup_win.bat)を実行し，VSCode の extension を一括インストールする．Linux の場合は，[`./setup/vscode/vscode_local_setup_linux.sh`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/setup/vscode/vscode_local_setup_linux.sh)を実行する．本バッチファイル，または shell の実行により，以下の extension がインストールされる．

- vscode-remote-extensionpack: VSCode でリモート開発を行うための extension
- aws-toolkit-vscode: AWS の各種サービスを VSCode から操作するための extension
- ec2-farm: AWS アカウント内の EC2 インスタンスの状態を確認し，起動・停止・再起動を行うための extension

### 4. CloudFormation で EC2 を構築

[`./setup/cf-template/cf-ec2.yaml`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/setup/cf-template/cf-ec2.yaml)（cf テンプレート）を利用し，CloudFormation で EC2 を構築する．以下に実際に構築されるリソースと，cf テンプレートの簡易説明を行う．また，CloudFormation の詳細な実行方法は後述しているので，必要があれば適宜参照されたい．

#### 構築するリソース

- EC2
- EC2 Key pair
- Security Group

<img src="./img/cf-ec2-architecture.png" width="500">

#### EC2 の環境について

Deep Learning 用の AMI を利用しているため，以下が全てインストールされている状態で EC2 が構築される．

- Git
- Docker
- NVIDIA Container Toolkit
- NVIDIA ドライバー
- CUDA, cuDNN, PyTorch

#### cf テンプレートの簡易説明

- VPC とサブネット ID をユーザー側で記述する必要がある
  - default VPC のパブリックサブネット等を選択すれば良い
- EC2 へのリモートアクセス・開発に必要と想定されるポリシーをアタッチしたロールは自動作成される．以下のポリシーをアタッチしている．
  - AmazonSSMManagedInstanceCore
  - AmazonS3FullAccess
  - AWSCodeCommitFullAccess
  - EC2InstanceProfileForImageBuilderECRContainerBuilds
  - AmazonSageMakerFullAccess
  - SecretsManagerReadWrite
  - AWSLambda_FullAccess
- セキュリティグループも自動作成しており，インバウンドは全てシャットアウトしている
- SSH 接続で利用する Key Pair を作成している
- EC2 インスタンス作成時，以下を自動実行している
  - git のアップグレード
  - aws cli のアップグレード
  - conda の初期設定
  - 再起動
- CloudFormation の出力部には，インスタンス ID と Key ID を出力している
  - 後述の shell で利用する

<details>
<summary>※CloudFormation 実行手順</summary>
<br/>

- [CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/)を開き，スタックの作成を押下
- テンプレートの指定 > テンプレートファイルのアップロード > ファイルの選択で上記で作成した yaml ファイルを指定し，次へを押下
  - [`./setup/cf-template/cf-ec2.yaml`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/setup/cf-template/cf-ec2.yaml)を upload する
- 任意のスタック名（利用者名などでよい）を入力後，以下のパラメータを設定・変更する
  - EC2InstanceType: インスタンスタイプ．デフォルトは g4dn.xlarge
  - ImageId: AMI の ID．デフォルトは Deep Learning AMI GPU PyTorch 2.1.0 の ID
  - SubnetID: 利用するパブリックサブネットの ID（デフォルト VPC のパブリックサブネット ID 等で問題ない）
  - VPCId: 利用する VPC の ID（デフォルト VPC の ID 等で問題ない）
  - VolumeSize: ボリュームサイズ．デフォルトは 100GB  
- 適切な IAM Role をアタッチし，次へを押下（一時的に Admin role で実施しても良いかもしれない）
- 作成されるまで 30 秒~1 分ほど待つ

</details>
<br/>

### 5. SSH の設定

[`./setup/get_aws_keypair/get_key_win.bat`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/setup/ssh/ssh_setup_win.bat)を実行し，秘密鍵のダウンロードと`.ssh/config`の設定を自動実行する．Linux の場合は[`./setup/get_aws_keypair/get_key_linux.sh`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/setup/ssh/ssh_setup_linux.sh)を実行すること．なお，実行前に，ソースコードの変数`KEY_ID`と`INSTANCE_ID`には CloudFormation の実行結果の各値を記述すること．

### 6. VSCode から EC2 インスタンスにログイン

VSCode のリモート接続機能を利用して，SSM Session Manager Plugin 経由で EC2 インスタンスに SSH でログインする．

- VSCode 上で，`F1`を押下し，`Remote-SSH: Connect to Host...`を選択
- `~/.ssh/config`に記述したホスト名を選択（デフォルトでは`ec2`となっている）
- リモート側の初期設定が終わるまで 30 秒程度待つ．（Select the platform of the remtoe host "ec2" という画面が出たら`Linux`を選択すること）
  - ※スタックの作成が完了しても，cf テンプレート内の UserData の shell 実行が終わるまで待つ必要があるため注意．（最長 5 分~10 分程度待つ．UserData の実行ログは`/var/log/cloud-init-output.log`で確認できる．）
- EC2 インスタンスにログイン後，インスタンス上に本リポジトリを clone する．
- `conda activate pytorch`実行後，[`./setup/check_vm_env/check_cuda_torch.sh`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/setup/check_vm_env/check_cuda_torch.sh)を実行し，EC2 インスタンス上で GPU や pytorch が利用可能であることを確認する．以下のような出力が表示されるはず．
  - pytorch を利用した MNIST の画像分類の学習を行うスクリプト[`./setup/check_vm_env/mnist_example/mnist.py`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/setup/check_vm_env/mnist_example/mnist.py)を用意しているため，これを実行しても構わない．

```
==============check cuda==============
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2023 NVIDIA Corporation
Built on Mon_Apr__3_17:16:06_PDT_2023
Cuda compilation tools, release 12.1, V12.1.105
Build cuda_12.1.r12.1/compiler.32688072_0
==============check gpu==============
Sat Dec 30 08:28:59 2023
+---------------------------------------------------------------------------------------+
| NVIDIA-SMI 535.104.12             Driver Version: 535.104.12   CUDA Version: 12.2     |
|-----------------------------------------+----------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |         Memory-Usage | GPU-Util  Compute M. |
|                                         |                      |               MIG M. |
|=========================================+======================+======================|
|   0  Tesla T4                       On  | 00000000:00:1E.0 Off |                    0 |
| N/A   31C    P8               9W /  70W |      0MiB / 15360MiB |      0%      Default |
|                                         |                      |                  N/A |
+-----------------------------------------+----------------------+----------------------+

+---------------------------------------------------------------------------------------+
| Processes:                                                                            |
|  GPU   GI   CI        PID   Type   Process name                            GPU Memory |
|        ID   ID                                                             Usage      |
|=======================================================================================|
|  No running processes found                                                           |
+---------------------------------------------------------------------------------------+
==============check torch==============
if you exec at first time, you might wait for a while...
torch.__version__: 2.1.0
torch.cuda.is_available(): True
```

### 7. EC2 インスタンスに VSCode extension をインストール

[`./setup/vscode/vscode_vm_setup.sh`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/setup/vscode/vscode_vm_setup.sh)を実行し，EC2 インスタンス上で Git の初期設定と VSCode extension のインストールを行う．なお，コード中の`NAME`と`MAIL`には，各自の名前とメールアドレスを記述すること．

### 8. Dev Containers と AWS Deep Learning Containers Images を利用したコンテナの構築

VSCode DevContainers と [AWS Deep Learning Containers Images](https://github.com/aws/deep-learning-containers/blob/master/available_images.md)を利用し，コンテナを構築する．[`./.devcontainer/devcontainer.json`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/.devcontainer/devcontainer.json)の initializeCommand で ECR へのログインを行うことで，[AWS Deep Learning Containers Images](https://github.com/aws/deep-learning-containers/blob/master/available_images.md)（AWS 公式が提供する ECR 上のイメージ）を pull している．[AWS Deep Learning Containers Images](https://github.com/aws/deep-learning-containers/blob/master/available_images.md)では，PyTorch, Tensorflow, MXNet などのフレームワークがプリインストールされたイメージ（SageMaker Training Job での実行環境イメージ）に加え，HuggingFace，StabilityAI のモデルの推論のためのイメージが提供されており，利用するイメージを適宜変更・カスタマイズすることで検証時の環境構築を効率化することができる．

- VSCode 上で，`F1`を押下し，`Dev Container: Reopen in Container`を選択し，Dev Containers を構築
  - [`./.devcontainer/devcontainer.json`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/.devcontainer/devcontainer.json)の`pj-name`という箇所には，各自のプロジェクト名を記述すること．
  - 初回のコンテナ構築時は，Docker イメージの pull に時間がかかるため，10 分~20 分程度待つ．
- [`./setup/check_vm_env/check_cuda_torch.sh`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/setup/check_vm_env/check_cuda_torch.sh)を実行し，コンテナ内で GPU や pytorch が利用可能であることを確認する．本リポジトリの設定だと以下のように表示される．

```
==============check cuda==============
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2023 NVIDIA Corporation
Built on Mon_Apr__3_17:16:06_PDT_2023
Cuda compilation tools, release 12.1, V12.1.105
Build cuda_12.1.r12.1/compiler.32688072_0
==============check gpu==============
Sat Dec 30 08:12:03 2023
+---------------------------------------------------------------------------------------+
| NVIDIA-SMI 535.104.12             Driver Version: 535.104.12   CUDA Version: 12.2     |
|-----------------------------------------+----------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |         Memory-Usage | GPU-Util  Compute M. |
|                                         |                      |               MIG M. |
|=========================================+======================+======================|
|   0  Tesla T4                       On  | 00000000:00:1E.0 Off |                    0 |
| N/A   31C    P8               9W /  70W |      0MiB / 15360MiB |      0%      Default |
|                                         |                      |                  N/A |
+-----------------------------------------+----------------------+----------------------+

+---------------------------------------------------------------------------------------+
| Processes:                                                                            |
|  GPU   GI   CI        PID   Type   Process name                            GPU Memory |
|        ID   ID                                                             Usage      |
|=======================================================================================|
|  No running processes found                                                           |
+---------------------------------------------------------------------------------------+
==============check torch==============
if you exec at first time, you might wait for a while...
torch.__version__: 2.1.0
torch.cuda.is_available(): True
```

## その他

### インスタンスの起動・停止

開発開始時・終了時には，VSCode extension `EC2 Farm`経由で各々の EC2 インスタンスを起動・停止することが可能である．（AWS コンソールを開く必要はない．）

### コーディングガイドラインと開発環境の設定

チーム開発において VSCode を利用するメリットは，Linter や Formatter をチームで共通化できる上，IDE の設定や利用する extension なども共通化することができる点である．これにより，チームメンバ間での利用するツールやコーディング上の認識齟齬は低減され，利便性の高い extension によって開発効率が向上すると考えられる．詳細は，[./docs/coding-guidelines.md](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/docs/coding-guidelines.md)を参照されたい．

### チームでの EC2 の運用・管理

インスタンスの切り忘れ防止のために，AWS Lambda を利用して，夜 12 時に全ての EC2 インスタンスを停止させている．なお，運用サーバーなど特定のインスタンスは除外可能にできるようにしている．詳細は，[./docs/operation_ec2.md](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/docs/operation_ec2.md)を参照されたい．

### その他 Tips

- Git 運用は，Git Graph を利用することで，GUI で行うことができる．
- Docker コンテナ運用は，Dev Containers を利用することで，GUI で行うことができる．
- [`./.devcontainer/Dockerfile`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/.devcontainer/Dockerfile)の 1 行目で指定しているイメージを適宜変更することで，利用するモデルに応じた環境を容易に構築することができる．
  - ECR で利用可能なイメージは，[本リンク](https://github.com/aws/deep-learning-containers/blob/master/available_images.md)を参照されたい．
  - 例えば，Stable Diffusion 系列のモデルや，Stable Diffusion Web UI などを実行したい場合などは，以下のイメージを指定することで，簡単に環境を構築することができる．
    - `763104351884.dkr.ecr.ap-northeast-1.amazonaws.com/stabilityai-pytorch-inference:2.0.1-sgm0.1.0-gpu-py310-cu118-ubuntu20.04-sagemaker`
  - イメージによっては，non-root user が定義されている可能性がある．その場合，Dockerfile の 12~27 行目はコメントアウトすること（Dockerfile 内では明示的に non-root user を作成している）
    - Dev Containers の`remoteUser` property を，[`./.devcontainer/devcontainer.json`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/.devcontainer/devcontainer.json)に追記しても良い．詳細は，VSCode の公式ドキュメント[^5]を参照されたい．

## 参考

[^1]: [AWS CLI の最新バージョンを使用してインストールまたは更新を行う](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-install.html)
[^2]: [AWS CLI をセットアップする](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-quickstart.html)
[^3]: [CA 証明書のエクスポート](https://help.zscaler.com/ja/deception/exporting-root-ca-certificate-active-directory-certificate-service)
[^4]: [Windows での Session Manager プラグインのインストール](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/install-plugin-windows.html)
[^5]: [Add a non-root user to a container](https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user)
