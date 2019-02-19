HAMDLERS = {
      "start": 'start',
      "Главная": 'start',
      "help": 'welcome',
      "Профиль": 'my_overview',
      "Настройки": 'my_settings',
      "Сделки": :escrow,
      "Клады": 'do_my_products',
      "Все клады": 'my_items',
      "Продукт": 'product',
      "Район": 'district',
      "О системе": 'welcome',
      "Заказы": 'my_trades',
      "Заказ": 'pending_trade',
      "Назад": 'go_back',
      "Правила": 'rules',
      "Платежи": 'payments',
      "payments": 'payments',
      "rules": 'rules',
      "Работа": 'jobs',
      "me": 'my_account',
      "cashout": 'cashout',
      "баланса": 'pay_by_balance',
      "оценку": 'rate_trade',
      "позже": 'later',
      "easypaysample": 'easypaysample',
      "Перезаклад!": 'reitem',
      "Выдать": 'approve_reitem',
      "Отказать": 'reject_reitem',
      "Клад": 'add_item',
      "Помощь": 'help',
      "запрос": 'cancel_dispute',
      "Взять": 'take_free',
      "геопозицию": 'save_location',
      "Бухгалтерия": 'system_accounts',
      "Админ": 'admin_menu',
      "Стата": 'botstat',
      "Долги": 'debts',
      "Прайсы": 'prices',
      "платить?": 'payments',
      "бот": 'new_bot',
      "Рекомендуем": 'welcome_bots',
      "регистрацию": 'cancel_new_bot',
      "кошель": 'service_wallets',
      "системе": 'service_about',
      "Bitcoin": 'service_btc',
      "Проблемы": 'abuse',
      "сделку": 'start_trade',
      "Данные": 'start_info',
      "Привязать": 'ask_token',
      "Подтвердить": 'confirm_escrow',
      "Отказаться": 'deny_escrow',
      "Реклама": 'activate_darkside',
      "Выключить Рекламу": 'remove_darkside',
      "Пополнение": 'admin_add_cash',
      "Продажи": 'admin_sales',
      "Официально": 'info',
      "Пожаловаться": 'abuse',
      "Отмена": 'cancel',
      "Кабинет": 'panel',
      "Вывести": 'cashout',
      "Выписка": 'client_statement',
      "Рефералы": 'client_referals'
}

CHAT_HAMDLERS = {
    "activate_darkside": 'activate_darkside',
    "remove_darkside": 'remove_darkside'
}

OVERVIEW = [
    'Общие настроки':
        ['support', 'title', 'avatar', 'description'],
    'Настройки бота автопродаж':
        ['tele', 'token', 'ref_rate', 'reserve_interval', 'retry_period']
]

LINES = [
    '#edc951', '#eb6841', '#cc2a36', '#4f372d', '#00a0b0', '#f96161', '#d0b783', '#2a334f', '#6b4423', '#0077AA'
]

COL_OPTIONS =
[
      "serp_type": ['город, район, продукт', 'город, продукт, район'],
      "underscored_name": ['без подчеркивания', 'с подчеркиванием'],
      "web_klad": ['выключиь', 'включить']

]

RANKS = {
    "Ужасно": 1,
    "Плохо": 2,
    "Нормально": 3,
    "Неплохо": 4,
    "Хорошо": 5
}

ENDPOINTS = %w(
        getUpdates setWebhook deleteWebhook getWebhookInfo getMe sendMessage
        forwardMessage sendPhoto sendAudio sendDocument sendSticker sendVideo
        sendVoice sendLocation sendVenue sendContact sendChatAction
        getUserProfilePhotos getFile kickChatMember leaveChat unbanChatMember
        getChat getChatAdministrators getChatMembersCount getChatMember
        answerCallbackQuery editMessageText editMessageCaption
        editMessageReplyMarkup answerInlineQuery sendGame setGameScore
        getGameHighScores deleteMessage
      ).freeze


MARKDAOWN_EXAMPLE =  """
Отзывы и более сотни трипрепортов о нашей продукции и магазине Вы можете прочитать на таких ресурсах:

[Ветка на БигБро](http://bbro.com)
[Ветка на Лигалйзере](http://legalizer.info)
[Ветка на LegalRC](http://legalrc.com)
"""
