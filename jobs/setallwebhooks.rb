require_relative './requires'

url = 'https://dksd10.herokuapp.com/hook'
puts "Setting webhooks to #{url} ... "
Bot.where(listed: 1).all.each do |b|
  begin
    from_bot = Telegram::Bot::Api.new(b.token)
    ur = "#{url}/#{b.token}"
    puts "Bot: #{b.tele}".colorize(:white)
    puts "WAS: #{from_bot.getWebhookInfo.inspect}".colorize(:red)
    from_bot.setWebhook(url: ur)
    puts "NOW: #{from_bot.getWebhookInfo.inspect}\n\n".colorize(:green)
  rescue => ex
    puts ex.message
  end
end

