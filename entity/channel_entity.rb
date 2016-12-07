# -*- coding: utf-8 -*-

module Plugin::Slack
  module Entity

    ChannelEntity = Retriever::Entity::RegexpEntity.
        filter(/<(#(C.+)\|(.+))>/, generator: -> s {
          default_face = /<(#(C.+)\|(.+))>/.match(s[:face])
          p default_face
          # s.merge(face: default_face[3])
          s
        })
  end
end