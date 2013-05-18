def with_date_format(format = "%m/%d/%Y")
  begin
    Datagrid.configure do |config|
      config.date_formats = format
    end
    yield
  ensure
    Datagrid.configure do |config|
      config.date_formats = nil
    end
  end
end
