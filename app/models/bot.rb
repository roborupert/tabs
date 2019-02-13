class Bot < Sequel::Model(:bot)
  include TSX::Billing
  include TSX::Currency
  include TSX::Context

  ACTIVE = 1
  INACTIVE = 0

  KIND_FULL = 1
  KIND_AUTOSHOP = 0
  KIND_SHIPMENT = 2

  SERP_CITY_FIRST = 0
  SERP_PRODUCT_FIRST = 1

  def self.chief
    Bot.find(tele: 'AMG67')
  end

  def self.escrow
    Bot.find(tele: 'TheAutobotEscrow')
  end

  def tell_owners (bot, text, buttons)
    rcpts = self.operators << self.beneficiary
    rcpts.each do |op|
      bot.api.send_message(
        chat_id: op.tele,
        text: text,
        parse_mode: :markdown,
        reply_markup: Telegram::Bot::Types::ReplyKeyboardMarkup.new(
          keyboard: [buttons],
          resize_keyboard: true
        )
      )
    end
  end

  def abuses
    Abuse.where(bot: self.id)
  end

  def create_wallet(client)
    # begin
    #   result = Faraday.get("https://block.io/api/v2/get_new_address/?api_key=#{BLOCKIO_KEY}").body
    #   puts result.colorize(:red)
    #   # wallet_label = "__wallet_#{self.tele}_#{client.id}"
    #   # puts "WALLET LABEL: #{wallet_label}".colorize(:red)
    #   # addr = BlockIo.get_new_address(:label => wallet_label)
    # rescue Exception => ex
    #   puts "WALLET WITH THIS LABEL EXISTS".colorize(:red)
    #   puts ex.backtrace.join("\n\t")
    #   addr = BlockIo.get_address_by_label(label: wallet_label)
    # end
    # begin
    #   wallet_label_system = "__wallet_#{self.tele}_#{client.id}_system"
    #   addr_system = BlockIo.get_new_address(:label => wallet_label_system)
    # rescue Exception => ex1
    #   addr_system = BlockIo.get_address_by_label(label: wallet_label_system)
    # end
    # wallet = Wallet.find(bot: self.id)
    # if wallet.nil?
    #   wallet = Wallet.create(
    #     bot: self.id,
    #     client: Client[permited.client].id,
    #     label: wallet_label,
    #     address: addr['data']['address'],
    #     system_address: addr_system['data']['address'],
    #     meth: Meth::__bitcoin.id,
    #     status: Wallet::ACTIVE
    #   )
    # end
    # wallet
  end

  def issue_wex(amount)
    api = Btce::TradeAPI.new(
        {
            url: "https://wex.nz/tapi",
            key: self.payment_option('key', Meth::__tokenbar),
            secret: self.payment_option('secret', Meth::__tokenbar),
        }
    )
    return api.trade_api_call(
        'CreateCoupon',
        currency: 'USD',
        amount: amount
    ).to_hash
  end

  def accept_wex(wex_usd)
    api = Btce::TradeAPI.new(
      {
        url: "https://wex.nz/tapi",
        key: self.payment_option('key', Meth::__tokenbar),
        secret: self.payment_option('secret', Meth::__tokenbar),
      }
    )
    puts api.inspect.black.on.white
    res = api.trade_api_call('RedeemCoupon', coupon: wex_usd).to_hash
    puts res.inspect.green
  end

  def set_var(var_name, value)
    vars = Vars.find_or_create(bot: self.id)
    vars[var_name.to_sym] = value
    vars.save
  end

  def get_var(var_name)
    vars = Vars.find(bot: self.id)
    vars[var_name.to_sym]
  end

  def cities_first?
    self.serp_type == Bot::SERP_CITY_FIRST
  end

  def products
    Price.distinct(:product).where(bot: self.id)
  end

  def products_by_city(c)
    prods = Product.select(Sequel.as(:product__id, :entity_id), Sequel.as(:product__russian, :entity_russian), Sequel.as(:product__icon, :entity_icon)).
        distinct(:product).
        join(:item, item__product: :product__id).
        join(:city, city__id: :item__city).
        where(
            item__bot: self.id,
            city__russian: c.russian,
            item__status: Item::ACTIVE
        )
    prods
  end

  def cities_list
    cities = City.
        distinct(:city).
        select(Sequel.as(:city__id, :cid), Sequel.as(:city__russian, :rus), Sequel.as(:item__bot, :bot_id)).
        join(:item, item__city: :city__id).
        where(
            :item__bot => self.id,
            item__status: Item::ACTIVE
        )
    cities
  end

  def cities
    ccts = ''
    cities = City.
        distinct(:city).
        select(Sequel.as(:city__id, :cid), Sequel.as(:city__russian, :rus), Sequel.as(:item__bot, :bot_id)).
        join(:item, item__city: :city__id).
        where(
            :item__bot => self.id,
            item__status: Item::ACTIVE
        )
    if !cities.empty?
      cities.each do |c|
        ccts << c[:rus].truncate(2, omission: '') + ", "
      end
      ccts.chomp(", ").truncate(15)
    else
      false
    end
  end

  def cities_full
    ccts = ''
    cities = City.
        distinct(:city).
        select(Sequel.as(:city__id, :cid), Sequel.as(:city__russian, :rus), Sequel.as(:item__bot, :bot_id)).
        join(:item, item__city: :city__id).
        where(
            :item__bot => self.id,
            item__status: Item::ACTIVE
        )
    if !cities.empty?
      cities.each do |c|
        ccts << "<a href='/s/#{self.tele}/city/#{c[:rus]}'>#{c[:rus]}</a> "
      end
      ccts.chomp(", ")
    else
      false
    end
  end

  def support_line(web = nil)
    line = ''
    if !self.support.nil?
      if self.support.split(',').empty?
        line = self.support
      else
        self.support.split(',').each do |sup|
          if web.nil?
            line << "[@#{sup}](t.me/#{sup}), "
          else
            line << "<a href='#{sup}'>http://t.me/#{sup}</a>, "
          end
        end
      end
      line.chomp!(', ')
    else
      line = "[@no_nickname](t.me/no_nickname), "
    end
    line
  end

  def pick_one_game
    p = Gameplay.
        select(Sequel.as(:game__id, :game_id)).
        join(:plugin, :plugin__id => :game__plugin).
        where(:game__bot => self.id, :game__status => Gameplay::ACTIVE).
        exclude('plugin.job is NOT NULL').
        order(Sequel.desc(:game__last_run)).last
    Gameplay[p[:game_id]].update(last_run: Time.now)
    return p
  end

  def cities_full_clear
    ccts = ''
    cities = City.
        distinct(:city).
        select(Sequel.as(:city__id, :cid), Sequel.as(:city__russian, :rus), Sequel.as(:item__bot, :bot_id)).
        join(:item, item__city: :city__id).
        where(
            :item__bot => self.id,
            item__status: Item::ACTIVE
        )
    if !cities.empty?
      cities.each do |c|
        ccts << "#{c[:rus]}, "
      end
      ccts.chomp(", ")
    else
      false
    end
  end

  def payment_balance(meth)
    ben = self.beneficiary
    Ledger.
        join(
            :client, client__id: :ledger__credit
        ).where(
        ledger__debit: meth.client,
        client__bot: self.id
    ).sum(:amount)
  end

  def notify_admins(bot, text)
    rcpts = self.admins
    rcpts.each do |op|
      begin
        bot.api.send_message(
          chat_id: Client[op].tele,
          text: text
        )
      rescue => ex
        puts ex.message
      end
    end
  end

  def system_clients
    Client.where(role: Client::HB_ROLE_SYSTEM)
  end

  def inactive?
    self.status == Bot::INACTIVE
  end

  def active?
    self.status ==  Bot::ACTIVE
  end

  def has_dispute?
    disp = Abuse.
        select(:dispute__id, :dispute__status, :dispute__trade).
        join(:client, client__id: :dispute__client).
        where(client__bot: self.id)
    if disp.nil?
      false
    else
      disp
    end
  end

  def sales_by_product(product)
    puts product.inspect
    i = 1
    prod = []
    while i < Date.today.end_of_month.day
      day = Date.new(Date.today.year, Date.today.month, i)
      sales = Trade.
          join(:item, item__id: :trade__item).
          where(item__bot: self.id, item__product: product[:prod]).
          filter(closed: day..day + 1.day).
          count(:trade__id).to_i
      prod << sales
      i += 1
    end
    prod
  end

  def sales_by_date(dat, products)
    res = []
    puts products.inspect
    products.each do |p|
      res.push(p.russian)
      cnt = Trade.
          join(:item, item__id: :trade__item).
          where(item__bot: self.id, item__product: p[:prod]).
          filter(closed: dat.to_date..dat.to_date + 1.day).
          count(:trade__id).to_i
      res.push(cnt)
    end
    res
  end

  def disputed
    Abuse.select(:dispute__id, :dispute__status, :dispute__trade).join(:trade, trade__id: :dispute__trade).where(bot: self.id)
  end

  def new_disputes
    Abuse.
        join(:client, client__id: :dispute__client).where(client__bot: self.id, dispute__status: Abuse::NEW).count(:dispute__id)
  end

  def beneficiary
    f = Team.find(bot: self.id, role: Client::HB_ROLE_SELLER)
    if f.nil?
      false
    else
      Client[f.client]
    end
  end

  def is_infobot?
    self.tele == 'DarksideNotes'
  end

  def is_chief?
    ["TheAutoTest", "TheAuto", "AMG67"].include?(self.tele)
  end

  def operators
    d = []
    Team.where(bot: self.id, role: Client::HB_ROLE_OPERATOR).each do |c|
      d << c.client
    end
    d
  end

  def admins
    d = []
    Team.where(bot: self.id, role: Client::HB_ROLE_ADMIN).each do |c|
      d << c.client
    end
    d
  end

  def bot_clients
    Client.where(bot: self.id)
  end

  def clients
    Client.where(id: self.operators).order(Sequel.desc(:created))
  end

  def chief_sellers
    by_bot ||= []
    Bot.exclude(tele: ["TSX", "TSXtest"]).where(status: Bot::ACTIVE).order(:id).all.each do |b|
      by_bot << b.id
    end
    by_bot
  end

  def all_dates
    ben = self.beneficiary
    Ledger.dataset.
      select(Sequel.as(Sequel.function(:to_char, :ledger__created, 'YYYY-mm-dd'), :dat)).
      where("ledger.debit = ? or ledger.credit = ?", ben.id, ben.id).
      order(Sequel.desc(:ledger__created)).
      all.
      uniq
  end

  def all_monthes
    ben = self.beneficiary
    Ledger.dataset.
        select(Sequel.as(Sequel.function(:to_char, :ledger__created, 'YYYY-mm-dd'), :dat)).
        where("ledger.debit = ? or ledger.credit = ?", ben.id, ben.id).
        order(Sequel.desc(:ledger__created)).
        all.
        uniq
  end

  def nickname(trunc = 15)
    finish_name = (self.underscored_name == 1 ? '_bot' : 'bot')
    "<a class='blue normal' href='https://t.me/#{self.tele}#{finish_name}'>@#{(self.tele + finish_name)}</a>"
  end

  def pure_nickname
    finish_name = (self.underscored_name == 1 ? '_bot' : 'bot')
    "@#{(self.tele + finish_name)}"
  end

  def link_no_title
    finish_name = (self.underscored_name == 1 ? '_bot' : 'bot')
    "<a class='bold' href='https://t.me/#{self.tele}#{finish_name}'>Бот</a>"
  end

  def nickname_md(trunc = 20)
    finish_name = (self.underscored_name == 1 ? '_bot' : 'bot')
    "[#{(self.title).truncate(trunc)}](https://t.me/#{self.tele}#{finish_name})"
  end


  def statement
    ben = self.beneficiary
    Ledger.
      where("ledger.debit = ? or ledger.credit = ?", ben.id, ben.id).
      order(Sequel.desc(:id), Sequel.desc(:created))
  end

  def today_income(dat)
    ben = self.beneficiary
    Ledger.
      where(ledger__credit: ben.id, created: (dat)..(dat + 1)).sum(:amount)
  end

  def system_client(cli)
    debit = DB.fetch("select sum(amount) as debit from ledger where credit in (select id from client where bot = #{self.id}) and debit = #{cli.id}")
    credit = DB.fetch("select sum(amount) as credit from ledger where debit in (select id from client where bot = #{self.id}) and credit = #{cli.id}")
    puts debit.inspect.colorize(:red)
    [debit.first[:debit], credit.first[:credit]]
  end


  def income
    ben = self.beneficiary
    Ledger.
        where(ledger__credit: ben.id).sum(:amount)
  end

  def sales
    Trade.where(bot: self.id).count(:id)
  end

  def all_items
    Item.where(bot: self.id).exclude(status: [Item::ESCROW_INACTIVE, Item::ESCROW_ACTIVE, Item::ESCROW_PAUSED]).count(:id)
  end

  def escrows(status = nil)
    if status.nil?
      Escrow.where('seller = ? or buyer = ?', hb_operator.id, hb_operator.id)
    else
      Escrow.where('seller = ? or buyer = ? and status = ?', hb_operator.id, hb_operator.id, status.to_i)
    end
  end

  def custom_buttons
    ar = []
    bts = Button.where(bot: self.id).all
    if bts.count > 0
      bts.each do |b|
        ar << b.title
      end
      return ar
    end
    nil
  end

  def active_items
    Item.where(bot: self.id, status: Item::ACTIVE).count(:id)
  end

  def listed?
    self.listed == 1
  end

  def active_clients
    Client.where(bot: self.id).exclude(role: Client::HB_ROLE_ARCHIVED).count(:id)
  end

  def items
    Item.where(bot: self.id, status: Item::ACTIVE).count(:id)
  end

  def sold_items
    Item.where(bot: self.id, status: Item::SOLD).count(:id)
  end

  def reserved_items
    Item.where(bot: self.id, status: Item::RESERVED).count(:id)
  end

  def today_sales(dat)
    Trade.where(bot: self.id, status: [Trade::FINISHED, Trade::FINALIZED]).exclude(closed: dat..dat + 1.day).count(:id)
  end

  def sales_by_product_and_date(product, dat)
    prc = Price.find(product: product.id, bot: self.id)
    Trade.
        join(:item, :item__id => :trade__item).
        where(item__bot: self.id, trade__status: [Trade::FINISHED, Trade::FINALIZED], :item__prc => prc.id, :trade__closed => dat..dat + 1.day).
        count(:trade__id)
  end

  def sales_by_product_and_date_and_district(product, dat, dist)
    prc = Price.find(product: product.id, bot: self.id)
    Trade.
        join(:item, :item__id => :trade__item).
        where(item__bot: self.id, item__district: dist.id, trade__status: [Trade::FINISHED, Trade::FINALIZED], :item__prc => prc.id, :trade__closed => dat..dat + 1.day).
        count(:trade__id)
  end


  def amount_sales_by_product_and_date(product, dat)
    prc = Price.find(product: product.id, bot: self.id)
    r = Trade.
        select(Sequel.function("sum", :trade__amount)).
        join(:item, :item__id => :trade__item).
        where(item__bot: self.id, trade__status: [Trade::FINISHED, Trade::FINALIZED], :item__prc => prc.id, :trade__closed => dat..dat + 1.day)
    r[0][:sum].nil? ?  0 : r[0][:sum]
  end

  def amount_sales_by_product_and_date_and_district(product, dat, dist)
    prc = Price.find(product: product.id, bot: self.id)
    r = Trade.
        join(:item, :item__id => :trade__item).
        where(item__bot: self.id, item__district: dist.id, trade__status: [Trade::FINISHED, Trade::FINALIZED], :item__prc => prc.id, :trade__closed => dat..dat + 1.day).
        sum(:trade__amount)
    r.nil? ?  0 : r
  end


  def prod_qnts(prod)
    prices = Price.dataset.distinct(:price__id).where(product: prod.id, bot: self.id).map{|x| x.id}
    pcc = Item.dataset.select(Sequel.as( :item__prc, :prc_id)).where(:bot => self.id).map{|x| x[:prc_id]}
    puts (pcc & prices).inspect
    # [1285, 1286, 1287, 1288]
    # [1285, 1286, 1288, 1287]
    pcc & prices
  end

  def has_active_game?
    Gameplay.find(bot: self.id, status: Gameplay::ACTIVE).nil?
  end

  def active_game
    Gameplay.where(bot: self.id, status: Gameplay::ACTIVE).order(Sequel.asc(:last_run)).first
  end

  def active_games
    Gameplay.where(bot: self.id, status: Gameplay::ACTIVE)
  end

  def sales_amount_by_product_and_date_and_qnt(city, dat, pric)
    as = Trade.
        select(
            Sequel.as(:price__id, :prc_id),
            Sequel.as(:price__qnt, :qnt),
            Sequel.as(Sequel.function("sum", :trade__amount), :prcc),
            Sequel.as(Sequel.function("count", :price__id), :sales)
        ).
        join(:item, :item__id => :trade__item).
        join(:price, :price__id => :item__prc).
        where(
            :item__bot => self.id,
            :trade__status => [Trade::FINISHED, Trade::FINALIZED],
            :trade__closed => dat..dat + 1.day,
            :item__city => city.id,
            :item__prc => pric.id
        ).
        group(:price__id).
        order(Sequel.desc(:qnt))
    as.first || nil
  end

  def today_bot_sales(dat)
    Trade.where(bot: self.id, status: [Trade::FINISHED, Trade::FINALIZED], closed: dat..dat + 1.day).count(:id)
  end

  def today_easypay(dat)
    ben = self.beneficiary
    Ledger.
      join(
        :client, client__id: :ledger__credit
      ).where(
        ledger__debit: Client::__easypay.id,
        ledger__created: (dat)..(dat + 1),
        client__bot: ben.id
      ).sum(:amount)
  end

  def today_wex(dat)
    ben = self.beneficiary
    Ledger.
        join(
            :client, client__id: :ledger__credit
        ).where(
        ledger__debit: Client::__wex.id,
        ledger__created: (dat)..(dat + 1),
        client__bot: self.id
    ).sum(:amount)
  end

  def today_exmo(dat)
    ben = self.beneficiary
    Ledger.
        join(
            :client, client__id: :ledger__credit
        ).where(
        ledger__debit: Client::__exmo.id,
        ledger__created: (dat)..(dat + 1),
        client__bot: self.id
    ).sum(:amount)
  end

  def today_livecoin(dat)
    ben = self.beneficiary
    Ledger.
        join(
            :client, client__id: :ledger__credit
        ).where(
        ledger__debit: Client::__livecoin.id,
        ledger__created: (dat)..(dat + 1),
        client__bot: self.id
    ).sum(:amount)
  end

  def today_nix(dat)
    ben = self.beneficiary
    Ledger.
        join(
            :client, client__id: :ledger__credit
        ).where(
        ledger__debit: Client::__nix.id,
        ledger__created: (dat)..(dat + 1),
        client__bot: self.id
    ).sum(:amount)
  end

  def today_qiwi(dat)
    ben = self.beneficiary
    Ledger.
        join(
            :client, client__id: :ledger__credit
        ).where(
        ledger__debit: Client::__qiwi.id,
        ledger__created: (dat)..(dat + 1),
        client__bot: self.id
    ).sum(:amount)
  end


  def today_kladmans(dat)
    ben = self.beneficiary
    Ledger.where(
        ledger__credit: Client::__kladmans.id,
        ledger__debit: ben.id,
        created: (dat)..(dat + 1)
    ).sum(:amount)
  end

  def today_cashin(dat)
    ben = self.beneficiary
    Ledger.where(
      ledger__credit: Client::__refunds.id,
      ledger__debit: ben.id,
      created: (dat)..(dat + 1)
    ).sum(:amount)
  end

  def today_bonuses(dat)
    ben = self.beneficiary
    Ledger.where(
      ledger__credit: Client::__bonus.id,
      ledger__debit: ben.id,
      created: (dat)..(dat + 1)
    ).sum(:amount)
  end

  def today_refunds(dat)
    ben = self.beneficiary
    Ledger.where(
        ledger__debit: Client::__debt.id,
        ledger__credit: ben.id,
        created: (dat)..(dat + 1)
    ).sum(:amount)
  end

  def today_btce(dat)
    Ledger.
      join(
        :client, client__id: :ledger__credit
      ).where(
      ledger__debit: Client::__btce.id,
      ledger__created: (dat)..(dat + 1),
      client__bot: self.id
    ).sum(:amount)
  end

  def today_commission(dat)
    ben = self.beneficiary
    Ledger.where(
      ledger__credit: Client::__commission.id,
      ledger__debit: ben.id,
      created: (dat)..(dat + 1)
    ).sum(:amount)
  end


  def paid_total
    ben = self.beneficiary
    Ledger.where(
        ledger__credit: Client::__commission.id,
        ledger__debit: ben.id,
        status: Ledger::CLEARED
    ).sum(:amount)
  end

  def paid_renta
    ben = self.beneficiary
    Ledger.where(
      ledger__credit: Client::__renta.id,
      ledger__debit: ben.id,
      status: Ledger::CLEARED
    ).sum(:amount)
  end

  def has_shares?
    Bot.where(partner: self.id).count > 0
  end

  def not_paid
    ben = self.beneficiary
    Ledger.where(
      ledger__credit: Client::__commission.id,
      ledger__debit: ben.id,
      status: Ledger::ACTIVE
    ).sum(:amount) || 0
  end

  def clear
    ben = self.beneficiary
    Ledger.where(
      ledger__credit: Client::__commission.id,
      ledger__debit: ben.id,
      status: Ledger::ACTIVE
    ).update(status: Ledger::CLEARED)
  end

  def say(to_whom, body)
    begin
      bot = Telegram::Bot::Api.new(self.token)
      bot.send_message(
        chat_id: to_whom,
        text: body,
        parse_mode: :markdown,
        disable_web_page_preview: false
      )
    rescue => e
      puts "Telegram API: #{e.message}"
    end
  end

  def add_operator(cl, role)
    pass = Time.now.to_i.to_s
    hashids = Hashids.new(TOKEN_SALT, 40, TOKEN_ALPHABET)
    token = hashids.encode(self.id, pass, cl.id, role)
    cl = Team.create(
      bot: self.id,
      client: cl.id,
      role: role,
      password: pass,
      token: token
    )
    cl
  end

  def self.search_bots_web
    by_bot = []
    Bot.where(status: Bot::ACTIVE ).each do |b|
      by_bot << b.id
    end
    by_bot
  end


  def full_nick
    if self.underscored_name == 1
      "#{self.tele}_bot"
    else
      "#{self.tele}bot"
    end
  end

  def set_beneficiary(cl)
    Team.create(
      bot: self.id,
      client: cl.id,
      role: Client::HB_ROLE_SELLER
    )
  end

  def available_payments
    Payment.join(:meth, :meth__id => :payment__meth).where(bot: self.id, :payment__status => Payment::ACTIVE, :meth__status => Meth::METHOD_PUBLIC)
  end

  def icons
    DB.fetch("SELECT col.column_name, col_description(c.oid, col.ordinal_position) AS comment FROM information_schema.columns AS col LEFT JOIN pg_namespace ns ON ns.nspname = col.table_schema LEFT JOIN pg_class c ON col.table_name = c.relname AND c.relnamespace = ns.oid LEFT JOIN pg_attrdef a ON c.oid = a.adrelid AND col.ordinal_position = a.adnum LEFT JOIN pg_attribute b ON b.attrelid = c.oid AND b.attname = col.column_name LEFT JOIN pg_type et ON et.oid = b.atttypid LEFT JOIN pg_collation coll ON coll.oid = b.attcollation LEFT JOIN pg_type bt ON et.typelem = bt.oid LEFT JOIN pg_namespace nbt ON bt.typnamespace = nbt.oid WHERE col.table_schema = 'public' AND col.table_name = 'bot' and col.column_name like '%icon%' ORDER BY col.table_name, col.ordinal_position").all
  end

  def settings
    DB.fetch("SELECT col.column_name, col_description(c.oid, col.ordinal_position) AS comment FROM information_schema.columns AS col LEFT JOIN pg_namespace ns ON ns.nspname = col.table_schema LEFT JOIN pg_class c ON col.table_name = c.relname AND c.relnamespace = ns.oid LEFT JOIN pg_attrdef a ON c.oid = a.adrelid AND col.ordinal_position = a.adnum LEFT JOIN pg_attribute b ON b.attrelid = c.oid AND b.attname = col.column_name LEFT JOIN pg_type et ON et.oid = b.atttypid LEFT JOIN pg_collation coll ON coll.oid = b.attcollation LEFT JOIN pg_type bt ON et.typelem = bt.oid LEFT JOIN pg_namespace nbt ON bt.typnamespace = nbt.oid WHERE col.table_schema = 'public' AND col.table_name = 'bot' and col.column_name not like '%icon%'  ORDER BY col.table_name, col.ordinal_position").all
  end

  def mirrors
    Bot.where(master: self.id)
  end

  def opt(key, meth)
    pmt = Payment.find(bot: self.id, meth: meth.id)
    if !pmt.nil?
      params = JSON.parse(pmt.params)
      params[key]
    else
      false
    end
  end


end