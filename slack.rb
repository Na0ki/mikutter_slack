# -*- coding: utf-8 -*-
require 'slack'
require 'httpclient'
require_relative 'model'
require_relative 'api'

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


  def image(display_url)
    connection = HTTPClient.new
    img = connection.get_content(display_url,
                                 'Authorization' => "Bearer #{UserConfig['slack_token']}")
    unless img.empty?
      p img
      img
    end
  end


  # 投稿
  on_slack_post do |channel, message|
    # Slackにメッセージの投稿
    api.post_message(channel, message).next { |res|
      notice "Slack:#{channel}に投稿しました: #{res}"
      # TODO: slack_gui側で下記activityを実行できるようにする
      # activity :slack, "Slack:#{channel}に投稿しました: #{res}"
    }.trap { |e|
      error "[#{self.class.to_s}] Slack:#{channel}への投稿に失敗しました: #{e}"
    }
  end


  # mikutter設定画面
  # @see http://mikutter.blogspot.jp/2012/12/blog-post.html
  settings('Slack') do
    settings('Slack アカウント') do
      input 'メールアドレス', :slack_email
      inputpass 'パスワード', :slack_password
    end

    settings('開発') do
      input('トークン', :slack_token)
    end
  end

end
