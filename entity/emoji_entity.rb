# -*- coding: utf-8 -*-

module Plugin::Slack
  module Entity

    # イワシがいっぱいだあ…ちょっとだけもらっていこうかな
    # EmojiEntity = Retriever::Entity::RegexpEntity.
    #     filter(/:[\w\-]+:/, generator: -> s {
    #       s.merge(open: 'http://totori.dip.jp/')
    #     })

    EmojiEntity = Retriever::Entity::RegexpEntity.
        filter(/:[\w\-]+:/, generator: -> s {
          team = s[:message].team
          team_id = team.id
          emoji_name = /:([\w\-]+):/.match(s[:face])[1]

          s.merge(open: "slack://#{team_id}/emoji/#{emoji_name}",
                  face: emoji_name
          )
        })

  end
end
