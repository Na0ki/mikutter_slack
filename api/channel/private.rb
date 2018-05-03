# -*- frozen_string_literal: true -*-

require_relative 'channel'

module Plugin::Slack
  module API
    # Private Channel API
    class PrivateChannel < Channel
      private def query_list
        channels = api.client.groups_list
        if channels['ok']
          channels['groups']
        else
          []
        end
      end

      private def query_history(channel)
        history = api.client.groups_history(channel: channel.id)
        if history['ok']
          history['messages']
        else
          []
        end
      end
    end
  end
end
