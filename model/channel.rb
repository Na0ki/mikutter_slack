# -*- coding: utf-8 -*-
# -*- frozen_string_literal: true -*-

module Plugin::Slack
  # Channelのモデル
  # @see https://api.slack.com/methods/channels.info
  class Channel < Diva::Model
    register :slack_channel, name: 'Slack Channel'

    field.string :id, required: true
    field.string :name, required: true

    field.time :created
    field.string :creator

    field.bool :is_archived
    field.bool :is_general
    field.bool :is_member
    field.bool :is_starred

    # TODO: User情報をchannelに持たせる
    # field.has :members, [Plugin::Slack::User], required: true

    # TODO: topicとpurposeはオブジェクト（どう持たせるか）
    # field.string :topic
    # field.string :purpose

    field.string :last_read
    field.string :latest
    field.int :unread_count
    field.int :unread_count_display

    field.has :team, Plugin::Slack::Team, required: true

    # 抽出タブのスラグを返す
    #
    # @return [String] スラグ
    def datasource_slug
      :"slack_#{team.id}_#{id}"
    end

    # 抽出タブの名前を返す
    #
    # @return [String] 抽出タブの名前
    def datasource_name
      ['slack', team.name, name]
    end

    # チャンネルのヒストリを返す
    #
    # @return [Delayer::Deferred::Deferredable] チャンネルの最新のMessageの配列を引数にcallbackするDeferred
    def history
      team.api.channel.history(self)
    end

    # メッセージの投稿
    #
    # @param [String] text 投稿メッセージ
    def post(text)
      team.api.channel.post(self, text)
    end

    # チャンネルのリンクを返す
    #
    # @return [String] リンク
    def perma_link
      Diva::URI("https://#{team.domain}.slack.com/archives/#{name}/")
    end

    def inspect
      "#{self.class}(id=#{id}, name=#{name})"
    end
  end
end
