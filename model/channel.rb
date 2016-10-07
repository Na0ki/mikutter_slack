# -*- coding: utf-8 -*-

module Plugin::Slack

  class Channel < Retriever::Model
    field.string :id, required: true
    field.string :name, required: true

    field.bool :is_member
    field.bool :is_starred
    field.bool :is_archived
    field.bool :is_general

    field.array :members, required: true

    field.has :topic, Topic
    field.has :purpose, Purpose

    field.int :unread_count
    field.int :unread_count_display
  end


  class Topic < Retriever::Model
    field.string :value
    field.string :creator
    field.time :last_set
  end


  class Purpose < Retriever::Model
    field.string :value
    field.string :creator
    field.time :last_set
  end

end
