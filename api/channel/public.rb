# -*- coding: utf-8 -*-
require_relative 'channel'

module Plugin::Slack
  module API

    class PublicChannel < Channel
      private def query_list
        api.client.channels_list['channels']
      end

      private def query_history
        api.client.channels_history(channel: channel.id)['messages']
      end
    end

  end
end
