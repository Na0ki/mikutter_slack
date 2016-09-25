# -*- coding: utf-8 -*-

module Plugin::Slack

  class Message < Retriever::Model
    include Retriever::Model::MessageMixin

    register :slack_message,
             name: 'Slack Message'

    field.string :type, required: true
    field.string :channel, required: true
    field.has :user, Plugin::Slack::User, required: true
    field.string :text, required: true
    field.string :ts, required: true
    field.string :team, required: true

    entity_class Retriever::Entity::URLEntity
  end



  class User < Retriever::Model
    include Retriever::Model::UserMixin

    field.string :idname

  end

end
