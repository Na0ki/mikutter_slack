# -*- coding: utf-8 -*-

module Plugin::Slack

  # Messageクラス
  # @see https://toshia.github.io/writing-mikutter-plugin/model/2016/09/30/model-messagemixin.html
  # @see https://toshia.github.io/writing-mikutter-plugin/model/2016/09/30/model-field.html
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


  # Userクラス
  # @see https://toshia.github.io/writing-mikutter-plugin/model/2016/09/30/model-usermixin.html
  # @see https://toshia.github.io/writing-mikutter-plugin/model/2016/09/30/model-field.html
  class User < Retriever::Model
    include Retriever::Model::UserMixin

    field.string :idname, required: true
    field.string :name, required: true
    field.string :profile_image_url

  end

end
