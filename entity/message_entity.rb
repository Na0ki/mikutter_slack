# -*- coding: utf-8 -*-

module Plugin::Slack
  module Entity

    # api = Plugin::Slack::Api

    # イワシがいっぱいだあ…ちょっとだけもらっていこうかな
    MessageEntity = Retriever::Entity::RegexpEntity.
        filter(/<#(C.+)>/, generator: -> s {
          s
        }).
        filter(/<@(U.+)>/, generator: -> s {
          s
        }).
        filter(/<!(.+)>/, generator: -> s {
          s
        }).
        filter(/:[\w\-]+:/, generator: -> s {
          team = s[:message].team
          team_id = team.id
          emoji_name = /:([\w\-]+):/.match(s[:face])[1]
          p team
          p team.emoji(emoji_name)

          s.merge(open: "slack://#{team_id}/emoji/#{emoji_name}",
                  face: emoji_name
          )
        }).
        filter(/<(https:\/\/.+\.slack\.com\/files\/([\w\-]+)\/([\w\-]+)\/(.+)\.png\|(.*))>/, generator: -> s {
          p s
          default_url = /<(https:\/\/.+\.slack\.com\/files\/([\w\-]+)\/(.+)\.png\|(.*))>/.match(s[:url])
          url = "https://files.slack.com/files-pri/#{s[:message].team.id}-#{default_url[3]}.png"
          s.merge(open: url, face: default_url[4], url: url)
        })
  end
end
