module TSX
  module Controllers
    module Public

      def welcome(data = nil)
        handle('welcome')
        if !data.nil?
          reply_update "welcome/#{data}"
        else
          reply_inline "welcome/contact_info"
        end
      end

      def info
        # if File.exists?("#{ROOT}/public/images/avatars/#{@tsx_bot.id}.jpg")
          reply_picture "avatars/tab.jpg", "#{@tsx_bot.pure_nickname}\n\n#{@tsx_bot.description}"
        # end
      end

      def prices
        reply_simple 'welcome/prices'
      end

      def not_permitted
        reply_simple 'welcome/not_permitted'
        [200, {}, ['']]
        halt
      end

      def help
        reply_simple 'welcome/help'
      end

      def payments
        reply_simple 'welcome/payments'
      end

      def easypaysample
        reply_picture 'easy_sample.jpg', 'Easypay sample'
      end

      def rules
        reply_simple 'welcome/rules'
      end

      def jobs
        reply_simple 'welcome/jobs'
      end

      def welcome_bots
        reply_simple 'welcome/bots'
      end

      def cashout
        reply_simple 'welcome/cashout'
      end

    end
  end
end