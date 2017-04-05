# -*- coding: utf-8 -*-
# -*- frozen_string_literal: true -*-

# apaではない
require 'slack'
require_relative 'api/auth'
require_relative 'api/realtime'
require_relative 'api/user'
require_relative 'api/channel/public'
require_relative 'api/channel/private'
require_relative 'api/emoji'

module Plugin::Slack
  module API
    # API の親クラス
    class APA
      attr_reader :client

      # @param [String] token APIトークン
      def initialize(token)
        @client = Slack::Client.new(token: token)
      end

      # Realtime APIに接続する
      def realtime_start
        @realtime ||= Plugin::Slack::Realtime.new(self).start
      end

      # チームを取得する
      # 一度でもTeamの取得に成功すると、二度目以降はその内容を返す
      #
      # @return [Delayer::Deferred::Deferredable] Teamを引数にcallbackするDeferred
      def team
        Thread.new { team! }
      end

      def users
        @users ||= Users.new(self)
      end

      def channel
        # @channel ||=
      end

      def public_channel
        @public_channel ||= PublicChannel.new(self)
      end

      def private_channel
        @private_channel ||= PrivateChannel.new(self)
      end

      def message
        @message ||= Message.new(self)
      end

      def emoji
        @emoji ||= Emoji.new(self)
      end

      private

      memoize def team!
        Plugin::Slack::Team.new(@client.team_info['team'].symbolize.merge(api: self))
      end
    end
  end
end
