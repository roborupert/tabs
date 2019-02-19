require_relative './requires'
logger = CronLogger.new
DB.logger = logger

hook = ARGV[0]
bot = ARGV[1]

puts "Bot: #{bot}"
puts "Setting webhook ... #{hook}"
b = Bot.find(tele: bot)
puts "Token: #{b.token}"
url = hook + b.token.to_s
puts "Webhook: #{url}"
from_bot = Telegram::Bot::Api.new(b.token)
puts "WAS: #{from_bot.getWebhookInfo.inspect}".colorize(:red)
from_bot.setWebhook(url: url)
puts "NOW: #{from_bot.getWebhookInfo.inspect}".colorize(:green)
