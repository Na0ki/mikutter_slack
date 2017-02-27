# -*- coding: utf-8 -*-
require 'slack'
require_relative 'object'

module Plugin::Slack
  module API

    class Emoji < Object

      # Emojiリストの取得
      # @return [Delayer::Deferred::Deferredable] 絵文字リストを引数にcallbackするDeferred
      def list
        Thread.new { api.client.emoji_list }
      end
    end

  end
end
