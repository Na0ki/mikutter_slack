# -*- coding: utf-8 -*-
require_relative 'object'

module Plugin::Slack
  module API

    # メッセージ投稿
    class Message < Object
      # メッセージの投稿
      # @param [String] channel チャンネル名
      # @param [String] text 投稿メッセージ
      def post(channel, text)
        Thread.new do
          api.client.chat_postMessage(channel: channel, text: text, as_user: true)
        end
      end

    end

  end
end
