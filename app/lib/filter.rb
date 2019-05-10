module Darkside

  class Filter
      include TSX::Elements

      def initialize(instance, prev)
        @instance = instance
        @prev = prev
      end

      def russian
        @instance.russian
      end

      def prev
        @prev.russian.class.name.downcase
      end

      def buttons
        if !@instance.instance_of?(Country)
          return [button("Назад", 'back'), button("Главная", 'main')]
        end
        return nil
      end

  end

end