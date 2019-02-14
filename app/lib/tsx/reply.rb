module TSX
  module Reply

    def reply_video(filename)
      file = Telebot::InputFile.new(fixture(filename), 'video/mp4')
      @bot.api.send_video(chat_id: chat, video: file)
    end

    def fixture(file_name)
      File.expand_path("#{ROOT}/public/images/#{file_name}", __FILE__)
    end

    def reply_picture (filename, caption)
      file = Telebot::InputFile.new(fixture(filename), 'image/png')
      @bot.api.send_photo(chat_id: chat, photo: file, caption: caption)
    end

    def delete_message(id)
      @bot.api.public_send(
        "delete_message",
        chat_id: chat,
        message_id: id
      )
    end

    def reply_inline(view, locals = {})
      v = render_md(view, locals)
      buts = Telegram::Bot::Types::InlineKeyboardMarkup.new(
          inline_keyboard: v.buttons
      )
      res = @bot.api.send_message(
          chat_id: chat,
          text: v.body,
          parse_mode: :markdown,
          reply_markup: buts,
          disable_web_page_preview: true
      )
      set_editable(res['result']['message_id'])
    end

    def reply_update(view, locals = {})
      v = render_md(view, locals)
      buts = Telegram::Bot::Types::InlineKeyboardMarkup.new(
          inline_keyboard: v.buttons
      )
      begin
        if message_id - has_editable? > 1
          raise
        end
        res = @bot.api.public_send(
            "edit_message_text",
            chat_id: chat,
            message_id: has_editable?,
            text: v.body,
            parse_mode: :markdown,
            reply_markup: buts,
            disable_web_page_preview: true
        )
        set_editable(res['result']['message_id'])
      rescue => ex
        if block_given?
          yield locals, ex
        end
      end
    end

    def send_inv(trade)
      item = Item[trade.item]
      product = Product[item.product]
      p1 = Array.new
      p1 << {amount: 50000, label: 'Оплата TSC кода'}
      puts p1.inspect
      ff = @bot.api.send_invoice(
        chat_id: chat,
        title: product.russian,
        description: 'деск',
        start_parameter: '3didus',
        payload: Time.now.to_i.to_s,
        provider_token: '361519591:TEST:1204c3405c08bf7f66683ce0b697b758',
        currency: 'UAH',
        prices: p1
      )
      puts ff.inspect
    end

    def update_message(mess)
      buts = Telegram::Bot::Types::InlineKeyboardMarkup.new(
          inline_keyboard: nil
      )
      begin
        res = @bot.api.public_send(
            "edit_message_text",
            chat_id: chat,
            message_id: has_editable?,
            text: mess,
            parse_mode: :markdown,
            reply_markup: buts
        )
        set_editable(res['result']['message_id'])
      rescue => ex
        if block_given?
          yield ex
        end
      end
    end

    def answer_callback(text)
      if callback_query?
        @bot.api.public_send(
            "answer_callback_query",
            callback_query_id: @payload.id,
            text: text
        )
      end
    end

    def reply_location(txt)
      buts = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
          keyboard: [[text: 'Отослать геопозицию', request_location: true]],
          resize_keyboard: true,
      )
      @bot.api.send_message(
          chat_id: chat,
          text: txt,
          reply_markup: buts
      )

    end

    def reply_plain (view, locals = {})
      v = render_md(view, locals)
      buts = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
          keyboard: v.buttons,
          resize_keyboard: locals[:resize].nil?,
          one_time_keyboard: (!locals[:one_time].nil?)
      )
      @bot.api.send_message(
        chat_id: chat,
        text: v.body,
        reply_markup: buts,
        disable_web_page_preview: true
      )
    end

    def reply_simple (view, locals = {})
      v = render_md(view, locals)
      buts = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
          keyboard: v.buttons,
          resize_keyboard: locals[:resize].nil?,
          one_time_keyboard: (!locals[:one_time].nil?)
      )
      if @links.nil?
        wlinks = true
      elsif @links == false
        wlinks = true
      else
        wlinks = false
      end
      # lg buts.inspect
      # lg v.body.inspect
      @bot.api.send_message(
          chat_id: chat,
          text: v.body,
          parse_mode: :markdown,
          reply_markup: buts,
          disable_web_page_preview: wlinks
      )
    end

    def send_item (view, locals = {})
      v = render_md(view, locals)
      buts = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
          keyboard: v.buttons,
          resize_keyboard: true
      )
      @bot.api.send_message(
          chat_id: hb_client.tele,
          text: v.body,
          reply_markup: buts
      )
    end

    def just_take(item)
      @bot.api.send_message(
          chat_id: chat,
          text: item.photo
      )
    end

    def reply_thread(mess, who)
      @bot.api.send_message(
          chat_id: !who.nil? ? who.tele : chat,
          reply_markup: nil,
          text: mess,
          parse_mode: :markdown
      )
    end


    def reply_message (mess, locals = {})
      buts = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
          keyboard: locals
      )
      res = @bot.api.send_message(
          chat_id: chat,
          reply_markup: buts,
          text: mess,
          disable_web_page_preview: true,
          parse_mode: :markdown
      )
      set_editable(res['result']['message_id'])
    end

    def hide_keyboard(mess, locals = {})
      buts = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
          hide_keyboard: true
      )
      @bot.api.send_message(
          chat_id: chat,
          reply_markup: buts,
          text: mess,
          disable_web_page_preview: true,
          parse_mode: :markdown
      )
    end


    def say(who, text)
      @bot.api.send_message(
        chat_id: who,
        text: text,
        parse_mode: :markdown
      )
    end

    def show_typing
      @bot.api.public_send(
          "send_chat_action",
          chat_id: chat,
          action: :typing
      )
    end

    def reply_error(locals = {})
      view = render_md('errors/internal', locals)
      @bot.api.send_message(
          chat_id: chat,
          text: view.body,
          reply_markup: {
              keyboard: view.buttons,
              resize_keyboard: false
          },
          parse_mode: :markdown
      )
    end

    def render_md(v, locals = {})
      if !File.exist?("#{ROOT}/app/views/tsx/#{v}.rb")
        TSX::View.new('Невозможно обработать запрос.', [btn_main])
      else
        locals.each do |var, val|
          instance_variable_set("@#{var}".to_sym, val)
        end
        template = File.read("#{ROOT}/app/views/tsx/#{v}.rb")
        b, bt = template.split('****')
        TSX::View.new(
            instance_eval('"' + b +'"'),
            instance_eval(bt)
        )
      end
    end

  end
end