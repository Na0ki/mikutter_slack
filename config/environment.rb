# -*- coding: utf-8 -*-
# -*- frozen_string_literal: true -*-

require 'yaml'

module Plugin::Slack
  module Environment
    ###################
    # App Information #
    ###################
    NAME = YAML.load_file(File.expand_path(File.join(__dir__, '..', '.mikutter.yml')))['name'] rescue nil
    VERSION = YAML.load_file(File.expand_path(File.join(__dir__, '..', '.mikutter.yml')))['version'] rescue nil

    #####################
    # OAuth Information #
    #####################
    SLACK_AUTHORIZE_URI = 'https://slack.com/oauth/authorize'
    SLACK_OAUTH_ACCESS_URI = 'https://slack.com/api/oauth.access'
    SLACK_CLIENT_ID = '43202035347.73645008566'
    SLACK_CLIENT_SECRET = 'f395c1c55fbaa0fb0a968bbf5d7372af'
    SLACK_OAUTH_SCOPE = 'client'
    SLACK_OAUTH_STATE = 'mikutter_slack'

    ################################
    # Oauth Redirect Server Config #
    ################################
    SLACK_REDIRECT_URI = 'http://localhost:8080/'
    SLACK_DOCUMENT_ROOT = File.join(__dir__, '..', 'www/')
    SLACK_SERVER_CONFIG = {
      DocumentRoot: SLACK_DOCUMENT_ROOT,
      BindAddress: 'localhost',
      Port: 8080
    }.freeze
  end
end
