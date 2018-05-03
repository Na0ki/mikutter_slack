# -*- frozen_string_literal: true -*-

Plugin.create(:slack) do
  defspell(:compose, :slack, :slack_channel,
           condition: lambda { |slack, channel|
             slack.team == channel.team
           }) do |slack, channel, body:|
    Thread.new {
      slack.api.client.chat_postMessage(channel: channel.id, text: body, as_user: true)
    }
  end

  defspell(:compose, :slack, :slack_message,
           condition: lambda { |slack, message|
             slack.team == message.team
           }) do |slack, message, body:|
    Thread.new {
      slack.api.client.chat_postMessage(channel: message.channel.id, text: body, as_user: true)
    }
  end
end
