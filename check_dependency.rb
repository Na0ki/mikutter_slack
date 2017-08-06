# -*- coding: utf-8 -*-
# -*- frozen_string_literal: true -*-

def check
  md = "# ライブラリの依存関係\n\n|name   |version|\n|:------|:------|\n"
  list = `bundle list`.split(/\n/)
  list.each do |deps|
    matched = /\*\s(?<name>.+)\s\((?<version>.+)\)/.match(deps)
    next if matched.nil?
    md += "|#{matched[:name]}|#{matched[:version]}|\n"
  end

  # 書き出し
  File.open(File.join(__dir__, 'doc', 'dependencies.md'), 'w') do |f|
    f.puts(md)
  end
end

check
