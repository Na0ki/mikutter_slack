# -*- coding: utf-8 -*-
# -*- frozen_string_literal: true -*-

module Plugin::Slack
  # Userクラス
  # @see https://toshia.github.io/writing-mikutter-plugin/model/2016/09/30/model-usermixin.html
  # @see https://toshia.github.io/writing-mikutter-plugin/model/2016/09/30/model-field.html
  # @see https://api.slack.com/methods/users.info
  class User < Diva::Model
    include Diva::Model::UserMixin

    field.string :id, required: true
    field.string :name, required: true
    field.bool :deleted
    field.string :color

    # TODO: implement
    # field.has :profile, Plugin::Slack::Profile, required: true
    field.bool :is_admin
    field.bool :is_owner
    field.bool :has_2fa

    field.has :team, Plugin::Slack::Team, required: true

    def idname
      name
    end

    def icon
      _, photos = Plugin.filtering(:photo_filter, self[:profile][:image_48], [])
      photos.first
    rescue => err
      #error err
      Skin['notfound.png']
    end

    def perma_link
      Diva::URI("https://#{team.domain}.slack.com/team/#{name}")
    end

    def to_s
      name
    end

    def inspect
      "#{self.class}(id = #{id}, name = #{name})"
    end
  end
end
