# -*- coding: utf-8 -*-
require 'uri'

module Plugin::Slack
  module Entity

    MessageEntity = Retriever::Entity::RegexpEntity.
        filter(/<(https:\/\/.+\.slack\.com\/files\/([\w\-]+)\/([\w\-]+)\/([\w\-]+)\.(jpg|jpeg|gif|png|bmp)(|\|(.*)))>/, generator: -> s {
          # s_url = +s[:url]
          # p "s_url = #{s_url}"
          # no_title = /<(https:\/\/.+\.slack\.com\/files\/([\w\-]+)\/([\w\-]+)\.(jpg|jpeg|gif|png|bmp))>/.match(s[:url])
          # with_title = /<(https:\/\/.+\.slack\.com\/files\/([\w\-]+)\/([\w\-]+)\/([\w\-]+)\.(jpg|jpeg|gif|png|bmp)\|(.*))>/.match(s[:url])
          # if no_title.nil?
          #   uri = with_title[3] # files-priに続くURI
          #   ext = with_title[4] # ファイル拡張子
          #   face = with_title[5] # 表示（ファイル名）
          # else
          #   uri = no_title[3] # files-priに続くURI
          #   ext = no_title[4] # ファイル拡張子
          #   face = no_title[1] # 表示（元URL）
          # end
          # url = "https://files.slack.com/files-pri/#{s[:message].team.id}-#{uri}.#{ext}"
          # s.merge(open: url,
          #         face: face,
          #         url: url)
          s
        }).
        filter(/<(!.+)>/, generator: -> s {
          s
        }).
        filter(/<(#(C.+)\|(.+))>/, generator: -> s {
          channel_face = /<(#(C.+)\|(.+))>/.match(s[:face])
          # s.merge(face: default_face[3])
          s
        }).
        filter(/<(@(U[\w\-]+)).*?>/, generator: -> s {
          no_name = /^(?!.*\|).*(?=@U+).*$/.match(s[:face]) # |（パイプ）を含まない文字列を取得
          with_name = /<(@(U.+)\|(.+))>/.match(s[:face]) # |（パイプ）の後にユーザー名が入っているもの
          if no_name.nil?
            user_id = with_name[2]
            user_name = "@#{with_name[3]}"
          else
            no_name = /<(@(U.+))>/.match(s[:face])
            user_id = no_name[1]
            user_name = no_name[1] # FIXME: ユーザーリストを取得して、マッチさせて表示名をIDからスクリーンネームにする
          end
          s.merge(url: user_id,
                  face: user_name)
        }).
        filter(/:[\w\-]+:/, generator: -> s {
          emoji_name = /:([\w\-]+):/.match(s[:face])[1]
          s.merge(open: 'http://totori.dip.jp/',
                  face: emoji_name,
                  url: 'http://totori.dip.jp/')
        }).
        filter(/<(.*)>/, generator: -> s {
          # p "others: #{s[:face]}"
          s
        })
  end
end
