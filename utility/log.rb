# -*- coding: utf-8 -*-

module Plugin::Slack
  class << self

    # デバッグログ
    # @param [self] this self
    # @param [String] msg メッセージ
    def logd(this, msg)
      notice "#{this.class.to_s}: #{msg}"
    end

    # エラーログ
    # @param [self] this self
    # @param [self] msg メッセージ
    def loge(this, msg)
      error "#{this.class.to_s}: #{msg}"
    end

  end
end
