# -*- coding: utf-8 -*-
# -*- frozen_string_literal: true -*-

require_relative '../entity/message_entity'
require_relative '../model/user'
require_relative '../model/channel'

# Messageクラス
# @see https://toshia.github.io/writing-mikutter-plugin/model/2016/09/30/model-messagemixin.html
# @see https://toshia.github.io/writing-mikutter-plugin/model/2016/09/30/model-field.html
module Plugin::Slack
  # メッセージ Model
  class Message < Diva::Model
    include Diva::Model::MessageMixin

    register :slack_message, name: 'Slack Message'

    field.has :channel, Plugin::Slack::Channel, required: true
    field.has :user, Plugin::Slack::User, required: true
    field.string :text, required: true
    field.time :created
    field.string :team, required: true
    field.string :ts, required: true

    entity_class Diva::Entity::URLEntity
    entity_class Plugin::Slack::Entity::MessageEntity

    alias description text

    # このMessageが所属するTeam
    #
    # @return [Plugin::Slack::Team] チーム
    def team
      channel.team
    end

    # Messageのリンク
    #
    # @return [Retriever::URI] リンク
    def perma_link
      Diva::URI("https://#{team.domain}.slack.com/archives/#{channel.name}/p#{ts.delete('.')}")
    end

    # 返信可能なメッセージかどうか
    # TODO: そのうち返信できる仕組みを作って repliable にする
    #
    # @return false
    def repliable?
      false
    end

    def inspect
      "#{self.class}(channel=#{channel}, user=#{user})"
    end
  end
end
