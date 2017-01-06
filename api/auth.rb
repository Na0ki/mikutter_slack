# -*- coding: utf-8 -*-
require 'slack'
require 'uri'
require 'httpclient'

module Plugin::Slack
  module API
    class Auth

      def initialize(client)
        @client = client
      end

      def oauth
        # TODO: localhostにサーバー待ち受けする
        Thread.new {
          client = HTTPClient.new
          query = {client_id: '43202035347.73645008566',
                   scope: 'client',
                   redirect_uri: 'http://localhost/',
                   state: 'mikutter_slack'}.to_hash
          client.get('https://slack.com/oauth/authorize', :query => query)
        }.next { |res|
          Delayer::Deferred.fail('Not Redirect') unless (res.status_code == 302)
          # OAuth認証用ページへのリダイレクトURL
          oauth_redirect_uri = res.header['location'][0]
          Plugin.call(:open, "https://slack.com#{URI.decode(oauth_redirect_uri)}")
        }.trap { |e| error e }
      end

      # 認証テスト
      # @return [Delayer::Deferred::Deferredable] 認証結果を引数にcallbackするDeferred
      def auth_test
        Thread.new { @client.auth_test }
      end

    end
  end
end
