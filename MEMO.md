* API Reference
    * [RTM API](https://api.slack.com/faq#real_time_messaging_api)
    * [Events API](https://api.slack.com/faq#events_api)


* 接続時（*on :hello*）
    ```
    {
        "reply_to"=>6642,
        "type"=>"message",
        "channel"=>"CHANNEL_ID",
        "user"=>"USER_ID",
        "text"=>"テストメッセージ",
        "ts"=>"1472728555.000003"
    }
    ```

* *on :message* でくるデータ
    ```
    {
        "type"=>"TYPE",
        "channel"=>"CHANNEL_ID",
        "user"=>"USER_ID",
        "text"=>"MESSAGE",
        "ts"=>"UNIX_TIME_FLOAT",
        "team"=>"TEAM_ID"
    }
    ```

* channelの履歴
    ```
    {
        "id"=>"CHANNEL_ID",
        "name"=>"CHANNEL_NAME",
        "is_channel"=>BOOLEAN,
        "created"=>UNIX_TIME,
        "creator"=>"USER_ID",
        "is_archived"=>BOOLEAN,
        "is_general"=>BOOLEAN,
        "is_member"=>BOOLEAN,
        "members"=>["USER_ID"],
        "topic"=>{
          "value"=>"",
          "creator"=>"",
          "last_set"=>0},
          "purpose"=>{
            "value"=>"mikutterでslack",
            "creator"=>"USER_ID",
            "last_set"=>UNIX_TIME
          },
        "num_members"=>1
      }
    ```
