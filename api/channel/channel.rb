# -*- coding: utf-8 -*-
# -*- frozen_string_literal: true -*-

require_relative '../object'

module Plugin::Slack
  module API
    # チャンネルの親クラス
    class Channel < Object
      # チャンネルリスト返す
      #
      # @return [Delayer::Deferred::Deferredable] 全てのChannelを引数にcallbackするDeferred
      def list
        Delayer::Deferred.when(
          team,
          request_thread(:list) { query_list }
        ).next { |team, channels_hash|
          channels_hash.map(&:symbolize).map { |c|
            Plugin::Slack::Channel.new(c.merge(team: team,
                                               created: Time.at(c[:created].to_i)))
          }
        }
      end

      # チャンネルリストを取得する。
      # listとの違いは、Deferredの戻り値がキーにチャンネルID、値にPlugin::Slack::Channelを持ったHashであること。
      #
      # @return [Delayer::Deferred::Deferredable] チームの全チャンネルを引数にcallbackするDeferred
      def dict
        list.next { |ary| Hash[ary.map { |c| [c.id, c] }] }
      end

      # 指定したChannelのヒストリを取得
      #
      # @param [Plugin::Slack::Channel] channel ヒストリを取得したいChannel
      # @return [Delayer::Deferred::Deferredable] チャンネルの最新のMessageの配列を引数にcallbackするDeferred
      def history(channel)
        Delayer::Deferred.when(
          team.next(&:user_dict),
          Thread.new { query_history(channel) }
        ).next { |users, histories|
          histories.select { |history|
            users.key?(history['user'])
          }.map { |history|
            Plugin::Slack::Message.new(channel: channel,
                                       user: users[history['user']],
                                       text: history['text'],
                                       created: Time.at(Float(history['ts']).to_i),
                                       team: channel[:team].name,
                                       ts: history['ts'])
          }
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
