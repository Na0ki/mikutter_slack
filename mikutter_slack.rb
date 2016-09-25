# -*- coding: utf-8 -*-
require 'slack'

Plugin.create(:mikutter_slack) do

  DEFINED_TIME = Time.new.freeze

  # トークンを設定
  token = UserConfig['mikutter_slack_token']
  unless token.empty? || token == nil?
    Slack.configure do |config|
      config.token = token
    end
  end


  # 認証テスト
  def auth_test
    auth = Slack.auth_test
    result = auth['ok'] ? '成功' : '失敗'
    timeline(:home_timeline) << Mikutter::System::Message.new(description: "Slackチーム #{auth['team']} の認証に#{result}しました！\n")
  end


  # RTM 及び Events API のインスタンス
  # RTM API: https://api.slack.com/faq#real_time_messaging_api
  # Events API: https://api.slack.com/faq#events_api
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
  #{
  #   "id"=>"CHANNEL_ID",
  #   "name"=>"CHANNEL_NAME",
  #   "is_channel"=>BOOLEAN,
  #   "created"=>UNIX_TIME,
  #   "creator"=>"USER_ID",
  #   "is_archived"=>BOOLEAN,
  #   "is_general"=>BOOLEAN,
  #   "is_member"=>BOOLEAN,
  #   "members"=>["USER_ID"],
  #   "topic"=>{
  #     "value"=>"",
  #     "creator"=>"",
  #     "last_set"=>0},
  #     "purpose"=>{
  #       "value"=>"mikutterでslack",
  #       "creator"=>"USER_ID",
  #       "last_set"=>UNIX_TIME
  #     },
  #   "num_members"=>1
  #}
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

  def get_emoji_list
    return EVENTS.emoji_list
  end

  def get_icon(events, id)
    events.users_list['members'].each { |u|
      if u['id'] == id
        return u.dig('profile', 'image_48')
      end
    }
    return Skin.get('icon.png')
  end


  # 接続時に呼ばれる
  # 接続時に以下のようにチャンネルの最後のメッセージが呼ばれる
  #{
  #   "reply_to"=>6642,
  #   "type"=>"message",
  #   "channel"=>"CHANNEL_ID",
  #   "user"=>"USER_ID",
  #   "text"=>"テストメッセージ",
  #   "ts"=>"1472728555.000003"
  # }
  RTM.on :hello do
    puts 'Successfully connected.'
    auth_test
    # p get_users_list(EVENTS)
    # p get_channel_list(EVENTS)
  end


  # メッセージ書き込み時に呼ばれる
  #{
  #   "type"=>"TYPE",
  #   "channel"=>"CHANNEL_ID",
  #   "user"=>"USER_ID",
  #   "text"=>"MESSAGE",
  #   "ts"=>"UNIX_TIME_FLOAT",
  #   "team"=>"TEAM_ID"
  # }
  RTM.on :message do |data|
    users = get_users_list(EVENTS)
    user = Mikutter::System::User.new(idname: "#{users[data['user']]}",
                                      name: "#{users[data['user']]}",
                                      profile_image_url: get_icon(EVENTS, data['user']))
    timeline(:home_timeline) << Mikutter::System::Message.new(user: user,
                                                              description: "#{data['text']}")
  end

  Thread.new do
    RTM.start
  end


  # コメントイン非推奨メソッド
  # on_appear do |ms|
  #   ms.each do |m|
  #     puts m.to_s
  #     if  m[:created] > DEFINED_TIME
  #       params = {
  #           channel: 'mikutter',
  #           text: m.to_s
  #       }
  #       EVENTS.chat_postMessage params
  #     end
  #   end
  # end

  # 設定画面
  settings 'Slack' do
    settings 'Slack アカウント' do
      input 'メールアドレス', :mikutter_slack_email
      inputpass 'パスワード', :mikutter_slack_password
    end

    settings '開発' do
      input 'トークン', :mikutter_slack_token
    end

  end

end
