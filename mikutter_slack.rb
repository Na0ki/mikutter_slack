# -*- coding: utf-8 -*-
require 'slack'
require_relative 'retriever'

Plugin.create(:mikutter_slack) do

  filter_extract_datasources do |ds|
    [ds.merge(mikutter_slack: 'Slack')]
  end


  DEFINED_TIME = Time.new.freeze

  # トークンを設定
  token = UserConfig['mikutter_slack_token']
  unless token.empty? || token == nil?
    Slack.configure do |config|
      config.token = token
    end
  end


  def initialize

  end


  # 認証テスト
  def auth_test
    auth = Slack.auth_test
    result = auth['ok'] ? '成功' : '失敗'
    timeline(:home_timeline) << Mikutter::System::Message.new(description: "Slackチーム #{auth['team']} の認証に#{result}しました！\n")
  end


  # RTM 及び Events API のインスタンス
  RTM = Slack.realtime
  EVENTS = Slack::Client.new


  # Get users list
  def get_users_list(events)
    users = Hash[events.users_list['members'].map { |m| [m['id'], m['name']] }]
    return users end


  # Get channels list
  def get_channel_list(events)
    channels = events.channels_list['channels']
    return channels end


  # Get channel history
  def get_channel_history(channel)
    users = get_users_list(client)
    # TODO: テスト用のコードのため要修正
    if channel['name'] == 'mikutter'
      messages = client.channels_history(channel: "#{channel['id']}")['messages']
      messages.each do |message|
        username = users[message['user']]
        print "@#{username} "
        puts message['text']
      end
    end end


  # Emojiリストの取得
  def get_emoji_list
    return EVENTS.emoji_list
  end


  # ユーザのアイコンを取得
  def get_icon(events, id)
    events.users_list['members'].each { |u|
      if u['id'] == id
        return u.dig('profile', 'image_48')
      end
    }
    return Skin.get('icon.png') end


  # 接続時に呼ばれる
  RTM.on :hello do
    puts 'Successfully connected.'
    auth_test end


  # メッセージ書き込み時に呼ばれる
  RTM.on :message do |data|
    users = get_users_list(EVENTS)

    # TODO: モデルでこの部分を調整する
    user = Mikutter::System::User.new(idname: "#{users[data['user']]}",
                                      name: "#{users[data['user']]}",
                                      profile_image_url: get_icon(EVENTS, data['user']))
    timeline(:home_timeline) << Mikutter::System::Message.new(user: user,
                                                              description: "#{data['text']}")
  end

  Thread.new do
    RTM.start
  end


  # mikutter設定画面
  settings 'Slack' do
    settings 'Slack アカウント' do
      input 'メールアドレス', :mikutter_slack_email
      inputpass 'パスワード', :mikutter_slack_password
    end

    settings '開発' do
      input 'トークン', :mikutter_slack_token
    end end

end
