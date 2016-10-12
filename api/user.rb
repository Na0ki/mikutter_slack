# -*- coding: utf-8 -*-
require 'slack'

module Plugin::Slack
  class User

    def initialize(client)
      @client = client
    end

    # ユーザーリストを取得
    # @return [Delayer::Deferred::Deferredable] チームの全ユーザを引数にcallbackするDeferred
    def users_list
      Thread.new do
        @client.users_list['members'].map { |m|
          Plugin::Slack::User.new(m.symbolize)
        }
      end
    end


    def bots_list
      Thread.new do
        @client.bots_info
      end
    end

  end
end
