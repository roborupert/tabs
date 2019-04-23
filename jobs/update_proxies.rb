require_relative './requires'
logger = CronLogger.new

logger.noise "Updating proxies from file ... "
proxies = "186.65.117.241:9734:SU9mHr:MoYvxk
186.65.117.184:9539:SU9mHr:MoYvxk
186.65.117.107:9340:SU9mHr:MoYvxk
186.65.117.207:9604:SU9mHr:MoYvxk
186.65.118.10:9946:SU9mHr:MoYvxk
186.65.115.125:9447:SU9mHr:MoYvxk
".split("\n")

proxies.each do |proxy_string|
  proxy = proxy_string.split(":")
  Prox.create(host: proxy[0], port: proxy[1], status: Prox::ONLINE, login: proxy[2], password: proxy[3], provider: "proxy6")
  logger.say("Proxy #{proxy.first}:#{proxy.last} added to proxy pool")
end

Prox::flush
DB.disconnect
logger.noise "Finished."
