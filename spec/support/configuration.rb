# frozen_string_literal: true

def with_date_format(format = "%m/%d/%Y")
  old_format = Datagrid.configuration.date_formats
  Datagrid.configure do |config|
    config.date_formats = format
  end
  yield
ensure
  Datagrid.configure do |config|
    config.date_formats = old_format
  end
end

def with_datetime_format(format = "%m/%d/%Y")
  old_format = Datagrid.configuration.datetime_formats
  Datagrid.configure do |config|
    config.datetime_formats = format
  end
  yield
ensure
  Datagrid.configure do |config|
    config.datetime_formats = old_format
  end
end
