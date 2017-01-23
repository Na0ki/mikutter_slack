# -*- coding: utf-8 -*-
require 'uri'

module Plugin::Slack
  module Entity

    MessageEntity = Retriever::Entity::RegexpEntity.
        #
        # Slackの画像URLのパース
        # そのままのURLだと, 画像を含んだHTMLが返ってくるため画像のみのURLに変換する
        # example:
        # before -> https://teamname.slack.com/files/username/random_id/filename
        # after -> https://files.slack.com/files-pri/team_id-random_id/filename
        # FIXME: 画像を開く際にはリクエストヘッダーをつける必要があるが、その処理を追加出来ていない
        filter(/<https:\/\/[\w\-]+\.slack\.com\/files\/[\w\-]+\/[\w\-]+\/.+(\.(jpg|jpeg|gif|png|bmp)).*>/, generator: -> s {
          if s[:url] =~ /\|/
            matched = /<https:\/\/[\w\-]+\.slack\.com\/files\/[\w\-]+\/(?<id>[\w\-]+)\/(?<name>.+)\|(?<face>.+)>/.match(s[:url])
          else
            matched = /<(?<face>https:\/\/[\w\-]+\.slack\.com\/files\/[\w\-]+\/(?<id>[\w\-]+)\/(?<name>.+))>/.match(s[:url])
          end
          # 画像のURLを生成
          url = Retriever::URI(URI.encode("https://files.slack.com/files-pri/#{s[:message].team.id}-#{matched[:id]}/#{matched[:name]}")).to_uri.to_s
          s.merge(open: url, face: matched[:face], url: url)
        }).
        #
        # その他の外部リンク
        # httpのスキーマにマッチする
        filter(/<https?:\/\/.+>/, generator: -> s {
          if s[:url] =~ /\|/
            matched = /<(?<url>https?:\/\/.+)\|(?<face>.+)>/.match(s[:url])
            face = matched[:face]
          else
            matched = /<(?<url>https?:\/\/.+)>/.match(s[:url])
            face = matched[:url]
          end
          s.merge(open: matched[:url], face: face, url: matched[:url])
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
        # ex. @hoge -> <user_id> または <user_id|hoge>
        filter(/<(@(U[\w\-]+)).*?>/, generator: -> s {
          if s[:url] =~ /\|/
            matched = /<(@(?<id>U.+)\|(?<name>.+))>/.match(s[:face])
            user_id = matched[:id]
          else
            matched = /<@(?<id>U.+)>/.match(s[:face])
            user_id = matched[:id]
            s[:message].team.user(user_id).next { |user|
              uri = Retriever::URI(URI.encode("https://#{s[:message].team.name}.slack.com/team/#{user.name}")).to_uri.to_s
              s[:message].entity.add(s.merge(open: uri, url: uri, face: "@#{user.name}"))
            }.trap { |e| error e }
          end
          uri = Retriever::URI("https://#{s[:message].team.name}.slack.com/team/#{user_id}").to_uri.to_s
          s.merge(open: uri, url: uri, face: "error(#{user_id})")
        }).
        #
        # 絵文字を表す
        # :emoji_id:
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
