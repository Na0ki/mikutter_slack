# -*- coding: utf-8 -*-

# Team Model
# @see https://api.slack.com/methods/team.info
module Plugin::Slack
  class Team < Retriever::Model

    field.string :id, required: true
    field.string :name, required: true
    field.string :domain, required: true
    field.string :email_domain

    # このチームに所属しているユーザを列挙する
    # @return [Delayer::Deferred::Deferredable] チームの全ユーザを引数にcallbackするDeferred
    def users
      cache = @users
      if cache
        Delayer::Deferred.new.next { cache }
      else
        api.users.next { |u| @users = u.freeze }
      end
    end

    # このチームに所属しているユーザを、メモリキャッシュから返す。
    # もしこのTeamのインスタンスにユーザがキャッシュされていない場合は、nilを返す。
    # Deferredで結果を遅らせることができず、すぐに結果が手に入らないなら失敗したほうが良い場合にこのメソッドを使う。
    # APIリクエストをしても良い場合はこのメソッドの代わりに Plugin::Slack::Team#users を利用する。
    # @return [Array] チームに所属するユーザの配列
    # @return [nil] 取得に失敗した場合
    def users!
      @users
    end

    # ユーザIDに対応するUserをcallbackするDeferredを返す。
    # IDに対応するユーザが見つからなかった場合は、nilを引数に、trapブロックが呼ばれる。
    # @param [String] ユーザID
    # @return [Delayer::Deferred::Deferredable] Userを引数にcallbackするDeferred
    def user(user_id)
      id_detector(users, user_id)
    end

    # このチームの全てのChannelを列挙する
    # @return [Delayer::Deferred::Deferredable] チームの全Channelを引数にcallbackするDeferred
    def channels
      cache = @channels
      if cache
        Delayer::Deferred.new.next { cache }
      else
        api.channels.next { |c| @channels = c.freeze }
      end
    end

    # このチームに所属しているチャンネルを、メモリキャッシュから返す。
    # もしこのTeamのインスタンスにチャンネルがキャッシュされていない場合は、nilを返す。
    # Deferredで結果を遅らせることができず、すぐに結果が手に入らないなら失敗したほうが良い場合にこのメソッドを使う。
    # APIリクエストをしても良い場合はこのメソッドの代わりに Plugin::Slack::Team#channels を利用する。
    # @return [Array] チームに所属するチャンネルの配列
    # @return [nil] 取得に失敗した場合
    def channels!
      @channels
    end

    # チャンネルIDに対応するChannelをcallbackするDeferredを返す。
    # IDに対応するチャンネルが見つからなかった場合は、nilを引数に、trapブロックが呼ばれる。
    # @param [String] channel_id チャンネルID
    # @return [Delayer::Deferred::Deferredable] Channelを引数にcallbackするDeferred
    def channel(channel_id)
      id_detector(channels, channel_id)
    end


    # TODO: コメントを書く
    def emojis
      # cache = @emoji
      # if cache
      #   Delayer::Deferred.new.next { cache }
      # else
      #   api.team.next { |t| @emoji = t.emoji_list[:emoji].freeze }
      # end
    end


    def emojis!
      @emoji
    end


    def emoji(emoji_name)
      id_detector(emojis, emoji_name)
    end

    def perma_link
      Retriever::URI("https://#{domain}.slack.com/")
    end

    def api
      self[:api]
    end

    def inspect
      "#{self.class.to_s}(id=#{id}, name=#{name})"
    end

    private

    def id_detector(defer, id)
      defer.next { |list|
        list.find { |o| o.id == id } or Delayer::Deferred.fail(:id_notfound)
      }
    end
  end
end
