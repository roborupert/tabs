require 'sinatra'
require 'mechanize'
require 'colorize'
require 'active_support'
require 'active_support/all'
require 'active_support/core_ext'
require 'action_view/helpers'
require 'socksify'
require 'socksify/http'
require 'tor'
require 'fileutils'
require 'anti_captcha'

def check_easy(possible_codes, wallet, item_amount, login, password)
  client = AntiCaptcha.new('7766d57328e2d81745bc87bcf2d6f765')
  options = {
      website_key: '6LefhCUTAAAAAOQiMPYspmagWsoVyHyTBFyafCFb',
      website_url: 'https://partners.easypay.ua/auth/signin'
  }
  solution = client.decode_nocaptcha!(options)
  resp = solution.g_recaptcha_response
  puts "RESPONSE: "
  puts resp

  web = Mechanize.new
  web.keep_alive = false
  web.read_timeout = 10
  web.open_timeout = 10
  web.user_agent = "Mozilla/5.0 Gecko/20101203 Firefox/3.6.13"
  # proxy = Prox.get_active
  # web.agent.set_proxy(proxy.host, proxy.port, proxy.login, proxy.password)
  # web.agent.set_proxy('176.107.180.171', 8000, 'jS8LST', 'sYKWgA')
  # web.agent.set_proxy('194.9.177.94', 3303, 'user12772', 'CqAn1H')
  # puts "Connecting from '#{proxy.provider}' over #{proxy.host}:#{proxy.port} ... ".colorize(:yellow)
  begin
    puts "Retrieving main page"
    easy = web.get('https://partners.easypay.ua/auth/signin')
    puts easy.inspect
    puts "Trying to login with #{login}/#{password}"
    # exit
    logged = easy.form do |f|
      f.login = login.to_s
      f.password = password.to_s
      f.gresponse = resp
    end.submit
    puts logged.inspect
    if logged.title == "EasyPay - Вход в систему"
      raise TSX::Exceptions::WrongEasyPass
    end
    puts "Checking all payments for the current day"
    hm = web.get("https://partners.easypay.ua/home")
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
      if matched
        dat =  "#{to_match}".match(/(\d{2}.\d{2}.\d{4}).*/)
        if Date.parse(dat.captures.first) < Date.today - 1.days
          return ResponseEasy.new('error', 'TSX::Exceptions::PaymentNotFound')
        end
        found_code = matched.captures.first + matched.captures.last
        included = possible_codes.include?(found_code)
        if included
          amt = amount.to_f.round.to_i
          if (amt + 3) < item_amount.to_i
            return ResponseEasy.new('error', 'TSX::Exceptions::NotEnoughAmount', nil, amt)
          else
            return ResponseEasy.new('success', nil, nil, amount.to_f.round.to_i )
          end
        end
      end
    end
    return ResponseEasy.new('error', 'TSX::Exceptions::PaymentNotFound')
  rescue Net::OpenTimeout
    # proxy.deactivate
    return ResponseEasy.new('error', 'TSX::Exceptions::OpenTimeout')
  rescue => e
    # proxy.deactivate
    puts e.message.colorize(:red)
    return ResponseEasy.new('error', 'TSX::Exceptions::Ex')
  end
end


check_easy(["10:3278887", "10:3278887"],
           '1027748',
           200,
           '380975251590',
           'BRICKS55'
)