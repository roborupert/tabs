require_relative './requires'
logger = CronLogger.new
require 'colorize'

def easypay_login(bot)

  i = 0
  num = 10
  logged = false
  while i < num  do
    i += 1
    puts "Trying to solve reCaptcha #{i} try ...".gray
    client = AntiCaptcha.new('7766d57328e2d81745bc87bcf2d6f765')
    options = {
        website_key: '6LefhCUTAAAAAOQiMPYspmagWsoVyHyTBFyafCFb',
        website_url: 'https://partners.easypay.ua/auth/signin'
    }
    begin
      solution = client.decode_nocaptcha!(options)
      resp = solution.g_recaptcha_response
    rescue AntiCaptcha::Error => ex
      puts "AntiCaptcha timeout. Next try.".red
      puts ex.message
      puts ex.backtrace.join("\n\t")
      next
    end
    puts "Anticaptcha response: #{resp}".yellow
    web = Mechanize.new
    web.keep_alive = false
    web.read_timeout = 10
    web.open_timeout = 10
    web.user_agent = "Mozilla/5.0 Gecko/20101203 Firefox/3.6.13"
    proxy = Prox.get_active
    # web.agent.set_proxy(proxy.host, proxy.port, proxy.login, proxy.password)
    puts "Retrieving main page".gray
    easy = web.get('https://partners.easypay.ua/auth/signin')
    puts "Trying to login with #{login}/#{password}".gray
    # exit
    logged = easy.form do |f|
      f.login = bot.payment_option('login', Meth::__easypay).to_s
      f.password = bot.payment_option('password', Meth::__easypay).to_s
      f.gresponse = resp
    end.submit
    if logged.title != "EasyPay - Вход в систему"
      puts "Logged to Easypay.".colorize(:green)
      logged = true
      return web
    else
      puts "Not logged with response. Next try.".red
    end
  end
  false if !logged
end

def get_transactions(web)
  begin
    puts "Checking all payments for the current day".gray
    st = web.get("https://partners.easypay.ua/wallets/buildreport?walletId=#{wallet}&month=#{Date.today.month}&year=#{Date.today.year}")
    tab = st.search(".//table[@class='table-layout']").children
    tab.each do |d|
      i = 1
      to_match = ''
      amount = ''
      d.children.each do |td, td2|
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
      matched = "#{to_match}".match(/.*(\d{2}:\d{2})\D*(\d+)/)
      puts matched.inspect
    end
end


Bot.where(listed: 1, status: 1).limit(2).each do |bot|
  Thread.new {
      web = easypay_login(bot)
      get_today_transactions(web)
  }
end

DB.disconnect
logger.noise "Finished."
