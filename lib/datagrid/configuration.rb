# frozen_string_literal: true

module Datagrid
  # ## Configuration
  #
  # Datagrid provides several configuration options.
  #
  # Here is the API reference and a description of the available options:
  #
  # ``` ruby
  # Datagrid.configure do |config|
  #   # Defines date formats that can be used to parse dates.
  #   # Note: Multiple formats can be specified. The first format is used to format dates as strings,
  #   # while other formats are used only for parsing dates from strings (e.g., if your app supports multiple formats).
  #   config.date_formats = ["%m/%d/%Y", "%Y-%m-%d"]
  #
  #   # Defines timestamp formats that can be used to parse timestamps.
  #   # Note: Multiple formats can be specified. The first format is used to format timestamps as strings,
  #   # while other formats are used only for parsing timestamps from strings (e.g., if your app supports multiple formats).
  #   config.datetime_formats = ["%m/%d/%Y %h:%M", "%Y-%m-%d %h:%M:%s"]
  # end
  # ```
  #
  # These options can be set globally in your application to customize Datagrid’s behavior.
  class Configuration
    # @return [Array<String>] Date parsing formats
    attr_accessor :date_formats
    # @return [Array<String>] Timestamp parsing formats
    attr_accessor :datetime_formats
  end
end
