class LinebotController < ApplicationController
  require 'line/bot'

  protect_from_forgery :except => [:callback]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head :bad_request
    end

    events = client.parse_events_from(body)

    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          # LINEから送られてきたメッセージが「疲れた」と一致するかチェック
          if event.message['text'].eql?('疲れた')
            # private内のtemplateメソッドを呼び出します。
            client.reply_message(event['replyToken'], template)
          end
        end
      end
    }

    head :ok
  end

  private

  def template
    {
      "type": "template",
      "altText": "this is a confirm template",
      "template": {
          "type": "confirm",
          "text": "ジム行く？",
          "actions": [
              {
                "type": "message",
                # Botから送られてきたメッセージに表示される文字列です。
                "label": "はい",
                # ボタンを押した時にBotに送られる文字列です。
                "text": "はい"
              },
              {
                "type": "message",
                "label": "いいえ",
                "text": "いいえ"
              }
          ]
      }
    }
  end
end
