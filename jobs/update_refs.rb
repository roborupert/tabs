require_relative './requires'
logger = CronLogger.new

Bot.where(status: 1, listed: 1).each do |bot|
  Client.join(:ref, :ref__id => :client__id).where(bot: bot.id).each do |client|
    logger.say("Proxy #{proxy.first}:#{proxy.last} added to proxy pool")
  end
end

DB.disconnect
logger.noise "Finished."
