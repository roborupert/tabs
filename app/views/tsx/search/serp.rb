#{bread_crumbs}
****
buts ||= []
buts = keyboard(@list, 3) do |rec|
  if rec.instance_of?(Product)
    "#{icon(rec[:entity_icon])} #{rec[:entity_russian]}"
  else
    rec.to_str(@tsx_bot)
  end
end
but_list ||= []
but_list << (@buttons ? @buttons.first : nil) << (@buttons ? @buttons.last : nil) << btn_pending_trades <<
             btn_finalized_trades << btn_admin
other_buts = keyboard(but_list - [nil], 3) do |b|
  b if !b.nil?
end
other_buts.each do |ar|
  buts.push(ar)
end
if !@tsx_bot.custom_buttons
  buts << [btn_bots_welcome, btn_cashout]
else
  buts << @tsx_bot.custom_buttons << [btn_bots_welcome]
end
buts




