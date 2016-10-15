# -*- coding: utf-8 -*-

module Plugin::Slack

  class Channel < Retriever::Model
    field.string :id, required: true
    field.string :name, required: true

    field.bool :is_member
    field.bool :is_starred
    field.bool :is_archived
    field.bool :is_general
    field.has :team, Plugin::Slack::Team, required: true
    field.int :unread_count
    field.int :unread_count_display
  end
end
