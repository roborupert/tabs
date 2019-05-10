module Darkside
  module Role

    def can?
      access = {
          "/" => Client::ALL,
          "/css/b22.css" => Client::ALL,
          "/js/b22.js" => Client::ALL,
          "/search" => Client::ALL,
          "/bot_statement" => Client::PUBLIC,
          "/auth" => Client::PUBLIC,
          "/auth/do" => Client::ALL,
          "/auth/exit" => Client::ALL,
          "/register" => Client::PUBLIC,
          "/account" => Client::LOGGED,
          "/payment_accepted" => Client::LOGGED,
          "/help" => Client::ALL,
          "/settings" => Client::ALL,
          "/start_escrow" => Client::LOGGED,
          "/shop/" => Client::ALL,
          "/tbr" => Client::PUBLIC,
          "/payment_not_found" => Client::LOGGED,
          "/payment_not_enough" => Client::LOGGED,
          "/offer" => Client::PUBLIC
      }
      @path = "/#{@path.split("/")[1]}"
      puts @path.red
      roles_access = access.fetch(@path, [])
      if hb_operator
        employee = Team.find(client: hb_operator.id, bot: hb_bot.id)
        if roles_access.include?(employee.role)
          ret = true
        else
          ret = false
        end
      else
        if roles_access.empty?
          ret = false
        elsif roles_access.include?(Client::HB_ROLE_PUBLIC)
          ret = true
        else
          ret = false
        end
      end
      ret
    end

  end
end