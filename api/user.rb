# -*- coding: utf-8 -*-
require 'slack'

module Plugin::Slack
  module API

    class Users

      def initialize(client)
        @client = client
      end

      # ユーザーリストを取得
      # @return [Delayer::Deferred::Deferredable] チームの全ユーザを引数にcallbackするDeferred
      def list
        Thread.new { @client.users_list['members'].map { |m| Plugin::Slack::User.new(m.symbolize) } }
      end


      def bots
        Thread.new { @client.bots_info }
      end

    end

  end
end
