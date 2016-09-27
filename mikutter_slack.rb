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
    if auth['ok']
      Plugin.call(:slack_connected, auth)
    else
      Plugin.call(:slack_connection_failed, auth)
    end
  end


  # RTM 及び Events API のインスタンス
  RTM = Slack.realtime
  EVENTS = Slack::Client.new


  # ユーザーリストを取得
  def get_users_list(events)
    users = Hash[events.users_list['members'].map { |m| [m['id'], m['name']] }]
    return users end


  # チャンネルリストを取得
  def get_channel_list(events)
    channels = events.channels_list['channels']
    return channels end


  # 全てのチャンネルのヒストリを取得
  def get_all_channel_history(channel)
    users = get_users_list(client)
    messages = client.channels_history(channel: "#{channel['id']}")['messages']
    messages.each do |message|
      username = users[message['user']]
      print "@#{username} "
      puts message['text']
    end end


  # 指定したチャンネル名のチャンネルのヒストリを取得
  def get_channel_history(channel, name)
    if channel['name'] == name
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
    # user = Mikutter::Slack::User.new(idname: "#{users[data['user']]}",
    #                                  name: "#{users[data['user']]}",
    #                                  profile_image_url: get_icon(EVENTS, data['user']))
    user = Mikutter::System::User.new(idname: "#{users[data['user']]}",
                                      name: "#{users[data['user']]}",
                                      profile_image_url: get_icon(EVENTS, data['user']))
    timeline(:home_timeline) << Mikutter::System::Message.new(user: user,
                                                              description: "#{data['text']}")
  end


  Thread.new do
    RTM.start
  end

  defactivity 'slack_connection', 'Slack接続情報'

  # 実績
  # http://mikutter.blogspot.jp/2013/03/blog-post.html
  defachievement(:mikutter_slack_achieve,
                 description: '設定画面からSlackのトークンを設定しよう',
                 hint: "Slackのトークンを取得して設定しよう！\nhttps://api.slack.com/docs/oauth-test-tokens"
  ) do |achievement|
    token = UserConfig['mikutter_slack_token']
    unless token.empty? || token.nil?
      achievement.take! end end


  # mikutter設定画面
  # http://mikutter.blogspot.jp/2012/12/blog-post.html
  settings('Slack') do
    settings('Slack アカウント') do
      input 'メールアドレス', :mikutter_slack_email
      inputpass 'パスワード', :mikutter_slack_password
    end

    settings('開発') do
      input('トークン', :mikutter_slack_token)
    end end

  on_slack_connected do |auth|
    activity :slack_connection, "Slackチーム #{auth['team']} の認証に成功しました！"
  end

  on_slack_connection_failed do |auth|
    activity :slack_connection, "Slackチーム #{auth['team']} の認証に失敗しました！"
  end

end
