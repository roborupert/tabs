require_relative './requires'
logger = CronLogger.new

logger.noise "Updating proxies from file ... "
proxies = "91.188.240.98:9216:4hWme2:CqAn1H
91.188.243.69:9996:4hWme2:CqAn1H
91.188.241.104:9503:4hWme2:CqAn1H
91.188.242.21:9727:4hWme2:CqAn1H
91.188.243.178:9364:4hWme2:CqAn1H
91.188.241.79:9526:4hWme2:CqAn1H
91.188.243.51:9475:4hWme2:CqAn1H
91.188.240.168:9948:4hWme2:CqAn1H
91.188.240.57:9626:4hWme2:CqAn1H
91.188.242.77:9965:4hWme2:CqAn1H
181.177.87.250:9814:Tv7c8j:SH9vuD
181.177.85.137:9525:Tv7c8j:SH9vuD
181.177.86.97:9786:Tv7c8j:SH9vuD
181.177.85.254:9180:Tv7c8j:SH9vuD
181.177.85.101:9443:Tv7c8j:SH9vuD
181.177.85.158:9694:Tv7c8j:SH9vuD
181.177.87.18:9338:Tv7c8j:SH9vuD
181.177.87.59:9112:Tv7c8j:SH9vuD
181.177.86.220:9596:Tv7c8j:SH9vuD
181.177.86.85:9772:Tv7c8j:SH9vuD
107.152.153.110:9435:4rrsyj:ggWqg8
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