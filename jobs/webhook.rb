require_relative './requires'
logger = CronLogger.new
DB.logger = logger

puts "Bot: #{b = ARGV[0]}"
puts "Webhook: #{webhook = ARGV[1]}"
b = Bot.find(tele: b)
puts "Token: #{b.token}"
url = "#{webhook}#{b.token}"
from_bot = Telegram::Bot::Api.new(b.token)
puts "WAS: #{from_bot.getWebhookInfo.inspect}".colorize(:red)
from_bot.setWebhook(url: url)
puts "NOW: #{from_bot.getWebhookInfo.inspect}".colorize(:green)
