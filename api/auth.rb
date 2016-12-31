# -*- coding: utf-8 -*-
require 'slack'

module Plugin::Slack
  module API
    class Auth

      def initialize(client)
        @client = client
      end

      def oauth(options)
        Thread.new { @client.oauth_access(options) }
      end

      # 認証テスト
      # @return [Delayer::Deferred::Deferredable] 認証結果を引数にcallbackするDeferred
      def auth_test
        Thread.new { @client.auth_test }
      end

    end
  end
end
