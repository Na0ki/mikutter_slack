# -*- coding: utf-8 -*-
# -*- frozen_string_literal: true -*-

require 'slack'
require_relative 'model'
require_relative 'api'
require_relative 'config/environment'

Plugin.create(:slack) do
  def start_realtime
    api = Plugin::Slack::API::APA.new(UserConfig['slack_token'])
    api.team.next { |team|
      @team = team
      # RTM 開始
      api.realtime_start
    }.trap { |err| error err }
  end

  # slack api インスタンス作成
  start_realtime

  # 抽出データソース
  # @see https://toshia.github.io/writing-mikutter-plugin/basis/2016/09/20/extract-datasource.html
  filter_extract_datasources do |ds|
    Enumerator.new{|y|
      Plugin.filtering(:worlds, y)
    }.select{|world|
      world.class.slug == :slack
    }.each{|world|
      world.team&.channels!&.each { |channel| ds[channel.datasource_slug] = channel.datasource_name }
    }
    [ds]
  end

  # 認証をブロードキャストする
  # @example Plugin.call(:slack_auth)
  on_slack_auth do
    Plugin::Slack::API::Auth.oauth.next { |_|
      start_realtime
    }.trap { |err| error err }
  end

  world_setting(:slack, 'Slack') do
    promise = Delayer::Deferred.new(true)
    url = await(Plugin::Slack::API::Auth.request_authorize_url(promise))
    label "認証用のURLをブラウザで開きました。\nブラウザでSlackにログインし、連携したいチームを選択してください。"
    Plugin.call(:open, url)
    token = await(promise)
    world = await(Plugin::Slack::World.build(token))
    label "#{world.team.name}(#{world.team.domain}) チームの #{world.user.name} としてログインしますか？"
    world
  end

  # # 投稿をブロードキャストする
  # # @example Plugin.call(:slack_post, channel_name, message)
  # on_slack_post do |channel_name, message|
  #   # Slackにメッセージの投稿
  #   @team.channels.next { |channels|
  #     channels.find { |c| c.name == channel_name }.post(message)
  #   }.next { |res|
  #     notice "Slack:#{channel_name}に投稿しました: #{res}"
  #   }.trap { |err|
  #     error "[#{self.class}] Slack:#{channel_name}への投稿に失敗しました: #{err}"
  #   }
  # end

  # mikutter設定画面
  # @see http://mikutter.blogspot.jp/2012/12/blog-post.html
  settings('Slack') do
    about('%s について' % Plugin::Slack::Environment::NAME,
          program_name: Plugin::Slack::Environment::NAME,
          copyright: '2016-2017 Naoki Maeda',
          version: Plugin::Slack::Environment::VERSION,
          comments: "サードパーティー製Slackクライアントの標準を夢見るmikutterプラグイン。\nこのプラグインは MIT License によって浄化されています。",
          license: (file_get_contents('./LICENSE') rescue nil),
          website: 'https://github.com/Na0ki/mikutter_slack.git',
          authors: %w[ahiru3net toshi_a],
          artists: %w[ahiru3net],
          documenters: %w[ahiru3net toshi_a])
  end
end
