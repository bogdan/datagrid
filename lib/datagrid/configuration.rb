module Datagrid

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  class Configuration < Struct.new(:date_formats, :datetime_formats)
  end
end
