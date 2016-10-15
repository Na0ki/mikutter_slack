# -*- coding: utf-8 -*-
require 'slack'
require_relative 'model'
require_relative 'api'

Plugin.create(:slack) do

  # slack api インスタンス作成
  slack_api = Plugin::Slack::API.new(UserConfig['slack_token'])
  # RTM 開始
  slack_api.realtime_start

  # Activity の設定
  defactivity 'slack_connection', 'Slack接続情報'


  # 抽出データソース
  # @see https://toshia.github.io/writing-mikutter-plugin/basis/2016/09/20/extract-datasource.html
  Thread.new {
    slack_api.channels.next { |channels|
      list = Hash.new
      channels.each do |channel|
        list["slack_#{channel.team.id}_#{channel.id}"] = ['slack', channel.team.name, channel.name]
      end
      list
    }
  }.next { |list|
    filter_extract_datasources do |ds|
      [list.symbolize.merge(ds)]
    end
  }

  # 実績設定
  # @see http://mikutter.blogspot.jp/2013/03/blog-post.html
  defachievement(:slack_achieve,
                 description: '設定画面からSlackのトークンを設定しよう',
                 hint: "Slackのトークンを取得して設定しよう！\nhttps://api.slack.com/docs/oauth-test-tokens"
  ) do |achievement|
    on_slack_connected do |auth|
      achievement.take!
    end
  end


  # mikutter設定画面
  # @see http://mikutter.blogspot.jp/2012/12/blog-post.html
  settings('Slack') do
    settings('Slack アカウント') do
      input 'メールアドレス', :slack_email
      inputpass 'パスワード', :slack_password
    end

    settings('開発') do
      input('トークン', :slack_token)
    end
  end


  # 接続時
  on_slack_connected do |auth|
    activity :slack_connection, "Slackチーム #{auth['team']} の認証に成功しました！"
  end


  # 接続失敗時
  on_slack_connection_failed do |auth|
    activity :slack_connection, "Slackチーム #{auth['team']} の認証に失敗しました！"
  end

end
