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
        filter(/<!.+>/, generator: -> s {
          s.merge(face: unescape(s[:face]))
        }).
        filter(/<#C.+>/, generator: -> s {
          matched = /<#(C.+)\|(.+)>/.match(s[:face])
          s[:message].team.channel(matched[1]).next { |c|
            s[:message].entity.add(s.merge(face: unescape(s[:face]),
                                           open: c))
          }
          s.merge(face: unescape(s[:face]))
        }).
        filter(/<(@(U[\w\-]+)).*?>/, generator: -> s {
          if s[:url] =~ /\|/
            user_id = /<(@(U.+)\|(.+))>/.match(s[:face])[2]
          else
            user_id = /<@(U.+)>/.match(s[:face])[1]
            s[:message].team.user(user_id).next { |user|
              uri = Retriever::URI(URI.encode("https://#{s[:message].team.name}.slack.com/team/#{user.name}")).to_uri.to_s
              s[:message].entity.add(s.merge(open: uri,
                                             url: uri,
                                             face: "@#{user.name}"))
            }.trap { |err|
              error err
            }
          end
          uri = Retriever::URI("https://#{s[:message].team.name}.slack.com/team/#{user_id}").to_uri.to_s
          s.merge(open: uri,
                  url: uri,
                  face: "error(#{user_id})")
        }).
        filter(/:[\w\-]+:/, generator: -> s {
          emoji_name = /:([\w\-]+):/.match(s[:face])[1]
          s.merge(open: 'http://totori.dip.jp/',
                  face: emoji_name,
                  url: 'http://totori.dip.jp/')
        }).
        filter(/<(.*)>/, generator: -> s {
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
