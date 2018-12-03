require 'active_support'
require 'active_support/all'
require 'active_support/core_ext'
require 'action_view/helpers'
require 'action_view/helpers/number_helper'
require 'action_view/helpers/date_helper'
require 'sinatra/multi_route'
require 'colorize'
require 'sinatra/reloader'
require 'will_paginate'
require 'will_paginate/sequel'
require 'will_paginate/view_helpers/sinatra'
require 'will_paginate/collection'
require 'faraday_middleware'
require 'faraday'
require 'active_support'
require 'action_view'
require 'cloudinary'
require 'cloudinary/helper'
require 'rack-timeout'
require 'sinatra/captcha'
require 'telegram/bot'
require 'telegram/bot/exceptions'

module TSX

  class ApplicationController < Sinatra::Base
    set :bind, '0.0.0.0'

    use Rack::Session::Cookie, secret: 'sbdddjfksdjfttsxtsxpostsetsession789999333hhjgg'

    register Sinatra::Reloader if not production?
    also_reload "#{ROOT}/app/models/*" if not production?

    register Sinatra::Partial
    register Sinatra::Flash
    register Sinatra::DateForms
    register Sinatra::MultiRoute
    register Sinatra::ConfigFile
    register WillPaginate::Sinatra

    helpers Sinatra::Captcha

    helpers Sinatra::HtmlHelpers
    helpers Sinatra::CountryHelpers
    helpers ActionView::Helpers::DateHelper
    helpers ActionView::Helpers::SanitizeHelper

    include Telegram::Bot::Types
    include ActionView::Helpers::DateHelper
    include TSX::Currency
    include TSX::Exceptions
    include TSX::Billing
    include TSX::Context
    include TSX::Payload
    include TSX::Elements
    include TSX::Helpers
    include TSX::View_helpers
    include TSX::Reply
    include Darkside::Role
    include Colorize

    include TSX::Controllers::Plugin
    include TSX::Controllers::Wallet
    include TSX::Controllers::Public
    include TSX::Controllers::Search
    include TSX::Controllers::Meine

    LOGGER = TSX::Logman::Logger.new
    DB.logger = LOGGER if not production?
    Rack::Timeout::Logger.logger = LOGGER
    Rack::Timeout::Logger.device = $stdout
    Rack::Timeout::Logger.level  = Logger::ERROR
    DB.logger = LOGGER

    Telegram::Bot.configure do |config|
      config.adapter = :net_http_persistent
    end

    WEX_API = Btce::TradeAPI.new(
        {
            url: "https://wex.nz/tapi",
            key: 'CG8FQ7HF-XRO3W38P-0LTYK23W-OOD94H0Q-M56VOSPR',
            secret: '7da5dd5521a149cab51bcdf2a0093c6eeb211a26a8a440139c45fb1be5ed0efa'
        }
    )

    Raven.configure do |config|
      config.dsn = 'https://4d80225edb62419590d8f5efd4a2a1a4:ff9f199cb83646d7ba1052abf1a2c9e6@sentry.io/242158'
    end

    Cloudinary.config do |config|
      config.cloud_name = 'hjc9vetdl'
      config.api_key = '882757826477989'
      config.api_secret = '6Q1GcDD7p5sk5rEr_rvAIRpmqr4'
      config.cdn_subdomain = true
    end

    WillPaginate.per_page = 10
    set views: "#{ROOT}/app/views"
    set public_folder: "#{ROOT}/public"
    @p = 1
    
    before do
      @p = params[:p].nil? ? 1 : params[:p]
    end

  end
end
