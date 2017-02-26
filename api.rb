# -*- coding: utf-8 -*-
# apaではない
require 'slack'
require_relative 'api/auth'
require_relative 'api/realtime'
require_relative 'api/user'
require_relative 'api/channel'

module Plugin::Slack
  module API
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
      # @return [Delayer::Deferred::Deferredable] Teamを引数にcallbackするDeferred
      def team
        Thread.new { team! }
      end

      def users
        @users ||= Users.new(self)
      end

      def channel
        @channel ||= Channel.new(self)
      end

      #
      # 工事中
      #

      # TODO: Plugin::Slack::Message に移行する
      # メッセージの投稿
      # @param [String] channel チャンネル名
      # @param [String] text 投稿メッセージ
      def post_message(channel, text)
        option = {channel: channel, text: text, as_user: true}
        Thread.new { @client.chat_postMessage(option) }
      end


      private

      memoize def team!
        Plugin::Slack::Team.new(@client.team_info['team'].symbolize.merge(api: self))
      end

    end
  end
end
