# -*- coding: utf-8 -*-
# -*- frozen_string_literal: true -*-

require 'slack'
require 'uri'
require 'cgi'
require 'json'
require 'httpclient'
require 'webrick'
require_relative '../config/environment'

module Plugin::Slack
  module API
    # 認証
    class Auth
      def initialize(client)
        @client = client
      end

      # OAuth認証を行う
      #
      # @return [Delayer::Deferred::Deferredable] なんかを引数にcallbackするDeferred
      # @see {https://api.slack.com/docs/oauth}
      def self.oauth
        request_authorize_url.next { |url|
          Plugin.call(:open, url)
        }
      end

      class << self
        # 認証用のURLを取得するDeferredを生成して返す
        def request_authorize_url
          Thread.new {
          client = HTTPClient.new
          client.get(Plugin::Slack::Environment::SLACK_AUTHORIZE_URI,
                     :query => {
                       client_id: Plugin::Slack::Environment::SLACK_CLIENT_ID,
                       scope: Plugin::Slack::Environment::SLACK_OAUTH_SCOPE,
                       redirect_uri: Plugin::Slack::Environment::SLACK_REDIRECT_URI,
                       state: Plugin::Slack::Environment::SLACK_OAUTH_STATE
                     },
                     'Content-Type' => 'application/json')
          }.next { |response|
            Delayer::Deferred.fail(response) unless response.status_code == 302
            Plugin.call(:slack_boot_callback_server)
            redirect_uri(response.header['location'][0])
          }
        end

        # OAuthのコールバックで得たcodeを用いてaccess_tokenを取得する
        #
        # @param [String] code コールバックコード
        # @return [Delayer::Deferred::Deferredable] access_tokenを引数にcallbackするDeferred
        # @see {https://api.slack.com/methods/oauth.access}
        def oauth_access(code)
          Thread.new(code) { |c|
            client = HTTPClient.new
            query = {
              client_id: Plugin::Slack::Environment::SLACK_CLIENT_ID,
              client_secret: Plugin::Slack::Environment::SLACK_CLIENT_SECRET,
              code: c,
              redirect_uri: Plugin::Slack::Environment::SLACK_REDIRECT_URI
            }.to_hash
            client.get(Plugin::Slack::Environment::SLACK_OAUTH_ACCESS_URI, :query => query, 'Content-Type' => 'application/json')
          }.next { |response|
            Delayer::Deferred.fail(response) unless response.status_code == 200
            result = JSON.parse(response.body, symbolize_names: true)
            Delayer::Deferred.fail(result[:error]) unless result[:ok]
            notice "scope: #{result[:scope]}, user_id: #{result[:user_id]}, team_name: #{result[:team_name]}, team_id: #{result[:team_id]}"
            result[:access_token]
          }
        end

        def redirect_uri(uri)
          if uri.include?('https://slack.com')
            URI.decode(uri)
          else
            "https://slack.com#{URI.decode(uri)}"
          end
        end

        def boot_callback_server
          Thread.new {
            # WebRickでOAuthリダイレクト待ち受け
            @server = WEBrick::HTTPServer.new(Plugin::Slack::Environment::SLACK_SERVER_CONFIG)
            @server.mount_proc('/') do |_, res|
              next unless res.status == 200
              query = CGI.parse(res.request_uri.query)
              # ローカルのHTMLを表示
              res.body = open(File.join(Plugin::Slack::Environment::SLACK_DOCUMENT_ROOT, 'index.html'))
              res.content_type = 'text/html'
              res.chunked = true

              # アクセストークンの取得
              oauth_access(query['code'][0]).next { |token|
                UserConfig['slack_token'] = token
                @server.shutdown
              }.trap { |err| error err }
            end
            trap('INT') { @server.shutdown }
            @server.start
          }.trap { |err| error err }
        end
      end

      # 認証テスト
      #
      # @return [Delayer::Deferred::Deferredable] 認証結果を引数にcallbackするDeferred
      def auth_test
        Thread.new { @client.auth_test }
      end

    end
  end
end
