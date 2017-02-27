# -*- coding: utf-8 -*-
require 'slack'
require 'uri'
require 'cgi'
require 'json'
require 'httpclient'
require 'webrick'
require_relative '../config/environment'

module Plugin::Slack
  module API
    class Auth

      # TODO: 認証を開発者トークンとOAuthのどちらでもできるようにする
      def initialize(client)
        @client = client
      end


      # OAuth認証を行う
      # @return [Delayer::Deferred::Deferredable] なんかを引数にcallbackするDeferred
      # @see {https://api.slack.com/docs/oauth}
      def self.oauth
        Thread.new {
          client = HTTPClient.new
          query = {
            client_id: Plugin::Slack::Environment::SLACK_CLIENT_ID,
            scope: Plugin::Slack::Environment::SLACK_OAUTH_SCOPE,
            redirect_uri: Plugin::Slack::Environment::SLACK_REDIRECT_URI,
            state: Plugin::Slack::Environment::SLACK_OAUTH_STATE
          }.to_hash
          client.get(Plugin::Slack::Environment::SLACK_AUTHORIZE_URI, :query => query, 'Content-Type' => 'application/json')
        }.next { |response|
          Delayer::Deferred.fail(response) unless (response.status_code == 302)
          # OAuth認証用ページへのリダイレクトURL
          uri = redirect_uri(response.header['location'][0])
          # ブラウザで認証ページを開く
          Plugin.call(:open, uri)
          Thread.new {
            # WebRickでOAuthリダイレクト待ち受け
            @server = WEBrick::HTTPServer.new(Plugin::Slack::Environment::SLACK_SERVER_CONFIG)
            @server.mount_proc('/') do |_, res|
              Delayer::Deferred.fail(res) unless res.status == 200
              query = CGI.parse(res.request_uri.query)
              # ローカルのHTMLを表示
              res.body = open(File.join(Plugin::Slack::Environment::SLACK_DOCUMENT_ROOT, 'index.html'))
              res.content_type = 'text/html'
              res.chunked = true

              # アクセストークンの取得
              self.oauth_access(query['code'][0]).next { |token|
                @server.shutdown
              }.trap { |err| error err }
            end
            trap('INT') { @server.shutdown }
            @server.start
          }.trap { |err| error err }
        }
      end


      # 認証テスト
      # @return [Delayer::Deferred::Deferredable] 認証結果を引数にcallbackするDeferred
      def auth_test
        Thread.new { @client.auth_test }
      end


      private


      # OAuthのコールバックで得たcodeを用いてaccess_tokenを取得する
      # @param [String] code コールバックコード
      # @return [Delayer::Deferred::Deferredable] access_tokenを引数にcallbackするDeferred
      # @see {https://api.slack.com/methods/oauth.access}
      def self.oauth_access(code)
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
          UserConfig['slack_token'] = result[:access_token]
        }
      end


      def self.redirect_uri(uri)
        if uri.include?('https://slack.com')
          URI.decode(uri)
        else
          "https://slack.com#{URI.decode(uri)}"
        end
      end

    end
  end
end
