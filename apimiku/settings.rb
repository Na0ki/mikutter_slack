# -*- frozen_string_literal: true -*-

Plugin.create(:slack) do
  # mikutter設定画面
  # @see http://mikutter.blogspot.jp/2012/12/blog-post.html
  settings('Slack') do
    about('%<plugin_name>s について' % Plugin::Slack::Environment::NAME,
          program_name: Plugin::Slack::Environment::NAME,
          copyright: '2016-2018 Naoki Maeda',
          version: Plugin::Slack::Environment::VERSION,
          comments: "サードパーティー製Slackクライアントの標準を夢見るmikutterプラグイン。\nこのプラグインは MIT License によって浄化されています。",
          license: (file_get_contents('./LICENSE') rescue nil),
          website: 'https://github.com/Na0ki/mikutter_slack.git',
          authors: %w[ahiru3net toshi_a],
          artists: %w[ahiru3net],
          documenters: %w[ahiru3net toshi_a])
  end
end
