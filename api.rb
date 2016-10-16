# -*- coding: utf-8 -*-
# apaではない
require 'slack'
require_relative 'api/auth'
require_relative 'api/realtime'

module Plugin::Slack
  class API
    attr_reader :client

    # @param [String] token APIトークン
    def initialize(token)
      @client = Slack::Client.new(token: token)
    end

    # Realtime APIに接続する
    def realtime_start
      @realtime ||= Plugin::Slack::Realtime.new(self).start
    end

    # チームを取得する。
    # 一度でもTeamの取得に成功すると、二度目以降はその内容を返す
    # @return [Delayer::Deferred::Deferredable] Teamを引数にcallbackするDeferred
    def team
      Thread.new { team! }
    end

    # ユーザーリストを取得
    # @return [Delayer::Deferred::Deferredable] チームの全ユーザを引数にcallbackするDeferred
    def users
      Thread.new do
        @client.users_list['members'].map { |m|
          Plugin::Slack::User.new(m.symbolize)
        }
      end
    end

    # ユーザーリストを取得する。
    # usersとの違いは、Deferredの戻り値がキーにユーザID、値にPlugin::Slack::Userを持ったHashであること。
    # @return [Delayer::Deferred::Deferredable] チームの全ユーザを引数にcallbackするDeferred
    def users_dict
      users.next{|ary| Hash[ary.map{|_|[_.id, _]}] }
    end

    # チャンネルリスト返す
    # @return [Delayer::Deferred::Deferredable] 全てのChannelを引数にcallbackするDeferred
    def channels
      Delayer::Deferred.when(
        team,
        Thread.new{ @client.channels_list['channels'] }
      ).next { |team, channels_hash|
        channels_hash.map{|_| Plugin::Slack::Channel.new(_.symbolize.merge(team: team)) }
      }
    end

    # チャンネルリストを取得する。
    # channelsとの違いは、Deferredの戻り値がキーにチャンネルID、値にPlugin::Slack::Channelを持ったHashであること。
    # @return [Delayer::Deferred::Deferredable] チームの全チャンネルを引数にcallbackするDeferred
    def channels_dict
      channels.next{|ary| Hash[ary.map{|_|[_.id, _]}] }
    end

    # 指定したChannelのヒストリを取得
    # @param [Plugin::Slack::Channel] channel ヒストリを取得したいChannel
    # @return [Delayer::Deferred::Deferredable] チャンネルの最新のMessageの配列を引数にcallbackするDeferred
    # @see https://github.com/aki017/slack-api-docs/blob/master/methods/channels.history.md
    def channel_history(channel)
      Delayer::Deferred.when(
        users_dict,
        Thread.new{ @client.channels_history(channel: channel.id)['messages'] }
      ).next{|users, histories|
        histories.select{|history|
          users.has_key?(history['user'])
        }.map do |history|
          Plugin::Slack::Message.new(channel: channel,
                                     user: users[history['user']],
                                     text: history['text'],
                                     created: Time.at(Float(history['ts']).to_i),
                                     team: 'mikutter')
        end
      }
    end


    # Emojiリストの取得
    # @return [Delayer::Deferred::Deferredable] 絵文字リストを引数にcallbackするDeferred
    def emoji_list
      Thread.new do
        @client.emoji_list
      end
    end

    private

    memoize def team!
      Plugin::Slack::Team.new(@client.team_info['team'].symbolize.merge(api: self))
    end
  end
end
