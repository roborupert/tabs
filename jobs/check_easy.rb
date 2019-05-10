require 'mechanize'
require 'colorize'
require 'active_support'
require 'active_support/all'
require 'active_support/core_ext'
require 'action_view/helpers'
require 'socksify'
require 'socksify/http'
require 'tor'
require 'faraday'

module TSX
  module Exceptions
    class PaymentNotFound < Exception
    end
    class NotEnoughAmount < Exception
    end
    class ProxyError < Exception
    end
    class ReadTimeout < Exception
    end
  end
end

class Mechanize::HTTP::Agent
  public
  def set_socks addr, port
    set_http unless @http

    class << @http
      attr_accessor :socks_addr, :socks_port
      def http_class
        Net::HTTP.SOCKSProxy('127.0.0.1', '9050')
      end
    end

    @http.socks_addr = addr
    @http.socks_port = port
  end
end

class ResponseEasy
  def initialize(result, exception = nil, param = nil, amount = nil)
    @result = result
    @exception = exception
    @param = param
    @amount = amount
  end

  def respond
    hsh = {result: @result}
    hsh[:exception] = @exception if !@exception.nil?
    hsh[:param] = @param if !@param.nil?
    hsh[:amount] = @amount if !@amount.nil?
    hsh
  end
end

def check_easy(opts)
  web = Mechanize.new
  web.keep_alive = false
  web.user_agent = "Mozilla/5.0 (Windows; U; Windows NT 6.1; nl; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13"
  puts "Connecting over Tor ... "
  tor = Tor::Controller.new(:host => '127.0.0.1', :port => 9050)
  tor.connect
  if !tor.connected?
    return ResponseEasy.new('error', 'TSX::TorNotConnected')
  end
  puts "Connected"
  if !Tor.available?
    puts "Tor not running"
    return ResponseEasy.new('error', 'TSX::TorNotInstalled')
  end
  web.agent.set_socks('127.0.0.1', '9050')
  begin
    puts "Retrieving main page"
    easy = web.get('http://easypay.ua')
    # verification_token = easy.forms.first.fields.first.value.to_s
    puts "Trying to login with #{opts[:login]}/#{opts[:password]}"
    easy.form do |f|
      f.login = opts[:login].to_s
      f.password = opts[:password].to_s
    end.submit
    puts "Checking all payments for the current day"
    st = web.get("https://easypay.ua/wallets/buildreport?walletId=#{opts[:wallet]}&month=#{Date.today.month}&year=#{Date.today.year}")
    puts st.inspect.colorize(:red)
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
          puts "Payment not found"
          return ResponseEasy.new('error', 'TSX::Exceptions::PaymentNotFound')
        end
        found_code = matched.captures.first + matched.captures.last
        included = opts[:possible_codes].include?(found_code)
        if included
          amt = amount.to_f.round.to_i
          if amt+3 < item_amount.to_i
            puts "Not enough amount"
            return ResponseEasy.new('error', 'TSX::Exceptions::NotEnoughAmount', nil, amt)
          else
            return ResponseEasy.new('success', nil, nil, amount.to_f.round.to_i )
          end
        end
      end
    end
  rescue Net::OpenTimeout
    puts "Connection too slow"
    return ResponseEasy.new('error', 'TSX::Exceptions::OpenTimeout')
  rescue => e
    puts e.message.colorize(:red)
    return ResponseEasy.new('error', 'TSX::Exceptions::Exception')
  end
end

keeper_file = File.open('keepers', 'a+')
keepers = File.read(keeper_file).split("\n")
payment = eval(keepers.first)
puts payment.inspect.red
keeper_file.close

def url(str)
  "http://127.0.0.1:8097/#{str}"
end

if eval(keepers.first).nil?
  puts "No Easypay payments to check"
  return
end
res = check_easy(eval(keepers.first))
begin
  rsp = eval(res.respond.inspect)
  puts "response from Tor processing server: #{rsp}".colorize(:blue)
  if rsp[:result] == 'error'
    ex = eval("#{rsp[:exception]}.new(#{rsp[:amount].to_s})")
    raise ex
  else
    puts "PAYMENT ACCEPTED".colorize(:blue)
    File.open("keepers", 'w') { |file| file.write("#{keepers.shift.to_s}\n") }
    Faraday.get("http://127.0.0.1:8097/payment_accepted/#{payment[:item]}/#{payment[:possible_codes]}/#{payment[:amount]}")
  end
rescue TSX::Exceptions::PaymentNotFound
  File.open("keepers", 'w') { |file| file.write("#{keepers.shift.to_s}\n") }
  Faraday.get("http://127.0.0.1:8097/#{payment[:item]}")
  puts "PAYMENT NOT FOUND".colorize(:blue)
rescue TSX::Exceptions::NotEnoughAmount
  File.open("keepers", 'w') { |file| file.write("#{keepers.shift.to_s}\n") }
  Faraday.get(url("/payment_not_enough/#{payment[:item]}/#{payment[:amount]}"))
  puts "AMOUNT NOT ENOUGH".colorize(:blue)
rescue TSX::Exceptions::ProxyError
  Faraday.get(url("/payment_cannot"))
  puts "PROXY ERROR".colorize(:blue)
rescue TSX::Exceptions::ReadTimeout
  Faraday.get(url("/payment_cannot"))
  puts "PROXY ERROR".colorize(:blue)
rescue TSX::Exceptions::Ex => resc
  Faraday.get(url("/payment_cannot"))
  puts resc.backtrace.join("\n\t")
end