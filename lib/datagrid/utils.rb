module Datagrid
  module Utils
    class << self

      TRUTH = [true, 1, "1", "true", "yes", "on"]

      def booleanize(value)
        TRUTH.include?(value)
      end

      def warn_once(message)
        @warnings ||= {}
        if @warnings[message] 
          false
        else
          warn message
          @warnings[message] = true
        end
      end
    end
  end
end
