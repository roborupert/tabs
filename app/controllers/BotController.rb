require 'telegram/bot'
require 'telegram/bot/exceptions'
require 'net/http/persistent'
require 'raven'
require 'colorize'

class TABTimeout < Timeout::Error; end
class BotController < TSX::ApplicationController

  post '/hook/*' do
    begin
      mess = ''
      token = params[:splat].first
      @bot = Telegram::Bot::Client.new(token)
      @tsx_bot = Bot.find(token: token)
      @tsx_host = request.host
      parse_update(request.body)
      setup_sessa
      raise 'Возникла проблема при регистрации вашего никнейма. Обратитесь в поддержку.' if !hb_client
      raise "Бот на техобслуживании." if @tsx_bot.inactive?
      raise "Вы забанены. Удачи." if hb_client.banned?
      show_typing
      call_handler
      log_update
    rescue Telegram::Bot::Exceptions::ResponseError => re
      hb_client.status = Client::CLIENT_BANNED
      hb_client.save
      mess = re.message
      puts mess
      puts re.backtrace.join("\n\t")
    rescue => ex
      puts "====================================="
      puts ex.message
      puts ex.backtrace.join("\n\t")
      puts mess
      puts "====================================="
    end
    [200, {}, ["----------------------- SUCCESS"]]
  end

  def no_command
    reply_simple 'errors/no_command'
  end

  def no_such_view view
    reply_simple 'errors/no_such_view', view_file: view
  end

end