# -*- coding: utf-8 -*-
require 'slack'

module Plugin::Slack
  class SlackAPI
    class << self

      def oauth(events, options)
        Thread.new do
          events.oauth_access(options)
        end
      end

      # トークンによる認証
      # @param [String] token 認証トークン
      # @return [Delayer::Deferred::Deferredable] 認証結果を引数にcallbackするDeferred
      def auth(token)
        Thread.new {
          unless token.empty? || token == nil?
            Slack.configure do |config|
              config.token = token
            end
          end
        }
      end

      # 認証テスト
      # @return [Delayer::Deferred::Deferredable] 認証結果を引数にcallbackするDeferred
      def auth_test
        Thread.new do
          Slack.auth_test
        end
      end

    end
  end
end
