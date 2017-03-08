# -*- coding: utf-8 -*-
require_relative 'channel'

module Plugin::Slack
  module API

    class PrivateChannel < Channel
      private def query_list
        api.client.groups_list['channels']
      end

      private def query_history
        api.client.groups_history(channel: channel.id)['messages']
      end
    end

  end
end
