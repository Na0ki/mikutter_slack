# -*- coding: utf-8 -*-

module Plugin::Slack
  module Entity

    UserEntity = Retriever::Entity::RegexpEntity.
        filter(/<(@U.+)\|(.+)>/, generator: -> s {
          s.merge(message: 'test')
        })

  end
end
