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

def check_easy(possible_codes, wallet, item_amount, login, password)
  web = Mechanize.new
  web.keep_alive = false
  web.read_timeout = 10
  web.open_timeout = 10
  web.user_agent = "Mozilla/5.0 Gecko/20101203 Firefox/3.6.13"
  # proxy = Prox.get_active
  # web.agent.set_proxy(proxy.host, proxy.port, proxy.login, proxy.password)
  web.agent.set_proxy('104.227.102.213', 9520, '4rrsyj', 'ggWqg8')
  # web.agent.set_proxy('194.9.177.94', 13303, 'user12772', '79xb0c')
  # puts "Connecting from '#{proxy.provider}' over #{proxy.host}:#{proxy.port} ... ".colorize(:yellow)
  begin
    puts "Retrieving main page"
    easy = web.get('http://easypay.ua')
    puts easy.inspect
    puts "Trying to login with #{login}/#{password}"
    exit
    logged = easy.form do |f|
      f.login = login.to_s
      f.password = password.to_s
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


# def check_easy(possible_codes, wallet, item_amount, login, password)
#   web = Mechanize.new
#   web.keep_alive = false
#   web.user_agent = "Mozilla/5.0 (Windows; U; Windows NT 6.1; nl; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13"
#   puts "Connecting over Tor ... "
#   # proxy = Prox.get_active
#   web.agent.set_proxy('velodrome.usefixie.com', 80, 'fixie', 'zD3mQpUIoiIn101')
#   begin
#     puts "Retrieving main page"
#     easy = web.get('http://easypay.ua')
#     # verification_token = easy.forms.first.fields.first.value.to_s
#     puts "Trying to login with #{login}/#{password}"
#     easy.form do |f|
#       f.login = login.to_s
#       f.password = password.to_s
#     end.submit
#     # wallet_page = web.get("https://easypay.ua/wallets/statement")
#     # puts wallet_page.inspect.white.on_red
#     # wallet = wallet_page.forms.last.fields.first.value
#     # if wallet.length > 6
#     #   # proxy.deactivate
#     #   puts "Wrong credentials".white.on_red
#     #   return ResponseEasy.new('error', 'TSX::Exceptions::WrongEasyPass')
#     # else
#     #   puts "Wallet found"
#     #   puts "#{wallet}".white.on_red
#     # end
#     puts "Checking all payments for the current day"
#     st = web.get("https://easypay.ua/wallets/buildreport?walletId=#{wallet}&month=#{Date.today.month}&year=#{Date.today.year}")
#     puts st.inspect.colorize(:red)
#     tab = st.search(".//table[@class='table-layout']").children
#     tab.each do |d|
#       i = 1
#       to_match = ''
#       amount = ''
#       d.children.each do |td, td2|
#         if i == 2
#           to_match << td.inner_text
#         end
#         if i == 6
#           amount = td.inner_text
#         end
#         if i == 10
#           to_match << td.inner_text
#         end
#         i = i + 1
#       end
#       matched = "#{to_match}".match(/.*(\d{2}:\d{2})\D*(\d+)/)
#       if matched
#         dat =  "#{to_match}".match(/(\d{2}.\d{2}.\d{4}).*/)
#         if Date.parse(dat.captures.first) < Date.today - 1.days
#           puts "Payment not found"
#           return ResponseEasy.new('error', 'TSX::Exceptions::PaymentNotFound')
#         end
#         found_code = matched.captures.first + matched.captures.last
#         included = possible_codes.include?(found_code)
#         if included
#           amt = amount.to_f.round.to_i
#           if amt+3 < item_amount.to_i
#             puts "Not enough amount"
#             return ResponseEasy.new('error', 'TSX::Exceptions::NotEnoughAmount', nil, amt)
#           else
#             return ResponseEasy.new('success', nil, nil, amount.to_f.round.to_i )
#           end
#         end
#       end
#     end
#   rescue Net::OpenTimeout
#     # exec 'service tor reload'
#     puts "Connection too slow"
#     return ResponseEasy.new('error', 'TSX::Exceptions::OpenTimeout')
#   rescue => e
#     # `service tor reload`
#     puts e.message.colorize(:red)
#     return ResponseEasy.new('error', 'TSX::Exceptions::Exception')
#   end
# end

# check_easy(["10:3278887", "10:3278887"],
#            '710965',
#            200,
#            '380960294934',
#            'икрарол888'
# )

check_easy(["10:3278887", "10:3278887"],
           '1027748',
           200,
           '380975251590',
           'BRICKS55'
)