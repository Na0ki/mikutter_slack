# -*- coding: utf-8 -*-
# apaではない
require 'slack'
require_relative 'api/auth'

module Plugin::Slack
  class SlackAPI
    class << self

      # ユーザーリストを取得
      # @param [Slack::Client] events EVENTS APIのインスタンス
      # @return [Delayer::Deferred::Deferredable] チームの全ユーザを引数にcallbackするDeferred
      def users(events)
        Thread.new do
          events.users_list['members'].map { |m|
            Plugin::Slack::User.new(m.symbolize)
          }
        end
      end


      # チャンネルリスト返す
      # @param [Slack::Client] events EVENTS APIのインスタンス
      # @return [Delayer::Deferred::Deferredable] チャンネル一覧
      def channels(events)
        Thread.new do
          events.channels_list['channels']
        end
      end


      # 全てのチャンネルのヒストリを取得
      # @param [Slack::Client] events EVENTS APIのインスタンス
      # @return [Delayer::Deferred::Deferredable] channels_history チャンネルのヒストリを引数にcallbackするDeferred
      # @see https://github.com/aki017/slack-api-docs/blob/master/methods/channels.history.md
      def all_channel_history(events)
        Thread.new do
          channels(events).next { |chs|
            events.channels_history(channel: "#{chs['id']}")['messages']
          }
        end
      end


      # 指定したチャンネル名のチャンネルのヒストリを取得
      # @param [Slack::Client] events EVENTS APIのインスタンス
      # @param [hash] channels
      # @param [String] name 取得したいチャンネル名
      # @return [Delayer::Deferred::Deferredable] channels_history チャンネルのヒストリを引数にcallbackするDeferred
      # @see https://github.com/aki017/slack-api-docs/blob/master/methods/channels.history.md
      def channel_history(events, channels, name)
        Thread.new do
          channel = channels.find { |c| c['name'] == name }
          events.channels_history(channel: "#{channel['id']}")['messages']
        end
      end


      # Emojiリストの取得
      # @param [Slack::Client] events EVENTS APIのインスタンス
      # @return [Delayer::Deferred::Deferredable] 絵文字リストを引数にcallbackするDeferred
      def emoji_list(events)
        Thread.new do
          events.emoji_list
        end
      end
    end
  end
end
