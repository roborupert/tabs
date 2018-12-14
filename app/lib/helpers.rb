module TSX
  module Helpers

    Array.class_eval do
      def paginate(page = 1, per_page = 15)
        WillPaginate::Collection.create(page, per_page, size) do |pager|
          pager.replace self[pager.offset, pager.per_page].to_a
        end
      end
    end

    # def self.include klass
    #   self.extend klass
    # end

    def cnt_bold(c)
      "#{c}"
    end

    def kladov(cnt)
      "#{cnt_bold(cnt)} #{Russian.p(cnt, "клад", "клада", "кладов")}"
    end

    def ludey(cnt)
      "#{cnt_bold(cnt)} #{Russian.p(cnt, "человек", "человека", "людей")}"
    end

    def otzivov(cnt)
      "#{cnt_bold(cnt)} #{Russian.p(cnt, "отзыв", "отзыва", "отзывов")}"
    end

    def postov(cnt)
      "#{cnt_bold(cnt)} #{Russian.p(cnt, "пост", "поста", "постов")}"
    end

    def dney(cnt)
      "#{cnt_bold(cnt)} #{Russian.p(cnt, "день", "дня", "дней")}"
    end

    def stranic(cnt)
      "#{cnt_bold(cnt)} #{Russian.p(cnt, "страница", "страницы", "страниц")}"
    end


    def zaprosov(cnt)
      "#{cnt_bold(cnt)} #{Russian.p(cnt, "запрос", "запроса", "запросов")}"
    end

    def klientov(cnt)
      "#{cnt_bold(cnt)} #{Russian.p(cnt, "клиент", "клиента", "клиентов")}"
    end

    def magazinov(cnt)
      "#{cnt_bold(cnt)} #{Russian.p(cnt, "магазин", "магазина", "магазинов")}"
    end

    def chasov(cnt)
      "#{cnt_bold(cnt)} #{Russian.p(cnt, "час", "часа", "часов")}"
    end

    def minut(cnt)
      "#{cnt_bold(cnt)} #{Russian.p(cnt, "минута", "минуты", "минут", "минут")}"
    end

    def prodazh(cnt)
      "#{cnt_bold(cnt)} #{Russian.p(cnt, "продажа", "продажи", "продаж", "продаж")}"
    end

    def pagina(collection)
      options = {
          #renderer: BootstrapPagination::Sinatra,
          class: 'pagination',
          inner_window: 4,
          outer_window: 2,
          page_links: false,
          previous_label: icn('arrow_left'),
          next_label: icn('arrow_right'),
          param_name: :p,
          container: true
      }
      will_paginate collection, options
    end

    def icn(code, big = "emoji")
      Twemoji.parse(":#{code}:", class_name: big)
    end

    def icon(code, text = '')
      unic = Twemoji.find_by_text(":#{code}:")
      if unic
        "#{Twemoji.render_unicode(unic)} #{text}"
      else
        icon('white_small_square', text)
      end
    end

    def icon_unicode(code)
      ccc = Twemoji.find_by(code: code)
      Twemoji.render_unicode ccc
    end

    def photo?(url)
      return true
      begin
        res = Faraday.get(url)
        # warn "RESP STATUS"
        # warn res.response.inspect
        res.status == 200
      rescue
        false
      end
    end

    def location(url)
      "location.href='#{url(url)}'"
    end

    def current_locale
      I18n.locale
    end

    def human_date(d)
      d.nil? ? 'n/a' : d.to_time.strftime("%b %d, %Y")
    end

    def human_date_short(d)
      d.nil? ? 'n/a' : d.to_time.strftime("%b %d")
    end

    def human_time(d)
      d.nil? ? 'n/a' : d.to_time.strftime("%H:%M")
    end

    def calc_commission(amount, comm)
      (amount * (comm.to_f/100)).round
    end

    def t(key, options = nil)
      I18n.translate(key, options)
    end

    def webrec(action, params = '')
      rec('web', hb_operator, hb_bot, action, params)
    end

    def botrec(action, params = '')
      rec('bot', hb_client, @tsx_bot, action, params)
    end

    def rec(init = 'unknown', cl, b, action, params)
      Rec.create(
          initiator: init.to_s,
          client: cl.nil? ? '' : cl.id,
          bot: b.nil? ? '' : b.id,
          action: action,
          params: params,
          logged: Time.now
      )
    end

    def ago(dat)
      distance_of_time_in_words(Time.now, dat)
    end

    def lg (text)
      puts text.colorize(:light_white)
    end

    def blue(text)
      puts text.colorize(:blue)
    end

    def cy(text)
      puts text.colorize(:cyan)
    end

    def warn(text)
      puts text.colorize(:red)
    end

    def deb(text)
      puts text.colorize(:light_white)
    end

    def tem(text)
      puts text.colorize(:green)
    end

    def conf(key)
      if !hb_bot
        false
      else
        hb_bot[key]
      end
    end

    def sms(client, msg, buts = nil)
      buts ||= ['Главная', 'Сделки']
      who = Client[Team.find(bot: hb_bot.id, client: client.id).notify]
      puts who.inspect
      if !who.nil?
        butts = Telegram::Bot::Types::InlineKeyboardMarkup.new(
            inline_keyboard: buts,
        )
        b = Bot.find(tele: 'DarksideRo')
        bot = Telegram::Bot::Client.new(b.token)
        bot.api.send_message(
          chat_id: who.tele,
          text: msg,
          parse_mode: :markdown,
          inline_keyboard: butts
        )
      end
    end

    def sms_admins(bot, text)
      b = Bot.find(tele: 'DarksideRo')
      rcpts = bot.admins
      rcpts.each do |op|
        begin
          who = Client[Team.find(bot: hb_bot.id, client: client.id).notify]
          if !who.nil?
              b.api.send_message(
                chat_id: who.tele,
                text: text,
                parse_mode: :markdown
            )
          end
        rescue => ex
          puts ex.message
        end
      end
    end


    def hb_filter
      if !session['hb_filter']
        session['hb_filter'] = Country.UKRAINE
      else
        session['hb_filter']
      end
    end

    def hb_filter_city
      session['hb_filter_city'] || false
    end

    def const_game(game)
      "TSX::#{game.title.capitalize}".constantize
    end

    def hb_dealing_bot
      Bot[session['hb_dealing_bot']] || false
    end

    def hb_trading
      Trade[session['hb_trading']] || false
    end

    def hb_buying
      Item[session['hb_buying']] || false
    end

    def hb_prev_filter
      session['hb_prev_filter'] || false
    end

    def hb_filter_district
      session['hb_filter_district'] || false
    end

    def hb_filter_product
      session['hb_filter_product'] || false
    end


    def hb_client
      cl = Client.find(tele: "#{chat}", bot: @tsx_bot.id)
      if cl.nil?
        begin
          Client.create(tele: "#{chat}", username: "#{from}", bot: @tsx_bot.id)
        rescue => ex
          deb ex.message
          return false
        end
      else
        cl
      end
      # cmd = @payload.text.split(' ').first == '/start'
      # referal = @payload.text.split(' ').last
      #
      # if  and !.nil?
      #   Ref.create(client: @session_client.id, )
      # end
    end

    def usd(cents)
      "$#{(cents.to_f/100).round(2)}"
    end

    def usd_number(cents)
      "#{(cents.to_f/100).round(2)}"
    end

    def usd_color(cents)
      if cents < 0
        "<span class='red'>$#{(cents.to_f/100).round(2)}</span>"
      else
        usd(cents)
      end
    end

    def location(url)
      "location.href='#{url}'"
    end

    def next_filter
      puts gsess('ds_filter').inspect.cyan
      if gsess('ds_filter').instance_of?(Country)
        return 'City'
      end
      if gsess('ds_filter').instance_of?(City)
        return 'Product'
      end
      if gsess('ds_filter').instance_of?(Product)
        return 'District'
      end
      if gsess('ds_filter').instance_of?(District)
        return 'show'
      end
    end

    def gsess(key)
      session["#{key}"]
    end

    def ssess(key, value)
      session["#{key}"] = value
    end

    def hb_currency
      session["TSX_CURRENCY"]
    end

    def hb_currency_label
      session["TSX_CURRENCY_LABEL"]
    end

    def hb_btc_system
      session["TSX_BTC_SYSTEM"] || 'не установлено'
    end

    def hb_btc
      session["TSX_BTC"] || 'не установлено'
    end

    def get_domain_from_url(url)
      uri = URI.parse(url)
      domain = PublicSuffix.parse(uri.host)
      domain.domain
    end

    def hb_bot
      if defined?(env)
        if env['rack.session']['_bot'].instance_of?(Bot)
          env['rack.session']['_bot']
        else
          Bot[env['rack.session']['_bot']] || false
        end
      else
        false
      end
    end

    def hb_bene
      if defined?(env)
        if env['rack.session']['_beneficiary'].instance_of?(Client)
         env['rack.session']['_beneficiary']
        else
          Client[env['rack.session']['_beneficiary']] || false
        end
      else
        false
      end
    end

    def hb_operator
      env['rack.session']['_operator'] || false
    end

    def hb_layout
      !hb_bot ? :"layouts/not_logged" : :"layouts/logged"
    end

    def hb_tbr_layout
      !hb_bot ? :"layouts/tbr_not_logged" : :"layouts/tbr_logged"
    end

    def register(role = Client::HB_ROLE_USER)
      bot = Bot::escrow
      pin = Time.now.to_i.to_s
      new_client = Client.create(bot: bot.id, tele: pin, username: pin, role: role)
      hashids = Hashids.new(TOKEN_SALT, 40, TOKEN_ALPHABET)
      @hash = hashids.encode(bot.id, pin.to_i, new_client.id, Client::HB_ROLE_USER)
      Team.create(bot: bot.id, client: new_client.id, role: Client::HB_ROLE_USER, password: pin, token: @hash)
      new_client
    end

    def login!(client)
      bot = Bot[client.bot]
      bene = bot.beneficiary
      case client.role
        when Client::HB_ROLE_USER
          env['rack.session']['_role'] = 'user'
        when Client::HB_ROLE_OPERATOR
          env['rack.session']['_role'] = 'operator'
        when Client::HB_ROLE_ADMIN
          env['rack.session']['_role'] = 'admin'
        when Client::HB_ROLE_API
          env['rack.session']['_role'] = 'api'
        when Client::HB_ROLE_KLADMAN
          env['rack.session']['_role'] = 'kladman'
        when Client::HB_ROLE_KLADMAN
          env['rack.session']['_role'] = 'support'
      end
      env['rack.session']['_beneficiary'] = bene
      env['rack.session']['_bot'] = bot.id
      env['rack.session']['_operator'] = client
      rec('web', client, bot, 'Успешная авторизация', "#{client.inspect}")
    end


  end
end