module TSX
  module Referals

    def self.progress(game)
      "#{game.conf('counter')} перешли по ссылке."
    end

    def winner
      nil
    end

  end
end