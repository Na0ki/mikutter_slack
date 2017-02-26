# -*- coding: utf-8 -*-

module Plugin::Slack

  class Channel < Retriever::Model
    register :slack_channel, name: 'Slack Channel'

    field.string :id, required: true
    field.string :name, required: true

    field.bool :is_member
    field.bool :is_starred
    field.bool :is_archived
    field.bool :is_general
    field.has :team, Plugin::Slack::Team, required: true
    field.int :unread_count
    field.int :unread_count_display

    # 抽出タブのスラグを返す
    # @return [String] スラグ
    def datasource_slug
      :"slack_#{team.id}_#{id}"
    end

    # 抽出タブの名前を返す
    # @return [String] 抽出タブの名前
    def datasource_name
      ['slack', team.name, name]
    end

    # チャンネルのヒストリを返す
    # @return [Delayer::Deferred::Deferredable] チャンネルの最新のMessageの配列を引数にcallbackするDeferred
    def history
      team.api.channel.history(self)
    end

    # チャンネルのリンクを返す
    # @return [String] リンク
    def perma_link
      Retriever::URI("https://#{team.domain}.slack.com/archives/#{name}/")
    end

    def inspect
      "#{self.class.to_s}(id=#{id}, name=#{name})"
    end
  end
end
