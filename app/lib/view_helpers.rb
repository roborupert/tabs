module TSX
  module View_helpers

    def bread_crumbs
      line = "#{sget('tsx_filter').russian}\n"
      # line = ''
      # line << "#{sget('tsx_filter').russian}, #{_district.russian}" unless _product
      # line << "#{_district.russian}" unless _district
      # line << "#{icon(_product[:icon], _product.russian)}" unless _product
      # if sget('tsx_filter').instance_of?(Product)
      #   line << "Найдено *#{Client::items_by_product(_product, _district, hb_client).count}*"
      # end
      line
    end

    def set_filters_back_web
      filter = session['tsx_filter']
      if filter.instance_of?(Item)
        session['tsx_filter'] = session['tsx_filter_district']
      end
      if filter.instance_of?(City)
        session['tsx_filter'] = session['tsx_filter_country']
        session['tsx_filter_country'] = Country[hb_bot.get_var('country')]
      end
      if filter.instance_of?(District)
        session['tsx_filter'] = session['tsx_filter_product']
        session['tsx_filter_product'] = session['tsx_filter']
      end
      if filter.instance_of?(Product)
        session['tsx_filter'] = session['tsx_filter_city']
        session['tsx_filter_product'] = session['tsx_filter']
      end
    end

    def btn_cancel
      icon('no_entry_sign', "Отмена")
    end

    def help_buttons
      but_list ||= []
      but_list <<
          icon('outbox_tray', 'Заказать вывод') <<
          icon('green_book', 'Выписка') <<
          icon('art', 'Рефералы') <<
          btn_main
      other_buts = keyboard(but_list - [nil], 2) do |b|
        b if !b.nil?
      end
      other_buts
    end

    def btn_add_item
      if hb_client.is_kladman?(@tsx_bot) or hb_client.is_admin?(@tsx_bot) or hb_client.is_operator?(@tsx_bot)
        icon(@tsx_bot.icon_new_item, 'Клад')
      else
        nil
      end
    end

    def btn_my_account
      icon('ghost', "Профиль")
    end

    def btn_main_web
      button("Главная", 'main')
    end

    def btn_main
      icon(@tsx_bot.icon, 'Главная')
    end

    def btn_later
      icon(@tsx_bot.icon, 'Оценить позже')
    end

    def btn_cashout
      icon(@tsx_bot.icon_cashin, 'Вывести')
    end

    def btn_cashin
      icon(@tsx_bot.icon_cashout, 'Пополнить')
    end

    def btn_items
      icon('secret', 'Клады')
    end

    def btn_settings
      'Настройки'
    end

    def btn_change_city
      icon(@tsx_bot.icon_back, 'Город')
    end

    def btn_change_district
      icon(@tsx_bot.icon_back, 'Район')
    end

    def btn_pending_trades
      if hb_client.has_pending_trade?(@tsx_bot)
        icon(@tsx_bot.icon_trade, 'Заказ')
      end
    end

    def btn_pending_trades_web
      if hb_operator != false
        if hb_operator.has_pending_trade?(hb_bot)
          button("#{icn(hb_bot.icon_trade)} Заказ", 'order')
        end
      end
    end

    def btn_finalized_trades
      if hb_client.has_not_ranked_trade?(@tsx_bot)
        icon(@tsx_bot.icon_trade, 'Поставить оценку')
      end
    end

    def btn_finalized_trades_web
      if hb_operator
        if hb_operator.has_not_ranked_trade?(hb_bot)
          button("#{icon(@tsx_bot.icon_trade)} Поставить оценку", 'rank')
        end
      end
    end

    def btn_prices
      icon('euro', 'Прайсы')
    end

    def btn_about
      icon('house_with_garden', 'Официально')
    end

    def btn_help
      icon(@tsx_bot.icon_help, 'Помощь')
    end

    def btn_help_web
      button("Помощь", 'help')
    end

    def btn_admin
      if hb_client.is_admin?(@tsx_bot) or hb_client.is_beneficiary?(@tsx_bot)
        icon(@tsx_bot.icon_job, 'Админ')
      end
    end

    def btn_bots_welcome
      icon('bow', 'Рекомендуем')
    end

    def btn_abuse
      icon('oncoming_police_car', 'Пожаловаться')
    end

    def btn_cashout
      '📤 Вывести'
    end

    def btn_bots_welcome_web
      button("#{icn('bow')} Рекомендуем", 'recommend')
    end

    def btn_back
      icon(@tsx_bot.icon_back, 'Назад')
    end

    def btn_back_web
      button("Назад", 'back')
    end

    def btn_change_product
      icon(@tsx_bot.icon_back, 'Продукт')
    end

    def item_editing_block(item)
      Product[item.product].russian
    end

    def method_details(method)
      case method
        when 'easypay'
          "Метод оплаты *EasyPay*\n" <<
          "Кошелек *#{@tsx_bot.is_chief? ? @seller_bot.payment_option('keeper', Meth::__easypay) : @tsx_bot.payment_option('keeper', Meth::__easypay)}*"
        when 'qiwi'
          "Кошелек *#{@tsx_bot.is_chief? ? @seller_bot.payment_option('phone', Meth::__qiwi) : @tsx_bot.payment_option('phone', Meth::__qiwi)}*"
        when 'exmo'
          "Метод оплаты *EXMO код*"
        when 'lc'
          "Метод оплаты *Livecoin код*"
        when 'btce'
          "Метод оплаты *код BTC-E USD*"
        when 'wex'
          "Метод оплаты *код WEX USD*"
        when 'tokenbar'
          "Метод оплаты *код TokenBar*"
        when 'nix'
          "Метод оплаты *NIX money*\n"+
          "NIX кошелек *U77372932650794*"
        when 'webmoney'
          "Метод оплаты *Webmoney BTX*\n"+
          "NIX кошелек *U912130716546*"
      end
    end

    def method_helper(method, item)
      puts "METHOD: #{method.downcase}"
      case method.downcase
        when 'tokenbar'
          puts "PRICE, CENTS: #{item.discount_price}"
          puts "NEEDED USD AMOUNT: #{item.discount_price / 100}"
          puts "NEEDED UAH AMOUNT: #{@tsx_bot.uah(item.discount_price)}"
          rats = BestchangeRates.new.rates('Exmo USD' => 'Visa/MasterCard UAH').first[:get].to_f.round(2)
          puts "Today EXMO exchange rate: #{rats}"
          metho = Meth.find(title: method)
          discount = item.discount_price_by_method(metho)
          percent = item.method_discount_rate(metho)
          if percent > 0
            meth_discount = item.discount_method_amount(percent)
            view_body = "К оплате *#{@tsx_bot.uah(discount)}*\n" <<
                "#{method_details(method)}\n" <<
                "Курс EXMO *#{rats}*\n"
            view_body <<
                "Скидка *#{@tsx_bot.uah(meth_discount)}* (`#{percent}%`)\n"
          else
            view_body = "К оплате *#{@tsx_bot.uah(item.discount_price)}*\n" <<
                "#{method_details(method)}\n" <<
                "Курс EXMO *#{rats}*\n"
            if item.old?
              view_body <<
                  "Скидка *#{@tsx_bot.uah(item.discount_amount)}* / `-#{@tsx_bot.discount}%`\n"
            end
          end
        when 'easypay'
          view_body =
              "К оплате *#{@tsx_bot.uah(item.discount_price)}*\n" <<
              "#{method_details(method)}\n"
          if item.old?
            view_body <<
                "Скидка `-#{@tsx_bot.discount}%` на *#{@tsx_bot.uah(item.discount_amount)}*\n"
          end
      end
      view_body
    end

    def method_desc(method)
      case method
        when 'tokenbar'
          "Пример `380971234567:00000000`"
        when 'easypay'
          "Пример `12:1399899`"
      end
    end

    def method_details_web(met)
      case met.russian.downcase
        when 'easypay'
          "Метод оплаты <b>EasyPay</b><br/> Кошелек <b>#{hb_bot.payment_option('keeper', Meth::__easypay)}</b>"
        when 'qiwi'
          "Метод оплаты *EasyPay*\n Кошелек *#{hb_bot.payment_option('wallet', Meth::__qiwi)}*"
        when 'wex'
          "Метод оплаты *код WEX USD*"
      end
    end


    def web_button(title, action)
      "<button onclick=#{location(action)}>#{title}</button>"
    end

    def welcome_keyboard
      [
          [
              button(@tsx_bot.tele, 'contact_info'),
              button('Не могу найти клад', 'escrow_sellers_info'),
          ],
          [
              button('Безопасность', 'security_info'),
              button('Оплата товара', 'btc_info')
          ],
          [
              button('Ищешь работу?', 'career_info')
          ]
      ]
    end

    def keyboard(list, slice = 3)
      buts = []
      list.each_slice(slice) do |slice|
        row = []
        slice.each do |res|
          begin
            line = yield res
            row << line
          rescue => eed
            puts "FALSE CLASS"
            puts eed.message
            puts eed.backtrace.join("\t\n")
          end
        end
        buts << row
      end
      buts
    end

    def inline_keyboard(list)
      buts = []
      list.each do |res|
        line = yield res
        buts << [line]
      end
    end

    def reputation_web(client)
      rnk = Rank::reputation(client)
      # puts "RANK: #{rnk}".colorize(:red)
      # stars = ''
      # i = 0
      # while i < rnk.floor + 1
      #   i += 1
      #   stars << "#{icn('full_moon')}"
      #   rest = 0
      #   puts "ОСТАТОК: #{rnk.modulo(i)}"
      #   if rnk.modulo(i) < 10
      #     stars << "#{icn('first_quarter_moon')}"
      #     rest = 0
      #   end
      # end
      "#{rnk == "NaN" ? "0.00" : rnk}"
    end

    def reputation(client)
      "#{icon('parking')} #{reputation_web(client)}"
    end

    def item_data
