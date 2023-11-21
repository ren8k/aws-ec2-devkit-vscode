# aws-ec2-devkit-vscode

## 目次

### 背景，課題，目的

## cf テンプレートで EC2 構築

#### 前提

- role では以下をアタッチしている

- role は作成しておく

### cf テンプレートで EC2 構築

- キーペアは新規作成
- ロールは既存のものをアタッチ

https://github.com/Renya-Kujirada/aws-cloud9/tree/master

- キーペアをダウンロード
  https://qiita.com/tsukamoto/items/1e0f3c8ecf4cba5cf485

### ローカル側での設定

- ssm プラグインの install
- remote ssh
-

### codecommit 等の認証設定（shell でやる）

### dev-container の設定

https://github.com/Azure/mlops-starter-sklearn/tree/main

https://github.com/Renya-Kujirada/kaggle-env-on-vscode/blob/main/.devcontainer/devcontainer.json

https://qiita.com/Spritaro/items/602118d946a4383bd2bb

## 参考

- [AWS Systems Manager と VS Code Remote SSH を組み合わせて快適なリモート開発環境を作る方法](https://dev.classmethod.jp/articles/how-to-use-vscode-remote-ssh-with-aws-systems-manager/)
- [Session ManagerプラグインをインストールしてローカルWindows PCからEC2へSession Managerで接続してみた](https://dev.classmethod.jp/articles/installed-session-manager-plugin-and-connected-from-local-windows-pc/)

---

# 背景

現状、クラウドネイティブに開発できるようになったが、開発環境として VSCode を利用したほうが効率が良い場面が多々ある。
例えば、VSCode を利用すれば、チーム内でリンターとフォーマッターの設定などを容易に統一することができる。特に、複数のエンジニアによる共同開発において、リポジトリ全体で一貫性を保つことは、解釈の違いの低減や可動性の工場、引き継ぎ工数の削減の観点で重要である。加えて、VSCode の Dev-Container を利用すれば、Docker の深い知見がなくとも簡単にコンテナ構築・コンテナ内で開発を行うことができるメリットもある。

# 課題

現状の Cloud9 ベースの運用の場合、linter の設定を自由に行えないため、コード内のバグ原因などの見落とし等に繋がってしまう恐れがある。加えて、Git、Docker、Linux 基盤の深い知見を求められるため、新規参画者には敷居が高く、即時参画には時間がかかってしまう問題がある。(cloud9 ではデフォルトで pylint を利用できるが、その設定などは煩雑で、手動で開発者が各々行う必要がある。)

# 解決したいこと

チーム内で、リンター・フォーマッターを統一することで、コードの解釈の違いの低減、無駄な Git Commit の削減を狙う。また、難解な docker コマンド、Git コマンドを利用せずに容易にコンテナ上での開発・GUI ベースの Git 運用を実行できるようにし、効率良く DevOps を回せるようにする。これにより、開発者の開発効率の向上・新規参画者への引き継ぎ工数を最小現にすることができる。加えて、本検証のナレッジをまとめ、事業部展開することにより、事業部全体の開発力の向上にも貢献できると考えられる。

# 依頼

空き時間等にこれらの検証を行っても問題ないか
上記理由で、若干残業してしまっても問題ないか？（30~35 時間前後になる可能性はある）

# 確認したこと（現状）

VSCode-EC2 へのセキュアな接続
EC2 を利用して CodeCommit から Clone 可能なこと
EC2 を利用してコンテナ構築が可能なこと
現状のコードは実行可能であること
setting.yaml の設定
cleanup.sh の実行

# TODO（これから）

dev container の利用
jupyter の実行とかもこれで簡単に実行可能
VSCode のフォーマッター等の設定
setting.json の設定とか、チーム用に考える
VSCode の拡張機能インストール（選択してコード化）
手順書化
markdown で codecommit に展開

## 以下まとめておく

メリット、デメリット、コスト

## 止め忘れの仕組み

スケジューリング、lambda
https://dev.classmethod.jp/articles/how-to-use-vscode-remote-ssh-with-aws-systems-manager/
https://dev.classmethod.jp/articles/how-to-use-aws-cloud-9-with-vscode-remote-ssh/

---

## Zscaler CA 証明書のエクスポート

- コンピュータ証明書の管理 > 信頼されたルート証明機関 > 証明書
- Zscalar Root CA を左クリック > すべてのタスク > エクスポート
  - 証明書のエクスポートウィザードで、次へ > Base 64 encoded X.509 を選択して次へ
  - 参照 > ディレクトリ・ファイル名を入力（ここではファイル名を`zscalar_root_cacert.cer`とする）> 次へ > 完了 > OK
- 証明書を aws configure のに設定 (以下の`path\to\`には証明書を配置したディレクトリを入力)  
  ca_bundle = C:path\to\zscalar_root_cacert.cer

https://help.zscaler.com/ja/deception/exporting-root-ca-certificate-active-directory-certificate-service
