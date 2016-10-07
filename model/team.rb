# -*- coding: utf-8 -*-

# Team Model
# @see https://api.slack.com/methods/team.info
module Plugin::Slack
  class Team < Retriever::Model

    field.string :id, required: true
    field.string :name, required: true
    field.string :domain, required: true
    field.string :email_domain
    field.has :channel, Channel, required: true
    field.has :user, User, required: true
    field.string :text, required: true

    def idname
      name
    end

    def profile_image_url
      self[:icon][:image_44]
    end
  end
end
