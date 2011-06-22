module Datagrid
  module Utils
    class << self

      TRUTH =["1", true, 1, "true", "yes"] 

      def booleanize(value)
        TRUTH.include?(value)
      end
    end
  end
end
