require 'base64'
class Client < Sequel::Model(:client)
  include TSX::Helpers
  include TSX::Elements
  include TSX::Context
  include Colorize

  def self.deb(text)
    puts text.colorize(:light_white)
  end

  HB_BITCOIN = 195
  HB_COMMISSION = 196
  HB_ESCROW = 198

  HB_ROLE_API = 14
  HB_ROLE_BUYER = 1
  HB_ROLE_SELLER = 2
  HB_ROLE_OPERATOR = 8
  HB_ROLE_ADMIN = 5
  HB_ROLE_KLADMAN = 3
  HB_ROLE_SYSTEM = 9
  HB_ROLE_BOT = 4
  HB_ROLE_SUPPORT = 11
  HB_ROLE_USER = 12
  HB_ROLE_ARCHIVED = 101
  HB_ROLE_SERVICE = 13
  HB_ROLE_PUBLIC = 102

  AUTOSHOP = 0
  SHIPMENT = 1

  CLIENT_BANNED = 0
  CLIENT_ACTIVE = 1

  ALL = [Client::HB_ROLE_USER, Client::HB_ROLE_ADMIN, Client::HB_ROLE_OPERATOR, Client::HB_ROLE_KLADMAN, Client::HB_ROLE_SUPPORT, Client::HB_ROLE_API],
  PUBLIC = [Client::HB_ROLE_PUBLIC, Client::HB_ROLE_API]
  LOGGED = [Client::HB_ROLE_USER, Client::HB_ROLE_OPERATOR]


  def is_upload_files?
    self.role == Client::HB_ROLE_KLADMAN
  end

  def voted?
    !Vote.find(username: self.tele).nil?
  end

  def has_notify?(bot)
    t = Team.find(bot: bot.id, client: self.id)
    if t.nil?
      false
    else
      !t.notify.nil?
    end
  end

  def escrow_buyer?(escrow)
    self.id == escrow.buyer
  end

  def banned?
    self.status == Client::CLIENT_BANNED
  end

  def disputes(st = Abuse::APPROVED)
    Abuse.join(:trade, trade__id: :dispute__trade).where(trade__buyer: self.id, dispute__status: st)
  end

  def has_dispute?
    has = Abuse.find(client: self.id, status: Abuse::NEW)
    !has.nil?
  end

  def has_vote?
    !Vote.find(username: self.tele, bot: self.bot).nil?
  end

  def has_bet?(game)
    !Bet.find(client: self.id, game: game.id).nil?
  end

  def reitem_possible?(trade)
    i = Item[trade.item]
    trades = self.buy_trades([Trade::FINALIZED, Trade::FINISHED]).count
    disputes = self.disputes.count > 0 ? self.disputes.count : 1
    if disputes == 0
      q = trades
    else
      q = (trades.to_f/disputes).round
    end
    min = Bot[trade.bot].reitem_trades_minimum
    deb "DISPS: #{disputes}"
    deb "TRADES: #{trades}"
    deb "Q: #{q}"
    deb "MIN: #{min}"
    return false if q < min
    return false if [56, 60, 62].include?(i.product)
    return true
  end

  def master
    puts "finding REFERAL".colorize(:red)
    r = Ref.find(referal: self.id)
    if !r.nil?
      Client[r.client]
    else
      false
    end
  end

  def referals
    Ref.where(client: self.id)
  end

  def make_referal_link(b)
    encoded = Base64.encode64("#{self.tele}")
    "https://t.me/#{b.full_nick}?start=#{encoded}"
  end

  def self.authenticate(c, u)
    begin
      Client.find_or_create(
          tele: c,
          username: u,
          country: Country.find(code: 'UA').id
      )
    rescue
      false
    end
  end

  begin
    auth = Client.find_or_create(
        tele: c,
        username: u,
        bot: b.id
    )
    auth
    auth.country = Country.find(code: 'UA')
    auth.save
  rescue
    false
  end

  def my_token
    Team.find(client: self.id, bot: self.bot).token || 'токен неизвестен'
  end

  def token(bot)
    Team.find(client: self.id, bot: bot.id, role: Client::HB_ROLE_ADMIN) || 'токен неизвестен'
  end

  def bonuses
    Ledger.where(credit: self.id, debit: Client::__gifts.id)
  end

  def self.__tsx
    Client.find(username: 'TSX_root')
  end

  def self.__ads
    Client.find(username: '__ads')
  end

  def self.__refunds
    Client.find(username: '__refunds')
  end

  def self.__debt
    Client.find(username: '__debt')
  end

  def self.__tokenbar
    Client.find(username: '__tokenbar')
  end

  def self.__escrow
    Client.find(username: '__escrow')
  end

  def self.__gifts
    Client.find(username: '__gifts')
  end

  def self.__referals
    Client.find(username: '__referals')
  end

  def self.__salary
    Client.find(username: '__kladmans')
  end

  def self.__other
    Client.find(username: '__other')
  end

  def self.__purchase
    Client.find(username: '__purchase')
  end

  def self.__bonus
    Client.find(username: '__bonus')
  end

  def self.__cash
    Client.find(username: '__cash')
  end

  def self.__renta
    Client.find(username: '__renta')
  end

  def self.__commission
    Client.find(username: '__commission')
  end

  def self.__easypay
    Client.find(username: '__easypay')
  end

  def self.__btce
    Client.find(username: '__btce')
  end

  def self.__qiwi
    Client.find(username: '__qiwi')
  end

  def self.__tsc
    Client.find(username: '__tsc')
  end

  def self.__exmo
    Client.find(username: '__exmo')
  end

  def self.__livecoin
    Client.find(username: '__livecoin')
  end

  def self.__nix
    Client.find(username: '__nix')
  end

  def self.__wex
    Client.find(username: '__wex')
  end

  def self.__cashout
    Client.find(username: '__cashout')
  end

  def cashin(amount, dc, payment_method = nil, operator = nil, details = nil)
    begin
      Ledger.
        create(
          debit: dc.id,
          credit: self.id,
          amount: amount,
          meth: payment_method.nil? ? nil : payment_method.id,
          details: details.nil? ? "Пополнение счета #{self.username}" : details,
          status: Ledger::ACTIVE,
          created: Time.now,
          operator: operator.id
        )
    rescue
        return false
    end
  end

  def kladman_get_paid(it)
    bot = Bot[self.bot]
    if bot.web_klad == 1
      Ledger.
        create(
          debit: bot.beneficiary.id,
          credit: Client::__kladmans.id,
          amount: uah2cents(bot.klad_price),
          details: "Зарплата кладчикам",
          status: Ledger::ACTIVE,
          created: Time.now,
          operator: Client::__tsx.id,
          item: it.id
        )
      Ledger.
        create(
          debit: Client::__kladmans.id,
          credit: self.id,
          amount: uah2cents(bot.klad_price),
          details: "За клад ##{it.id}",
          status: Ledger::ACTIVE,
          created: Time.now,
          operator: Client::__tsx.id,
          item: it.id
        )
    end
  end

  def trades_avg_amount
    am = self.buy_trades([Trade::FINISHED, Trade::FINALIZED]).sum(:amount)
    cnt = self.buy_trades([Trade::FINISHED, Trade::FINALIZED]).count
    if am.nil? or am == 0
      0
    else
      (am/cnt).round
    end
  end

  def can_try?
    puts "#{self.next_try}".colorize(:red)
    puts "#{Time.now}".colorize(:red)
    if self.next_try
      if self.next_try < Time.now
        return true
      end
    end
    false
  end

  def allow_try
    self.next_try = nil
    self.save
  end

  def set_next_try(bot)
    self.next_try = Time.now + (bot.retry_period).minute
    self.save
  end

  def next_try_in
    if self.next_try.nil?
      0
    else
      ((Time.now - self.next_try)/60).round.abs
    end
  end

  def pay_for_trade(trade, meth = nil)
    it = Item[trade.item]
    b = Bot[it.bot]
    ben = b.beneficiary
    Ledger.
      create(
        debit: self.id,
        credit: ben.id,
        trade: trade.id,
        amount: it.price,
        meth: meth.nil? ? nil : meth.id,
        details: "Клад ##{it.id} оплачен. Заказ ##{trade.id}.",
        status: Ledger::ACTIVE,
        created: Time.now,
        operator: Client::__tsx.id
      )
    Ledger.
      create(
        debit: ben.id,
        credit: Client::__commission.id,
        trade: trade.id,
        amount: calc_commission(it.price, b.commission),
        details: "Комиссионные платформы. Заказ ##{it.id},  клад ##{it.id}.",
        status: Ledger::ACTIVE,
        created: Time.now,
        operator: Client::__tsx.id
      )
    # Ledger.
    #   create(
    #     debit: ben.id,
    #     credit: Client::__bonus.id,
    #     trade: trade.id,
    #     amount: uah2cents(b.bonus),
    #     details: "Бонусы за заказ на внутренний счет.",
    #     status: Ledger::ACTIVE,
    #     created: Time.now,
    #     operator: Client::__tsx.id
    #   )
    # Ledger.
    #   create(
    #     debit: Client::__bonus.id,
    #     credit: self.id,
    #     trade: trade.id,
    #     amount: uah2cents(b.bonus),
    #     details: "Бонус за заказ. Заказ ##{it.id},  клад ##{it.id}.",
    #     status: Ledger::ACTIVE,
    #     created: Time.now,
    #     operator: Client::__tsx.id
    #   )
    mst = self.master
    if mst.is_a?(Client)
      pr = Price[it.prc]
      ref_amount = ((pr.price.to_f * b.get_var('ref_rate').to_f)/100).round
      Ledger.
        create(
          debit: ben.id,
          credit: Client::__referals.id,
          trade: trade.id,
          amount: ref_amount,
          details: "Реферальные отчисления за клад ##{it.id}",
          status: Ledger::ACTIVE,
          created: Time.now,
          operator: Client::__tsx.id
        )
      Ledger.
        create(
          debit: Client::__referals.id,
          credit: mst.id,
          trade: trade.id,
          amount: ref_amount,
          details: "Реферальные за покупку @#{self.username} на сумму ##{b.amo(pr.price)}.",
          status: Ledger::ACTIVE,
          created: Time.now,
          operator: Client::__tsx.id
        )
      rec("bot", Client::__referals, b, "Реферальные выплачены клиенту #{mst.id}", b.amo(ref_amount))
    end
  end


  def avatar_url
    client_bot = Bot[self.bot]
    if client_bot.avatar.nil?
      puts "AVA"
      puts self.bot
      bot = Telegram::Bot::Client.new(client_bot.token)
      user_profile = bot.api.get_user_profile_photos(user_id: self.tele)
      file_id = user_profile.dig('result','photos',0,0,'file_id')
      file = bot.api.get_file(file_id: file_id)
      file_path = file.dig('result', 'file_path')
      photo_url = "https://api.telegram.org/file/bot#{client_bot.token}/#{file_path}"
      uploaded = Cloudinary::Uploader.upload(photo_url)
      client_bot.avatar = uploaded['url']
      client_bot.save
    end
  end

  def self.search_by_filters(current_filter, tsx_bot, dist = false)
    case current_filter.class.name.downcase
      when 'product'
        items = Client::availabla_products(current_filter, tsx_bot)
      when 'country'
        items = Client::cities_by_country(current_filter, tsx_bot)
      when 'city'
        items = Client::districts_by_city(current_filter, tsx_bot)
      when 'district'
        items = Client::products_by_district(current_filter, tsx_bot)
    end
    items
  end

  def self.search_by_filters_product(current_filter, tsx_bot, city = false)
    case current_filter.class.name.downcase
      when 'product'
        items = Client::districts_by_product(current_filter, tsx_bot, city)
      when 'country'
        items = Client::cities_by_country(current_filter, tsx_bot)
      when 'city'
        items = Client::products_by_city(current_filter, tsx_bot)
      when 'district'
        items = Client::products_by_district(current_filter, tsx_bot)
    end
    items
  end

  def self.new_item_by_filters(current_filter)
    case current_filter.class.name.downcase
      when 'country'
        items = Country.all
      when 'city'
        items = City::all_cities_by_country(current_filter)
      when 'district'
        items = Product.available
    end
    items
  end

  def self.cities_by_country(country, tsx_bot)
    cities = City.select(Sequel.as(:city__id, :entity_id), Sequel.as(:city__russian, :entity_russian)).
      distinct(:city).
      join(:item, item__city: :city__id).
      join(:country, :country__id => :city__country).
      where(
        item__bot: tsx_bot,
        country__russian: country.russian,
        item__status: Item::ACTIVE
      )
      # exclude(:item__client => client.id)
    cities
  end

  def self.districts_by_product(product, tsx_bot, city)
    dists = District.select(Sequel.as(:district__id, :entity_id), Sequel.as(:district__russian, :entity_russian)).
        distinct(:district).
        join(:item, item__district: :district__id).
        where(
            item__bot: tsx_bot,
            item__product: product.id,
            item__status: Item::ACTIVE,
            item__city: city.id
        )
    dists
  end


  def self.all_cities_by_country(country)
    cities = City.
        distinct(:city).
        join(:item, item__city: :city__id).
        where(
            city__country: country.id,
            item__status: Item::ACTIVE
        )
    cities
  end

  def credited
    credit = Ledger.dataset.
        select{Sequel.as(Sequel.expr{COALESCE(sum(:ledger__amount), 0)}, :credit)}.
        where(credit: self.id)
    credit.map(:credit)[0]
  end

  def debited
    credit = Ledger.dataset.
        select{Sequel.as(Sequel.expr{COALESCE(sum(:ledger__amount), 0)}, :debit)}.
        where(debit: self.id)
    credit.map(:debit)[0]
  end

  def self.districts_by_city(city, tsx_bot)
    dists = District.
        distinct(:district).
        join(:item, item__district: :district__id).
        where(
            item__bot: tsx_bot,
            district__city: city.id,
            item__status: Item::ACTIVE
        )
        # exclude(:item__client => client.id)
    dists
  end

  def self.products_by_district(district, tsx_bot)
    prods = Product.select(Sequel.as(:product__id, :entity_id), Sequel.as(:product__russian, :entity_russian), Sequel.as(:product__icon, :entity_icon)).
        distinct(:product).
        join(:item, item__product: :product__id).
        where(
            item__bot: tsx_bot,
            item__district: district.id,
            item__status: Item::ACTIVE
        )
        # exclude(:item__client => client.id)
    prods
  end

  def self.products_by_district_sold(district, tsx_bot)
    prods = Product.select(Sequel.as(:product__id, :entity_id), Sequel.as(:product__russian, :entity_russian), Sequel.as(:product__icon, :entity_icon)).
        distinct(:product).
        join(:item, item__product: :product__id).
        where(
            item__bot: tsx_bot,
            item__district: district.id,
            item__status: Item::SOLD
        )
    # exclude(:item__client => client.id)
    prods
  end

  def self.districts_by_city_and_product(product, tsx_bot, city)
    dists = District.select(Sequel.as(:district__id, :entity_id), Sequel.as(:district__russian, :entity_russian)).
        distinct(:district).
        join(:item, item__district: :district__id).
        where(
            item__bot: tsx_bot,
            item__product: product.id,
            item__status: Item::ACTIVE,
            item__city: city.id
        )
    dists
  end

  def self.products_by_city(city, tsx_bot)
    prods = Product.select(Sequel.as(:product__id, :entity_id), Sequel.as(:product__russian, :entity_russian), Sequel.as(:product__icon, :entity_icon)).
        distinct(:product).
        join(:item, item__product: :product__id).
        join(:city, city__id: :item__city).
        where(
            item__bot: tsx_bot,
            city__russian: city.russian,
            item__status: Item::ACTIVE
        )
    # exclude(:item__client => client.id)
    prods
  end


  def self.items_by_product(product, tsx_bot, dist)
    items = Item.where(
        bot: tsx_bot,
        product: product.id,
        district: dist.id,
        item__status: Item::ACTIVE
    ).exclude(item__prc: nil)
        # exclude(:item__client => client.id)
    items
  end

  def self.items_by_the_district(tsx_bot, product, dist)
    items = Item.
      where(
        bot: tsx_bot,
        product: product.id,
        :item__district=> dist.id,
        item__status: Item::ACTIVE
    ).exclude(item__prc: nil)
    # exclude(:item__client => client.id)
    items
  end

  def is_tokenbar?
    true
  end

  def can_cashout?
    false
  end

  def self.items_by_the_district_web(tsx_bot, product, dist)
    items = Item.
        select(Sequel.as(:item__id, :id)).
        join(:district, :district__id => :item__district).
        where(
            bot: tsx_bot,
            product: product.id,
            :district__russian => dist.russian,
            item__status: Item::ACTIVE
        ).exclude(item__prc: nil)
    # exclude(:item__client => client.id)
    items
  end


  def escrow_helper
    status = self.escrow > 0 ? "#{icon('key')} *#{self.escrow} мин.*" : "#{icon('no_entry_sign')} *без страховки*"
    button = self.escrow > 0 ? "Запретить страхование" : "Разрешить страхование"
    action = self.escrow > 0 ? "my_escrow_off" : "my_escrow_on"
    {status: status, button: button, action: action}
  end

  def my_products
    Item.distinct(:product).where(client: self.id, status: Item::ACTIVE)
  end

  def my_cities
    Item.distinct(:city).where(client: self.id, status: Item::ACTIVE)
  end

  def my_cities_by_product(prod)
    Item.where(client: self.id, product: prod.id, status: Item::ACTIVE)
  end

  def my_districts
    Item.distinct(:district).where(client: self.id, status: Item::ACTIVE)
  end

  def my_districts_by_city(city)
    District.join(:item, item__district: :district__id).
        where(item__city: city.id, item__client: self.id)
  end

  def my_items_by_product_district(product, district)
    Item.where(product: product.id, district: district.id, status: Item::ACTIVE)
  end

  def items_by_district(district)
    Item.where(district: district.id, client: self.id, status: Item::ACTIVE)
  end

  def items_by_city(city)
    Item.where(city: city.id, client: self.id, status: Item::ACTIVE)
  end

  def items_by(product)
    Item.where(product: product.id, client: self.id)
  end

  def my_all_items
    Item.where(client: self.id, status: Item::ACTIVE)
  end

  def sold_items
    Item.where(client: self.id, status: Item::SOLD)
  end

  def active_items
    Item.where(client: self.id, status: Item::ACTIVE)
  end

  def all_items
    Item.where(client: self.id)
  end

  def easypay_total
    Ledger.where(
        ledger__debit: Client::__easypay.id,
        ledger__credit: self.id,
        status: Ledger::CLEARED
    ).sum(:amount)
  end

  def wex_total
    Ledger.where(
        ledger__credit: Client::__easypay.id,
        ledger__debit: self.id,
        status: Ledger::CLEARED
    ).sum(:amount)
  end

  def commission_total
    Ledger.where(
        ledger__credit: Client::__commission.id,
        ledger__debit: self.id
    ).sum(:amount)
  end

  def escrow_total
    Ledger.where(
        ledger__credit: Client::__escrow.id,
        ledger__debit: self.id
    ).sum(:amount)
  end


  def salary_total
    Ledger.where(
        ledger__credit: Client::__salary.id,
        ledger__debit: self.id,
        status: Ledger::CLEARED
    ).sum(:amount)
  end

  def other_total
    Ledger.where(
        ledger__credit: Client::__other.id,
        ledger__debit: self.id,
        status: Ledger::CLEARED
    ).sum(:amount)
  end

  def cashout_total
    Ledger.where(
        ledger__credit: Client::__cashout.id,
        ledger__debit: self.id
    ).sum(:amount)
  end

  def purchase_total
    Ledger.where(
        ledger__credit: Client::__purchase.id,
        ledger__debit: self.id,
        status: Ledger::CLEARED
    ).sum(:amount)
  end

  def spendings
    Ledger.
        where("ledger.credit = ? and trade is ?", self.id, nil).sum(:amount)
  end

  def earnings
    Ledger.
      where("ledger.debit = ? and trade is ?", self.id, nil).sum(:amount)
  end

  def statement2(bot)
    DB.fetch("select * from ledger where credit in (select id from client where bot = #{bot.id}) or debit in (select id from client where bot = #{bot.id}) order by ledger.created desc")
  end

  def statement
    Ledger.
        where("ledger.debit = ? or ledger.credit = ?", self.id, self.id).
        order(Sequel.desc(:id), Sequel.desc(:created))
  end

  def internal_statement
    Ledger.
        where("ledger.debit = ? or ledger.credit = ? and internal = 1", self.id, self.id).
        order(Sequel.desc(:id), Sequel.desc(:created))
  end

  def me? client
    self.id == client.id
  end
  alias_method :is?, :me?

  def has_funds?
    self.available_cash > 0
  end

  def system?
    self.role == Client::HB_ROLE_SYSTEM
  end

  def bot?
    self.role == Client::HB_ROLE_BOT
  end

  def allowed?
    self.available_cash > 300
  end

  def active?
    self.available_cash > 0
  end

  def actions
    Ledger.where('ledger.debit = ? and task is not ?', self.id, nil)
  end

  def enough_funds? amount
    balance = self.available_cash
    return false if balance.nil?
    return false if balance < amount
  end

  def can_finalize? trade
    Time.now > trade.escrow_finish
  end

  def sales
    Trade.
      join(:item, trade__item: :item__id).
      where(trade__seller: self.id, trade__status: Trade::FINALIZED)
  end

  def client_referals
    Ref.select(:referal).where(client: self.id).count || 0
  end

  def ref_sales
    credit = Ledger.dataset.
        select{Sequel.as(Sequel.expr{COALESCE(count(:ledger__id), 0)}, :bns)}.
        where(credit: self.id, debit: Client::__referals.id)
    credit.map(:bns)[0]
  end

  def ref_cash
    credit = Ledger.dataset.
        select{Sequel.as(Sequel.expr{COALESCE(sum(:ledger__amount), 0)}, :bns)}.
        where(credit: self.id, debit: Client::__referals.id)
    credit.map(:bns)[0]
  end


  def bonuses_cash
    credit = Ledger.dataset.
      select{Sequel.as(Sequel.expr{COALESCE(sum(:ledger__amount), 0)}, :bns)}.
      where(credit: self.id, debit: Client::__gifts.id)
    credit.map(:bns)[0]
  end

  def available_cash
    debit = Ledger.dataset.
      select{Sequel.as(Sequel.expr{COALESCE(sum(:ledger__amount), 0)}, :debit)}.
      where(debit: self.id)
    credit = Ledger.dataset.
        select{Sequel.as(Sequel.expr{COALESCE(sum(:ledger__amount), 0)}, :credit)}.
        where(credit: self.id)
    # credit.map(:credit)[0] - debit.map(:debit)[0] + self.ref_cash
    credit.map(:credit)[0] - debit.map(:debit)[0]
  end

  def bonus_cash
    credit = Ledger.dataset.
      select{Sequel.as(Sequel.expr{COALESCE(sum(:ledger__amount), 0)}, :bns)}.
      where(credit: self.id, debit: Client::__bonus.id)
    credit.map(:bns)[0]
  end

  def locked_cash
    locked = Ledger.dataset.
      select{Sequel.as(Sequel.expr{COALESCE(sum(:ledger__amount), 0)}, :locked)}.
      where(credit: Client::__escrow.id, debit: self.id)
    unlocked = Ledger.dataset.
      select{Sequel.as(Sequel.expr{COALESCE(sum(:ledger__amount), 0)}, :unlocked)}.
      where(debit: Client::__escrow.id, credit: self.id)
    locked.map(:locked)[0] - unlocked.map(:unlocked)[0]
  end

  def not_paid_cash
    credit = Ledger.dataset.
        select{Sequel.as(Sequel.expr{COALESCE(sum(:ledger__amount), 0)}, :credit)}.
        where(status: Ledger::ACTIVE, credit: self.id)
    credit.map(:credit)[0]
  end

  def paid_cash
    credit = Ledger.dataset.
        select{Sequel.as(Sequel.expr{COALESCE(sum(:ledger__amount), 0)}, :credit)}.
        where(status: Ledger::CLEARED, credit: self.id)
    credit.map(:credit)[0]
  end


  def expired_trade
    Trade.
        find('buyer = ? and status = ? and created < ?', self.id, Trade::PENDING, Time.now - 10.minute)
  end

  def buy_trades(status)
    cli = self.id
    ts = Item.dataset.
      select(:trade__id___trade).
      select_append(Sequel.lit('item.*')).
      join(:trade, {trade__item: :item__id}).
      where(buyer: cli).
      order(Sequel.desc(:trade__id))
    ts.where(trade__status: status)
  end

  def sell_trades(status)
    cli = self.id
    ts = Item.dataset.
        select(:trade__id___trade).
        select_append(Sequel.lit('item.*')).
        join(:trade, {trade__item: :item__id}).
        where(seller: cli).
        order(Sequel.desc(:trade__id))
    ts.where(trade__status: status)
  end

  def my_trades(status)
    cli = self.id
    ts = Item.dataset.
        select(:trade__id___trade).
        select_append(Sequel.lit('item.*')).
        join(:trade, {trade__item: :item__id}).
        where(seller: cli).
        or(buyer: cli)
    ts.where(trade__status: status)
  end

  def rank_seller(trade, rank)
    Rank.create(trade: trade.id, rank: rank, seller: self.id, buyer: trade.buyer)
  end

  def has_not_ranked_trade?(bot)
    Trade.find(buyer: self.id, status: Trade::FINALIZED, bot: bot.id)
  end

  def has_pending_trade?(bot)
    Trade.find(buyer: self.id, status: Trade::PENDING, bot: bot.id)
  end

  def shop?
    is = Team.find(client: self.id, role: Client::HB_ROLE_SELLER)
    if !is.nil?
      sh = Bot[is.bot]
    else
      false
    end
  end

  def is_beneficiary?(bot)
    is = Team.find(client: self.id, role: Client::HB_ROLE_SELLER, bot: bot.id)
    if !is.nil?
      Bot[is.bot]
    else
      false
    end
  end

  def user?
    self.role == Client::HB_ROLE_USER
  end

  def is_admin?(bot)
    is = Team.find(client: self.id, role: Client::HB_ROLE_ADMIN, bot: bot.id)
    if !is.nil?
      Bot[is.bot]
    else
      false
    end
  end

  def is_support?(bot)
    is = Team.find(client: self.id, role: Client::HB_ROLE_SUPPORT, bot: bot.id)
    if !is.nil?
      Bot[is.bot]
    else
      false
    end
  end

  def is_kladman?(bot)
    is = Team.find(client: self.id, role: Client::HB_ROLE_KLADMAN, bot: bot.id)
    if !is.nil?
      Bot[is.bot]
    else
      false
    end
  end

  def is_operator?(bot)
    is = Team.find(client: self.id, role: Client::HB_ROLE_OPERATOR, bot: bot.id)
    if !is.nil?
      Bot[is.bot]
    else
      false
    end
  end

  def readable_role(bot)
    team = Team.find(bot: bot.id, client: self.id, role: [Client::HB_ROLE_OPERATOR, Client::HB_ROLE_KLADMAN, Client::HB_ROLE_SYSTEM, Client::HB_ROLE_ADMIN, Client::HB_ROLE_SELLER, Client::HB_ROLE_USER])
    if team.nil?
      false
    else
      t("roles.#{team.role}")
    end
  end

end