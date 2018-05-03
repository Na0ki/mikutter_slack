# -*- frozen_string_literal: true -*-

Plugin.create(:slack) do
  # 抽出データソース
  # @see https://toshia.github.io/writing-mikutter-plugin/basis/2016/09/20/extract-datasource.html
  filter_extract_datasources do |ds|
    Enumerator.new { |y|
      Plugin.filtering(:worlds, y)
    }.select { |world|
      world.class.slug == :slack
    }.each { |world|
      world.team&.channels!&.each { |channel| ds[channel.datasource_slug] = channel.datasource_name }
    }
    [ds]
  end
end
