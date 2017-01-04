# -*- coding: utf-8 -*-
require 'uri'

module Plugin::Slack
  module Entity

    MessageEntity = Retriever::Entity::RegexpEntity.
        filter(/<(https:\/\/.+\.slack\.com\/files\/[\w\-]+\/([\w\-]+)\/(.+)(\.jpg|\.jpeg|\.gif|\.png|\.bmp)(.*|\|[\w\-]+))>/, generator: -> s {
          # FIXME: 画像を開く際にはリクエストヘッダーをつける必要があるが、その処理を追加出来ていない
          m = /<(.+)>/.match(s[:url])[1]
          if s[:url] =~ /\|/
            n = /https:\/\/.+\.slack\.com\/files\/[\w\-]+\/([\w\-]+)\/(.+)/.match(m&.split('|')[0])
            face = m.split('|')[1] # 表示名
          else
            n = /https:\/\/.+\.slack\.com\/files\/[\w\-]+\/([\w\-]+)\/(.+)/.match(m)
            face = m # 表示名（元URL）
          end
          url = Retriever::URI("https://files.slack.com/files-pri/#{s[:message].team.id}-#{n[1]}/#{n[2]}").to_uri.to_s
          s.merge(open: url,
                  face: face,
                  url: url)
        }).
        filter(/<https?:\/\/.+>/, generator: -> s {
          orig = /<(.+)>/.match(s[:face])[1]
          if s[:url] =~ /\|/
            n = orig&.split('|')
            url = n[0]
            face = n[1]
          else
            url = orig
            face = url
          end
          s.merge(open: url,
                  face: face,
                  url: url)
        }).
        filter(/<(!.+)>/, generator: -> s {
          s.merge(face: unescape(s[:face]))
        }).
        filter(/<(#(C.+)\|(.+))>/, generator: -> s {
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
