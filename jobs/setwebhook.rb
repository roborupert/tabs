require_relative './requires'
logger = CronLogger.new

hook = 'https://dksd100.herokuapp.com/hook/'
puts "Bot: " + ARGV[0]
puts "Setting webhook ... "
b = Bot.find(tele: ARGV[0])
puts "Token: #{b.token}"
url = hook + b.token.to_s
puts "Webhook: #{url}"
from_bot = Telegram::Bot::Api.new(b.token)
puts "WAS: #{from_bot.getWebhookInfo.inspect}".colorize(:red)
from_bot.setWebhook(url: url)
puts "NOW: #{from_bot.getWebhookInfo.inspect}".colorize(:green)
