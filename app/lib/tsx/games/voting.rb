module TSX
    module Voting

      def self.progress(game)
        "#{game.conf('counter')} раз проголосовано."
      end

      def winner
        Vote::best_this_month
      end

    end
end