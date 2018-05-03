# -*- frozen_string_literal: true -*-

Plugin.create(:slack) do
  # 認証をブロードキャストする
  # @example Plugin.call(:slack_auth)
  on_slack_auth do
    Plugin::Slack::API::Auth.oauth.next { |_|
      start_realtime
    }.trap { |err| error err }
  end
end
