require_relative './requires'
logger = CronLogger.new

logger.noise "Updating proxies from file ... "
proxies = "194.9.177.94:3303:user12772:79xb0c
185.174.103.75:3303:user12772:79xb0c
185.174.103.183:3303:user12772:79xb0c
194.9.176.5:3303:user12772:79xb0c
194.9.176.228:3303:user12772:79xb0c
194.9.176.107:3303:user12772:79xb0c
185.174.101.164:3303:user12772:79xb0c
194.9.178.90:3303:user12772:79xb0c
194.9.177.99:3303:user12772:79xb0c
194.9.176.210:3303:user12772:79xb0c
".split("\n")

proxies.each do |proxy_string|
  proxy = proxy_string.split(":")
  Prox.create(host: proxy[0], port: proxy[1], status: Prox::ONLINE, login: proxy[2], password: proxy[3], provider: "proxy6")
  logger.say("Proxy #{proxy.first}:#{proxy.last} added to proxy pool")
end

Prox::flush
DB.disconnect
logger.noise "Finished."
