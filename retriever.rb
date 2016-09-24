# -*- coding: utf-8 -*-

module Plugin::Slack
  class Message < Retriever::Model

    field.string :type, required: true
    field.string :channel, required: true
    field.string :user, required: true
    field.string :text, required: true
    field.string :ts, required: true
    field.string :team, required: true

    def idname

    end

    def user
      self
    end

  end
end