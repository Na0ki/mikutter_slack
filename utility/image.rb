# -*- coding: utf-8 -*-

module Plugin::Slack
  class << self
    # slack
    defimageopener('twitpic', %r<^http://twitpic\.com/[a-zA-Z0-9]+>) do |display_url|

      # TODO: implement
      # 下記のはコピペ
      connection = HTTPClient.new
      page = connection.get_content(display_url)
      next nil if page.empty?
      doc = Nokogiri::HTML(page)
      result = doc.css('img').lazy.find_all{ |dom|
        %r<https?://.*?\.cloudfront\.net/photos/(?:large|full)/.*> =~ dom.attribute('src')
      }.first
      open(result.attribute('src'))
    end
  end
end