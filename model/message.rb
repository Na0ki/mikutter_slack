# -*- coding: utf-8 -*-

# Messageクラス
# @see https://toshia.github.io/writing-mikutter-plugin/model/2016/09/30/model-messagemixin.html
# @see https://toshia.github.io/writing-mikutter-plugin/model/2016/09/30/model-field.html
module Plugin::Slack
  class Message < Retriever::Model
    include Retriever::Model::MessageMixin

    register :slack_message,
             name: 'Slack Message'

    field.string :channel, required: true
    field.has :user, User, required: true
    field.string :text, required: true
    field.time :created
    field.string :team, required: true

    entity_class Retriever::Entity::URLEntity

    def to_show
      @to_show ||= self[:text]
    end
  end
end
