# -*- coding: utf-8 -*-
require 'slack'

module Plugin::Slack
  class SlackAPI
    class << self
      # 認証テスト
      # @return [boolean] 認証成功の可否
      def auth_test
        auth = Slack.auth_test
        if auth['ok']
          Plugin.call(:slack_connected, auth)
        else
          Plugin.call(:slack_connection_failed, auth)
        end
        auth['ok']
      end


      # ユーザーリストを取得
      # @param [Slack::Client] events EVENTS APIのインスタンス
      # @return [Delayer::Deferred::Deferredable] チームの全ユーザを引数にcallbackするDeferred
      def users(events)
        Thread.new{
          events.users_list['members'].map { |m|
            Plugin::Slack::User.new(m.symbolize)
          }
        }
      end


      # チャンネルリスト返す
      # @param [Slack::Client] events EVENTS APIのインスタンス
      # @return [Array] channels チャンネル一覧
      def channels(events)
        events.channels_list['channels']
      end


      # 全てのチャンネルのヒストリを取得
      # @param [Slack::Client] events EVENTS APIのインスタンス
      # @return [JSON] 全チャンネルのヒストリ
      # @see https://github.com/aki017/slack-api-docs/blob/master/methods/channels.history.md
      def all_channel_history(events)
        events.channels_history(channel: "#{channels(events)['id']}")['messages']
      end


      # 指定したチャンネル名のチャンネルのヒストリを取得
      # @param [Slack::Client] events EVENTS APIのインスタンス
      # @param [hash] channels
      # @param [String] name 取得したいチャンネル名
      # @return [Delayer::Deferred::Deferredable] channels_history チャンネルのヒストリを引数にcallbackするDeferred
      # @see https://github.com/aki017/slack-api-docs/blob/master/methods/channels.history.md
      def channel_history(events, channels, name)
        Thread.new do
          channel = channels.find{|c| c['name'] == name }
          events.channels_history(channel: "#{channel['id']}")['messages']
        end
      end


      # Emojiリストの取得
      # @param [Slack::Client] events EVENTS APIのインスタンス
      # @return [JSON] 絵文字リスト
      def emoji_list(events)
        events.emoji_list
      end
    end
  end
end
