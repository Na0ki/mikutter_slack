# -*- coding: utf-8 -*-
require 'slack'
require_relative 'object'

module Plugin::Slack
  module API

    class Users < Object
      # ユーザーリストを取得
      # @return [Delayer::Deferred::Deferredable] チームの全ユーザを引数にcallbackするDeferred
      def list
        Delayer::Deferred.when(request_thread(:list) { api.client.users_list['members'] }, team).next do |user_list, a_team|
          user_list.map { |m| Plugin::Slack::User.new(m.symbolize.merge(team: a_team)) }
        end
      end

      # ユーザーリストを取得する
      # usersとの違いは、Deferredの戻り値がキーにユーザID、値にPlugin::Slack::Userを持ったHashであること。
      # @return [Delayer::Deferred::Deferredable] チームの全ユーザを引数にcallbackするDeferred
      def dict
        list.next { |ary| Hash[ary.map { |_| [_.id, _] }] }
      end

      # ボットの情報を取得
      # @return [Delayer::Deferred::Deferrable] チームのボットの情報を取得
      def bots
        Thread.new { api.client.bots_info }
      end

    end

  end
end
