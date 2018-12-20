require_relative 'requires'
require 'hashids'
hashids = Hashids.new(TOKEN_SALT, 40, TOKEN_ALPHABET)
hash = hashids.encode(5, 223423423, 220347)
puts hash


