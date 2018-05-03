# -*- frozen_string_literal: true -*-

require_relative 'channel'

module Plugin::Slack
  module API
    # Public Channel API
    class PublicChannel < Channel
      private def query_list
        channels = api.client.channels_list
        if channels['ok']
          channels['channels']
        else
          []
        end
      end

      private def query_history(channel)
        history = api.client.channels_history(channel: channel.id)
        if history['ok']
          history['messages']
        else
          []
        end
      end
    end
  end
end
