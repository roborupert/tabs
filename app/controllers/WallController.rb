require 'uri/http'
module TSX
  class WallController < TSX::ApplicationController

    get '/css/*.css' do
      content_type 'text/css', charset: 'utf-8'
      file = params[:splat].first
      sass file.to_sym, views: "#{ROOT}/assets/sass"
    end

    get '/help' do
      session['tsx_filter'] = nil
      haml :'public/help', layout: hb_layout
    end

    get '/ff/*/*' do
      # create filter class instance like Country, City, District, etc.
      filter = params['splat'].first.capitalize.constantize[params['splat'].last]
      ssess('ds_filter', filter)
      ssess("ds_#{filter.class.name.downcase}", filter.class.name.capitalize[params['splat'].last])
      prev = gsess('ds_filter_previous')
      if prev.nil?
        ssess('ds_filter_previous', gsess('ds_filter'))
      end
      if gsess('ds_filter').instance_of?(Product)
        ssess('ds_city', gsess('ds_filter_previous'))
      end
      # get items by above filter
      if filter.instance_of?(Product)
        items = Client::items_by_the_district(
            Bot.search_bots_web,
            filter,
            Product[filter.id]
        )
      else
        items = Client::search_by_filters_product(params['splat'].first.capitalize.constantize[params['splat'].last], Bot.search_bots_web, gsess('ds_city'))
      end
      bttons ||= []
      ic = hb_bot.icon
      items.each do |rec|
        puts rec.inspect
        if rec.instance_of?(Product)
          ic = icon(rec[:entity_icon])
          bttons << button("#{ic} #{rec[:entity_russian]}", rec[:entity_id])
        else
          ic = icon(hb_bot.icon_geo)
          bttons << button("#{ic} #{rec[:entity_russian]}", rec[:entity_id])
        end
      end
      puts bttons.inspect.blue
      haml :'serp/serp', layout: hb_layout, locals: {btns: bttons, criteria: items.first.class.name.downcase, icon: ic, filter: filter, next_filter: next_filter, prev: gsess('ds_filter_previous')}
    end

    get '/search' do
      @escrows = Item.select(:item__client, :item__product).where(status: Item::ESCROW_ACTIVE).group(:item__client, :item__product).paginate(@p.to_i, 15)
      haml :'public/search', layout: hb_layout
    end


    get '/start_escrow/:item' do
      if !hb_operator
        new_client = register
        login!(new_client)
      end
      it = Item[params[:item]]
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
    end

    get '/search' do
      @escrows = Item.where(status: Item::ESCROW_ACTIVE).paginate(@p.to_i, 15)
      haml :'public/search', layout: hb_layout
    end

    get '/recommended' do
      @available_bots = Bot.select_all(:bot).join(:vars, :vars__bot => :bot__id).where(listed: 1).order(Sequel.desc(:vars__today_sales))
      haml :'public/recommended', layout: hb_layout, locals: {its: @available_bots}
    end

    get '/s/:shop' do
      bot = Bot.find(tele: params[:shop])
      session['hb_dealing_bot'] = bot.id
      @its = Client::cities_by_country(Country.UKRAINE, bot.id)
      haml :'public/shop-single', layout: hb_layout, locals: {bot: bot, its: @its}
    end

    get '/choose_payment/:item' do
      @payments = hb_dealing_bot.available_payments
      session['hb_buying'] = Item[params[:item]].id
      haml :'public/choose_payment', layout: hb_layout, locals: {bot: hb_dealing_bot}
    end

    get '/payment/:method' do
      @meth = Meth.find(title: params[:method])
      haml :'public/payment', layout: hb_layout, locals: {bot: hb_dealing_bot}
    end

    get '/pay/:method/:item' do
      @method = Meth.find(title: params[:method])
      begin
        pending = hb_operator.has_pending_trade?(hb_bot)
        if pending
          trade_item = Item[pending.item]
          trade_item.status = Item::ACTIVE
          trade_item.save
          pending.delete
          flash['info'] = 'Предыдущий заказ отменен.'
        end
        if Trade.find(item: params[:item]).nil?
          it = Item[params[:item]]
          it.unlock = Time.now + RESERVE_INTERVAL.minute
          it.status = Item::RESERVED
          it.save
          seller = hb_bot.beneficiary
          pric = Price[it.prc]
          comm = pric[:price] * (hb_bot.commission.to_f)/100
          tr = Trade.create(
              buyer: hb_operator.id,
              bot: hb_bot.id,
              seller: seller.id,
              item: it.id,
              status: Trade::PENDING,
              escrow: seller.escrow,
              amount: pric[:price] - comm,
              commission: comm
          )
          session['hb_buying'] = it.id
          session['hb_trading'] = tr.id
          webrec('Бронирование клада', it.id)
          redirect url("/pay/#{@method.title}/#{it.id}")
        else
          flash['info'] = "#{icn(hb_dealing_bot.icon_info)} Этот клад уже кто-то зарезервировал или купил. Выберите другой."
          it = Item[params[:item]]
          it.unlock = nil
          it.save
          redirect back
        end
      rescue PG::InvalidTextRepresentation => resc
        puts resc.message
        flash['info'] = "#{icn(hb_dealing_bot.icon_info)} Невозможно создать заказ. Попробуйте еще раз, пожалуйста."
        redirect back
      rescue => ex
        puts ex.message.colorize(:red)
        flash['info'] = "#{icn(hb_dealing_bot.icon_info)} Невозможно создать заказ. Попробуйте еще раз, пожалуйста. 2"
        redirect back
      end
    end

    get '/s/:shop/:param/:value' do
      bot = Bot.find(tele: params[:shop])
      cl = params[:param]
      vl = params[:value]
      filt = cl.capitalize.constantize.find(russian: vl)
      session['hb_filter'] = filt
      puts filt.inspect
      if filt.instance_of?(Country)
        @its = Client::cities_by_country(filt, bot.id)
      end
      if filt.instance_of?(City)
        session['hb_filter_city'] = filt
        session['hb_prev_filter'] = Country.UKRAINE
        @its = Client::products_by_city(filt, bot.id)
      end
      if filt.instance_of?(Product)
        session['hb_filter_product'] = filt
        session['hb_prev_filter'] = hb_filter
        @its = Client::districts_by_product(filt, bot.id, hb_filter_city)
      end
      if filt.instance_of?(District)
        session['hb_filter_district'] = filt
        @its = Client::items_by_the_district_web(
            bot.id,
            hb_filter_product,
            hb_filter_district
        )
      end
      # @its = Client::search_by_filters_product(d, bot.id, hb_filter_city)
      haml :'public/shop-single', layout: hb_layout, locals: {bot: bot, its: @its}
    end

    get '/payment/:klad' do
      haml :'public/payment', layout: hb_layout, locals: {bot: bot, item: Item[params[:klad]]}
    end

    # get '/shop/:shop/city/:city' do
    #   b = Bot[params[:shop]]
    #   c = City[params[:city]]
    #   its = Client::search_by_filters_product(c, b.id)
    #   haml :'public/shop-single', layout: hb_layout, locals: {bot: b, city: c, its: its}
    # end
    #
    # get '/shop/:shop/city/:city/prod/:prod' do
    #   @bot = Bot[params[:shop]]
    #   @city = City[params[:city]]
    #   @prod = Product[params[:prod]]
    #   @its = Client::search_by_filters_product(@prod, @bot.id, @city)
    #   haml :'public/shop-single', layout: hb_layout, locals: {bot: @bot, city: @city, dist: @dist, its: @its}
    # end


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
        redirect url('/')
      else
        flash['info'] = 'Такой никнейм уже существует'
        redirect back
      end
    end

    get '/offer/:client/:product' do
      @cl = Client[params[:client]]
      @bbot = Bot[@cl.bot]
      @prod = Product[params[:product]]
      @img = Item.where(product: @prod.id, bot: @bbot.id).exclude(img: nil)
      @shipments = Item.where(product: @prod.id, bot: @bbot.id).distinct(:shipment)
      @periods = Item.where(product: @prod.id, bot: @bbot.id).distinct(:escrow)
      haml :'public/offer', layout: hb_layout
    end

    get '/auth' do
      haml :'public/login', layout: hb_layout
    end

    get '*' do
      if !hb_bot
        @path = @request.path_info
        if !can?
          haml :'public/denied', layout: hb_layout
        else
          pass
        end
      else
        pass
      end
    end


  end
end