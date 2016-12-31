# -*- coding: utf-8 -*-
require 'slack'

module Plugin::Slack
  module API
    class Channel
      # FIXME: 形だけprivateチャンネルを取得できるようなメソッドに変更. 後日動くか検証する.（足らない部分に関しては api.rb 参照）

      # チームを取得する。
      # 一度でもTeamの取得に成功すると、二度目以降はその内容を返す
      # @return [Delayer::Deferred::Deferredable] Teamを引数にcallbackするDeferred
      def team
        Thread.new { team! }
      end


      ##################
      # Public Channel #
      ##################

      # パブリックチャンネルリスト返す
      # @return [Delayer::Deferred::Deferredable] 全てのChannelを引数にcallbackするDeferred
      def pub_list
        Delayer::Deferred.when(
            team,
            Thread.new { @client.channels_list['channels'] }
        ).next { |team, channels_hash|
          channels_hash.map { |_| Plugin::Slack::Channel.new(_.symbolize.merge(team: team)) }
        }
      end

      # パブリックチャンネルリストを取得する。
      # channelsとの違いは、Deferredの戻り値がキーにチャンネルID、値にPlugin::Slack::Channelを持ったHashであること。
      # @return [Delayer::Deferred::Deferredable] チームの全チャンネルを引数にcallbackするDeferred
      def pub_dict
        channels.next { |ary| Hash[ary.map { |_| [_.id, _] }] }
      end

      # 指定したパブリックChannelのヒストリを取得
      # @param [Plugin::Slack::Channel] channel ヒストリを取得したいChannel
      # @return [Delayer::Deferred::Deferredable] チャンネルの最新のMessageの配列を引数にcallbackするDeferred
      # @see https://github.com/aki017/slack-api-docs/blob/master/methods/channels.history.md
      def pub_history(channel)
        Delayer::Deferred.when(
            users_dict,
            Thread.new { @client.channels_history(channel: channel.id)['messages'] }
        ).next { |users, histories|
          histories.select { |history|
            users.has_key?(history['user'])
          }.map { |history|
            Plugin::Slack::Message.new(channel: channel,
                                       user: users[history['user']],
                                       text: history['text'],
                                       created: Time.at(Float(history['ts']).to_i),
                                       team: channel[:team].name)
          }
        }
      end


      ###################
      # Private Channel #
      ###################

      # プライベートチャンネルリスト返す
      # @return [Delayer::Deferred::Deferredable] 全てのChannelを引数にcallbackするDeferred
      def pvt_list
        Delayer::Deferred.when(
            team,
            Thread.new { @client.groups_list['channels'] }
        ).next { |team, channels_hash|
          channels_hash.map { |_| Plugin::Slack::Channel.new(_.symbolize.merge(team: team)) }
        }
      end

      # プライベートチャンネルリストを取得する。
      # channelsとの違いは、Deferredの戻り値がキーにチャンネルID、値にPlugin::Slack::Channelを持ったHashであること。
      # @return [Delayer::Deferred::Deferredable] チームの全チャンネルを引数にcallbackするDeferred
      def pvt_dict
        channels.next { |ary| Hash[ary.map { |_| [_.id, _] }] }
      end

      # 指定したプライベートChannelのヒストリを取得
      # @param [Plugin::Slack::Channel] channel ヒストリを取得したいChannel
      # @return [Delayer::Deferred::Deferredable] チャンネルの最新のMessageの配列を引数にcallbackするDeferred
      # @see https://github.com/aki017/slack-api-docs/blob/master/methods/groups.history.md
      def pvt_history(channel)
        Delayer::Deferred.when(
            users_dict,
            Thread.new { @client.groups_history(channel: channel.id)['messages'] }
        ).next { |users, histories|
          histories.select { |history|
            users.has_key?(history['user'])
          }.map do |history|
            Plugin::Slack::Message.new(channel: channel,
                                       user: users[history['user']],
                                       text: history['text'],
                                       created: Time.at(Float(history['ts']).to_i),
                                       team: channel[:team].name)
          end
        }
      end


      private

      memoize def team!
        Plugin::Slack::Team.new(@client.team_info['team'].symbolize)
      end

    end
  end
end
