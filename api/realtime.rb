# -*- frozen_string_literal: true -*-

module Plugin::Slack
  # RTM API
  class Realtime
    attr_reader :api

    # コンストラクタ
    #
    # @param [Plugin::Slack::API] api 接続対象のSlackAPIのインスタンス
    def initialize(api)
      @api = api
      @realtime = @api.client.realtime
      @defined_time = Time.new
    end

    # Realtime APIに実際に接続する
    #
    # @return [Plugin::Slack::Realtime] self
    def start
      setup
      Thread.new {
        # RTMに接続開始
        @realtime.start
      }.trap { |err| error err }
      self
    end

    private

    # RTM のインスタンス生成時に取得できる情報をモデルに格納する
    def modelize
      Thread.new(@realtime.instance_variable_get('@response')) { |res|
        Delayer::Deferred.fail(res['error']) unless res['ok']
        #
        # team = res['team']          # Object
        # channels = res['channels']  # Array
        # groups = res['groups']      # Array
        # ims = res['ims']            # Array
        # users = res['users']        # Array
        # bots = res['bots']          # Array
        #
        # channels.each { |c| p c }
        # bots.each { |bot| p bot }
      }
    end

    # 接続時の処理
    #   * 認証テスト
    #   * チームの取得
    #   * チャンネルの取得
    #   * チャンネルのヒストリ取得
    def connected
      Plugin::Slack::API::Auth.new(api.client).auth_test.next { |auth|
        notice "[AUTH SUCCESS] team: #{auth['team']}, user: #{auth['user']}"

        # 認証失敗時は強制的にエラー処理へ飛ばし、ヒストリを取得しない
        Delayer::Deferred.fail(auth) unless auth['ok']
        # Activityに通知
        Plugin.call(:slack_connected, auth)

        api.team.next { |team| # チームの取得
          team.channels.next { |channels| # チームのチャンネルリストを取得
            Delayer::Deferred.when(*channels.map { |channel|
              api.public_channel.history(channel).next { |message|
                Plugin.call(:extract_receive_message, channel.datasource_slug, message)
              }.trap { |err| error err }
              api.private_channel.history(channel).next { |message|
                Plugin.call(:extract_receive_message, channel.datasource_slug, message)
              }.trap { |err| error err }
            })
          }
        }
      }.trap { |err|
        # 認証失敗時のエラーハンドリング
        error err
        Plugin.call(:slack_connection_failed, err)
      }
    end

    # 受信したメッセージのデータソースへの投稿
    #
    # @param [Hash] message メッセージ
    def on_receive_message(message)
      # 起動前や中身が空の場合は何もしない
      return if @defined_time > Time.at(Float(message['ts']).to_i) || message['text'].empty?

      # メッセージの処理
      api.team.next { |team|
        Delayer::Deferred.when(
          team.user(message['user']),
          team.channel(message['channel'])
        ).next { |user, channel|
          msg = Plugin::Slack::Message.new(channel: channel,
                                           user: user,
                                           text: message['text'],
                                           created: Time.at(Float(message['ts']).to_i),
                                           team: team[:name],
                                           ts: message['ts'])
          Plugin.call(:extract_receive_message, channel.datasource_slug, [msg])
        }
      }.trap { |err| error err }
    end

    def setup
      # 接続時に呼ばれる
      @realtime.on :hello do
        connected
      end

      # メッセージ書き込み時に呼ばれる
      #
      # @param [Hash] data メッセージ
      @realtime.on :message do |message|
        on_receive_message(message)
      end
    end
  end
end
