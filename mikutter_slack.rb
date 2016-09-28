# -*- coding: utf-8 -*-
require 'slack'
require_relative 'retriever'

Plugin.create(:mikutter_slack) do

  filter_extract_datasources do |ds|
    [ds.merge(mikutter_slack: 'slack')]
  end

  # 認証テスト
  def auth_test
    auth = Slack.auth_test
    if auth['ok']
      Plugin.call(:slack_connected, auth)
    else
      Plugin.call(:slack_connection_failed, auth)
    end
    return auth['ok'] end


  # ユーザーリストを取得
  # @param [Slack::Client] events APIのインスタンス(EVENTS)
  # @return [Array] ユーザーリスト
  def users(events)
    users = Hash[events.users_list['members'].map { |m| [m['id'], m['name']] }]
    return users end


  # チャンネルリスト取得変えす
  # @param [Slack::Client] events APIのインスタンス(EVENTS)
  # @return [Array] channels チャンネル一覧
  def channels(events)
    channels = events.channels_list['channels']
    return channels end


  # 全てのチャンネルのヒストリを取得
  def all_channel_history
    channel = channels(EVENTS)
    users = users(EVENTS)
    messages = client.channels_history(channel: "#{channel['id']}")['messages']
    messages.each do |message|
      username = users[message['user']]
      print "@#{username} "
      puts message['text']
    end end


  # 指定したチャンネル名のチャンネルのヒストリを取得
  def channel_history(events ,channel, name)
    if channel['name'] == name
      users = users(events)
      messages = events.channels_history(channel: "#{channel['id']}")['messages']
      messages.each do |message|
        username = users[message['user']]
        print "@#{username} "
        puts message['text']
      end
      Plugin.call(:appear, messages)
      Plugin.call(:extract_receive_message, :mikutter_slack, messages)
    end end


  # Emojiリストの取得
  def emoji_list(events)
    return events.emoji_list
  end


  # ユーザのアイコンを取得
  def get_icon(events, id)
    events.users_list['members'].each { |u|
      if u['id'] == id
        return u.dig('profile', 'image_48')
      end
    }
    return Skin.get('icon.png') end


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
    auth_test
    # channel_history(EVENTS, channels(EVENTS), 'mikutter')
  end


  # メッセージ書き込み時に呼ばれる
  RTM.on :message do |data|
    users = users(EVENTS)

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


  # 接続時
  on_slack_connected do |auth|
    activity :slack_connection, "Slackチーム #{auth['team']} の認証に成功しました！"
  end


  # 接続失敗時
  on_slack_connection_failed do |auth|
    activity :slack_connection, "Slackチーム #{auth['team']} の認証に失敗しました！"
  end

end
