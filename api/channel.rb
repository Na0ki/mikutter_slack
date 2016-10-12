# -*- coding: utf-8 -*-
require 'slack'

module Plugin::Slack
  module API
    class Channel

      def initialize(client)
        @client = client
      end

      # チャンネルリスト返す
      # @return [Delayer::Deferred::Deferredable] チャンネル一覧
      def list
        Thread.new do
          @client.channels_list['channels']
        end
      end


      # 全てのチャンネルのヒストリを取得
      # @return [Delayer::Deferred::Deferredable] channels_history チャンネルのヒストリを引数にcallbackするDeferred
      # @see https://github.com/aki017/slack-api-docs/blob/master/methods/channels.history.md
      def all_history
        Thread.new do
          list.next { |channel|
            @client.channels_history(channel: "#{channel['id']}")['messages']
          }
        end
      end


      # 指定したチャンネル名のチャンネルのヒストリを取得
      # @param [String] name 取得したいチャンネル名
      # @return [Delayer::Deferred::Deferredable] channels_history チャンネルのヒストリを引数にcallbackするDeferred
      # @see https://github.com/aki017/slack-api-docs/blob/master/methods/channels.history.md
      def history(name)
        Thread.new do
          channel = list.find { |c| c['name'] == name }
          @client.channels_history(channel: "#{channel['id']}")['messages']
        end
      end

    end
  end
end
