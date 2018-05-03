# -*- frozen_string_literal: true -*-

Plugin.create(:slack) do
  world_setting(:slack, 'Slack') do
    promise = Delayer::Deferred.new(true)
    url = await(Plugin::Slack::API::Auth.request_authorize_url(promise))
    label "認証用のURLをブラウザで開きました。\nブラウザでSlackにログインし、連携したいチームを選択してください。"
    Plugin.call(:open, url)
    token = await(promise)
    world = await(Plugin::Slack::World.build(token))
    label "#{world.team.name}(#{world.team.domain}) チームの #{world.user.name} としてログインしますか？"
    world
  end
end
