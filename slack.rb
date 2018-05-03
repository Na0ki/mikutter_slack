# -*- frozen_string_literal: true -*-

require 'slack'
require_relative 'model'
require_relative 'api'
require_relative 'config/environment'

Plugin.create(:slack) do
  def start_realtime
    api = Plugin::Slack::API::APA.new(UserConfig['slack_token'])
    api.team.next { |team|
      @team = team
      # RTM 開始
      api.realtime_start
    }.trap { |err| error err }
  end

  require_relative 'apimiku/apimiku'

  # slack api インスタンス作成
  start_realtime
end
