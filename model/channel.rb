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

    def datasource_slug
      :"slack_#{team.id}_#{id}"
    end

    def datasource_name
      ['slack', team.name, name]
    end

    def perma_link
      Retriever::URI("https://#{team.domain}.slack.com/archives/#{name}/")
    end

    def inspect
      "#{self.class.to_s}(id=#{id}, name=#{name})"
    end
  end
end
