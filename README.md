# mikutter_slack
Slack for mikutter


## これなん
mikutter で Slack が使えてしまうやつ（を目指してます）


## インストール方法
1. 以下のコマンドをターミナルで実行してください。
    ```
    $ mkdir -p ~/.mikutter/plugin
    $ cd ~/.mikutter/plugin
    $ git clone https://github.com/Na0ki/mikutter_slack.git slack
    ```

1. Gemに依存しているので、mikutterのディレクトリにいき、以下のコマンドを実行してください。
    ```
    $ bundle install
    ```

1. mikutterを再起動してください。


## 認証
* 認証の方法（OAuth）
    1. slackの設定を開き、「認証する」ボタンをクリックします。
    1. ブラウザが開くので、認証するチームを選択の上、アクセスの許可をしてください。
    1. 認証が成功すると、ブラウザのタブを閉じmikutterに戻るよう指示するページが表示されます。  
    指示に従いmikutterに戻って下さい。
    1. 引き続き抽出タブの設定に進んでください。

* 認証の方法（開発者向け）
    1. https://api.slack.com/web にアクセスし、 *Generate test token* をクリックします。
    1. アクセス権を与えたいチームの行の *create token* をクリックします。
    1. *confirm* をクリックします。
    1. *Token* の列に表示されているテキストをコピーします。
    1. mikutterを起動し、Slackの設定の「開発」の *トークン* に上記トークンをコピーします。
    1. mikutterを再起動すれば認証がされます。
    1. 引き続き抽出タブの設定に進んでください。


## 使い方
1. 設定から「抽出タブ」を選択し、追加をクリックしてください。
1. 適当な名前を入れ、「OK」をクリックしてください。
1. 作った抽出タブを選択し、「編集」をクリックしてください。
1. データソースの「slack」にチェックを入れ、閉じてください。
1. 設定からslackの認証設定をしたらmikutterを再起動して完了です。


## 開発に関するWiki
* [mikutter_slack Wiki](https://github.com/Na0ki/mikutter_slack/wiki)


## システム要件
*要件を満たしているなら動くとは言っていない*  
推奨バージョンはmikutterのgitリポジトリの最新のdevelopブランチです。  
developブランチ以外では動作しません。  
mikutterのgitリポジトリURLはこちら -> git://toshia.dip.jp/mikutter.git

| name      |      version  |
|:----------|--------------:|
|mikutter   | 3.6.0-develop |
|ruby       |         2.3.0 |


## ライセンス
[MIT LICENSE](/LICENSE)
