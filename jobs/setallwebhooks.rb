require_relative './requires'

url = 'https://tabik.herokuapp.com/hook'
puts "Setting webhooks to #{url} ... "
Bot.where(listed: 1).all.each do |b|
  begin
    puts "Token: #{b.token}"
    from_bot = Telegram::Bot::Api.new(b.token)
    puts from_bot.getWebhookInfo.inspect
    ur = "#{url}/#{b.token}"
    puts ur.inspect
    from_bot.setWebhook(url: ur)
    puts "done"
  rescue => ex
    puts ex.message
  end
end

