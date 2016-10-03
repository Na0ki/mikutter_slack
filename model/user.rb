# -*- coding: utf-8 -*-

# Userクラス
# @see https://toshia.github.io/writing-mikutter-plugin/model/2016/09/30/model-usermixin.html
# @see https://toshia.github.io/writing-mikutter-plugin/model/2016/09/30/model-field.html
module Plugin::Slack
  class User < Retriever::Model
    include Retriever::Model::UserMixin

    field.string :idname, required: true
    field.string :name, required: true
    field.string :profile_image_url
  end
end
