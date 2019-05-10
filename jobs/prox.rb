require_relative './requires'
logger = CronLogger.new

logger.noise "Updating proxies ... "
proxies = "66.70.146.188:3129
144.217.121.79:3129
66.70.159.203:3129
91.134.50.128:3129
144.217.156.226:3129
144.217.107.0:3129
192.95.23.202:3129
66.70.146.195:3129
66.70.146.1:3129
66.70.159.225:3129
".split("\n")

puts proxies.inspect
proxies.each do |proxy_string|
  proxy = proxy_string.split(':')
  Prox.create(host: proxy.first, port: proxy.last, status: Prox::ONLINE)
  logger.say("Proxy #{proxy.first}:#{proxy.last} added to proxy pool")
end

DB.disconnect
logger.noise "Finished."