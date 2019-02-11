class District < Sequel::Model(:district)
  include TSX::Elements
  include TSX::Helpers

  def to_str(bot)
    "#{icon(bot.icon_geo)} #{self[:entity_russian]}"
  end

  def sales_by_district(hb_bot, dist)
    s = Stat.where(bot: hb_bot.id, district: dist.id).sum(:sales)
    s.nil? ? 0 : s
  end

  def sales_amount_by_district(hb_bot, dist)
    s = Stat.where(bot: hb_bot.id, district: dist.id).sum(:amount)
    s.nil? ? 0 : s
  end

end