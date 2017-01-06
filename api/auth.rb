# -*- coding: utf-8 -*-
require 'slack'
require 'uri'
require 'httpclient'
require 'webrick'

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
                   redirect_uri: 'http://localhost:8080/',
                   state: 'mikutter_slack'}.to_hash
          client.get('https://slack.com/oauth/authorize', :query => query)
        }.next { |res|
          Delayer::Deferred.fail(res) unless (res.status_code == 302)
          # OAuth認証用ページへのリダイレクトURL
          oauth_redirect_uri = res.header['location'][0]
          Plugin.call(:open, "https://slack.com#{URI.decode(oauth_redirect_uri)}")
          Thread.new {
            http = WEBrick::HTTPServer.new({:DocumentRoot => __dir__,
                                            :BindAddress => 'localhost',
                                            :Port => 8080
                                           })
            # FIXME: WebRickでアクセストークンを取得できるようにする
            http.mount_proc('/') do |request, response|
              p request
              p response
            end
            trap('INT') { http.stop }
            http.start
          }.next { |_|
            # Delayer::Deferred.fail(response) unless (response.nil? or response&.status_code == 200)
            p _
          }
        }.trap { |e| error e }
      end

      # 認証テスト
      # @return [Delayer::Deferred::Deferredable] 認証結果を引数にcallbackするDeferred
      def auth_test
        oauth
        Thread.new { @client.auth_test }
      end

    end
  end
end
