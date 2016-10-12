# -*- coding: utf-8 -*-
# apaではない
require 'slack'
require_relative 'api/auth'

module Plugin::Slack
  class SlackAPI
    attr_reader :realtime

    # @param [Slack::Client] events EVENTS APIのインスタンス
    def initialize(token)
      @client = Slack::Client.new(token: token)
      @realtime = @client.realtime
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


    # チャンネルリスト返す
    # @return [Delayer::Deferred::Deferredable] チャンネル一覧
    def channels
      Thread.new do
        @client.channels_list['channels']
      end
    end


    # 全てのチャンネルのヒストリを取得
    # @return [Delayer::Deferred::Deferredable] channels_history チャンネルのヒストリを引数にcallbackするDeferred
    # @see https://github.com/aki017/slack-api-docs/blob/master/methods/channels.history.md
    def all_channel_history
      Thread.new do
        channels.next { |chs|
          @client.channels_history(channel: "#{chs['id']}")['messages']
        }
      end
    end


    # 指定したチャンネル名のチャンネルのヒストリを取得
    # @param [hash] channels
    # @param [String] name 取得したいチャンネル名
    # @return [Delayer::Deferred::Deferredable] channels_history チャンネルのヒストリを引数にcallbackするDeferred
    # @see https://github.com/aki017/slack-api-docs/blob/master/methods/channels.history.md
    def channel_history(channels, name)
      Thread.new do
        channel = channels.find { |c| c['name'] == name }
        @client.channels_history(channel: "#{channel['id']}")['messages']
      end
    end


    # Emojiリストの取得
    # @return [Delayer::Deferred::Deferredable] 絵文字リストを引数にcallbackするDeferred
    def emoji_list
      Thread.new do
        @client.emoji_list
      end
    end
  end
end
