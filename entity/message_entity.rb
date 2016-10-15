# -*- coding: utf-8 -*-

module Plugin::Slack
  module Entity

    # イワシがいっぱいだあ…ちょっとだけもらっていこうかな
    MessageEntity = Retriever::Entity::RegexpEntity.
        filter(/<(.*?)>/, generator: -> s {
          s
        }).
        filter(/<(#C.+)>/, generator: -> s {
          s
        }).
        filter(/<(@U.+)>/, generator: -> s {
          s
        }).
        filter(/<!.+>/, generator: -> s {
          s
        }).
        filter(/:[\w\-]+:/, generator: -> s {
          s.merge(open: 'http://totori.dip.jp/')
        })

  end
end
