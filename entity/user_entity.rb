# -*- coding: utf-8 -*-

module Plugin::Slack
  module Entity

    UserEntity = Retriever::Entity::RegexpEntity.
        filter(/<(@(U.+)\|(.+)||@(U.+))>/, generator: -> s {
          # TODO: ユーザーリストを取得して、マッチさせて表示名をIDからスクリーンネームにする
          p s[:face]
          default_face = /<(@(U.+)\|(.+)||@(U.+))>/.match(s[:face])
          p default_face
          s
        })

  end
end
