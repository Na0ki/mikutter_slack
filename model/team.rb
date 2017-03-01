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
    #
    # @return [Delayer::Deferred::Deferredable] チームの全ユーザを引数にcallbackするDeferred
    def users
      cache = @users
      if cache
        Delayer::Deferred.new.next { cache }
      else
        api.users.list.next { |u| @users = u.freeze }
      end
    end

    def user_dict
      users.next { |users_iter| Hash[users_iter.map { |u| [u.id, u] }] }
    end

    # このチームに所属しているユーザを、メモリキャッシュから返す。
    # もしこのTeamのインスタンスにユーザがキャッシュされていない場合は、nilを返す。
    # Deferredで結果を遅らせることができず、すぐに結果が手に入らないなら失敗したほうが良い場合にこのメソッドを使う。
    # APIリクエストをしても良い場合はこのメソッドの代わりに Plugin::Slack::Team#users を利用する。
    #
    # @return [Array] チームに所属するユーザの配列
    # @return [nil] 取得に失敗した場合
    def users!
      @users
    end

    # ユーザIDに対応するUserをcallbackするDeferredを返す。
    # IDに対応するユーザが見つからなかった場合は、nilを引数に、trapブロックが呼ばれる。
    #
    # @param [String] ユーザID
    # @return [Delayer::Deferred::Deferredable] Userを引数にcallbackするDeferred
    def user(user_id)
      id_detector(users, user_id)
    end

    # このチームの全てのChannelを列挙する
    #
    # @return [Delayer::Deferred::Deferredable] チームの全Channelを引数にcallbackするDeferred
    def channels
      cache = @channels
      if cache
        Delayer::Deferred.new.next { cache }
      else
        api.channel.list.next { |c| @channels = c.freeze }
      end
    end

    # このチームに所属しているチャンネルを、メモリキャッシュから返す。
    # もしこのTeamのインスタンスにチャンネルがキャッシュされていない場合は、nilを返す。
    # Deferredで結果を遅らせることができず、すぐに結果が手に入らないなら失敗したほうが良い場合にこのメソッドを使う。
    # APIリクエストをしても良い場合はこのメソッドの代わりに Plugin::Slack::Team#channels を利用する。
    #
    # @return [Array] チームに所属するチャンネルの配列
    # @return [nil] 取得に失敗した場合
    def channels!
      @channels
    end

    # チャンネルIDに対応するChannelをcallbackするDeferredを返す。
    # IDに対応するチャンネルが見つからなかった場合は、nilを引数に、trapブロックが呼ばれる。
    #
    # @param [String] channel_id チャンネルID
    # @return [Delayer::Deferred::Deferredable] Channelを引数にcallbackするDeferred
    def channel(channel_id)
      id_detector(channels, channel_id)
    end

    # このチームの全てのEmojiを列挙する
    #
    # @return [Delayer::Deferred::Deferredable] チームの全Emojiを引数にcallbackするDeferred
    def emojis
      cache = @emoji
      if cache
        Delayer::Deferred.new.next { cache }
      else
        api.emoji.list.next { |emoji| @emoji = emoji }
      end
    end

    # このチームに所属しているEmojiを、メモリキャッシュから返す。
    # もしこのTeamのインスタンスにEmojiがキャッシュされていない場合は、nilを返す。
    # Deferredで結果を遅らせることができず、すぐに結果が手に入らないなら失敗したほうが良い場合にこのメソッドを使う。
    # APIリクエストをしても良い場合はこのメソッドの代わりに Plugin::Slack::Team#emoji を利用する。
    #
    # @return [Array] チームに所属するEmojiの配列
    # @return [nil] 取得に失敗した場合
    def emojis!
      @emoji
    end

    # Emoji名に対応するEmojiをcallbackするDeferredを返す。
    # IDに対応するチャンネルが見つからなかった場合は、nilを引数に、trapブロックが呼ばれる。
    # 基本的にはURLを返すが、他の絵文字にaliasされている場合は `alias:絵文字名` といった形式の文字列を返す
    #
    # @param [String] emoji_name emoji名
    # @return [Delayer::Deferred::Deferredable] EmojiのURLを引数にcallbackするDeferred
    def emoji(emoji_name)
      emojis.next { |e| e[emoji_name] or Delayer::Deferred.fail(:emoji_not_found) }
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
      defer.next { |list| list.find { |o| o.id == id } or Delayer::Deferred.fail(:id_not_found) }
    end

  end
end
