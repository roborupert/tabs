require_relative './requires'

hook = 'https://dksd100.herokuapp.com/hook/'
puts "Token: #{ARGV[0]}"
puts "Setting webhook ... "
url = hook + ARGV[0].to_s
puts "Webhook: #{url}"
from_bot = Telegram::Bot::Api.new(ARGV[0])
puts from_bot.getWebhookInfo.inspect
from_bot.setWebhook(url: ARGV[1])
