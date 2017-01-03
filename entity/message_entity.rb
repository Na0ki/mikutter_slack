# -*- coding: utf-8 -*-
require 'uri'

module Plugin::Slack
  module Entity

    MessageEntity = Retriever::Entity::RegexpEntity.
        filter(/<(https:\/\/.+\.slack\.com\/files\/[\w\-]+\/([\w\-]+)\/(.+)(\.jpg|\.jpeg|\.gif|\.png|\.bmp)(.*|\|[\w\-]+))>/, generator: -> s {
          # FIXME: 画像を開く際にはリクエストヘッダーをつける必要があるが、その処理を追加出来ていない
          # TODO: URL周りは取りこぼしが多いのでカバーする
          if s[:url] =~ /\|/
            tmp = /<(.+)>/.match(s[:url])[1]&.split('|') # URLとファイル名で分割（区切り文字パイプ）
            tmp2 = /https:\/\/.+\.slack\.com\/files\/[\w\-]+\/([\w\-]+)\/(.+)/.match(tmp[0])
            face = tmp[1] # 表示名
          else
            tmp = /<(.+)>/.match(s[:url])[1]
            tmp2 = /https:\/\/.+\.slack\.com\/files\/[\w\-]+\/([\w\-]+)\/(.+)/.match(tmp)
            face = tmp # 表示名（元URL）
          end
          url = "https://files.slack.com/files-pri/#{s[:message].team.id}-#{tmp2[1]}/#{tmp2[2]}"
          s.merge(open: url,
                  face: face,
                  url: url)
        }).
        filter(/<https?:\/\/.+>/, generator: -> s {
          url = /<(.+)>/.match(s[:face])[1]
          s.merge(open: url,
                  face: url,
                  url: url)
        }).
        filter(/<(!.+)>/, generator: -> s {
          s
        }).
        filter(/<(#(C.+)\|(.+))>/, generator: -> s {
          s
        }).
        filter(/<(@(U[\w\-]+)).*?>/, generator: -> s {
          no_name = /^(?!.*\|).*(?=@U+).*$/.match(s[:face]) # |（パイプ）を含まない文字列を取得
          with_name = /<(@(U.+)\|(.+))>/.match(s[:face]) # |（パイプ）の後にユーザー名が入っているもの
          team_name = s[:message].team.name
          if no_name.nil?
            user_id = with_name[2]
          else
            no_name = /<@(U.+)>/.match(s[:face])
            user_id = no_name[1]
            s[:message].team.user(user_id).next { |user|
              s[:message].entity.add(s.merge(open: "https://#{team_name}.slack.com/team/#{user.name}",
                                             url: "https://#{team_name}.slack.com/team/#{user.name}",
                                             face: "@#{user.name}"))
            }.trap { |err|
              error err
            }
          end
          s.merge(open: "https://#{team_name}.slack.com/team/#{user_id}",
                  url: "https://#{team_name}.slack.com/team/#{user_id}",
                  face: "error(#{user_id})")
        }).
        filter(/:[\w\-]+:/, generator: -> s {
          emoji_name = /:([\w\-]+):/.match(s[:face])[1]
          s.merge(open: 'http://totori.dip.jp/',
                  face: emoji_name,
                  url: 'http://totori.dip.jp/')
        }).
        filter(/<(.*)>/, generator: -> s {
          puts "others: #{s[:face]}"
          s
        })
  end
end
