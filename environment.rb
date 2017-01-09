# -*- coding: utf-8 -*-
require 'yaml'

module Plugin::Slack
  module Environment

    NAME = YAML.load_file(File.expand_path(File.join(__dir__, '.mikutter.yml')))['name'] rescue nil
    VERSION = YAML.load_file(File.expand_path(File.join(__dir__, '.mikutter.yml')))['version'] rescue nil

    SLACK_CLIENT_ID = '43202035347.73645008566'
    SLACK_CLIENT_SECRET = 'f395c1c55fbaa0fb0a968bbf5d7372af'

    SLACK_REDIRECT_URI = 'http://localhost:8080/'

  end
end