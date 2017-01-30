# -*- coding: utf-8 -*-
require 'uri'

module Plugin::Slack
  module Entity

    MessageEntity = Retriever::Entity::RegexpEntity.
        #
        # Slackの画像URLのパース
        # そのままのURLだと, 画像を含んだHTMLが返ってくるため画像のみのURLに変換する
        # その他はそのままリンクにする
        # また, <https://teamname.slack.com/...|label> といった形式の場合は, faceをlabelにする
        #
        # @example
        #   before -> https://teamname.slack.com/files/username/random_id/filename
        #   after -> https://files.slack.com/files-pri/team_id-random_id/filename
        #
        # FIXME: 画像を開く際にはリクエストヘッダーをつける必要があるが、その処理を追加出来ていない
        filter(/<https:\/\/[\w\-]+\.slack\.com\/files\/[\w\-]+\/[\w\-]+\/.+(\.(jpg|jpeg|gif|png|bmp)).*>/, generator: -> s {
          matched = /<https:\/\/[\w\-]+\.slack\.com\/files\/[\w\-]+\/(?<id>[\w\-]+)\/(?<filename>.+?)(?:\|(?<face>.+))?>/.match(s[:url])
          # 画像のURLを生成
          url = Retriever::URI(URI.encode("https://files.slack.com/files-pri/#{s[:message].team.id}-#{matched[:id]}/#{matched[:filename]}")).to_uri.to_s
          s.merge(open: url, face: matched[:face] || url, url: url)
        }).
        filter(/<https?:\/\/.+>/, generator: -> s {
          matched = /<(?<url>https?:\/\/.+?)(?:\|(?<face>.+))?>/.match(s[:url])
          s.merge(open: matched[:url], face: matched[:face] || matched[:url], url: matched[:url])
        }).
        #
        # @everyone や @here などの特殊コマンド
        # <!everyone> や <!here> といったフォーマット
        filter(/<!.+>/, generator: -> s {
          s.merge(face: unescape(s[:face]))
        }).
        #
        # チャンネルのリンクを表す
        # ex. #channel -> <channel_id>
        filter(/<#C.+>/, generator: -> s {
          matched = /<#(?<id>C.+)\|.+>/.match(s[:face])
          s[:message].team.channel(matched[:id]).next { |c|
            s[:message].entity.add(s.merge(face: unescape(s[:face]), open: c))
          }
          s.merge(face: unescape(s[:face]))
        }).
        #
        # ユーザーを表す
        # @example
        #   @hoge -> <user_id> または <user_id|hoge>
        filter(/<(@(U[\w\-]+)).*?>/, generator: -> s {
          matched = /<(@(?<id>U.+?)(?:\|(?<name>.+))?)>/.match(s[:face])
          name = matched[:name] || "loading(#{matched[:id]})"

          if matched[:name].nil?
            s[:message].team.user(matched[:id]).next { |user|
              uri = Retriever::URI(URI.encode("https://#{s[:message].team.name}.slack.com/team/#{user.name}")).to_uri.to_s
              s[:message].entity.add(s.merge(open: uri, url: uri, face: "@#{user.name}"))
            }.trap { |e|
              error e
              name = "error(#{matched[:id]})"
            }
          end

          uri = Retriever::URI("https://#{s[:message].team.name}.slack.com/team/#{matched[:id]}").to_uri.to_s
          s.merge(open: uri, url: uri, face: name)
        }).
        #
        # 絵文字を表す
        # @example
        #   :emoji_id: -> emoji_name
        filter(/:[\w\-]+:/, generator: -> s {
          matched = /:(?<name>[\w\-]+):/.match(s[:face])
          s.merge(open: 'http://totori.dip.jp/', face: matched[:name], url: 'http://totori.dip.jp/')
        }).
        #
        # 残り
        filter(/<(.*)>/, generator: -> s {
          p s[:face]
          s.merge(face: unescape(s[:face]))
        })


    private


    # @see https://github.com/slack-ruby/slack-ruby-client/blob/master/lib/slack/messages/formatting.rb
    def self.unescape(message)
      CGI.unescapeHTML(message.gsub(/[“”]/, '"')
                           .gsub(/[‘’]/, "'")
                           .gsub(/<(?<sign>[?@#!]?)(?<dt>.*?)>/) { |_|
        sign = $~[:sign]
        dt = $~[:dt]
        rhs = dt.split('|', 2).last
        case sign
          when '@', '!'
            "@#{rhs}"
          when '#'
            "##{rhs}"
          else
            rhs
        end
      })
    end
  end
end
