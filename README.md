# mikutter_slack
Slack for mikutter


## これなん
mikutter で Slack が使えてしまうやつ（を目指してます）


## インストール方法
以下のコマンドをターミナルで実行し、mikutterを再起動してください。
```
$ mkdir -p ~/.mikutter/plugin
$ cd ~/.mikutter/plugin
$ git clone https://github.com/Na0ki/mikutter_slack.git slack
```

## 使い方
1. 設定から「抽出タブ」を選択し、追加を押す。
1. 適当な名前を入れ、「OK」を押す。
1. 作った抽出タブを選択し、編集を押す。
1. データソースの「slack」にチェックを入れ、閉じる。
1. 設定からslackの認証設定をしたらmikutterを再起動して完了です。


## 認証の仕方
1. https://api.slack.com/web にアクセスし、 *Generate test token* をクリックします。
1. アクセス権を与えたいチームの行の *create token* をクリックします。
1. *confirm* をクリックします。
1. *Token* の列に表示されているテキストをコピーします。
1. mikutterを起動し、Slackの設定の「開発」の *トークン* に上記トークンをコピーします。
1. mikutterを再起動すれば認証がされます。


## 開発に関するWiki
1. [mikutter_slack Wiki](https://github.com/Na0ki/mikutter_slack/wiki)


# システム要件
| name      |      version  |  
|:----------|--------------:|
|mikutter   | 3.5.0-develop |
