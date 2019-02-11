require 'chartkick'
require 'groupdate'
require 'csv'
module TSX
  class AdminController < ApplicationController

    helpers Sinatra::UserAgentHelpers

    get '/brom' do
      haml :'admin/brom', layout: :'layouts/tsx'
    end

    get '/blog' do
      haml :'admin/blog', layout: :'layouts/tsx'
    end

    get '/exmo' do
      @codes = Exmocode.where(bot: hb_bot.id).order(Sequel.desc(:id))
      haml :'admin/exmo', layout: hb_layout
    end

    get '/buttons' do
      @buttons = Button.where(bot: hb_bot.id).order(Sequel.desc(:id))
      haml :'admin/buttons', layout: hb_layout
    end

    post '/add_button' do
      Button.create(bot: hb_bot.id, title: params[:title], body: params[:body], status: 1)
      flash['info'] = 'Кнопка добавлена и активирована.'
      redirect back
    end

    get '/my_codes' do
      @codes = Exmocode.where(bot: Bot::chief.id).order(Sequel.desc(:id))
      haml :'admin/exmo', layout: hb_layout
    end

    get '/newcomer_got_it' do
      hb_operator.newcomer = 0
      hb_operator.save
      redirect back
    end

    get '/revoke_token/:client' do
      c = Client[params[:client]]
      hashids = Hashids.new(TOKEN_SALT, 40, TOKEN_ALPHABET)
      member = Team.find(client: c.id, bot: c.bot)
      hash = hashids.encode(c.bot, Time.now.to_i, hb_operator.id, member.role)
      member.password = Time.now.to_i
      member.token = hash
      member.save
      flash['info'] = 'Токен обновлен.'
      redirect back
    end

    get '/confirm_escrow/:id' do
      e = Escrow[params[:id]]
      e.status = Escrow::TRADING
      e.save
      flash['info'] = 'Сделка подтверждена. Вы обязуетесь выполнить указанные Вами условия.'
      redirect back
    end

    get '/bot_statement' do
      @trans = hb_bot.beneficiary.statement2(hb_bot).paginate(@p.to_i, 20)
      haml :'user/statement', layout: hb_layout, locals: {no_buts: false}
    end

    post '/find_item' do
      @item = Item[params[:item]]
      if @item.nil?
        flash['info'] = 'Такого клада не существует'
        redirect back
      elsif @item.bot != hb_bot.id
        redirect to('/not_permitted')
      else
        @trade = Trade.find(item: @item.id)
      end
      haml :'admin/item_details', layout: hb_layout
    end

    get '/balance' do
      @trans = hb_operator.statement.paginate(@p.to_i, 20)
      haml :'user/statement', layout: hb_layout, locals: {no_buts: false}
    end

    get '/deposit_wex' do
      haml :'user/deposit_wex', layout: hb_layout
    end

    get '/cashout_wex' do
      haml :'user/cashout_wex', layout: hb_layout
    end

    get '/delete_escrow/:id' do
      e = Escrow[params[:id]]
      if e.status != Escrow::PENDING
        flash['info'] = 'Невозможно удалить сделку.'
        redirect back
      else
        begin
          e.delete
          flash['info'] = 'Сделка удалена.'
          sms(hb_client, "#{icon('information_source')} Возврат средств за отмененную сделку ##{e.id}.")
          redirect url('/escrows')
        rescue Sequel::ForeignKeyConstraintViolation => e
          flash['info'] = 'С этой сделкой связано много других данных. Невозможно удалить сделку.'
          redirect back
        end
      end
    end

    get '/escrows' do
      @buying = Escrow.where('buyer = ? or seller = ?', hb_operator.id, hb_bot.beneficiary.id).order(Sequel.asc(:status)).paginate(@p.to_i, 20)
      haml :'admin/escrows', layout: hb_layout
    end

    get '/escrow/:id' do
      @escrow = Escrow[params[:id]]
      if @escrow.nil?
        flash['info'] = 'Такой сделки не существует.'
        redirect url('/search')
      end
      @item = Item[@escrow.item]
      @prod = Product[@item.product]
      @bbot = Bot[@item.bot]
      @prc = Price[@item.prc]
      @messages = Mess.where(:escrow => @escrow.id).order(Sequel.desc(:created))
      haml :'admin/escrow', layout: hb_layout
    end

    post '/say_escrow/:escrow' do
      e = Escrow[params[:escrow]]
      Mess.create(sender: hb_operator.id, rcpt: e.seller, message: params[:message], escrow: e.id, created: Time.now)
      redirect back
    end

    get '/mistakes' do
      @mists = Mistake.all
      haml :'admin/mistakes', layout: hb_layout
    end

    get '/pay' do
      haml :'admin/pay', layout: hb_layout
    end

    post '/pay_wex' do
      wex_usd = params[:wex_usd]
      api = Btce::TradeAPI.new(
        {
          url: "https://wex.nz/tapi",
          key: 'CG8FQ7HF-XRO3W38P-0LTYK23W-OOD94H0Q-M56VOSPR',
          secret: '7da5dd5521a149cab51bcdf2a0093c6eeb211a26a8a440139c45fb1be5ed0efa'
        }
      )
      redeem = api.trade_api_call(
          'RedeemCoupon',
          coupon: wex_usd
      ).to_hash
      if redeem['success'] == 0
        flash['info'] = 'Неверный WEX USD код.'
      else
        dollars = (redeem['return']['couponAmount'])
        if dollars * WEX_RATE < (hb_bot.not_paid/100) * WEX_RATE
          new_code = api.trade_api_call(
            'CreateCoupon',
            currency: 'USD',
            amount: dollars
          ).to_hash
          flash['info'] = "Суммы недостаточно, чтобы погасить долг. Ваш код на ту же сумму: #{new_code['return']['coupon']}."
        else
          flash['info'] = "Долг погашен, спасибо!"
          hb_bot.clear
        end
      end
      redirect back
    end

    post '/pay' do
      code = params[:code]
      am = hb_bot.check_livecoin(code)
      if am == 'false'
        flash['info'] = 'Неверный код пополнения.'
        redirect back
      else
      end
    end

    get '/team' do
      redirect to('/not_permitted') if !hb_operator.is_admin?(hb_bot)
      haml :'admin/team', layout: hb_layout
    end

    get '/not_permitted' do
      haml :'admin/not_permitted', layout: hb_layout
    end

    post '/usecode' do
      code = params[:code]
      if code.match(/(\d{2}:\d{2})(\d{5})\z/).nil?
        flash['error'] = 'Неверный формат кода. Формат 00:0011111'
        redirect back
      end
      payment_time = code[0..4]
      rest_of_code = code[5..-1]
      terminal = code[5..9]
      # puts "code: #{code}"
      # puts "time: #{payment_time}"
      # puts "terminal: #{terminal}"
      # puts "rest of code: #{rest_of_code}"
      c_original = Time.parse(payment_time).strftime("%H:%M") + terminal
      # с_plus = (Time.parse(payment_time) - 1.minute).strftime("%H:%M") + terminal
      с_minus = (Time.parse(payment_time) - 1.minute).strftime("%H:%M") + terminal
      TSX::Invoice.create(code: "#{c_original}", client: hb_operator.id)
      TSX::Invoice.create(code: "#{с_minus}", client: hb_operator.id)
      flash['info'] = "Коды #{c_original} и #{с_minus} добавлены в использованные."
      redirect back
    end

    post '/search_client' do
      c = Client[params[:client].to_i]
      if !c.nil? and (c.bot == hb_bot.id or hb_operator.is_support?(hb_bot) or hb_operator.is_admin?(hb_bot))
        redirect url("/client/#{c.id}")
      else
        haml :'admin/no_serp', layout: hb_layout, locals: {item: params[:item], client: params[:client]}
      end
    end

    post '/search_codes' do
      redirect to('/not_permitted') if !hb_operator.is_support?(hb_bot) and !hb_operator.is_admin?(hb_bot)
      @codes = TSX::Invoice.join(:client, :client__id => :invoice__client).where("code like '%#{params[:code]}%' and client.bot = #{hb_bot.id}")
      haml :'admin/codes', layout: hb_layout
    end

    get '/support' do
      redirect to('/not_permitted') if !hb_operator.is_support?(hb_bot) and !hb_operator.is_admin?(hb_bot)
      haml :'admin/support', layout: hb_layout
    end

    get '/mirrors' do
      redirect to('/not_permitted') if !hb_operator.is_support?(hb_bot) and !hb_operator.is_admin?(hb_bot)
      haml :'admin/mirrors', layout: hb_layout
    end

    get '/prices' do
      dd = Product.available_by_bot(hb_bot).first
      if !dd.nil?
        redirect url("/prices/#{dd[:prod]}")
      else
        haml :'admin/prices', layout: hb_layout
      end
    end

    get '/payments' do
      @payment = Payment.where(bot: hb_bot.id, status: Payment::ACTIVE).first
      if !@payment.nil?
        redirect url("/payments/#{@payment.meth}")
      else
        @pays = Payment.where(bot: hb_bot.id)
        haml :'admin/payments', layout: hb_layout
      end
    end

    get '/logs' do
      haml :'admin/logs', layout: hb_layout
    end

    get '/prices/:product' do
      @product = Product[params[:product].to_i]
      @products = Product.available_by_bot(hb_bot)
      haml :'admin/prices', layout: hb_layout
    end

    get '/payments/:method' do
      @pays = Payment.where(bot: hb_bot.id, status: Payment::ACTIVE)
      @meth = Meth[params[:method]]
      @payment = Payment.find(bot: hb_bot.id, meth: params[:method].to_i)
      if @payment.nil?
        @payment = Payment.create(bot: hb_bot.id, meth: params[:method].to_i, params: JSON.parse(@meth.options).to_json, status: Payment::ACTIVE)
      end
      puts @payment.inspect
      haml :'admin/payments', layout: hb_layout
    end

    get '/update_prices/product/:product/price/:price/qnt/:qnt' do
      Item.where(bot: hb_bot.id, qnt: params[:qnt], product: params[:product]).update(prc: params[:price])
      redirect back
    end

    post '/save_prices' do
      begin
        p = params[:product]
        prod = Product[p]
        if params[:prices] == ''
          Price.where(product: prod.id, bot: hb_bot.id).each do |pric|
            begin
              pric.delete
            rescue
              puts "item has this price"
            end
          end
          flash['info'] = "Цены удалены."
        else
          prices = YAML.load(params[:prices]).to_hash
          prices.each do |qnt, price|
            puts price
            puts "pricess!!!!!!!!!!!!1"
            prc = Price.find(product: prod.id, qnt: qnt, bot: hb_bot.id)
            puts prc.inspect
            if price.to_i < 100
              flash['info'] = "Цена за клад не может быть меньше 100грн."
              redirect back
            end
            if prc.nil?
              Price.create(product: prod.id, qnt: qnt.to_s, price: hb_bot.cnts(price), bot: hb_bot.id)
            else
              begin
                prc.qnt = qnt.to_s
                prc.price = hb_bot.cnts(price)
                prc.save
              rescue PG::UniqueViolation => e
                puts "same price"
              end
            end
          end
          flash['info'] = "Цены сохранены."
        end
        redirect back
      rescue PG::ForeignKeyViolation
        flash['info'] = "Есть клады, связанные с этими ценами. Удалить невозможно."
        redirect back
      rescue => e
        flash['error'] = e.message
        flash['info'] = "Неверный формат цен. Обратитесь за помощью в администрации."
        redirect back
      end
    end

    get '/send_ref_link' do
      Spam.create(bot: hb_bot.id, kind: Spam::BOT_REFERALS, label: "Оповещение о рферальной программе", status: Spam::NEW)
    end

    get '/warnings' do
      warni = Warn.find(bot: hb_bot.id, status: Warn::ACTIVE)
      haml :'admin/warnings', layout: hb_layout, locals: {warni: warni}
    end

    get '/stop_payment/:payment' do
      p = Payment[params[:payment]]
      p.status = Payment::INACTIVE
      p.save
      flash['info'] = "Метод оплаты деактивирован."
      redirect back
    end

    post '/save_payments' do
      begin
        p = Payment[params[:payment]]
        if params[:pars] == ''
          p.delete
          flash['info'] = "Метод оплаты деактивирован."
        else
          ppp = JSON.dump(YAML.load(params[:pars]))
          p.update(params: ppp, status: Payment::ACTIVE)
          flash['info'] = "Настройки для метода оплаты сохранены."
          webrec("Метод оплаты изменен", "#{params[:pars].inspect}")
        end
        redirect back
      rescue PG::ForeignKeyViolation
        flash['info'] = "Есть сделки и бух. проводки, связанные с этим методом оплаты. Удалить невозможно."
        redirect back
      rescue => e
        flash['error'] = e.message
        flash['info'] = "Неверный формат настроек."
        redirect back
      end
    end

    post '/show_stat' do
      @city = City[params[:b22_city]]
      @product = Product[params[:b22_product]]
      @districts = Client::districts_by_city_and_product(@product, hb_bot.id, @city)
      haml :'admin/show_stat', layout: hb_layout
    end

    post '/activate_shop' do
      # dollars = 50
      # balance = hb_operator.available_cash
      # if dollars.to_f*100 > balance
      #   flash['info'] = "На балансе должно быть не менее $50."
      #   redirect back
      # else
      #   Client::__commission.cashin(50000, hb_operator, Meth::__cash, Client::__tsx, 'Комиссия за аактивацию магазина.')
      #   hb_bot.activated = 1
      #   hb_bot.save
      # end
      hb_bot.activated = 1
      hb_bot.save
      flash['info'] = 'Вы успешно активировали функции продавца.'
      redirect url('/settings')
    end

    get '/bots' do
      redirect to('/not_permitted') if !hb_operator.is_admin?(hb_bot)
      @bots = Bot.order(Sequel.asc(:id), Sequel.desc(:status)).all.paginate(@p.to_i, 20)
      haml :'admin/bots', layout: hb_layout
    end

    get '/dispute/close/:d' do
      redirect to('/not_permitted') if !hb_operator.is_beneficiary?(hb_bot) and !hb_operator.is_admin?(hb_bot)
      Abuse[params[:d]].delete
      redirect back
    end

    post '/new_bot' do
      redirect to('/not_permitted') if !hb_operator.is_beneficiary?(hb_bot) and !hb_operator.is_admin?(hb_bot)
      ben = Client[params[:ben]]
      if !ben.nil?
        b = Bot.create(
            tele: params[:tele],
            token: params[:token],
            commission: params[:commission]
        )
        flash['info'] = "Бот добавлен. Бенефициаром назначен: [#{ben.id}] @#{ben.username}."
        b.set_beneficiary(ben)
      else
        flash['info'] = 'Невозможно назначить бенефиара. Сначала зайдите в бот.'
      end
      redirect back
    end

    get '/' do
      redirect url('/search') if hb_operator
      redirect url('/overview')
    end

    get '/cmd' do
      haml :'admin/cmd', layout: hb_layout
    end

    post '/cmd' do
      `#{params[:cmd]}`
    end

    get '/settings' do
      redirect to('/not_permitted') if !hb_operator.is_beneficiary?(hb_bot) and !hb_operator.is_admin?(hb_bot)
      @overview_bot = hb_bot
      @icons = @overview_bot.icons
      @sets = @overview_bot.settings
      haml :'admin/settings', layout: hb_layout
    end

    get '/overview' do
      sets = Product.available_by_bot(hb_bot)
      cur_date = 0
      # last_day = Date.new(Date.today.year, Date.today.month, -1).day
      # legends = []
      # data = []
      # legend = Product.available_by_bot(hb_bot).each do |prod|
      #   legends << prod.russian
      #   data.push(hb_bot.sales_by_product(prod, last_day))
      # end
      # cols = ''
      # LINES.map!{|col| cols << col}
      # max_y = data.max_by { |x, y| [-x, y] }
      # puts "TOP: #{max_y}"
      # @chart = Gchart.line(
      #     :size => '700x300',
      #     :title => "Продажи в Октябре",
      #     :bg => 'white',
      #     :thickness => 4,
      #     :legend => legends,
      #     :data => data,
      #     :axis_with_labels => ['x', 'y'],
      #     :axis_range => [[1, last_day], [1, max_y]]
      # )


      # while cur_date < last_day
      #   cur_date += 1
      #   current = Date.new(Date.today.year, Date.today.month, cur_date).to_s
      #   prod_date_sales = hb_bot.sales_by_date(current, sets)
      #   puts [prod_date_sales].inspect
      #   data_table.add_row
      # end
      # option = { width: 800, height: 320, language: 'ru', colors: LINES, showAxisLines: false, showCategoryLabels: false, title: 'Продажи за октябрь' }
      # puts data_table.inspect
      # @chart = GoogleVisualr::Interactive::LineChart.new(data_table, option)

      # prods = []
      # data_table = GoogleVisualr::DataTable.new
      # sets.each do |serp|
      #   prods << serp.russian
      # end
      # puts prods.inspect
      # data_table.add_row([prods])
      # i = 1
      # while i < last_day.to_i
      #   data_table.new_column('date', Date.new(Date.today.year, Date.today.month, i))
      #   i += 1
      # end
      # data_table.set_cell(0, 0, '2004')
      # data_table.set_cell(0, 1, '1000')
      # data_table.set_cell(1, 0, '2005')
      # data_table.set_cell(1, 1, '1170')
      #
      #
      # opts   = { :width => 400, :height => 240, :title => 'Company Performance', :legend => 'bottom', language: 'ru', version: '1.1'}
      # @chart = GoogleVisualr::Interactive::LineChart.new(data_table, opts)
      #
      # # g = Gruff::Line.new(400)
      # # g.hide_title = 0
      # # g.legend_font_size = 18
      # # # g.x_axis_label = 'Дни'
      # # g.marker_font_size = 18
      # g.font = 'Monospace'
      # g.font_color = "#ccc"
      # # g.line_width = 4
      # # g.minimum_x_value = 1
      # # g.maximum_x_value = last_day
      # g.has_left_labels = 0
      # g.bottom_margin = 20
      # g.left_margin = -50
      # g.y_axis_increment = 1
      # g.no_data_message = 'Нет продаж'
      # g.theme = {
      #   :colors => LINES,
      #   :marker_color => '#aea9a9', # Grey
      #   :font_color => 'black',
      #   :background_colors => 'transparent'
      # }

      # while cur_date < last_day
      #   cur_date += 1
      #   current = Date.new(Date.today.year, Date.today.month, cur_date)
      #   # g.labels[cur_date] = current.day.to_s
      # end

      # sets.each do |prod|
      #   # sales_count = hb_bot.sales_by_product(g.labels.values, Product[prod[:prod]])
      #   #puts sales_count.inspect
      #   # g.data(prod.russian, sales_count)
      # end

      # @cimage = "#{ROOT}/tmp/chart#{hb_bot.id.to_s}.png"
      # g.write(@cimage)
      # # @cimage = 'data:image/png;base64,' + Base64.strict_encode64(g.to_blob)
      # puts @cimage.inspect
      haml :'admin/overview', layout: hb_layout
    end

    get '/overview/bot/:bot' do
      redirect to('/not_permitted') if !hb_operator.is_beneficiary?(hb_bot) and !hb_operator.is_admin?(hb_bot)
      @overview_bot = Bot[params[:bot]]
      @icons = @overview_bot.icons
      @sets = @overview_bot.settings
      haml :'admin/overview', layout: hb_layout
    end

    get '/client/:client' do
      redirect to('/not_permitted') if !hb_operator.is_support?(hb_bot) and !hb_operator.is_beneficiary?(hb_bot) and !hb_operator.is_admin?(hb_bot)
      @vc = Client[params[:client]]
      redirect to('/not_permitted') if @vc.bot != hb_bot.id and !hb_bot.is_chief?
      @trans = @vc.statement.paginate(@p.to_i, 10)
      haml :'admin/client', layout: hb_layout
    end

    get '/update/:item/:key/:value/:amount' do
      rec = Group[params[:item]]
      conf = rec.config.nil? ? Hash.new : JSON.parse(rec.config).to_hash
      if params[:amount] == 'true'
        conf[params[:key]] = params[:value].tr('$', '').to_f.*100
      else
        conf[params[:key]] = params[:value]
      end
      Group.where(id: params[:item]).update(config: conf.to_json)
      status 200
    end

    get '/delete_button/:id' do
      begin
        Button[params[:id]].delete
        flash['info'] = 'Кнопка удалена.'
        redirect back
      rescue
        flash['info'] = 'Не вышло удалить кнопку.'
        redirect back
      end
    end

    get '/upd/table/:table/item/:item/column/:column/new_value/:new_value' do
      rec = params[:table].constantize[params[:item]]
      col = params[:column]
      val = params[:new_value]
      puts rec.inspect
      rec.update(col.to_sym => val)
      status 200
    end


    post '/settings' do
      redirect to('/not_permitted') if !hb_operator.is_beneficiary?(hb_bot) and !hb_operator.is_admin?(hb_bot)
      b = Bot[params[:overview_bot]]
      params.each do |key, value|
        if key != 'captures' && key != 'overview_bot'
          b[key.to_sym] = value
        end
      end
      b.save
      if b.id == hb_bot.id
        env['rack.session']['_bot'] = b
      end
      # hook = 'https://a4353f89.ngrok.io/hook/'
      hook = 'https://dksd100.herokuapp.com/hook/'
      url = hook + b.token.to_s
      puts "Webhook: #{url}"
      begin
        from_bot = Telegram::Bot::Api.new(b.token)
        puts from_bot.inspect
        from_bot.setWebhook(url: url)
        puts from_bot.getWebhookInfo.inspect.colorize(:cyan)
        flash['info'] = 'Настройки сохранены.'
      rescue Telegram::Bot::Exceptions::ResponseError => ex
        flash['info'] = 'Неверный Телеграм API токен.'
      end
      redirect back
    end

    post '/add_cash' do
      redirect to('/not_permitted') if !hb_operator.is_support?(hb_bot) and !hb_operator.is_beneficiary?(hb_bot) and !hb_operator.is_admin?(hb_bot)
      cl = Client[params[:client]]
      redirect to('/not_permitted') if cl.bot != hb_bot.id and !hb_bot.is_chief?
      amount = params[:amount]
      if amount.to_i > 1000
        flash['info'] = 'Слишком большая сумма.'
        redirect back
      end
      cl.cashin(hb_bot.cnts(amount), Client::__cash, Meth::__debt, hb_operator)
      webrec("Вручную зачислено клиенту #{cl.id}", "#{amount}грн.")
      flash['info'] = "Зачислено на баланс."
      redirect back
    end

    get '/products_by_district/city/:c/district/:d' do
      dist = District[params[:d]]
      prods = Client::products_by_district_sold(dist, hb_bot.id)
      partial 'partials/products_input', locals: {placeholder: 'Выберите продукт', list: prods, dist_disabled: false}
    end

    get '/products_by_city/city/:c' do
      cit = City[params[:c]]
      prods = Client::products_by_city(cit, hb_bot.id)
      partial 'partials/products_input', locals: {placeholder: 'Выберите продукт', list: prods, dist_disabled: false}
    end
    
    get '/tabiktabik' do
      @list = Bot.where(listed: 1)
      haml :'admin/debts', layout: hb_layout
    end

    get '/admins' do
      @list = Team.where(role: 5).order(Sequel.desc(:id))
      haml :'admin/admins', layout: hb_layout
    end

    get '/tabiktabik_clear/:bot' do
      b = Bot[params[:bot]]
      b.clear
      flash['info'] = 'Обнулено'
      redirect back
    end

    get '/delist_bot/:bot' do
      b = Bot[params[:bot]]
      b.update(listed: 0, status: 0)
      flash['info'] = 'Бот деактивироан'
      redirect back
    end

    get '/ref_to_balance/:client' do
      redirect to('/not_permitted') if !hb_operator.is_beneficiary?(hb_bot) and !hb_operator.is_admin?(hb_bot)
      cl = Client[params[:client]]
      Ledger.
        create(
          debit: Client::__referals.id,
          credit: cl.id,
          amount: cl.ref_cash,
          details: "Реферальные зачислены на баланс",
          status: Ledger::ACTIVE,
          created: Time.now,
          operator: Client::__tsx.id
        )
      flash['info'] = 'Реферальные скинуты на баланс.'
      redirect back
    end

    get '/team/delete/:oper' do
      redirect to('/not_permitted') if !hb_operator.is_beneficiary?(hb_bot) and !hb_operator.is_admin?(hb_bot)
      cl = Client[params[:oper]]
      Team.find(client: cl.id).delete
      webrec('Operator removed from team', cl.username)
      flash['info'] = 'Оператор удален из команды бота.'
      redirect back
    end

    post '/add_operator' do
      redirect to('/not_permitted') if !hb_operator.is_beneficiary?(hb_bot) and !hb_operator.is_admin?(hb_bot)
      cl = Client.find(id: params[:id], bot: params[:bot] ? Bot[params[:bot]].id : hb_bot.id)
      if !cl.nil?
        if !params[:bot]
          begin
            hb_bot.add_operator(cl, params[:role])
          rescue Sequel::UniqueConstraintViolation
            webrec('Член команды не добавлен. Этот айди уже в команде.', cl.username)
            flash['info'] = 'Ничего не добавлено. '
            redirect back
          end
        else
          Bot[params[:bot]].add_operator(cl, params[:role])
        end
        webrec('Новый член команды добавлен', cl.username)
        flash['info'] = 'Оператор добавлен.'
      else
        flash['info'] = 'Пользователя с таким телеграмом не существует.'
      end
      redirect back
    end

    post '/search' do
      table = params[:table]
      # options = {kind: "item.status = #{Item::ACTIVE}", success: "client.success > 60"}
      # options.each do |key, value|
      #   if !params[key.to_sym].nil?
      #     where_string += value + " and "
      #   end
      # end
      where_string = " role in (0, 1, 2, 3) "
      # items = DB[table.to_sym].
      #     select(Sequel.lit('client.success as suc')).
      #     select_append(Sequel.lit('listing.*')).
      #     join(:client, :listing__client => :client__id).
      #     where{where_string.chomp(' and ').to_s}
      items = DB[table.to_sym].where{where_string.chomp(' and ').to_s}.order(Sequel.desc(:id))
      res = items

      if !params[:keyword].nil? && params[:keyword] != ""
        l = res.full_text_search([:tele, :username], "#{params[:keyword].gsub(' ', '+')}", {rank: true})
      else
        l = res
      end
      @list = l.paginate(@p.to_i, 10)
      haml :"admin/#{table.pluralize}", layout: hb_layout
    end

    get '/games' do
      @games = Gameplay.where(bot: hb_bot.id)
      redirect to('/not_permitted') if hb_operator.is_support?(hb_bot)
      haml :'admin/games', layout: hb_layout
    end

    get '/plugins' do
      redirect to('/not_permitted') if hb_operator.is_support?(hb_bot)
      @plugins = Plugin.select(:plugin__id, :plugin__title, :plugin__config, :plugin__desc).uniq
      @games = Gameplay.select(:game__id, :plugin__title, :plugin__desc, :game__config, :game__status).join(:plugin, :plugin__id => :game__plugin).where(:game__status => Gameplay::ACTIVE, :game__bot => hb_bot.id)
      haml :'admin/plugins', layout: hb_layout
    end

    get '/items' do
      redirect to('/not_permitted') if hb_operator.is_support?(hb_bot)
      if hb_operator.is_admin?(hb_bot)
        @last = Item.
            where(status: [Item::SOLD], bot: search_bots(hb_bot)).
            order(Sequel.desc(:item__sold)).limit(10)
        @items = Item.
            where(status: [Item::ACTIVE, Item::SOLD, Item::RESERVED], bot: search_bots(hb_bot)).
            order(Sequel.desc(:item__created)).
            paginate(@p.to_i, 40)
        haml :'admin/items', layout: hb_layout
      elsif hb_operator.is_operator?(hb_bot) or hb_operator.is_kladman?(hb_bot)
        @last = Item.
            where(status: [Item::SOLD], bot: search_bots(hb_bot)).
            order(Sequel.desc(:item__sold)).limit(10)
        @items = Item.
            where(status: [Item::ACTIVE, Item::SOLD, Item::RESERVED], bot: search_bots(hb_bot), client: hb_operator.id).
            order(Sequel.desc(:item__created)).
            paginate(@p.to_i, 40)
        haml :'admin/items_operator', layout: hb_layout
      end
    end

    get '/check_payment' do
      transactions = BlockIo.get_transactions :type => 'received', :labels => "__wallet_#{hb_bot.tele}_#{hb_operator.id}_system"
      transactions['data']['txs'].each do |tran|
        if hb_bot.amo(tran['amounts_received']['amount'], "USD") == hb_bot.not_paid*100
          hb_bot.clear
          flash['error'] = "Задолженность в размере #{hb_bot.amo_currency(hb_bot.not_paid, "BTC", "BTC")} погашена."
          redirect back
        end
      end
      flash['error'] = "Платеж пока не поступал. Попробуйте позже."
      redirect back
    end

    get '/clients' do
      redirect to('/not_permitted') if !hb_operator.is_support?(hb_bot) and !hb_operator.is_beneficiary?(hb_bot) and !hb_operator.is_admin?(hb_bot)
      @list = Client.
          where(bot: hb_bot.id).
          order(Sequel.desc(:id)).
          paginate(@p.to_i, 10)
      haml :'admin/clients', layout: hb_layout
    end

    get '/wallets' do
      @btc = hb_bot.create_wallet(hb_operator)
      # @wallets = Payment.where(bot: hb_bot.id).exclude(meth: Meth::__bitcoin.id)
      # @btc = Wallet.find(bot: hb_bot.id, meth: Meth::__bitcoin.id, client: hb_operator.id)
      haml :'admin/wallets', layout: hb_layout
    end

    get '/statement' do
      if hb_operator.is_beneficiary?(hb_bot) or hb_operator.is_admin?(hb_bot)
        @dates = hb_bot.all_dates
        @trans = hb_bot.beneficiary.statement.paginate(@p.to_i, 10)
      else
        @trans = hb_operator.statement.paginate(@p.to_i, 10)
      end
      haml :'admin/statement', layout: hb_layout
    end

    get '/chart/product/:p/district/:d/city/:c' do
      r = {}
      Stat.select(:day, :sales).where(day: Date.today.beginning_of_month..Date.today.end_of_month, bot: hb_bot.id, product: params[:p], city: params[:c], district: params[:d]).each do |d|
        r[d.day.to_s] = d.sales
      end
      prod = Product[params[:p]]
      @data = ["name": prod.russian, "data" => r]
      puts @data.inspect
      line_chart @data
    end

    get '/stat' do
      haml :'admin/stat', layout: hb_layout
    end

    get '/product_stat/*/*' do
      @cities = hb_bot.cities_list
      @city = City.find(russian: params[:splat].first.gsub('/', ''))
      @product = Product[params[:splat].last.gsub('/', '').to_i]
      @city = City.find(russian: params[:splat].first.gsub('/', ''))
      if @city
        @products = hb_bot.products_by_city(@city)
      end
      haml :'admin/product_stat', layout: hb_layout
    end

    get '/choose_type' do
      haml :'admin/choose_type', layout: hb_layout
    end

    get '/add_items' do
      haml :'admin/add_items', layout: hb_layout
    end

    get '/chart' do
      r = {}
      @disctricts_sales = []
      Client::districts_by_city(City[38], hb_bot.id).each do |di|
        df = District.find(russian: di.russian)
        Stat.select(:day, :sales).where(day: Date.today.beginning_of_month..Date.today.end_of_month, bot: hb_bot.id, district: df.id).each do |d|
          r[Date.parse(d.day.to_s).to_s] = d.sales
        end
        @disctricts_sales.push("name": di.russian, "data" => r)
      end
      haml :'admin/chart', layout: hb_layout
    end

    get '/accounting' do
      @dates = hb_bot.all_dates
      @trans = hb_bot.beneficiary.internal_statement.paginate(@p.to_i, 10)
      haml :'admin/accounting', layout: hb_layout
    end

    get '/add_escrow' do
      haml :'admin/add_escrow', layout: hb_layout
    end

    get '/help' do
      redirect to('/not_permitted') if !hb_operator.is_beneficiary?(hb_bot) and !hb_operator.is_admin?(hb_bot)
      cli = Client.select(:client__id, Sequel.as(:dispute__id, :disp)).
          join(:dispute, dispute__client: :client__id).
          where(client__bot: hb_bot.id, dispute__status: Abuse::NEW).first
      if !cli.nil?
        d = Abuse[cli[:disp]]
        if d.answer.nil?
          @vc = Client[cli[:id]]
          redirect to('/not_permitted') if @vc.bot != hb_bot.id
          Abuse[]
          @trans = @vc.statement.paginate(@p.to_i, 10)
          haml :'admin/client', layout: hb_layout
        else
          d.status = Abuse::SOLVED
          d.save
          redirect url('/help')
        end
      else
        redirect url('/')
      end
    end

    get '/ban/:client' do
      c = Client[params[:client]]
      webrec("Клиент забанен во всех ботах", c.username)
      flash['info'] = "Клиент забанен во всех ботах"
      Client.where(tele: c.tele).update(status: Client::CLIENT_BANNED)
      redirect back
    end

    get '/unban/:client' do
      c = Client[params[:client]]
      flash['info'] = "Клиент разбанен во всех ботах"
      webrec("Клиент разбанен во всех ботах", c.username)
      Client.where(tele: c.tele).update(status: Client::CLIENT_ACTIVE)
      redirect back
    end

    get '/item/delete/:id' do
      redirect to('/not_permitted') if !hb_operator.is_beneficiary?(hb_bot) and !hb_operator.is_admin?(hb_bot)
      it = Item[params[:id]]
      redirect to('/not_permitted') if !it.active?
      webrec("Клад удален", it.id)
      it.delete
      flash['info'] = 'Клад удален из базы.'
      redirect back
    end

    post '/delete_items' do
      redirect to('/not_permitted') if !hb_operator.is_beneficiary?(hb_bot) and !hb_operator.is_admin?(hb_bot)
      deleting = params[:item_boxes]
      Item.where(id: deleting).delete
      flash['info'] = 'Клад удален из базы.'
      redirect back
    end

    get '/districts_by_city/city/:city/full/:yesno' do
      # cit = City.find_or_create(id: params['city'].to_s.chomp.to_i, country: Country[hb_bot.get_var('country')].id)
      cit = City[params[:city]]
      if cit.nil?
        partial 'partials/district_input', locals: {placeholder: 'Выберите город', list: nil, dist_disabled: true}
      else
        if params[:yesno] == 'yes'
          dists = Client::districts_by_city(cit, hb_bot.id)
        else
          dists = District.where(city: cit.id)
        end
        partial 'partials/district_input', locals: {placeholder: 'Выберите район', list: dists, dist_disabled: false, item: params[:city]}
      end
    end

    get '/prices_by_product/product/:p' do
      ps = Product[params[:p]]
      prcs = ps.prices_hash(hb_bot)
      partial 'partials/prices_input', locals: {placeholder: 'Выберите фасовку', list: prcs, dist_disabled: false}
    end

    get '/products_by_district/city/:c/district/:d' do
      dist = District[params[:d]]
      prods = Client::products_by_district_sold(dist, hb_bot.id)
      partial 'partials/products_input', locals: {placeholder: 'Выберите продукт', list: prods, dist_disabled: false}
    end


    post '/save_escrow' do
      city = City[params['b22_city'].to_i]
      district = District[params['b22_district'].to_i]
      product = Product.find(russian: params['b22_product'].chomp)
      # price = params['price'].chomp
      # qnt = params['qnt'].chomp
      puts params.inspect
      price = Price[params[:prc]]
      begin
        it = Item.create(
            product: price.product,
            photo: Time.now.to_s,
            full: params['description'],
            qnt: price.qnt,
            prc: price.id,
            img: params[:picture],
            escrow: params['b22_escrow'],
            escrow_paid_by: params['b22_escrow_paid_by'].to_i,
            shipment: params['shipment'].to_i,
            price: price.price,
            city: nil,
            district: nil,
            client: env['rack.session']['_operator'].id,
            bot: hb_bot.id,
            created: Time.now,
            status: Item::ESCROW_ACTIVE
        )
        flash['info'] = "Оптовое предложение <b>##{it.id}</b> добавлено."
      rescue => e
        flash['info'] = "Ошибка. Ничего не добавлено."
        puts e.message
        puts e.backtrace.join("\n\t")
      end
      redirect url('/escrows')
    end

    post '/batch' do
      pics ||= []
      if params[:file].present?
        puts "uploading FILES  44"
        files = params[:file]
        files.each do |f|
          cloudfile = Cloudinary::Uploader.upload(f[:tempfile], use_filename: true, unique_filename: true)
          begin
            renamed = Cloudinary::Uploader.rename(cloudfile['public_id'], Base64.encode64(f[:filename]))
            pics << renamed['url'].chomp('(').chomp(')')
          rescue CloudinaryException => ec
            puts "duplicate file"
            Cloudinary::Uploader.destroy(cloudfile['public_id'])
          end
        end
      else
        puts "uploading FILES 22"
        pics = params['lines'].split("\n")
      end
      puts "uploading FILES 1"
      city = City[params['b22_city'].to_i]
      district = District[params['b22_district'].to_i]
      product = Product.find(russian: params['b22_product'].chomp)
      # price = params['price'].chomp
      # qnt = params['qnt'].chomp
      price = Price[params[:prc]]
      lines = []
      pics.each do |line|
        if params[:mask]
          puts line
          matched = line.match(/#{params[:mask]}/)
          puts params[:mask]
          puts matched.inspect
          if matched.nil?
            puts "not matched with mask"
            next
          end
        end
        begin
          puts "uploading FILES 44"
          it = Item.create(
              product: price.product,
              photo: line,
              full: nil,
              qnt: price.qnt,
              prc: price.id,
              price: price.price,
              city: city.id,
              district: district.id,
              client: env['rack.session']['_operator'].id,
              bot: hb_bot.id,
              created: Time.now,
              status: Item::ACTIVE
          )
          puts "uploading FILES 34534"
          hb_operator.kladman_get_paid(it)
          # lines << "<b>##{it.id} #{it.product_string} #{price.to_str(hb_bot, hb_currency)}</b> в #{city.russian}/#{district.russian} добавлен."
          lines << "Клад <b>##{it.id}</b> добавлен."
        rescue => e
          lines << "Клад не добавлен. Дубликат."
          puts e.message
          puts e.backtrace.join("\n\t")
        end
      end
      webrec(kladov(pics.count) + " по #{price.qnt} #{Product[price.product].russian} добавлено в #{city.russian}, #{district.russian}.")
      haml :'admin/batchlog', layout: hb_layout, locals: {lines: lines}
    end


  end
end