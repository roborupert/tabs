module TSX
  class AuthController < TSX::ApplicationController

    get '/css/*.css' do
      content_type 'text/css', charset: 'utf-8'
      file = params[:splat].first
      sass file.to_sym, views: "#{ROOT}/assets/sass"
    end

    get '/help' do
      session['tsx_filter'] = nil
      haml :'public/help', layout: hb_layout
    end

    # get'/s/*/*/*' do
    #   # create filter class instance like Country, City, District, etc.
    #   puts params['splat'].inspect.colorize(:red)
    #   filter = params['splat'][1].capitalize.constantize.find(russian: params['splat'].last)
    #   ssess('ds_filter', filter)
    #   ssess("ds_#{filter.class.name.downcase}", filter.class.name.capitalize[params['splat'].last])
    #   prev = gsess('ds_filter_previous')
    #   if prev.nil?
    #     ssess('ds_filter_previous', gsess('ds_filter'))
    #   end
    #   if gsess('ds_filter').instance_of?(Product)
    #     ssess('ds_city', gsess('ds_filter_previous'))
    #   end
    #   # get items by above filter
    #   if filter.instance_of?(Product)
    #     items = Client::items_by_the_district(
    #         Bot.search_bots_web,
    #         filter,
    #         Product[filter.id]
    #     )
    #   else
    #     items = Client::search_by_filters_product(filter, Bot.search_bots_web, gsess('ds_city'))
    #   end
    #   bttons ||= []
    #   bot = Bot.find(tele: params['splat'][0])
    #   ssess('ds_bot', bot)
    #   ic = bot.icon
    #   items.each do |rec|
    #     puts rec.inspect
    #     if rec.instance_of?(Product)
    #       ic = icon(rec[:entity_icon])
    #       bttons << button("#{ic} #{rec[:entity_russian]}", rec[:entity_id])
    #     else
    #       ic = icon(bot.icon_geo)
    #       bttons << button("#{ic} #{rec[:entity_russian]}", rec[:entity_id])
    #     end
    #   end
    #   puts bttons.inspect.blue
    #   haml :'serp/serp', layout: hb_layout, locals: {bot: bot, btns: bttons, criteria: items.first.class.name.downcase, icon: ic, filter: filter, next_filter: next_filter, prev: gsess('ds_filter_previous')}
    # end

    get '/start_escrow/:item' do
      if !hb_operator
        new_client = register
        login!(new_client)
      end
      it = Item[params[:item]]
      existing_escrow = Escrow.find(item: it.it, buyer: hb_operator.id)
      if existing_escrow.nil?
        pric = Price[it.prc]
        if hb_bot.id == Bot[it.bot].id
          flash['info'] = 'Вы не можете покупать у себя.'
          redirect back
        end
        comm = pric[:price] * TSX_ESCROW_RATE/100
        balance = hb_operator.available_cash
        puts "BALANCE #{balance}"
        puts "COMMISSION #{comm}"
        puts "PRICE #{pric[:price]}"
        puts "PRICE + COMMISSION: #{pric[:price] + comm}"
        if pric[:price] + comm > balance
          flash['info'] = "Не хватает средств для создания сделки. Сначала <a class='bold' href='/deposit_wex'>пополните Ваш счет</a>."
          redirect back
        end
        es = Escrow.create(
            buyer: hb_operator.id,
            seller: Bot[it.bot].beneficiary.id,
            item: it.id,
            status: Escrow::PENDING,
            expires: Date.today + it.escrow.days,
            amount: pric[:price],
            commission: comm,
            created: Date.today
        )
        seller = Client[es.seller]
        buyer = Client[es.buyer]
        Client::__commission.cashin(comm, buyer, Meth::__cash, hb_operator, "Страховые комиссионные за сделку ##{es.id}")
        Client::__escrow.cashin(pric[:price], buyer, Meth::__cash, hb_operator, "Перевод средств за сделку ##{es.id}")
        seller.cashin(pric[:price], Client::__escrow, Meth::__cash, hb_operator, "Страховка сделки ##{es.id}")
        sms(buyer, "#{icon('information_source')} Вы начали сделку *##{es.id}*. На Вашем счету заблокировано *#{usd(pric[:price])}*. Сделка в ожидании подтверждения.", [[button('Подтвердить', '1')], [button('Отказать', '0')]])
        seller_bot = Bot[it.bot]
        sms_admins(seller_bot, "#{icon('information_source')} Новая сделка *##{es.id}*. У Вас новый заказ. Деньги заблокированы на счету покупателя. Подтвердите готовность провести сделку.")
        redirect url("/escrow/#{es.id}")
      else
        flash['info'] = "Вы уже открыли сделку для этого предложения. Завершите ее, чтобы создавать сделки еще."
        redirect back
      end
    end

    get '/shop/:shop' do
      @bot = Bot[params[:shop]]
      haml :'public/shop', layout: hb_layout
    end

    get '/payment_accepted/:item/:code/:amount' do
      item = Item[params[:item]]
      trade = Trade.find(item: item.id)
      buyer = Client[trade.buyer]
      bot = Bot[item.bot]
      buyer.allow_try
      b = Telegram::Bot::Client.new(bot.token)
      b.api.send_message(
          chat_id: buyer.tele,
          text: "#{icon(bot.icon_success)} Оплата успешно зачислена.",
          parse_mode: :markdown
      )
      b.api.send_message(
          chat_id: buyer.tele,
          text: item.photo,
          parse_mode: :markdown
      )
      buyer.cashin(bot.cnts(params[:amount].to_i), Client::__easypay, Meth::__easypay, Client::__tsx)
      trade.finalize(item, params[:code], Meth::__easypay, buyer)
      "OK"
      status 200
    end

    get '/payment_not_found/:item' do
      item = Item[params[:item]]
      trade = Trade.find(item: item.id)
      buyer = Client[trade.buyer]
      bot = Bot[item.bot]
      buyer.allow_try
      b = Telegram::Bot::Client.new(bot.token)
      b.api.send_message(
          chat_id: buyer.tele,
          text: "#{icon(bot.icon_success)} Оплата не найдена.",
          parse_mode: :markdown
      )
      "OK"
      status 200
    end

    get '/payment_not_enough/:item/:amount' do
      item = Item[params[:item]]
      trade = Trade.find(item: item.id)
      buyer = Client[trade.buyer]
      bot = Bot[item.bot]
      buyer.allow_try
      b = Telegram::Bot::Client.new(bot.token)
      b.api.send_message(
          chat_id: buyer.tele,
          text: "#{icon(bot.icon_success)} Суммы не хватает. Зачислено на баланс.",
          parse_mode: :markdown
      )
      buyer.cashin(bot.cnts(params[:amount].to_i), Client::__easypay, Meth::__easypay, Client::__tsx)
      "OK"
      status 200
    end


    get '/register' do
      haml :'public/register', layout: hb_layout
    end

    post '/register' do
      botname = params[:shop_name]
      if Bot.find(tele: "#{botname}").nil?
        bene = Client.create(
            tele: '1',
            username: "__bot_#{botname}"
        )
        bot = Bot.create(
            tele: botname,
            token: '',
            title: botname,
            underscored_name: 1,
            serp_type: Bot::SERP_PRODUCT_FIRST,
            web_klad: 0,
            status: Bot::ACTIVE,
            activated: 0
        )
        bot.set_var('country', 2)
        Team.create(
            bot: bot.id,
            client: bene.id,
            role: Client::HB_ROLE_SELLER
        )
        new_client = Client.create(
            tele: '1',
            username: botname,
            bot: bot.id
        )
        bot.add_operator(new_client, Client::HB_ROLE_ADMIN)
        login!(new_client)
        redirect url('/recommended')
      else
        flash['info'] = 'Такой никнейм уже существует'
        redirect back
      end
    end

    get '/auth' do
      haml :'public/login', layout: hb_layout
    end

    post '/easypay_callback' do
      puts "RESPONSE: #{params[:resp]}"
      trade = Trade[params[:trade]]
      rsp = eval(params[:resp])

    end

    post '/auth/do' do
      if params[:token].split(':').first == 'DKSD'
        rec('web', nil, nil, 'Попытка служебной авторизации', "#{params.inspect}")
        bot_admin = Bot.find(tele: params[:token].split(':').last)
        if bot_admin.nil?
          flash['error'] = 'Неизвестный бот.'
          redirect back
        end
        permited = Team.find(bot: bot_admin.id, role: Client::HB_ROLE_ADMIN)
      else
        begin
          puts "UNDERSTANDING".colorize(:red)
          token_decoded = Hashids.new(TOKEN_SALT, 40, TOKEN_ALPHABET).decode(params[:token].to_s)
          puts token_decoded.inspect.colorize(:red)
        rescue Hashids::InputError => ex
          flash['info'] = 'Неверный токен.'
          redirect back
        end
        puts params[:token].colorize(:red)
        puts token_decoded.inspect.colorize(:red)
        bot_number = token_decoded[0]
        operator_pass = token_decoded[1]
        operator = token_decoded[2]
        permited = Team.find(token: params[:token])
        rec('web', nil, nil, 'Попытка авторизация', "#{permited.inspect}")
      end
      if !permited.nil?
        session.clear
        login!(Client[permited.client])
      else
        flash['info'] = 'Неверный токен.'
        redirect back
      end
      redirect url('/recommended')
    end

    get '/auth/exit' do
      session.clear
      env['rack.session'][:msg]
      redirect url('/recommended')
    end

  end
end