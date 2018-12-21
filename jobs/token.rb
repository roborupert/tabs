require_relative 'requires'
require 'hashids'
hashids = Hashids.new(TOKEN_SALT, 40, TOKEN_ALPHABET)
hash = hashids.encode(5, 2234238234, 279260)
puts hash


