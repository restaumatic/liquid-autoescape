module Liquid
  module Autoescape
    class SafeString < String
      def self.mark_safe(str)
        if self.is_safe? str
          return str
        else
          if !str.is_a?(String)
            raise str
          end
          return self.new(str)
        end
      end

      def self.is_safe?(str)
        str.is_a? SafeString
      end

      def to_s
        self
      end
    end
  end
end
