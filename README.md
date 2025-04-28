# VSCode Dev Containers を利用した AWS EC2 上での開発環境構築手順<!-- omit in toc -->

本リポジトリでは，Windows・Mac・Linux PC 上の Visual Studio Code IDE (VSCode) から AWS EC2 へリモート接続し，VSCode Dev Containers を利用して深層学習や LLM アプリケーション開発を効率良く行えるようにするための手順を示す．

なお，本リポジトリはチーム開発時に，所属チームへクラウドネイティブで効率的な開発手法を導入することを目的としており，python コーディングにおける linter, formatter や VSCode extension，setting.json なども共通のものを利用するようにしている．

## TL;DR <!-- omit in toc -->

以下の Tips を整理し，手順書としてまとめた．また，最小限の手順で済むよう，bat ファイルや shell スクリプトを用意している．

- AWS Systems Manager (SSM) 経由で VSCode から EC2 にセキュアに SSH 接続する方法
- チーム開発時の IDE として VSCode を利用し，uv，Ruff，mypy を共通的に利用する方法
- AWS Deep Learning Containers Images 等をベースに Dev Containers 上で開発する方法

## 目次<!-- omit in toc -->

- [背景と課題](#背景と課題)
- [目的](#目的)
- [オリジナリティ](#オリジナリティ)
- [前提](#前提)
- [手順](#手順)
- [手順の各ステップの詳細](#手順の各ステップの詳細)
  - [1. AWS CLI のインストールとセットアップ](#1-aws-cli-のインストールとセットアップ)
  - [2. SSM Session Manager plugin のインストール](#2-ssm-session-manager-plugin-のインストール)
  - [3. ローカルの VSCode に extension をインストール](#3-ローカルの-vscode-に-extension-をインストール)
  - [4. CloudFormation で EC2 を構築](#4-cloudformation-で-ec2-を構築)
    - [構築するリソース](#構築するリソース)
    - [EC2 の仕様について](#ec2-の仕様について)
    - [cf テンプレート利用時の入力パラメータについて](#cf-テンプレート利用時の入力パラメータについて)
    - [cf テンプレートの簡易説明](#cf-テンプレートの簡易説明)
  - [5. SSH の設定](#5-ssh-の設定)
  - [6. VSCode から EC2 インスタンスにログイン](#6-vscode-から-ec2-インスタンスにログイン)
  - [7. EC2 インスタンスに VSCode extension をインストール](#7-ec2-インスタンスに-vscode-extension-をインストール)
  - [8. Dev Containers を利用したコンテナの構築](#8-dev-containers-を利用したコンテナの構築)
- [その他](#その他)
  - [インスタンスの起動・停止](#インスタンスの起動停止)
  - [コーディングガイドラインと開発環境の設定](#コーディングガイドラインと開発環境の設定)
  - [チームでの EC2 の運用・管理](#チームでの-ec2-の運用管理)
  - [Tips](#tips)
    - [VSCode Extension](#vscode-extension)
    - [Dockerfile](#dockerfile)
    - [CPU インスタンスで開発する場合](#cpu-インスタンスで開発する場合)
    - [CloudFormation Template の UserData の実行ログ](#cloudformation-template-の-userdata-の実行ログ)
    - [Ruff が動作しない場合](#ruff-が動作しない場合)
- [参考](#参考)

## 背景と課題

社内のローカル PC 上で，深層学習モデルを開発する際，PoC 毎に環境構築が必要で時間を要してしまう課題がある．例えば，NVIDIA drivers や CUDA，PyTorch などのセットアップに苦労し，本来注力すべき本質的な開発タスクに十分なリソースを割くことができない．

また，LLM API を利用したアプリケーションをチームで開発する際，社内プロキシが原因で開発が非効率になる課題がある．具体的には，SSL 証明書関連のエラーに苦労することや，リモートリポジトリを利用できず，コードのバージョン管理や共有ができないことがある．

その他，チームの各メンバが利用する開発環境が統一化されていない場合，チームとしての開発効率が低下してしまう課題がある．特に，利用する OS や Python パッケージ管理ツール，Linter，Formatter が異なる場合，コードの一貫性が失われ，レビュープロセスが複雑化する．加え，環境の違いによりメンバ間でのコードの実行結果の再現性が損なわれる．

AWS Cloud9 や SageMaker AI Studio Code Editor のようなクラウドネイティブ IDE を利用することで，上記の課題を解消することは可能である．しかし，ローカルの VSCode と比較すると，これらのサービスには慣れや経験が必須である．また，Dev Containers などの VSCode の Extensions を利用することはできず，CLI ベースで Docker を利用する必要がある．そのため，初学者や新規参画者には敷居が高く，即時参画には時間を要してしまう課題がある．

## 目的

ローカル PC 上の VSCode から，VSCode Remote SSH により，SSM Session Manager Plugin 経由で EC2 インスタンスにログインし，EC2 上で開発できるようにする．その際，AWS Deep Learning AMIs を利用する．また，VSCode Dev Containers を利用し，開発環境をコンテナとして統一化する．これにより，開発環境の構築を自動化し，メンバ間でのコードの実行結果の再現性を担保する．また，社内プロキシ起因の課題を回避し，CodeCommit などのセキュアなリポジトリサービスを利用することができる．

また，チーム開発で利用する IDE として VSCode を利用し，Python パッケージ管理ツール，Linter，Formatter，Extensions を統一化する．これにより，チームとしてのコーディングスタイルの統一化，コードの可動性や一貫性の向上を狙う．また，VSCode の Extensions である Dev Containers や Git Graph を利用することで，初学者には敷居の高い docker コマンドや git コマンドを利用せず，容易にコンテナ上での開発や，GUI ベースの Git 運用をできるようにする．

<img src="./img/vscode-ssm-ec2.png" width="500">

## オリジナリティ

深層学習モデル開発，LLM API を利用したアプリケーション開発，SageMaker Pipelines 開発など，用途別に Dev Containers の環境を用意している．これらの環境では，基本的には Python パッケージ管理には uv，Formatter や Linter には Ruff を利用しており，git や aws cli が利用可能である．加え，Dev Containers を利用しているので Cline や Amazon Q Developer などの VSCode Extensions をコンテナ内でセキュアに利用することが可能である．

| コンテナ名                                                                                            | 用途                                            | 特徴                                                                                                                                                                        |
| ----------------------------------------------------------------------------------------------------- | ----------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [cpu-uv](https://github.com/ren8k/aws-ec2-devkit-vscode/tree/main/.devcontainer/cpu-uv)               | LLM API を利用したアプリケーション開発を想定    | - 軽量な Docker イメージを利用 <br> - uv や Ruff を利用可能                                                                                                                 |
| [gpu-uv](https://github.com/ren8k/aws-ec2-devkit-vscode/tree/main/.devcontainer/gpu-uv)               | 深層学習モデル開発                              | - CUDA や cuDNN がセットアップ済み <br> - uv や Ruff を利用可能                                                                                                             |
| [gpu-sagemaker](https://github.com/ren8k/aws-ec2-devkit-vscode/tree/main/.devcontainer/gpu-sagemaker) | SageMaker Pipeline の開発や Training Job の実行 | - [AWS Deep Learning Containers Images](https://github.com/aws/deep-learning-containers/blob/master/available_images.md) を利用 <br> - PyTorch がプリインストール済み (pip) |

## 前提

Windows，Linux 上には VSCode は install されているものとする．加え，AWS ユーザーは作成済みであり，以下のポリシーで定義される権限を最低限付与していることを想定している．なお，手順書中では，Windows でのセットアップに主眼を起き記述している．（Linux でも同様の手順で実施可能．）

<details>
<summary>最低限必要なポリシー</summary>
<br/>

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EC2InstanceManagement",
      "Effect": "Allow",
      "Action": ["ec2:StartInstances", "ec2:StopInstances"],
      "Resource": "arn:aws:ec2:*:*:instance/*"
    },
    {
      "Sid": "EC2DescribeAccess",
      "Effect": "Allow",
      "Action": "ec2:DescribeInstances",
      "Resource": "*"
    },
    {
      "Sid": "SSMSessionAccess",
      "Effect": "Allow",
      "Action": "ssm:StartSession",
      "Resource": [
        "arn:aws:ssm:*:*:document/AWS-StartSSHSession",
        "arn:aws:ec2:*:*:instance/*"
      ]
    },
    {
      "Sid": "SSMParameterAccess",
      "Effect": "Allow",
      "Action": "ssm:GetParameter",
      "Resource": "arn:aws:ssm:*:*:parameter/ec2/keypair/*"
    }
  ]
}
```

</details>
<br/>

## 手順

1. AWS CLI のインストールとセットアップ
2. SSM Session Manager plugin のインストール
3. ローカルの VSCode に extension をインストール
4. CloudFormation で EC2 を構築
5. SSH の設定
6. VSCode から EC2 インスタンスにログイン
7. EC2 インスタンスに VSCode extension をインストール
8. Dev Containers を利用したコンテナの構築

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

Zscaler を利用してプロキシエージェント経由で通信を行う場合，Zscaler では SSL インスペクションの設定がなされているため，https 通信を行うときにルート証明書の情報が Zscaler のものに上書きされる．そのため，Zscaler のルート証明書を実行環境の証明書の信頼リストに登録しなければ https 通信が失敗する場合がある．

**Windows の場合**

公式ドキュメント[^3]を参考に，Zscaler のルート証明書をエクスポートする．

- コンピュータ証明書の管理 > 信頼されたルート証明機関 > 証明書
- Zscalar Root CA を左クリック > すべてのタスク > エクスポート
  - 証明書のエクスポートウィザードで，次へ > Base 64 encoded X.509 を選択して次へ
  - 参照 > ディレクトリ・ファイル名を入力（ここではファイル名を`zscalar_root_cacert.cer`とする）> 次へ > 完了 > OK

**macOS の場合**

- Keychain を開き，システムチェーン -> システム の中にある Zscaler Root CA を右クリック
- 「"Zscaler Root CA"を書き出す...」 を選択
- `/path/to/zscalar_root_cacert.cer`などのファイル名で，任意のパスに保存

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

#### EC2 の仕様について

Deep Learning 用の AMI を利用しているため，以下が全てインストールされている状態で EC2 が構築される．詳細な仕様は，本 AWS ドキュメント[^5-1] [^5-2]を参照されたい．

- Git
- AWS CLI (v2 は `aws2`，v1 は `aws` コマンド)
- Python (3.11)
- Docker
- NVIDIA Container Toolkit
- NVIDIA driver (570.86.15)
- CUDA, cuDNN (12.6)
- PyTorch (2.6)
- uv

#### cf テンプレート利用時の入力パラメータについて

| パラメータ名      | 説明                                  | デフォルト値                                                                  |
| ----------------- | ------------------------------------- | ----------------------------------------------------------------------------- |
| `EC2InstanceType` | 利用する EC2 のインスタンスタイプ     | `g4dn.xlarge` (GPU インスタンス)，`m5.large`などの CPU インスタンスも設定可能 |
| `ImageId`         | 利用する EC2 の AMI の種類            | `Deep Learning OSS Nvidia Driver AMI GPU PyTorch 2.6 (Ubuntu 22.04)`          |
| `SubnetId`        | インターネット接続可能なサブネット ID | 指定必須（不明な場合は default VPC のパブリックサブネットを利用）             |
| `VolumeSize`      | EC2 のボリュームサイズ                | 100GB                                                                         |
| `VPCId`           | 利用するサブネットが属する VPC の ID  | 指定必須（不明な場合は default VPC を利用）                                   |

#### cf テンプレートの簡易説明

- EC2 へのリモートアクセス・開発に必要と想定されるポリシーをアタッチしたロールは自動作成される．以下のポリシーをアタッチしている．
  - AmazonSSMManagedInstanceCore
  - AmazonS3FullAccess
  - AWSCodeCommitFullAccess
  - EC2InstanceProfileForImageBuilderECRContainerBuilds
  - AmazonSageMakerFullAccess
  - SecretsManagerReadWrite
  - AWSLambda_FullAccess
  - AmazonBedrockFullAccess
  - AmazonECS_FullAccess
- セキュリティグループも自動作成しており，インバウンドは全てシャットアウトしている
- SSH 接続で利用する Key Pair を作成している
- EC2 インスタンス作成時，以下を自動実行している
  - git のアップグレード
  - UV のインストール
  - venv の仮想環境の activate
- CloudFormation の出力部には，インスタンス ID と Key ID を出力している
  - 後述の shell で利用する

<details>
<summary>※CloudFormation 実行手順</summary>
<br/>

- [CloudFormation コンソール](https://console.aws.amazon.com/cloudformation/)を開き，スタックの作成を押下
- テンプレートの指定 > テンプレートファイルのアップロード > ファイルの選択で上記で作成した yaml ファイルを指定し，次へを押下
  - [`./setup/cf-template/cf-ec2.yaml`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/setup/cf-template/cf-ec2.yaml)を upload する
  - 任意の事情で upload が出来ない場合，テンプレートを S3 経由で利用するか，Application Composer を利用してテンプレートを利用すると良い (ローカル PC 上 or CloudShell 上で，cf テンプレートを S3 にアップロードする必要がある)
- 任意のスタック名（利用者名などでよい）を入力後，以下のパラメータを設定・変更する
  - EC2InstanceType: インスタンスタイプ．デフォルトは g4dn.xlarge
  - ImageId: AMI の ID．デフォルトは Deep Learning AMI GPU PyTorch の ID
  - SubnetID: 利用するパブリックサブネットの ID（デフォルト VPC のパブリックサブネット ID 等で問題ない）
  - VPCId: 利用する VPC の ID（デフォルト VPC の ID 等で問題ない）
  - VolumeSize: ボリュームサイズ．デフォルトは 100GB
- 適切な IAM Role をアタッチし，次へを押下（一時的に AdministratorAccess を付与したロールを利用しても良い）
- 作成されるまで 5 分ほど待つ

</details>
<br/>

### 5. SSH の設定

[`./setup/get_aws_keypair/get_key_win.bat`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/setup/ssh/ssh_setup_win.bat)を実行し，秘密鍵のダウンロードと`.ssh/config`の設定を自動実行する．Linux の場合は[`./setup/get_aws_keypair/get_key_linux.sh`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/setup/ssh/ssh_setup_linux.sh)を実行すること．なお，実行前に，ソースコードの変数`KEY_ID`と`INSTANCE_ID`には CloudFormation の実行結果の各値を記述すること．

### 6. VSCode から EC2 インスタンスにログイン

VSCode のリモート接続機能を利用して，SSM Session Manager Plugin 経由で EC2 インスタンスに SSH でログインする．以下，CloudFormation により EC2 の構築が完了している前提で説明する．

- VSCode 上で，`F1`を押下し，`Remote-SSH: Connect to Host...`を選択
- `~/.ssh/config`に記述したホスト名を選択（デフォルトでは`ec2`となっている）
- Select the platform of the remtoe host "ec2" という画面が出たら`Linux`を選択すること
  - ※スタックの作成が完了しても，cf テンプレート内の UserData の shell 実行が終わるまで待つ必要があるため注意．（CloudFormation の実行完了後， 2, 3 分程度待つこと．UserData の実行ログは`/var/log/cloud-init-output.log`で確認できる．）
- EC2 インスタンスにログイン後，インスタンス上に本リポジトリを clone する．
- [`./setup/check_vm_env/check_cuda_torch.sh`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/setup/check_vm_env/check_cuda_torch.sh)を実行し，EC2 インスタンス上で GPU や pytorch が利用可能であることを確認する．以下のような出力が表示されるはずである．
  - PyTorch を利用した MNIST の画像分類の学習を行うスクリプト[`./setup/check_vm_env/mnist_example/mnist.py`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/setup/check_vm_env/mnist_example/mnist.py)を用意しているため，これを実行しても構わない．

```
==============check cuda==============
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2024 NVIDIA Corporation
Built on Tue_Oct_29_23:50:19_PDT_2024
Cuda compilation tools, release 12.6, V12.6.85
Build cuda_12.6.r12.6/compiler.35059454_0
==============check gpu==============
Sun Apr 27 04:59:53 2025
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 570.86.15              Driver Version: 570.86.15      CUDA Version: 12.8     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  Tesla T4                       On  |   00000000:00:1E.0 Off |                    0 |
| N/A   26C    P8              9W /   70W |       1MiB /  15360MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
==============check torch==============
if you exec at first time, you might wait for a while...
torch.__version__: 2.6.0+cu126
torch.cuda.is_available(): True
```

### 7. EC2 インスタンスに VSCode extension をインストール

[`./setup/vscode/vscode_vm_setup.sh`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/setup/vscode/vscode_vm_setup.sh)を実行し，EC2 インスタンス上で Git の初期設定と VSCode extension のインストール，VSCode の setting.json の設定を行う．なお，shell 実行時，Git の設定で利用する名前とメールアドレスをコマンドから入力すること．

### 8. Dev Containers を利用したコンテナの構築

Dev Containers を利用することで，GUI でコンテナを起動し，コンテナ内で容易に開発することができる．

- VSCode 上で`F1`を押下し，`Dev Container: Reopen in Container`を選択する．
- 本リポジトリ上では，以下の 3 つの選択肢が表示されるため，用途別にコンテナ環境を選択すること．
  - [cpu-uv](https://github.com/ren8k/aws-ec2-devkit-vscode/tree/main/.devcontainer/cpu-uv): LLM API を利用したアプリケーション開発を想定．
  - [gpu-uv](https://github.com/ren8k/aws-ec2-devkit-vscode/tree/main/.devcontainer/gpu-uv): 深層学習モデル開発を想定．
  - [gpu-sagemaker](https://github.com/ren8k/aws-ec2-devkit-vscode/tree/main/.devcontainer/gpu-sagemaker): SageMaker Pipeline の開発や SageMaker Training Job の実行を想定．

以下に利用時の注意点を示す．

- `devcontainer.json`の 2 行目の`pj-name`という箇所には，各自のプロジェクト名を記述すること．
- 初回のコンテナ構築時は，Docker イメージの pull に時間がかかるため，10 分程度待つ．
- [.devcontainer ディレクトリ](https://github.com/ren8k/aws-ec2-devkit-vscode/tree/main/.devcontainer)内で利用しない環境フォルダ以外は削除して問題ない．

以下に，各コンテナ利用時の簡易説明を行う．

<details>
<summary>cpu-uv</summary>
<br/>

- Python パッケージ管理には uv，Linter や Formatter には Ruff を利用している．
- Dockerfile 内部では，sudo を利用可能な一般ユーザーの作成および， AWS CLI v2 のインストールを行っている．
- `uv add <パッケージ名>` でパッケージを install 可能．
- `uv remove <パッケージ名>` でパッケージを uninstall 可能．
- Python のバージョンを変更したい場合，`pyproject.toml`の`requires-python`を変更した後，`uv python pin <バージョン>` ，`uv sync`を実行する．
  - Ex. Python 3.11 を利用したい場合: `pyproject.toml`の`requires-python`を`">=3.11"`に変更し，`uv python pin 3.10 && uv sync`
- `uv run python`コマンド，または，venv の仮想環境を activate した状態で`python`コマンドを利用して，Python コードを実行可能．
  - 仮想環境の activate は`. .venv/bin/activate`コマンドで可能

</details>
<br/>

<details>
<summary>gpu-uv</summary>
<br/>

- Python パッケージ管理には uv，Linter や Formatter には Ruff を利用している．
- Dockerfile 内部では，sudo を利用可能な一般ユーザーの作成および， AWS CLI v2 のインストールを行っている．
- `uv add <パッケージ名>` でパッケージを install 可能．
- `uv remove <パッケージ名>` でパッケージを uninstall 可能．
- Python のバージョンを変更したい場合，`pyproject.toml`の`requires-python`を変更した後，`uv python pin <バージョン>` ，`uv sync`を実行する．
  - Ex. Python 3.11 を利用したい場合: `pyproject.toml`の`requires-python`を`">=3.11"`に変更し，`uv python pin 3.10 && uv sync`
- `uv run python`コマンド，または，venv の仮想環境を activate した状態で`python`コマンドを利用して，Python コードを実行可能．
  - 仮想環境の activate は`. .venv/bin/activate`コマンドで可能
- PyTorch を install する場合，[`uv add torch torchvision`](https://docs.astral.sh/uv/guides/install-python/) を実行する．
- CUDA のバージョンは以下．

```
$ nvcc -V
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2025 NVIDIA Corporation
Built on Fri_Feb_21_20:23:50_PST_2025
Cuda compilation tools, release 12.8, V12.8.93
Build cuda_12.8.r12.8/compiler.35583870_0
```

</details>
<br/>

<details>
<summary>gpu-sagemaker</summary>
<br/>

- [AWS Deep Learning Containers Images](https://github.com/aws/deep-learning-containers/blob/master/available_images.md)を利用し，コンテナを構築している．[AWS Deep Learning Containers Images](https://github.com/aws/deep-learning-containers/blob/master/available_images.md)は，PyTorch, Tensorflow, MXNet などのフレームワークがプリインストールされたイメージ（SageMaker Training Job での実行環境イメージ）に加え，HuggingFace，StabilityAI のモデルの推論のためのイメージが提供されており，利用するイメージを適宜変更・カスタマイズすることで検証時の環境構築を効率化することができる．
- Python パッケージ管理には pip，Linter や Linter には Ruff を利用している．pip を利用している理由は，本コンテナの利用は，pip 経由でプリインストールされている PyTorch などをクイックに利用することを想定しているためである．
- Dockerfile 内部では， AWS CLI v2 のインストールを行っている．
- devcontainer.json では以下の処理を行っている．
  - `initializeCommand`で， ECR へのログイン
  - `features`で，non-root ユーザーの作成
  - `remote`で，コンテナにおけるプロセス実行ユーザーを指定
- [`./setup/check_vm_env/check_cuda_torch.sh`](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/setup/check_vm_env/check_cuda_torch.sh)を実行し，コンテナ内で GPU や PyTorch が利用可能であることを確認する．

```
==============check cuda==============
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2024 NVIDIA Corporation
Built on Tue_Oct_29_23:50:19_PDT_2024
Cuda compilation tools, release 12.6, V12.6.85
Build cuda_12.6.r12.6/compiler.35059454_0
==============check gpu==============
Sun Apr 27 04:57:38 2025
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 570.86.15              Driver Version: 570.86.15      CUDA Version: 12.8     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  Tesla T4                       On  |   00000000:00:1E.0 Off |                    0 |
| N/A   29C    P8             13W /   70W |       1MiB /  15360MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|  No running processes found                                                             |
+-----------------------------------------------------------------------------------------+
==============check torch==============
if you exec at first time, you might wait for a while...
torch.__version__: 2.6.0+cu126
torch.cuda.is_available(): True
```

</details>
<br/>

## その他

### インスタンスの起動・停止

開発開始時・終了時には，VSCode extension `EC2 Farm`経由で各々の EC2 インスタンスを起動・停止することが可能である．（AWS コンソールを開く必要はない．）

### コーディングガイドラインと開発環境の設定

チーム開発において VSCode を利用するメリットは，Linter や Formatter をチームで共通化できる上，IDE の設定や利用する extension なども共通化することができる点である．これにより，チームメンバ間での利用するツールやコーディング上の認識齟齬は低減され，利便性の高い extension によって開発効率が向上すると考えられる．また，pre-commit を利用し Git コミットする直前に Ruff や mypy による Lint，Format，型のチェックを行っている．詳細は，[./docs/coding-guidelines.md](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/docs/coding-guidelines.md)を参照されたい．

### チームでの EC2 の運用・管理

インスタンスの切り忘れ防止のために，AWS Lambda を利用して，夜 12 時に全ての EC2 インスタンスを停止させている．なお，運用サーバーなど特定のインスタンスは除外可能にできるようにしている．詳細は，[./docs/operation_ec2.md](https://github.com/Renya-Kujirada/aws-ec2-devkit-vscode/blob/main/docs/operation_ec2.md)を参照されたい．

### Tips

#### VSCode Extension

- Git 運用は，`Git Graph` を利用することで，GUI で行うことができる．
- Docker コンテナ運用は，`Dev Containers` を利用することで，GUI で行うことができる．
- EC2 インスタンスの起動や停止は，ローカルの VSCode にインストールした extension の`ec2-farm`で行える．
  - `ec2-farm`を開き，右クリックで EC2 を起動 or 停止が可能
- リモートの Dev Container 環境への接続は，ローカルの VSCode にインストールした extension の`Project Manager`で行える．
  - Project Manager に登録したい Dev Container 環境を VSCode で起動
  - `Project Manager`を開き，Save Project (小さいディスクのアイコン) を選択し，Dev Container 環境を登録（任意の名前で保存可能）
  - 次回以降は，`ec2-farm`で EC2 を起動後，`Project Manager`に表示された Dev Container 名を選択することで，ssh 接続および Dev Container 起動と接続までが一度に実行可能

#### Dockerfile

- gpu-sagemaker において，Dockerfile の 1 行目で指定しているイメージを適宜変更することで，利用するモデルに応じた環境を容易に構築することができる．
  - ECR で利用可能なイメージは，[本リンク](https://github.com/aws/deep-learning-containers/blob/master/available_images.md)を参照されたい．
  - 例えば，Stable Diffusion 系列のモデルや，Stable Diffusion Web UI などを実行したい場合などは，以下のイメージを指定することで，簡単に環境を構築することができる．
    - `763104351884.dkr.ecr.ap-northeast-1.amazonaws.com/stabilityai-pytorch-inference:2.0.1-sgm0.1.0-gpu-py310-cu118-ubuntu20.04-sagemaker`
  - イメージによっては，non-root user が定義されている可能性がある．その場合，Dockerfile の 12~27 行目はコメントアウトすること（Dockerfile 内では明示的に non-root user を作成している）
- non-root user を作成する際，Dockerfile ではなく，`devcontainer` の `features`の `common-utils` や`remoteUser`で設定することも可能である．詳細や使用例は，公式ドキュメント[^5-3]や公式リポジトリ[^6]，技術ブログ[^7]を参照されたい．

#### CPU インスタンスで開発する場合

- EC2 インスタンスのインスタンスタイプを，`m5.xlarge`などに変更する
  - 利用している AMI では GPU インスタンス以外は非推奨だが，問題なく動作した
- gpu-sagemaker の`.devcontainer/devcontainer.json`の 9 行目と 14 行目をコメントアウトする
  - docker コマンドの引数`--gpus all`を除外する
- コンテナのリビルドを実行する

#### CloudFormation Template の UserData の実行ログ

- EC2 インスタンスの以下のパスにログが出力される
  - `/var/log/cloud-init-output.log`

#### Ruff が動作しない場合

- VSCode 上で`F1`を押下し，`Python: Select Interpreter`を選択し，利用する Python のパスが適切に設定されているかを確認する．

## 参考

[^1]: [AWS CLI の最新バージョンを使用してインストールまたは更新を行う](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-install.html)
[^2]: [AWS CLI をセットアップする](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-quickstart.html)
[^3]: [CA 証明書のエクスポート](https://help.zscaler.com/ja/deception/exporting-root-ca-certificate-active-directory-certificate-service)
[^4]: [Windows での Session Manager プラグインのインストール](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/install-plugin-windows.html)
[^5-1]: [AWS Deep Learning AMI GPU PyTorch 2.6 (Ubuntu 22.04)](https://aws.amazon.com/jp/releasenotes/aws-deep-learning-ami-gpu-pytorch-2-6-ubuntu-22-04/)
[^5-2]: [AWS Deep Learning AMIs](https://docs.aws.amazon.com/ja_jp/dlami/latest/devguide/dlami-dg.pdf)
[^5-3]: [Add a non-root user to a container](https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user)
[^6]: [github repository: devcontainers / features](https://github.com/devcontainers/features/tree/main/src/common-utils)
[^7]: [devcontainer で X11 forwarding 可能な環境を作る (あと uv と CUDA 環境も構築)](https://zenn.dev/colum2131/articles/c8b053b84ade7f)
