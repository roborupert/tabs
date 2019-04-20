require_relative './requires'
logger = CronLogger.new

logger.noise "Updating proxies from file ... "
proxies = "91.188.243.81:9119:9wqyrA:FpYJB8
138.59.205.126:9616:P5jM74:MwfMzF
138.59.207.48:9864:P5jM74:MwfMzF
91.188.243.163:9836:41Y8o6:oMknMN
104.227.96.211:9584:ucwwAh:swH4ay
".split("\n")

proxies.each do |proxy_string|
  proxy = proxy_string.split(":")
  Prox.create(host: proxy[0], port: proxy[1], status: Prox::ONLINE, login: proxy[2], password: proxy[3], provider: "proxy6")
  logger.say("Proxy #{proxy.first}:#{proxy.last} added to proxy pool")
end

Prox::flush
DB.disconnect
logger.noise "Finished."
