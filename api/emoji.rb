# -*- frozen_string_literal: true -*-

require 'slack'
require_relative 'object'

module Plugin::Slack
  module API
    # 絵文字取得API
    class Emoji < Object
      # Emojiリストの取得
      #
      # @return [Delayer::Deferred::Deferredable] 絵文字リストを引数にcallbackするDeferred
      def list
        Thread.new { api.client.emoji_list['emoji'] }
      end
    end
  end
end
