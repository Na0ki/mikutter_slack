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
        auth['ok'] end


      # ユーザーリストを取得
      # @param [Slack::Client] events EVENTS APIのインスタンス
      # @return [Array] ユーザーリスト
      def users(events)
        Hash[events.users_list['members'].map { |m| [m['id'], m['name']] }] end


      # チャンネルリスト返す
      # @param [Slack::Client] events EVENTS APIのインスタンス
      # @return [Array] channels チャンネル一覧
      def channels(events)
        events.channels_list['channels'] end


      # 全てのチャンネルのヒストリを取得
      # @param [Slack::Client] events EVENTS APIのインスタンス
      # @return [Array] 全チャンネルのヒストリリスト
      def all_channel_history(events)
        channel = channels(events)
        events.channels_history(channel: "#{channel['id']}")['messages'] end


      # 指定したチャンネル名のチャンネルのヒストリを取得
      # @param [Slack::Client] events EVENTS APIのインスタンス
      # @param [hash] channels
      # @param [String] name チャンネル名
      # @return [Array] channels_history チャンネルのヒストリリスト
      def channel_history(events, channels, name)
        channels.each do |channel|
          if channel['name'] == name
            return events.channels_history(channel: "#{channel['id']}")
          end
        end end


      # Emojiリストの取得
      # @param [Slack::Client] events EVENTS APIのインスタンス
      # @return Array 絵文字リスト
      def emoji_list(events)
        events.emoji_list end


      # ユーザのアイコンを取得
      # @param [Slack::Client] events EVENTS APIのインスタンス
      # @param [String] id ユーザーID
      # @return [String] アイコンのURL
      def get_icon(events, id)
        events.users_list['members'].each { |u|
          return u.dig('profile', 'image_48') if u['id'] == id
        }
        Skin.get('icon.png') end

    end
  end
end
