# -*- coding: utf-8 -*-
# -*- frozen_string_literal: true -*-

module Plugin::Slack
  # Emoji モデル
  class Emoji < Retriever::Model
    field.string :name, required: true
    field.string :url, required: true
    field.has :image, Diva::Model, required: true

    def perma_link
      url
    end

    def inspect
      "#{self.class}(name=#{name}, url=#{url})"
    end
  end
end
