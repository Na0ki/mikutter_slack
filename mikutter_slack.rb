# -*- coding: utf-8 -*-
require 'slack'
require 'yaml'

Plugin.create(:mikutter_slack) do

  DEFINED_TIME = Time.new.freeze.to_f

  # conf.yml からトークンを取得
  begin
    TOKEN = YAML.load_file(File.join(__dir__, 'conf.yml'))
  rescue LoadError
    notice 'Could not load conf file'
  end

  # トークンを設定
  Slack.configure do |config|
    config.token = TOKEN['auth']['token']
  end

  # DEBUG
  p Slack.auth_test

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
    p get_users_list(EVENTS)
    p get_channel_list(EVENTS)
    p DEFINED_TIME
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
    p data
    if DEFINED_TIME < data['ts'].to_f
      Service.primary.post(:message => "#{data['text']}")
    end
  end

  Thread.new do
    RTM.start
  end

end
