# -*- coding: utf-8 -*-
require 'slack'

module Plugin::Slack
  class API
    def oauth(options)
      Thread.new do
        @client.oauth_access(options)
      end
    end

    # 認証テスト
    # @return [Delayer::Deferred::Deferredable] 認証結果を引数にcallbackするDeferred
    def auth_test
      Thread.new do
        @client.auth_test
      end
    end

  end
end
