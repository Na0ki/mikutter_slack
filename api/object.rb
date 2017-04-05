# -*- coding: utf-8 -*-
# -*- frozen_string_literal: true -*-

module Plugin::Slack
  module API
    # 基底クラス
    class Object
      attr_reader :parent
      alias api parent

      def initialize(parent)
        @parent = parent
      end

      def team
        parent.team
      end

      private

      # TODO: comment
      #
      # @param [Symbol] identity
      # @param [callback]
      def request_thread(identity)
        promise = Delayer.Deferred.new(true)
        request_thread_pool(identity).new do
          begin
            result = request_thread_cache[identity] ||= yield
            promise.call(result)
          rescue StandardError => err
            promise.fail(err)
          end
        end
        promise
      end

      # TODO: comment
      #
      # @param [Symbol] _identity
      memoize def request_thread_pool(_identity)
        SerialThreadGroup.new
      end

      # TODO: comment
      #
      def request_thread_cache
        @request_thread_cache ||= TimeLimitedStorage.new(Symbol)
      end
    end
  end
end
