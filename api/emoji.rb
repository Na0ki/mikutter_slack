# -*- coding: utf-8 -*-
require 'slack'

module Plugin::Slack
  module API
    class Emoji

      def initialize(client)
        @client = client
      end


      # Emojiリストの取得
      # @return [Delayer::Deferred::Deferredable] 絵文字リストを引数にcallbackするDeferred
      def emoji_list
        Thread.new { @client.emoji_list }
      end
    end

  end
end
