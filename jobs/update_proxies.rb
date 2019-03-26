require_relative './requires'
logger = CronLogger.new

logger.noise "Updating proxies from file ... "
proxies = "107.152.153.110:9435:4rrsyj:ggWqg8
107.152.153.96:9197:4rrsyj:ggWqg8
107.152.153.201:9312:4rrsyj:ggWqg8
104.227.102.86:9614:4rrsyj:ggWqg8
107.152.153.133:9861:4rrsyj:ggWqg8
104.227.102.201:9452:4rrsyj:ggWqg8
104.227.102.213:9520:4rrsyj:ggWqg8
104.227.102.164:9303:4rrsyj:ggWqg8
104.227.102.200:9188:4rrsyj:ggWqg8
104.227.96.240:9816:4rrsyj:ggWqg8
".split("\n")

proxies.each do |proxy_string|
  proxy = proxy_string.split(":")
  Prox.create(host: proxy[0], port: proxy[1], status: Prox::ONLINE, login: proxy[2], password: proxy[3], provider: "proxy6")
  logger.say("Proxy #{proxy.first}:#{proxy.last} added to proxy pool")
end

Prox::flush
DB.disconnect
logger.noise "Finished."
