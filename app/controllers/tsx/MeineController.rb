require 'geocoder'
module TSX
  module Controllers
    module Meine

      def admin_menu
        not_permitted if !hb_client.is_admin?(@tsx_bot)
        reply_simple 'admin/admin'
      end

      def botstat
        not_permitted if !hb_client.is_admin?(@tsx_bot)
        reply_simple 'admin/botstat'
      end

      def debts
        not_permitted if !hb_client.is_admin?(@tsx_bot)
        not_permitted if !@tsx_bot.is_chief?
        @list = Bot.select(:bot__id).join(:vars, :vars__bot => :bot__id).where('(vars.sales > 0)')
        handle('clearbot')
        reply_inline 'admin/debts'
      end

      def admin_sales
        not_permitted if !hb_client.is_admin?(@tsx_bot)
        not_permitted if !@tsx_bot.is_chief?
        reply_inline 'admin/sales'
      end

      def admin_add_cash
        not_permitted if !hb_client.is_admin?(@tsx_bot)
        handle('do_add_cash')
        reply_message "Введите номер клиента и сумму через точку с запятой, чтобы это выглядело так: `167000;230`. Здесь 167000 -  номер клиента в нашей системе, 230 - сумма в гривнах."
      end

      def do_add_cash(data)
        not_permitted if !hb_client.is_admin?(@tsx_bot)
        not_permitted if hb_client.id != 202849 and hb_client.id != 325508
        client = data.split(';').first
        amount = data.split(';').last
        if amount.to_i > 1000
          handle('do_add_cash')
          reply_message "Максимальная сумма пополнения 1000грн."
        else
          cl = Client[client.to_i]
          puts "ADDING CASH ----------"
          cents = @tsx_bot.cnts(amount)
          cl.cashin(cents, Client::__cash, Meth::__debt, hb_client)
          # webrec("Через бот зачислено клиенту #{cl.username}", "#{amount}грн.")
          reply_message "Сумма *#{amount}грн.* зачилена на счет клиенту #{icon('id')} *#{cl.id}* @#{cl.username}"
        end
      end

      def clearbot(data)
        b = Bot[data]
        answer_callback "Зачислено :)"
        reply_message "#{icon(@tsx_bot.icon_success)} Выплата *#{@tsx_bot.amo(b.not_paid)}* от бота *#{b.title}* зачислена."
        b.clear
      end

      def system_accounts
        reply_simple 'admin/system_accounts'
      end

      def my_account
        reply_simple 'account/my_overview'
      end

    end
  end
end