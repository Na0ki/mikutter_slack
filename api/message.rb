# -*- coding: utf-8 -*-

module Plugin::Slack
  module API

    # メッセージ投稿
    class Message

      # メッセージの投稿
      # @param [String] channel チャンネル名
      # @param [String] text 投稿メッセージ
      def post(channel, text)
        option = {channel: channel, text: text, as_user: true}
        Thread.new { @client.chat_postMessage(option) }
      end

    end

  end
end
