# -*- coding: utf-8 -*-

module Plugin::Slack
  class Realtime
    attr_reader :api

    # @param [Plugin::Slack::API] api 接続対象のSlackAPIのインスタンス
    def initialize(api)
      @api = api
      @realtime = @api.client.realtime
      @defined_time = Time.new
    end


    # Realtime APIに実際に接続する
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

    # 接続時
    def connected
      Plugin::Slack::API::Auth.new(api.client).auth_test.next { |auth|
        notice "[認証成功] チーム: #{auth['team']}, ユーザー: #{auth['user']}" # DEBUG

        # 認証失敗時は強制的にエラー処理へ飛ばし、ヒストリを取得しない
        Delayer::Deferred.fail(auth) unless auth['ok']
        # Activityに通知
        Plugin.call(:slack_connected, auth)

        api.team.next { |team| # チームの取得
          team.channels.next { |channels| # チームのチャンネルリストを取得
            Delayer::Deferred.when(*channels.map { |channel|
              api.channel.history(channel).next { |messages|
                Plugin.call(:extract_receive_message, channel.datasource_slug, messages)
              }
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
    # @param [Hash] data メッセージ
    def receive_message(data)
      # 起動時間より前のタイムスタンプの場合は何もしない（ヒストリからとってこれる）
      # 起動時に最新の一件の投稿が呼ばれるが、その際に on :message が呼ばれてしまうのでその対策
      return unless @defined_time < Time.at(Float(data['ts']).to_i)
      # 投稿内容が空の場合はスキップ
      return if data['text'].empty?

      # メッセージの処理
      api.team.next { |team|
        Delayer::Deferred.when(
          team.user(data['user']),
          team.channel(data['channel'])
        ).next { |user, channel|
          message = Plugin::Slack::Message.new(channel: channel,
                                               user: user,
                                               text: data['text'],
                                               created: Time.at(Float(data['ts']).to_i),
                                               team: team[:name],
                                               ts: data['ts'])
          Plugin.call(:extract_receive_message, channel.datasource_slug, [message])
        }
      }.trap { |err| error err }
    end


    def setup
      # 接続時に呼ばれる
      @realtime.on :hello do
        connected
      end

      # メッセージ書き込み時に呼ばれる
      # @param [Hash] data メッセージ
      @realtime.on :message do |data|
        receive_message(data)
      end
    end

  end
end
