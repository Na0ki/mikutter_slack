# -*- coding: utf-8 -*-
require_relative 'channel'

module Plugin::Slack
  module API

    class PrivateChannel < Channel
      # プライベートチャンネルリスト返す
      # @return [Delayer::Deferred::Deferredable] 全てのChannelを引数にcallbackするDeferred
      def list
        Delayer::Deferred.when(
          team,
          request_thread(:list) { api.client.groups_list['channels'] }
        ).next { |team, channels_hash|
          channels_hash.map { |_| Plugin::Slack::Channel.new(_.symbolize.merge(team: team)) }
        }
      end

      # プライベートチャンネルリストを取得する
      # channelsとの違いは、Deferredの戻り値がキーにチャンネルID、値にPlugin::Slack::Channelを持ったHashであること
      #
      # @return [Delayer::Deferred::Deferredable] チームの全チャンネルを引数にcallbackするDeferred
      def dict
        channels.next { |ary| Hash[ary.map { |_| [_.id, _] }] }
      end

      # 指定したプライベートChannelのヒストリを取得
      #
      # @param [Plugin::Slack::Channel] channel ヒストリを取得したいChannel
      # @return [Delayer::Deferred::Deferredable] チャンネルの最新のMessageの配列を引数にcallbackするDeferred
      # @see https://github.com/aki017/slack-api-docs/blob/master/methods/groups.history.md
      def history(channel)
        Delayer::Deferred.when(
          team.next { |t| t.user_dict },
          Thread.new { api.client.groups_history(channel: channel.id)['messages'] }
        ).next { |users, histories|
          histories.select { |history|
            users.has_key?(history['user'])
          }.map do |history|
            Plugin::Slack::Message.new(channel: channel,
                                       user: users[history['user']],
                                       text: history['text'],
                                       created: Time.at(Float(history['ts']).to_i),
                                       team: channel[:team].name,
                                       ts: history['ts'])
          end
        }
      end

      # メッセージの投稿
      #
      # @param [Plugin::Slack::Channel] channel チャンネルModel
      # @param [String] text 投稿メッセージ
      def post(channel, text)
        Thread.new { api.client.chat_postMessage(channel: channel.id, text: text, as_user: true) }
      end

    end

  end
end
