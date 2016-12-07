# -*- coding: utf-8 -*-

module Plugin::Slack
  module Entity

    MessageEntity = Retriever::Entity::RegexpEntity.
        filter(/<(!.+)>/, generator: -> s {
          # FIXME: なんかマッチしない
          s
        }).
        filter(/<(https:\/\/.+\.slack\.com\/files\/([\w\-]+)\/([\w\-]+)\/(.+)\.png\|(.*))>/, generator: -> s {
          default_url = /<(https:\/\/.+\.slack\.com\/files\/([\w\-]+)\/(.+)\.png\|(.*))>/.match(s[:url])
          url = "https://files.slack.com/files-pri/#{s[:message].team.id}-#{default_url[3]}.png"
          Thread.new {

          }.next { |res|
            p res
            s.merge(open: res, face: default_url[4])
          }
        })
  end
end
