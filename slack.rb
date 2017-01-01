# -*- coding: utf-8 -*-
require 'slack'
require 'httpclient'
require_relative 'model'
require_relative 'api'

Plugin.create(:slack) do

  # slack api インスタンス作成
  slack_api = Plugin::Slack::API::APA.new(UserConfig['slack_token'])
  slack_api.team.next { |team|
    @team = team
    # RTM 開始
    slack_api.realtime_start
  }.trap { |err|
    error err
  }

  # Activity の設定
  defactivity 'slack_connection', 'Slack接続情報'


  # 抽出データソース
  # @see https://toshia.github.io/writing-mikutter-plugin/basis/2016/09/20/extract-datasource.html
  filter_extract_datasources do |ds|
    @team&.channels!&.each do |channel|
      ds[channel.datasource_slug] = channel.datasource_name
    end
    [ds]
  end


  # 実績設定
  # @see http://mikutter.blogspot.jp/2013/03/blog-post.html
  defachievement(:slack_achieve,
                 description: '設定画面からSlackのトークンを設定しよう',
                 hint: "Slackのトークンを取得して設定しよう！\nhttps://api.slack.com/docs/oauth-test-tokens"
  ) do |achievement|
    on_slack_connected do |_|
      achievement.take!
    end
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


  # 接続時
  on_slack_connected do |auth|
    activity :slack_connection, "Slackチーム #{auth['team']} の認証に成功しました！"
  end


  # 接続失敗時
  on_slack_connection_failed do |auth|
    activity :slack_connection, "Slackチーム #{auth['team']} の認証に失敗しました！"
  end


  # コマンド登録
  # コマンドのslugはpost_to_slack_#{チーム名}_#{チャンネル名}の予定
  command(:post_to_slack,
          name: 'Slackに投稿する',
          condition: lambda { |_| true },
          visible: true,
          role: :postbox
  ) do |opt|
    msg = Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text # postboxからメッセージを取得

    channels = []
    @team.instance_variable_get('@channels').each { |c| channels.push(c.name) }

    dialog = Gtk::Dialog.new('Slackに投稿',
                             $main_application_window,
                             Gtk::Dialog::DESTROY_WITH_PARENT,
                             [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK],
                             [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL])

    dialog.vbox.add(Gtk::Label.new('チャンネル'))
    channel_list = Gtk::ComboBox.new(true)
    dialog.vbox.add(channel_list)
    channels.each { |c| channel_list.append_text(c) }
    channel_list.set_active(0)

    dialog.show_all
    result = dialog.run

    if result == Gtk::Dialog::RESPONSE_OK
      channel_name = channels[channel_list.active]
      dialog.destroy

      # Slackにメッセージの投稿
      slack_api.post_message(channel_name, msg).next { |res|
        activity :slack, "Slack:#{channel_name}に投稿しました: #{res}"
        Delayer.new {
          # 投稿成功時はpostboxのメッセージを初期化
          Plugin.create(:gtk).widgetof(opt.widget).widget_post.buffer.text = ''
        }
      }.trap { |err|
        activity :slack, "Slack:#{channel_name}への投稿に失敗しました: #{err}"
        error "#{self.class.to_s}: #{msg}"
      }
    end
  end

end
