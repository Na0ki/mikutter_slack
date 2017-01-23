# -*- coding: utf-8 -*-
require_relative '../entity/message_entity'
require_relative '../entity/user_entity'
require_relative '../model/user'
require_relative '../model/channel'

# Messageクラス
# @see https://toshia.github.io/writing-mikutter-plugin/model/2016/09/30/model-messagemixin.html
# @see https://toshia.github.io/writing-mikutter-plugin/model/2016/09/30/model-field.html
module Plugin::Slack
  class Message < Retriever::Model
    include Retriever::Model::MessageMixin

    register :slack_message,
             name: 'Slack Message'

    field.has :channel, Plugin::Slack::Channel, required: true
    field.has :user, Plugin::Slack::User, required: true
    field.string :text, required: true
    field.time :created
    field.string :team, required: true
    field.string :ts, required: true

    entity_class Retriever::Entity::URLEntity
    entity_class Plugin::Slack::Entity::MessageEntity

    def to_show
      @to_show ||= self[:text]
    end

    # このMessageが所属するTeam
    # @return [Plugin::Slack::Team] チーム
    def team
      channel.team
    end

    # Messageのリンク
    # @return [Retriever::URI] リンク
    def perma_link
      Retriever::URI("https://#{team.domain}.slack.com/archives/#{channel.name}/p#{ts.gsub('.', '')}")
    end

    def inspect
      "#{self.class.to_s}(channel=#{channel.to_s}, user=#{user.to_s})"
    end
  end
end
