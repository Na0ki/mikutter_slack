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
        Delayer::Deferred.new.next{ cache }
      else
        api.users.next{ |u| @users = u.freeze }
      end
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
        Delayer::Deferred.new.next{ cache }
      else
        api.channels.next{ |c| @channels = c.freeze }
      end
    end

    # チャンネルIDに対応するChannelをcallbackするDeferredを返す。
    # IDに対応するチャンネルが見つからなかった場合は、nilを引数に、trapブロックが呼ばれる。
    # @param [String] channel_id チャンネルID
    # @return [Delayer::Deferred::Deferredable] Channelを引数にcallbackするDeferred
    def channel(channel_id)
      id_detector(channels, channel_id)
    end

    private

    def id_detector(defer, id)
      defer.next{ |list|
        list.find{ |o| o.id == id } or Delayer::Deferred.fail(:id_notfound)
      }
    end

    def api
      self[:api]
    end
  end
end
