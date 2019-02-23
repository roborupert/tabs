Введите код подтверждения платежа. *ВВОДИТЕ КОД ЧЕРЕЗ 10 МИНУТ ПОСЛЕ ОПЛАТЫ!*
****
btns = []
more_buts = []
more_buts << icon('dollar', 'Оплатить с баланса') if @balance_btn
more_buts << icon('hand', 'Взять') if @take_free_btn
btns << more_buts << [icon(@tsx_bot.icon_cancel, 'Отменить'), btn_main] << [icon(@tsx_bot.icon_payments, 'Как платить?')]
btns
