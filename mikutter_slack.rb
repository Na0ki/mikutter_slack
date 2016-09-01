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

  p Slack.auth_test

  # RTM(Real Time Messaging)に接続
  client = Slack.realtime
  event = Slack::Client.new

  p client
  p event

  # Get users list
  def get_users_list(c)
    users = Hash[c.users_list['members'].map { |m| [m['id'], m['name']] }]
    return users
  end


  # Get channels list
  def get_channel_list(c)
    channels = c.channels_list['channels']
    return channels
  end

  client.on :hello do
    puts 'Successfully connected.'
    p get_users_list(event)
    p get_channel_list(event)
    p DEFINED_TIME
  end


  client.on :message do |data|
    p data
    if DEFINED_TIME < data['ts'].to_f
      Service.primary.post(:message => "#{data['text']}")
    end
  end

  client.start

  # RTM.start_async do
  #   RTM.on :message do |data|
  #     puts data
  #
  #     text = ''
  #
  #     if data['text'].include?('ておくれ')
  #       text = 'としぁ'
  #       RTM.message channel: data['channel'], text: text
  #     end
  #     if data['text'].include?('おるみん')
  #       text = '大破'
  #       RTM.message channel: data['channel'], text: text
  #     end
  #     if data['text'].include?('eject')
  #       text = '(☝ ՞ਊ ՞)☝ウイーン'
  #       RTM.message channel: data['channel'], text: text
  #     end
  #
  #     Service.primary.post(:message => "#{data.text}#{text}", :system => true)
  #   end
  # end
  #
  # RTM.on :hello do
  #   puts 'connected!'
  #   # RTM.message channel: 'C25K3E94J', text: 'connected!'
  # end


  # users = get_users_list(client)
  # channels = get_channel_list(client)
  #
  #
  # channels.each do |channel|
  #   c_name = channel['name']
  #   if c_name == 'mikutter'
  #     puts "- id: #{channel['id']}, name: #{channel['name']}"
  #     # Get channel history
  #     messages = client.channels_history(channel: "#{channel['id']}")['messages']
  #     messages.each do |message|
  #       username = users[message['user']]
  #       print "@#{username} "
  #       puts message['text']
  #     end
  #   end
  # end
end
