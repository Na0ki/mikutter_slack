# -*- coding: utf-8 -*-

module Plugin::Slack
  # Userクラス
  # @see https://toshia.github.io/writing-mikutter-plugin/model/2016/09/30/model-usermixin.html
  # @see https://toshia.github.io/writing-mikutter-plugin/model/2016/09/30/model-field.html
  class User < Retriever::Model
    include Retriever::Model::UserMixin

    field.string :id, required: true
    field.string :name, required: true
    field.has :team, Plugin::Slack::Team, required: true

    def idname
      name
    end

    def profile_image_url
      self[:profile][:image_48]
    end

    def perma_link
      Retriever::URI("https://#{team.domain}.slack.com/team/#{name}")
    end

    def inspect
      "#{self.class.to_s}(id = #{id}, name = #{name})"
    end
  end
end