"#{@item.product_string} *#{@item.make('qnt', 'вес')}* *#{@item.price_string}*,
#{@item.city_string}, #{@item.district_string} (#{@item.make('details', 'коротко')})
#{@item.make('full', 'подробное описание клада')}"
    end

    def system_clients(bot)
      lines = ""
      bot.system_clients.each do |c|
        lines << "#{c.description} *#{bot.amo(c.available_cash)}*\n"
      end
      lines
    end

    def bot_stat
      bots = Bot.where(status: Bot::ACTIVE)
      lines = ""
      bots.each do |bot|
        if !bot.is_chief?
          if bot.beneficiary != false
            lines << "*" << bot.title << "*\n"
            lines << "К выплате *" << bot.amo(bot.not_paid) << "*\n"
            lines << "/clear 57\n\n"
          else
            lines << bot.title << " .. нет владельца" << "\n"
          end
        end
      end
      lines
    end

    def list_wholesale_prices(bbb)
      lines = ""
      @products = Product.wholesale_by_bot(bbb)
      @products.each do |product|
        prices = Price.where(product: product[:prod], bot: bbb.id).distinct(:price__qnt)
        lines << "#{icn(product.icon)} <b>#{product.russian}</b> "
        prices.each do |pr|
          if pr.price > 3500
            lines << "#{pr.qnt} #{bbb.amo(pr.price)} "
          end
        end
        lines << "<br/>"
      end
      lines
    end

    def list_prices_web
      bbb = @tsx_bot || hb_bot
      lines = ""
      @products = Product.available_by_bot(bbb)
      @products.each do |product|
        prices = Price.where(product: product[:prod], bot: bbb.id).distinct(:price__qnt)
        puts prices.inspect
        lines << "#{icn(product.icon)} <b>#{product.russian}</b> <a href='/prices/#{product[:prod]}'>изменить</a> "
        prices.each do |pr|
          lines << "#{pr.qnt} #{bbb.amo(pr.price)} "
        end
        lines << "<br/>"
      end
      lines
    end

    def list_payments
      bbb = @tsx_bot || hb_bot
      lines = ""
      @pays = Payment.where(bot: bbb.id)
      @pays.each do |m|
        met = Meth[m.meth]
        lines << "<img width='30px' src='images/payments/#{met.title}.png'> <b>#{met.russian}</b><br/>"
        JSON.parse(m.params).each do |key, value|
          lines << "#{icon('key')} <b>#{key}:</b> <span class='dlighted'>#{value}</span><br/>"
        end
        lines << "<br/>"
      end
      lines
    end

    def line_color_string(color)
      Hash.new('borderColor': "#{color}", 'backgroundColor': 'rgba(255, 255, 255, 0)', 'borderWidth': '2', 'pointRadius': '3')
    end

    def list_prices
      bbb = @tsx_bot || hb_bot
      lines = ""
      @products = Product.available_by_bot(bbb)
      @products.each do |product|
        next if product[:icount] == 0
        lines << "#{icon(product.icon)} *#{product.russian}*\n"
        prices = Price.where(product: product[:prod], bot: bbb.id).distinct(:price__qnt)
        prices.each do |pr|
          lines << "#{pr.qnt}     `#{bbb.amo(pr.price)}`\n"
        end
      end
      lines
    end

    def share_stat
      bots = Bot.where(partner: @tsx_bot.id)
      line = ''
      if bots.count > 0
        line << "\n*Статистика рефералов*\n\n"
        bots.each do |bot|
          line << "`#{bot.tele}` .. #{@tsx_bot.amo(bot.not_paid*bot.share/100)}\n"
        end
        line
      end
    end

    def darkside_sales
      line = ''
      (1.month.ago.to_date..Date.today).map{ |date|
        line << "#{date.strftime("%b %d")} .. #{prodazh(Darkside::System.sales_count_by_day(date))} на *#{@tsx_bot.uah(prodazh(Darkside::System.sales_amount_by_day(date)))}*, комиссия *#{@tsx_bot.uah(Darkside::System.not_paid_by_day(date))}*\n"
      }
      line
    end

    def best_bot
      lines = ""
      b = Vote::best_this_month
      if !b.nil?
        lines << "*Авторитет*\nЛучший шоп по мнению самих пользователей.\n\n"
        lines << "#{b.nickname_md} 🎖️🎖️🎖️\nОтзывы #{icon('+1')} #{Rank::positive(b.beneficiary)} #{icon('-1')} #{Rank::negative(b.beneficiary)}\nВ наличии *#{kladov(b.active_items)}*\nГорода *#{b.cities_full_clear}*\n#{b.description}"
        lines
      end
    end

    def main_top
      lines = ""
      bots = Bot.select_all(:bot).join(:vars, :vars__bot => :bot__id).where(listed: 1).order(Sequel.desc(:vars__today_sales)).limit(5)
      lines << "\n*Топ-5*\nЛучшие магазины нашей системы. Рейтинг обновляется несколько раз в день автоматически.\n\n"
      top = 1
      bots.each do |b|
        case top
          when 1
            lines << "🥇 #{b.nickname_md} #{b.cities}\n"
          when 2
            lines << "🥈 #{b.nickname_md} #{b.cities}\n"
          when 3
            lines << "🥉 #{b.nickname_md} #{b.cities}\n"
          when 4
            lines << "🏅 #{b.nickname_md} #{b.cities}\n"
          when 5
            lines << "🏅 #{b.nickname_md} #{b.cities}\n"
        end
        top += 1
      end
      lines
    end

    def bots_welcome
      lines = ""
      lines << "*Остальные магазины*\nТоп остальных магазинов системы. Список формируется по колиечству продаж за вчера..\n\n"
      bots = Bot.select_all(:bot).join(:vars, :vars__bot => :bot__id).where(listed: 1).order(Sequel.desc(:vars__today_sales)).offset(5)
      top = 1
      bots.each do |b|
        lines  << ("#{icon('small_orange_diamond')} #{b.nickname_md} #{b.awards} #{b.cities}\n") if b.cities
        top += 1
        next if top <= 5
      end
      lines
    end

    def bots_welcome_risk
      bots = Bot.select_all(:bot).join(:vars, :vars__bot => :bot__id).where(risky: 1).order(Sequel.desc(:vars__today_sales))
      lines = "*Магазины на проверке*\nВ этом списке новые магазины. Мы ничего не можем сказать о них. В течение нескольких дней мы проверим их клады и примем решение.\n\n"
      bots.each do |b|
        lines  << ("#{icon('small_orange_diamond')} #{b.nickname_md} #{b.awards} #{b.cities}\n") if b.cities
      end
      lines
    end

    def client_details(client)
sh = client.shop?
shop_info = ''
if sh != false
shop_info = "Бот магазин *#{sh.title}*
Продаж *#{client.sell_trades([Trade::FINALIZED, Trade::FINISHED]).count}* на *#{@tsx_bot.amo(client.sell_trades([Trade::FINALIZED, Trade::FINISHED]).sum(:price))}*"
end

"Клиент #{icon('id')} *#{client.id}*
Никнейм *#{client.username}*
Репутация #{reputation(client)}
Баланс *#{@tsx_bot.amo(client.available_cash)}*
Покупок *#{client.buy_trades([Trade::FINALIZED, Trade::FINISHED]).count}* на *#{@tsx_bot.amo(client.buy_trades([Trade::FINALIZED, Trade::FINISHED]).sum(:price))}*
#{shop_info}"
    end
  end
end