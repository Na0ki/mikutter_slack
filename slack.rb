# -*- coding: utf-8 -*-
require 'slack'
require_relative 'model'

Plugin.create(:slack) do

  # 抽出データソース
  # @see https://toshia.github.io/writing-mikutter-plugin/basis/2016/09/20/extract-datasource.html
  filter_extract_datasources do |ds|
    [{slack: 'slack'}.merge(ds)]
  end


  # トークンを設定
  token = UserConfig['slack_token']
  unless token.empty? || token == nil?
    Slack.configure do |config|
      config.token = token
    end
  end


  # RTM 及び Events API のインスタンス
  RTM = Slack.realtime
  EVENTS = Slack::Client.new


  # 接続時に呼ばれる
  RTM.on :hello do
    puts 'Successfully connected.'
    auth_result = Plugin::Slack::SlackAPI.auth_test
    puts "Slack Auth Test Result: #{auth_result ? '成功' : '失敗'}"
    if auth_result
      histories = Plugin::Slack::SlackAPI.channel_history(EVENTS, Plugin::Slack::SlackAPI.channels(EVENTS), 'mikutter')
      histories['messages'].each do |history|
        Thread.new {
          Plugin::Slack::SlackAPI.users(EVENTS)
        }.next { |users|
          [Plugin::Slack::SlackAPI.get_icon(EVENTS, history['user']), users]
        }.next { |icon, users|
          Plugin::Slack::User.new(idname: "#{users[history['user']]}",
                                  name: "#{users[history['user']]}",
                                  profile_image_url: icon)
        }.next { |user|
          Plugin::Slack::Message.new(channel: 'mikutter',
                                     user: user,
                                     text: "#{history['text']}",
                                     created: Time.at(Float(history['ts']).to_i),
                                     team: 'ahiru3net')
        }.next { |message|
          Plugin.call :extract_receive_message, :slack, [message]
        }.trap { |err|
          error err
        }
      end
    end
  end


  # メッセージ書き込み時に呼ばれる
  # @param [Hash] data メッセージ
  # Thread に関しては以下を参考
  # @see https://github.com/toshia/delayer-deferred
  RTM.on :message do |data|
    # 起動時間より前のタイムスタンプの場合は何もしない（ヒストリからとってこれる）
    # 起動時に最新の一件の投稿が呼ばれるが、その際に on :message が呼ばれてしまうのでその対策
    # @defined_time は {https://github.com/toshia/pluggaloid/blob/master/lib/pluggaloid/plugin.rb#L96} で定義済み
    next unless @defined_time < Time.at(Float(data['ts']).to_i)
    # 投稿内容が空の場合はスキップ
    next if data['text'].empty?

    # メッセージの処理
    Thread.new {
      # ユーザー一覧取得
      Plugin::Slack::SlackAPI.users(EVENTS)
    }.next { |users|
      # User オブジェクト作成
      Plugin::Slack::User.new(idname: "#{users[data['user']]}",
                              name: "#{users[data['user']]}",
                              profile_image_url: Plugin::Slack::SlackAPI.get_icon(EVENTS, data['user']))
    }.next { |user|
      # Message オブジェクト作成
      Plugin::Slack::Message.new(channel: 'test',
                                 user: user,
                                 text: "#{data['text']}",
                                 created: Time.at(Float(data['ts']).to_i),
                                 team: 'test')
    }.next { |message|
      # データソースにメッセージを投稿
      Plugin.call(:extract_receive_message, :slack, [message])
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
