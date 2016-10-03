# -*- coding: utf-8 -*-
require 'slack'
require_relative 'model'

Plugin.create(:mikutter_slack) do

  # 抽出データソース
  # @see https://toshia.github.io/writing-mikutter-plugin/basis/2016/09/20/extract-datasource.html
  filter_extract_datasources do |ds|
    [{mikutter_slack: 'slack'}.merge(ds)]
  end


  # トークンを設定
  token = UserConfig['mikutter_slack_token']
  unless token.empty? || token == nil?
    Slack.configure do |config|
      config.token = token
    end end


  # RTM 及び Events API のインスタンス
  RTM = Slack.realtime
  EVENTS = Slack::Client.new


  # 接続時に呼ばれる
  RTM.on :hello do
    puts 'Successfully connected.'
    puts "Slack Auth Test Result: #{Plugin::Slack::SlackAPI.auth_test}"
  end


  # メッセージ書き込み時に呼ばれる
  RTM.on :message do |data|

    Thread.new {
      Plugin::Slack::SlackAPI.users(EVENTS)
    }.next { |users|
      Plugin::Slack::User.new(idname: "#{users[data['user']]}",
                              name: "#{users[data['user']]}",
                              profile_image_url: Plugin::Slack::SlackAPI.get_icon(EVENTS, data['user']))
    }.next { |user|
      Plugin::Slack::Message.new(channel: 'test',
                                 user: user,
                                 text: "#{data['text']}",
                                 created: Time.at(Float(data['ts']).to_i),
                                 team: 'test')
    }.next { |message|
      Plugin.call(:extract_receive_message, :mikutter_slack, [message])
    }.trap { |err|
      error err
    }

  end


  Thread.new {
    # RTMに接続開始
    RTM.start
  }.trap { |err|
    error err
  }

  defactivity 'slack_connection', 'Slack接続情報'

  # 実績設定
  # @see http://mikutter.blogspot.jp/2013/03/blog-post.html
  defachievement(:mikutter_slack_achieve,
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
      input 'メールアドレス', :mikutter_slack_email
      inputpass 'パスワード', :mikutter_slack_password
    end

    settings('開発') do
      input('トークン', :mikutter_slack_token)
    end end


  # 接続時
  on_slack_connected do |auth|
    activity :slack_connection, "Slackチーム #{auth['team']} の認証に成功しました！"
  end


  # 接続失敗時
  on_slack_connection_failed do |auth|
    activity :slack_connection, "Slackチーム #{auth['team']} の認証に失敗しました！"
  end

end
