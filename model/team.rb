# -*- coding: utf-8 -*-

# Team Model
# @see https://api.slack.com/methods/team.info
module Plugin::Slack
  class Team < Retriever::Model

    field.string :id, required: true
    field.string :name, required: true
    field.string :domain, required: true
    field.string :email_domain
  end
end
