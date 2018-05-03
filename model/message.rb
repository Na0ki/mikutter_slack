# -*- frozen_string_literal: true -*-

require_relative '../entity/message_entity'
require_relative '../model/user'
require_relative '../model/channel'

# Messageクラス
# @see https://toshia.github.io/writing-mikutter-plugin/model/2016/09/30/model-messagemixin.html
# @see https://toshia.github.io/writing-mikutter-plugin/model/2016/09/30/model-field.html
module Plugin::Slack
  # メッセージ Model
  class Message < Diva::Model
    include Diva::Model::MessageMixin

    register :slack_message, name: 'Slack Message'

    field.has :channel, Plugin::Slack::Channel, required: true
    field.has :user, Plugin::Slack::User, required: true
    field.string :text, required: true
    field.time :created
    field.string :team, required: true
    field.string :ts, required: true

    entity_class Diva::Entity::URLEntity
    entity_class Plugin::Slack::Entity::MessageEntity

    @emoji_score = {}

    alias description text

    # このMessageが所属するTeam
    #
    # @return [Plugin::Slack::Team] チーム
    def team
      channel.team
    end

    # Messageのリンク
    #
    # @return [Retriever::URI] リンク
    def perma_link
      Diva::URI("https://#{team.domain}.slack.com/archives/#{channel.name}/p#{ts.delete('.')}")
    end

    # @deprecated Use compose spell instead.
    def postable?(world = nil)
      world, = Plugin.filtering(:world_current, nil) unless world
      Plugin[:slack].compose?(self, world)
    end

    # @deprecated Use compose spell instead.
    def post(_to: nil, message:, **_kwrest)
      world, = Plugin.filtering(:world_current, nil)
      Plugin[:slack].compose(self, world, body: message)
    end

    def parse_emoji(text, yielder)
      return unless /:(.+)?:/.match?(text)

      # FIXME: Just for DEBUG
      if text&.include?('akkiesoft')
        puts 'parse emoji'
        puts '-' * 40
        puts "\n\n"
        p text
        puts "\n\n"
        puts '-' * 40
      end

      team.emoji(text).next { |url|

        puts 'emoji url'
        p url

        # 絵文字URLがaliasにされている場合を考慮する
        emoji_alias = /alias:(?<name>.+)?/.match(url)
        if emoji_alias.nil?
          yielder << [Plugin::Slack::Emoji.new(text, url, open(url))]
        else
          team.emoji(emoji_alias[:name]).next do |e_url|
            yielder << [Plugin::Slack::Emoji.new(text, e_url, open(e_url))]
          end
        end
      }.trap { |err|
        error err
        yielder << [Plugin::Score::TextNote.new(description: text)]
      }

      # team.emoji(matched[:name]).next { |url|
      # 絵文字URLがaliasにされている場合を考慮する
      # emoji_alias = /alias:(?<name>.+)?/.match(url)
      # if emoji_alias.nil?
      #   entity.add(s.merge(open: url, url: url, face: matched[:face]))
      # else
      #   team.emoji(emoji_alias[:name]).next { |e_url|
      #     entity.add(s.merge(open: e_url, url: e_url, face: matched[:face]))
      #   }
      # end
      # }.trap { |err|
      #   error err
      #   entity.add(s.merge(open: Skin['notfound.png'], face: matched[:name]))
      # }
      # s.merge(open: Skin['notfound.png'], face: matched[:name])
      # score = emojis.inject(Array(text)) { |fragments, emoji|
      #   name = ":#{emoji.name}:"
      #   fragments.flat_map do |fragment|
      #     if fragment.is_a?(String)
      #       if fragment == name
      #         [emoji]
      #       else
      #         sub_fragments = fragment.split(name).flat_map { |str| [str, emoji] }
      #         sub_fragments.pop unless fragment.end_with?(name)
      #         sub_fragments
      #       end
      #     else
      #       [fragment]
      #     end
      #   end
      # }.map { |chunk|
      #   if chunk.is_a?(String)
      #     Plugin::Score::TextNote.new(description: chunk)
      #   else
      #     chunk
      #   end
      # }
      #
      # yielder << score if !score.empty? || score.size == 1 && !score[0].is_a?(Plugin::Score::TextNote)
      # @emoji_score[text] = score
      yielder
    end

    def inspect
      "#{self.class}(channel=#{channel}, user=#{user})"
    end
  end
end
