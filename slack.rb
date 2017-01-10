# -*- coding: utf-8 -*-
require 'slack'
require 'httpclient'
require_relative 'model'
require_relative 'api'
require_relative 'config/environment'

Plugin.create(:slack) do

  # slack api インスタンス作成
  api = Plugin::Slack::API::APA.new(UserConfig['slack_token'])
  api.team.next { |team|
    @team = team
    # RTM 開始
    api.realtime_start
  }.trap { |e| error e }


  # 抽出データソース
  # @see https://toshia.github.io/writing-mikutter-plugin/basis/2016/09/20/extract-datasource.html
  filter_extract_datasources do |ds|
    @team&.channels!&.each { |channel| ds[channel.datasource_slug] = channel.datasource_name }
    [ds]
  end


  on_slack_auth do
    Plugin::Slack::API::Auth.oauth.next { |_|
      api = Plugin::Slack::API::APA.new(UserConfig['slack_token'])
      api.team.next { |team|
        @team = team
        # RTM 開始
        api.realtime_start
      }.trap { |e| error e }
    }.trap { |e| error e }
  end


  # 投稿
  on_slack_post do |channel, message|
    # Slackにメッセージの投稿
    api.post_message(channel, message).next { |res|
      notice "Slack:#{channel}に投稿しました: #{res}"
    }.trap { |e|
      error "[#{self.class.to_s}] Slack:#{channel}への投稿に失敗しました: #{e}"
    }
  end


  # mikutter設定画面
  # @see http://mikutter.blogspot.jp/2012/12/blog-post.html
  settings('Slack') do

    settings('OAuth認証') do
      auth = Gtk::Button.new('認証する')
      auth.signal_connect('clicked') { Plugin.call(:slack_auth) }
      closeup auth
    end

    settings('開発者専用') do
      input('トークン', :slack_token)
    end

    about(_('%s について' % Plugin::Slack::Environment::NAME), {
        :program_name => _('%s' % Plugin::Slack::Environment::NAME),
        :copyright => _('2016-%s Naoki Maeda') % '2017',
        :version => Plugin::Slack::Environment::VERSION,
        :comments => _("サードパーティー製Slackクライアントのデファクトスタンダードを目指すmikutterプラグイン。\nこのソフトウェアは %{license} によって浄化されています。") % {license: 'MIT License'},
        :license => (file_get_contents('./LICENSE') rescue nil),
        :website => _('https://github.com/Na0ki/mikutter_slack.git'),
        :authors => %w(ahiru3net toshi_a),
        :artists => %w(ahiru3net),
        :documenters => %w(ahiru3net toshi_a)
    })

  end

end
