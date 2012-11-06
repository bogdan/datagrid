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

      def add_html_classes(options, *classes)
        options = options.clone
        options[:class] ||= ""
        if options[:class].is_a?(Array)
          options[:class] += classes
        else
          # suppose that it is a String
          options[:class] += " " unless options[:class].blank?
          options[:class] += classes.join(" ")
        end
        options
      end


    end
  end
end
