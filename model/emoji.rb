# -*- coding: utf-8 -*-
'slack'

module Plugin::Slack
  class Emoji < Retriever::Model

    field.string :name, required: true
    field.string :url, required: true
    field.has :image, Retriever::Model, required: true


    def perma_link
      url
    end

    def inspect
      "#{self.class.to_s}(name=#{name}, url=#{url})"
    end

  end
end
