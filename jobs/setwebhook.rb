require_relative './requires'
logger = CronLogger.new

hook = 'https://dksd.herokuapp.com/hook/'
puts "Bot: " + ARGV[0]
puts "Setting webhook ... "
b = Bot.find(tele: ARGV[0])
puts "Token: #{b.token}"
url = hook + b.token.to_s
puts "Webhook: #{url}"
from_bot = Telegram::Bot::Api.new(b.token)
from_bot.setWebhook(url: url)
puts from_bot.getWebhookInfo.inspect
