# -*- coding: utf-8 -*-

module Plugin::Slack
  class Realtime
    attr_reader :slack_api

    # @param [Plugin::Slack::API] slack_api 接続対象のSlackAPIのインスタンス
    def initialize(slack_api)
      @slack_api = slack_api
      @realtime = @slack_api.client.realtime
      @defined_time = Time.new
    end


    # Realtime APIに実際に接続する
    # @return [Plugin::Slack::Realtime] self
    def start
      setup
      Thread.new {
        # RTMに接続開始
        @realtime.start
      }.trap { |err|
        error err
      }
      self
    end


    private

    # 接続時
    def connected
      slack_api.auth_test.next { |auth|
        notice "\n\t===== 認証成功 =====\n\tチーム: #{auth['team']}\n\tユーザー: #{auth['user']}" # DEBUG

        # 認証失敗時は強制的にエラー処理へ飛ばし、ヒストリを取得しない
        Delayer::Deferred.fail(auth) unless auth['ok']
        # Activityに通知
        Plugin.call(:slack_connected, auth)

        slack_api.team.next { |team|
          team.channels.next { |channels|
            channels.each do |channel|
              slack_api.channel_history(channel).next { |messages|
                Plugin.call :extract_receive_message, channel.datasource_slug, messages
              }.trap { |err|
                err.inspect
              }
            end
          }
        }.trap { |err|
          error err
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
      slack_api.team.next{ |team|
        Delayer::Deferred.when(
          team.user(data['user']),
          team.channel(data['channel'])
        ).next { |user, channel|
          message = Plugin::Slack::Message.new(channel: channel,
                                               user: user,
                                               text: data['text'],
                                               created: Time.at(Float(data['ts']).to_i),
                                               team: 'test')
          Plugin.call(:extract_receive_message, channel.datasource_slug, [message])
        }
      }.trap { |err|
        error err
      }
    end


    def setup
      # 接続時に呼ばれる
      @realtime.on :hello do
        connected

        # Reserver.new(30) {
        #   # TODO: 30秒ごとに ping を送る
        #   # @see {https://api.slack.com/rtm}
        #   # {"type": "ping"} こんな感じのjson
        #   @realtime.on :ping do
        #     puts 'aieeeeeeee'
        #     @slack_api.send({'type':'ping'})
        #   end
        # }
      end

      # メッセージ書き込み時に呼ばれる
      # @param [Hash] data メッセージ
      # Thread に関しては以下を参考
      # @see https://github.com/toshia/delayer-deferred
      @realtime.on :message do |data|
        receive_message(data)
      end

    end
  end
end
