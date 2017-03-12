# -*- coding: utf-8 -*-
require_relative 'channel'

module Plugin::Slack
  module API

    class PrivateChannel < Channel
      private def query_list
        channels = api.client.groups_list
        Delayer::Deferred.fail(channels['error']) unless channels['ok']
        channels['groups']
      end

      private def query_history(channel)
        history = api.client.groups_history(channel: channel.id)
        Delayer::Deferred.fail(history['error']) unless history['ok']
        history['messages']
      end
    end

  end
end
