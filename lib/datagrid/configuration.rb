module Datagrid

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  # Datagrid configuration object
  class Configuration
    # @return [Array<String>] Date parsing formats
    attr_accessor :date_formats
    # @return [Array<String>] Timestamp parsing formats
    attr_accessor :datetime_formats
  end
end
