require 'socksify'
require 'socksify/http'
require 'btce'

module Btce
  class API
    BTCE_DOMAIN = "wex.nz"
  end
end

module TSX
  module Billing

    class Mechanize::HTTP::Agent
      public
      def set_socks addr, port
        set_http unless @http

        class << @http
          attr_accessor :socks_addr, :socks_port
          def http_class
            # TCPSocket::socks_username = 'tallhours79'
            # TCPSocket::socks_password = 'tillcheck84'
            Net::HTTP.SOCKSProxy(socks_addr, socks_port)
          end
        end

        @http.socks_addr = addr
        @http.socks_port = port
      end
    end

    def payment_option(key, meth)
      pmt = Payment.find(bot: self.id, meth: meth.id)
      if !pmt.nil?
        params = JSON.parse(pmt.params)
        params[key]
      else
        false
      end
    end

    def check_qiwi(code)
      begin
        check_url = "https://qiwigate.ru/api?key=HEY5UQBDVR7CKZEVSPLNG2GTBR9N0X&method=qiwi.get.history&start=#{Date.today.strftime("%d.%m.%Y")}&finish=#{Date.today.strftime("%d.%m.%Y")}"
        puts check_url.colorize(:yellow)
        resp = eval(Faraday.get(check_url).body)
        puts "Getting transactions from Qiwi... "
        resp[:history].each do |payment|
          if payment[:tx] == code
            puts "found tx=#{code}".colorize(:green)
            amount = ((payment[:cash].split(",").first.to_f/100) * RUB_RATE).round
            puts "amount=#{amount}".colorize(:green)
            return amount
          end
        end
        puts "No Qiwi payment found".colorize(:red)
        return 'false'
      rescue => e
        puts e.message.colorize(:red)
      end
    end

    def check_tsc(code)
      rs = Tsc.verify_tscx_code(code)
      puts rs.inspect.colorize(:red)
      if rs == 'false'
        return 'false'
      else
        return ((rs.to_f/100) * UAH_RATE).round
      end
    end

    def check_wex(code)
      api = Btce::TradeAPI.new(
          {
              url: "https://wex.nz/tapi",
              key: self.payment_option('key', Meth::__wex),
              secret: self.payment_option('secret', Meth::__wex)
          }
      )
      redeem = api.trade_api_call(
          'RedeemCoupon',
          coupon: code
      ).to_hash
      puts redeem.inspect
      if redeem['success'] == 0
        return 'false'
      elsif redeem['return']['couponCurrency'] != 'USD'
        return 'false'
      else
        cents = (redeem['return']['couponAmount']).to_f * 100
        return cents
      end
    end

    def check_tokenbar(payment_id)
      resp = eval(Net::HTTP.post_form(
          URI('http://tokenbar.net/api/check'), {
          aid: 1,
          payment_id: payment_id,
          hash: Digest::MD5.hexdigest("1#{payment_id}f1f70ec40aaa")
      }
      ).body.inspect)
      return ResponseEasy.new('success', nil, nil, 10000)
      if resp['code']
        accepted = Bot::chief.accept_wex(resp['code'])
        if accepted['success'] == 0
          return ResponseEasy.new('error', 'TSX::Exceptions::PaymentNotFound')
        else
          return ResponseEasy.new('success', nil, nil, accepted.to_f.round.to_i )
        end
      else
        return ResponseEasy.new('error', 'TSX::Exceptions::PaymentNotFound')
      end
    end

    def used_code?(code, bot_id)
      payment_time = code[0..4]
      rest_of_code = code[5..-1]
      terminal = code[5..9]
      c_original = Time.parse(payment_time).strftime("%H:%M") + terminal
      с_minus = (Time.parse(payment_time) - 1.minute).strftime("%H:%M") + terminal
      used_code = Invoice.
          join(:client, :client__id => :invoice__client).
          join(:bot, :bot__id => :client__bot).
          where("(invoice.code like '%#{c_original}%' or invoice.code like '%#{с_minus}%') and (bot.id = #{bot_id})")
      # puts used_code.inspect.colorize(:yellow)
      if used_code.count == 0
        return [c_original, с_minus]
      else
        raise TSX::Exceptions::UsedCode
      end
    rescue => ex
      # puts ex.message.colorize(:yellow)
      # puts ex.backtrace.join("\n\t").colorize(:yellow)
      raise TSX::Exceptions::WrongFormat
    end

    def still_checking?(code, bot_id)
      payment_time = code[0..4]
      rest_of_code = code[5..-1]
      terminal = code[5..9]
      c_original = Time.parse(payment_time).strftime("%H:%M") + terminal
      с_minus = (Time.parse(payment_time) - 1.minute).strftime("%H:%M") + terminal
      checking = Invoice.
          join(:client, :client__id => :invoice__client).
          join(:bot, :bot__id => :client__bot).
          where("((invoice.code like '%#{c_original}%' and checking = 1 ) or (invoice.code like '%#{с_minus}%' and checking = 1)) and (bot.id = #{bot_id})")
      raise TSX::Exceptions::StillChecking if checking.count > 0
    end


    def check_easypay_format(code)
      "#{code}".match(/(\d{2}:\d{2})(\d{5})\z/)
    end

    def check_tokenbar_format(code)
      "#{code}".match(/(\d{12}):(\d{8})\z/)
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

    def botrec(action, params = '', cl)
      rec('bot', cl, self, action, params)
    end

    def rec(init = 'unknown', cl, b, action, params)
      Rec.create(
          initiator: init.to_s,
          client: cl.nil? ? '' : cl.id,
          bot: b.nil? ? '' : b.id,
          action: action,
          params: params,
          logged: Time.now
      )
    end


    def check_easy(cl, possible_codes, wallet, item_amount, login, password)
      puts "CHECK EASY!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!".colorize(:red)
      botrec('easypay check', possible_codes.inspect, cl)
      begin
        i = 0
        num = 5
        logged = false
        while i < num  do
          i += 1
          botrec("[CHECK] Trying to solve reCaptcha #{i} try ...", possible_codes.inspect, cl)
          puts "Trying to solve reCaptcha #{i} try ... "
          client = AntiCaptcha.new('7766d57328e2d81745bc87bcf2d6f765')
          options = {
              website_key: '6LefhCUTAAAAAOQiMPYspmagWsoVyHyTBFyafCFb',
              website_url: 'https://partners.easypay.ua/auth/signin'
          }
          begin
            solution = client.decode_nocaptcha!(options)
            resp = solution.g_recaptcha_response
          rescue AntiCaptcha::Timeout => ex
            botrec("[CHECK] AntiCaptcha timeout. Next try.", ex.message, cl)
            puts "AntiCaptcha timeout. Next try."
            puts ex.message
            next
          end
          puts resp.colorize(:yellow)
          web = Mechanize.new
          web.keep_alive = false
          web.read_timeout = 10
          web.open_timeout = 10
          web.user_agent = "Mozilla/5.0 Gecko/20101203 Firefox/3.6.13"
          proxy = Prox.get_active
          web.agent.set_proxy(proxy.host, proxy.port, proxy.login, proxy.password)
          puts "Connecting from '#{proxy.provider}' over #{proxy.host}:#{proxy.port} ... ".colorize(:yellow)
          puts "Retrieving main page"
          easy = web.get('https://partners.easypay.ua/auth/signin')
          puts "Trying to login with #{login}/#{password}"
          botrec("[CHECK] Trying to login.", possible_codes.inspect, cl)
          # exit
          logged = easy.form do |f|
            f.login = login.to_s
            f.password = password.to_s
            f.gresponse = resp
          end.submit
          if logged.title != "EasyPay - Вход в систему"
            botrec("[CHECK] Logged.", possible_codes.inspect, cl)
            logged = true
            break
          else
            botrec("[CHECK] Not logged.", possible_codes.inspect, cl)
            puts "Not logged with response. Next try."
          end
        end
        return ResponseEasy.new('error', 'TSX::Exceptions::AntiCaptcha') if !logged
        puts "Checking all payments for the current day"
        botrec("[CHECK] Checking all payments", possible_codes.inspect, cl)
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
        botrec("[CHECK] PaymentNotFound", e.message, cl)
        return ResponseEasy.new('error', 'TSX::Exceptions::PaymentNotFound')
      rescue Net::OpenTimeout
        botrec("[CHECK] OpenTimeout", e.message, cl)
        return ResponseEasy.new('error', 'TSX::Exceptions::OpenTimeout')
      rescue => e
        botrec("[CHECK] Exception", e.message, cl)
        puts e.message.colorize(:red)
        return ResponseEasy.new('error', 'TSX::Exceptions::Ex')
      end
    end


  end
end