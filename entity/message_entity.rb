# -*- frozen_string_literal: true -*-

require 'uri'

module Plugin::Slack
  # メッセージのEntityを色々いじる
  module Entity
    # TODO: `foo` や ```hoge``` といった投稿の場合はパースしない
    MessageEntity = Diva::Entity::RegexpEntity.
      #
      # Slackの画像URLのパース
      # そのままのURLだと, 画像を含んだHTMLが返ってくるため画像のみのURLに変換する
      # その他はそのままリンクにする
      # また, <https://teamname.slack.com/...|label> といった形式の場合は, faceをlabelにする
      #
      # @example
      #   before -> <https://teamname.slack.com/files/username/random_id/filename>
      #   after -> https://files.slack.com/files-pri/team_id-random_id/filename
      #
      # FIXME: 画像を開く際にはリクエストヘッダーをつける必要があるが、その処理を追加出来ていない
      filter(%r{<https:\/\/[\w\-]+\.slack\.com\/files\/[\w\-]+\/[\w\-]+\/.+(\.(jpg|jpeg|gif|png|bmp)).*?>}, generator: lambda { |s|
        matched = %r{<https:\/\/[\w\-]+\.slack\.com\/files\/[\w\-]+\/(?<id>[\w\-]+)\/(?<filename>.+?)(?:\|(?<face>.+))?>}.match(s[:url])
        # 画像のURLを生成
        url = Diva::URI(
          URI.encode("https://files.slack.com/files-pri/#{s[:message].team.id}-#{matched[:id]}/#{matched[:filename]}")
        ).to_uri.to_s
        s.merge(open: url, face: matched[:face] || url, url: url)
      }).
      #
      # その他HTTPなURLのパース(http, https)
      # また, <https://sample.example.com/...|label> といった形式の場合は, faceをlabelにする
      #
      # @example
      #   before -> <https://github.com>
      #   after -> https://github.com
      filter(%r{<https?:\/\/.+?>}, generator: lambda { |s|
        matched = %r{<(?<url>https?:\/\/.+?)(?:\|(?<face>.+))?>}.match(s[:url])
        s.merge(open: matched[:url], face: matched[:face] || matched[:url], url: matched[:url])
      }).
      #
      # @everyone や @here などの特殊コマンドのパース
      # <!everyone> や <!here|@here> といったフォーマット
      #
      # @example
      #   <!here|@here> -> @here
      filter(/<!.+?>/, generator: lambda { |s|
        matched = /<!(?<id>[A-Za-z]+?)(?:\|(?<name>[!-~]+?))?>/.match(s[:face])
        s.merge(face: matched[:name] || "@#{matched[:id]}")
      }).
      #
      # チャンネル名のパース
      # チャンネルIDは大文字のCをプレフィックスに持つ
      #
      # @example
      #   <#channel_id|channel_name> -> #channel_name
      filter(/<#C.+?>/, generator: lambda { |s|
        matched = /<#(?<id>C.+?)\|.+?>/.match(s[:face])
        s[:message].team.channel(matched[:id]).next { |c|
          s[:message].entity.add(s.merge(face: unescape(s[:face]), open: c))
        }
        s.merge(face: unescape(s[:face]))
      }).
      #
      # ユーザーのパース
      # ユーザーIDは大文字のUをプレフィックスに持つ
      #
      # @example
      #   @hoge -> <user_id> または <user_id|hoge>
      filter(/<(@(U[\w\-]+)).*?>/, generator: lambda { |s|
        matched = /<(@(?<id>U.+?)(?:\|(?<name>.+))?)>/.match(s[:face])
        name = matched[:name] || "loading(#{matched[:id]})"

        if matched[:name].nil?
          s[:message].team.user(matched[:id]).next { |user|
            uri = Diva::URI(URI.encode("https://#{s[:message].team.name}.slack.com/team/#{user.name}")).to_uri.to_s
            s[:message].entity.add(s.merge(open: uri, url: uri, face: "@#{user.name}"))
          }.trap { |err|
            error err
            uri = Diva::URI(URI.encode("https://#{s[:message].team.name}.slack.com/team/#{matched[:id]}")).to_uri.to_s
            s[:message].entity.add(s.merge(open: uri, url: uri, face: "error(#{matched[:id]})"))
          }
        end

        uri = Diva::URI("https://#{s[:message].team.name}.slack.com/team/#{name}").to_uri.to_s
        s.merge(open: uri, url: uri, face: "@#{name}")
      }).
      #
      # 絵文字をパースする
      # TODO: Emoji IDから絵文字を取得しentityに情報として追加する
      #
      # @example
      #   :emoji_id: -> emoji_id
      filter(/:[\w\-]+:/, generator: lambda { |s|
        matched = /(?<face>:(?<name>[\w\-]+)?:)/.match(s[:face])
        s[:message].team.emoji(matched[:name]).next { |url|
          # 絵文字URLがaliasにされている場合を考慮する
          emoji_alias = /alias:(?<name>.+)?/.match(url)
          if emoji_alias.nil?
            s[:message].entity.add(s.merge(open: url, url: url, face: matched[:face]))
          else
            s[:message].team.emoji(emoji_alias[:name]).next { |e_url|
              s[:message].entity.add(s.merge(open: e_url, url: e_url, face: matched[:face]))
            }
          end
        }.trap { |err|
          error err
          s[:message].entity.add(s.merge(open: Skin['notfound.png'], face: matched[:name]))
        }
        s.merge(open: Skin['notfound.png'], face: matched[:name])
      }).
      #
      # 上記までの正規表現にマッチしなかった全ての <something> を取得
      # うまくパース出来ていないということになるので、error出力している
      filter(/<(.*)>/, generator: lambda { |s|
        error "Did not match any regex: #{s[:face]}"
        s
      })

    # @see https://github.com/slack-ruby/slack-ruby-client/blob/master/lib/slack/messages/formatting.rb
    def self.unescape(message)
      CGI.unescapeHTML(
        message.gsub(/[“”]/, '"')
          .gsub(/[‘’]/, "'")
          .gsub(/<(?<sign>[?@#!]?)(?<dt>.*?)>/) { |_|
          sign = $LAST_MATCH_INFO[:sign]
          dt = $LAST_MATCH_INFO[:dt]
          rhs = dt.split('|', 2).last
          case sign
          when '@', '!'
            "@#{rhs}"
          when '#'
            "##{rhs}"
          else
            rhs
          end
        }
      )
    end
  end
end
