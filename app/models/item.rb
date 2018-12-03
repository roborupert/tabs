require 'action_view/helpers'
require 'action_view/helpers/number_helper'
require 'action_view/helpers/date_helper'

class Item < Sequel::Model(:item)
  include TSX::Helpers
  include TSX::Elements
  include ActionView::Helpers::DateHelper

  OLD = 9
  FRESH = 1

  ACTIVE = 1
  INACTIVE = 0
  SOLD = 2
  RESERVED = 3
  REITEM = 4

  ESCROW_ACTIVE = 5
  ESCROW_INACTIVE = 6
  ESCROW_PAUSED = 7

  ESCROW_PAID_BY_SELLER = 0
  ESCROW_PAID_BY_BUYER = 1
  ESCROW_PAID_BY_EQUAL = 2

  SHIPMENT_MAIL = 0
  SHIPMENT_LOCATION = 1
  SHIPMENT_BOTH = 2

  def readable_shipment
    if !self.shipment.nil?
      t("escrow_shipment.#{self.shipment}")
    else
      ""
    end
  end

  def old?
    self.old == Item::OLD
  end

  def discount?
    old?
  end

  def price_string(currency, label)
    p = Price[self.prc]
    b = Bot[self.bot]
    if self.old?
      puts "OLD ITEM: DRAWING ICON"
      "#{p.qnt} за #{icon(b.icon_old)}#{b.amo_currency(self.discount_price, currency, label)}"
    else
      "#{p.qnt} за #{b.amo_currency(p.price, currency, label)}"
    end
  end

  def discount_price
    p = Price[self.prc]
    bot = Bot[self.bot]
    if self.old?
      return p.price - (p.price.to_f * bot.discount.to_f / 100).round.to_i
    else
      return p.price
    end
  end

  def method_discount_rate(method)
    ra = Bot[self.bot].payment_option('discount', method)
    return 0 if !ra
    return ra.to_i
  end

  def discount_price_by_method(method)
    p = Price[self.prc]
    bot = Bot[self.bot]
    discount = bot.payment_option('discount', method)
    return p.price if !discount
    if discount.to_i > 0
      p = p.price - (p.price.to_f * discount.to_f / 100).round.to_i
      puts "PRICE WITH METH DISCOUNT: #{p}"
      return p
    elsif self.old?
      puts "OLD KLAD"
      return p.price - (p.price.to_f * bot.discount.to_f / 100).round.to_i
    else
      puts "NOT OLD KLAD"
      return p.price
    end
  end

  def discount_commission
    b = Bot[self.bot]
    p = Price[self.prc]
    self.discount_price * (b.discount.to_f / 100).round.to_i
  end

  def discount_amount
    p = Price[self.prc]
    bot = Bot[self.bot]
    p.price.to_f * bot.discount.to_f / 100.round.to_i
  end

  def discount_method_amount(percent)
    p = Price[self.prc]
    p.price.to_f * percent.to_i / 100.round.to_i
  end

  def my? client
    self.client == client.id
  end

  def seller
    Bot[self.bot]
  end

  def i_added?(c)
    self.client == c.id
  end

  def inactive?
    self.status == Iten::INACTIVE
  end

  def active?
    self.status == Item::ACTIVE
  end

  def sold?
    self.status == Item::SOLD
  end

  def self.all_active
    Item.where(status: Item::ACTIVE)
  end

  def self.cities_with_items
    Item.distinct(:item__city).where(status: Item::ACTIVE)
  end

  def self.available_cities
    line = ''
    Item::cities_with_items.each do |city|
      line << "#{city}, "
    end
    line.chomp(', ')
  end

  def fresh?
    self.created.to_date == Date.today.to_date
  end

  def long_title
    seller = Client[self.client]
    prod = Product[self.product]
    p = Price.find(id: self.prc)
    p.to_str
  end

  def make(field, d)
    self[field.to_sym].nil? ? "#{icon('no_entry_sign')} #{d}"  : self[field.to_sym]
  end

  def product_string
    if self.product.nil?
      "#{icon('no_entry_sign')} продукт"
    else
      pr = Product[self.product]
      "#{icon(pr[:icon])} #{pr.russian}"
    end
  end

  def district_string
    self.district.nil? ? "#{icon('no_entry_sign')} район" : District[self.district].russian
  end

  def city_string
    self.city.nil? ? "#{icon('no_entry_sign')} город" : City[self.city].russian
  end

  def country_string
    # self.city.nil? ? "" : Country[City[self.city].country].russian
    ct = City[self.city]
    Country[ct.country].russian
  end

  def readable_status
    t("items.#{self.status}")
  end

  def string_for_items
    if !self.prc.nil?
      p = Price[self.prc]
      "#{p.qnt} за #{cents2uah(p.price)}грн."
    else
      false
    end
  end

end