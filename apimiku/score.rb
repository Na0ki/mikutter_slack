# -*- frozen_string_literal: true -*-

Plugin.create(:slack) do
  # カスタム絵文字をEmojiNoteにするフィルタ
  filter_score_filter do |model, note, yielder|
    model.parse_emoji(note.description, yielder) if model.is_a?(Plugin::Slack::Message)
    [model, note, yielder]
  end
end
