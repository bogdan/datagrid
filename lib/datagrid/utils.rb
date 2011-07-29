module Datagrid
  module Utils
    class << self

      TRUTH = [true, 1, "1", "true", "yes", "on"]

      def booleanize(value)
        TRUTH.include?(value)
      end
    end
  end
end
