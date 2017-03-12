# -*- coding: utf-8 -*-
require_relative 'channel'

module Plugin::Slack
  module API

    class PublicChannel < Channel
      private def query_list
        channels = api.client.channels_list
        Delayer::Deferred.fail(channels['error']) unless channels['ok']
        channels['channels']
      end

      private def query_history(channel)
        history = api.client.channels_history(channel: channel.id)
        Delayer::Deferred.fail(history['error']) unless history['ok']
        history['messages']
      end
    end

  end
end
