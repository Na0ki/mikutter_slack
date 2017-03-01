# -*- coding: utf-8 -*-
module Plugin::Slack::API
  class Object
    attr_reader :parent
    alias_method :api, :parent

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
    def request_thread(identity, &block)
      promise = Delayer.Deferred.new(true)
      request_thread_pool(identity).new do
        begin
          result = request_thread_cache[identity] ||= block.call
          promise.call(result)
        rescue Exception => err
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
