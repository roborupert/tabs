require_relative './requires'
require 'colorize'

logger = CronLogger.new
# DB.logger = logger

def easypay_login(bot)
  i = 0
  num = 10
  logged = false
  while i < num  do
    i += 1
    puts "#{bot.title}:  Trying to solve reCaptcha #{i} try ..."
    client = AntiCaptcha.new('7766d57328e2d81745bc87bcf2d6f765')
    options = {
        website_key: '6LefhCUTAAAAAOQiMPYspmagWsoVyHyTBFyafCFb',
        website_url: 'https://partners.easypay.ua/auth/signin'
    }
    begin
      solution = client.decode_nocaptcha!(options)
      resp = solution.g_recaptcha_response
    rescue AntiCaptcha::Error => ex
      puts "#{bot.title}: AntiCaptcha timeout. Next try.".red
      next
    end
    puts "#{bot.title}: Got AntiCaptcha response: #{resp}".green
    web = Mechanize.new
    web.keep_alive = false
    web.read_timeout = 10
    web.open_timeout = 10
    web.user_agent = "Mozilla/5.0 Gecko/20101203 Firefox/3.6.13"
    proxy = Prox.get_active
    # web.agent.set_proxy(proxy.host, proxy.port, proxy.login, proxy.password)
    puts "#{bot.title}: Retrieving main page".white
    easy = web.get('https://partners.easypay.ua/auth/signin')
    login = bot.payment_option('login', Meth::__easypay)
    password = bot.payment_option('password', Meth::__easypay)
    puts "#{bot.title}: Trying to login with #{login}/#{password}".white
    begin
      # exit
      logged = easy.form do |f|
        f.login = login.to_s
        f.password = password.to_s
        f.gresponse = resp
      end.submit
    rescue => e
      puts "#{bot.title}: Not logged to Easypay.".colorize(:red)
      next
    end
    if logged.title != "EasyPay - Вход в систему"
      puts "#{bot.title}: Logged to Easypay.".colorize(:green)
      logged = true
      return web
    else
      puts "#{bot.title}: Not logged with response. Next try.".colorize(:red)
    end
  end
  false if !logged
end

def get_today_transactions(web, bot)
  puts "#{bot.title}: Checking all payments for the current day".white
  wallet = bot.payment_option('wallet', Meth::__easypay)
  st = web.get("https://partners.easypay.ua/wallets/buildreport?walletId=#{wallet}&month=#{Date.today.month}&year=#{Date.today.year}")
  tab = st.search(".//table[@class='table-layout']").children
  puts "#{bot.title}: TAB COUNT: #{tab.count}"
  tab.each do |d|
    i = 1
    to_match = ''
    amount = ''
    d.children.each do |td, td2|
      puts td.inspect
      if i == 2
        to_match << td.inner_text
      end
      if i == 6
        amount = td.inner_text
      end
      if i == 10
        to_match << td.inner_text
      end
      i = i + 1
    end
    puts to_match.red
    matched = "#{to_match}".match(/.*(\d{2}:\d{2})\D*(\d+)/)
    if matched
      code = "#{matched.captures.first}#{matched.captures.last}"
      p = Easypay.where("bot = #{bot.id} and code = '#{code}' and amount = '#{amount}'")
      if p.count == 0
        Easypay.create(bot: bot.id, code: code, amount: amount)
      end
    else
      puts "NOT MATCHED".red
    end
  end
end

threads = []
Bot.where(listed: 1, status: 1).limit(3).each do |bot|
  threads << Thread.new {
    puts "BOT: #{bot.title}".blue
    web = easypay_login(bot)
    get_today_transactions(web, bot)
  }
end
ThreadsWait.all_waits(threads) do |t|
  STDERR.puts "Thread #{t} has terminated."
end

DB.disconnect
logger.noise "Finished."
