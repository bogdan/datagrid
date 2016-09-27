def with_date_format(format = "%m/%d/%Y")
  begin
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
end

def with_datetime_format(format = "%m/%d/%Y")
  begin
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
end

def with_raw_csv_headers
  begin
    old_value = Datagrid.configuration.raw_csv_headers
    Datagrid.configure do |config|
      config.raw_csv_headers = true
    end
    yield
  ensure
    Datagrid.configure do |config|
      config.raw_csv_headers = old_value
    end
  end
end
