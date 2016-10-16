# -*- coding: utf-8 -*-

module Plugin::Slack
  class << self
    # Twitter cardsのURLを画像のURLに置き換える。
    # HTMLを頻繁にリクエストしないように、このメソッドを通すことでメモ化している。
    # ==== Args
    # [display_url] http://d250g2.com/
    # ==== Return
    # String 画像URL(http://d250g2.com/d250g2.jpg)
    def image(display_url)
      connection = HTTPClient.new
      page = connection.get_content(display_url)
      unless page.empty?
        doc = Nokogiri::HTML(page)
        doc.css('file_page_image').first.attribute('src') end end
    memoize :slack
  end
end

module Plugin::Slack
  defimageopener('slack', %r<^http://.+\.slack\.com/[a-zA-Z0-9]+>) do |display_url|
    img = Plugin::PhotoSupport.slack(display_url)
    open(img) if img
  end
end
