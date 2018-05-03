# frozen_string_literal: true

require_relative '../api'

module Plugin::Slack
  # World model
  class World < Diva::Model
    register :slack, name: 'Slack'

    field.string :slug, required: true
    field.string :token, required: true

    attr_writer :user

    def self.build(token)
      world = new(token: token, slug: '')
      Delayer::Deferred.when(
        Thread.new { world.api.client.auth_test },
        world.api.users.dict
      ).next { |auth, user_map|
        world.user = user_map[auth['user_id']]
        world.slug = "slack-#{auth['team_id']}-#{auth['user_id']}".to_sym
        world
      }
    end

    def initialize(args)
      notice args.inspect
      super(args)
      user_refresh if args[:user].is_a?(Hash)
      api.realtime_start
    end

    def user
      @user || Plugin::Slack::User.new(self[:user])
    end

    def team
      user.team
    end

    def icon
      user.icon
    end

    def title
      "#{user.name}(#{team&.domain}.slack.com)"
    end

    def api
      @api ||= Plugin::Slack::API::APA.new(token)
    end

    def to_hash
      super.merge(
        user: {
          id: user.id,
          name: user.name,
          profile: { image_48: user[:profile][:image_48] }
        }
      )
    end

    # @deprecated Use compose spell instead.
    def post(to: nil, message:, **_kwrest)
      Plugin[:slack].compose(self, to, body: message)
    end

    # @deprecated Use compose spell instead.
    def postable?(target = nil)
      Plugin[:slack].compose?(self, target)
    end

    def inspect
      "#<#{self.class}: #{team.domain}.slack.com #{user.inspect}>"
    end

    private

    def user_refresh
      api.users.dict.next { |user_map|
        notice user_map
        notice "user id: #{self[:user].inspect}"
        @user = user_map[self[:user][:id]]
        notice user.inspect
      }.trap { |err|
        error err
      }
    end
  end
end
