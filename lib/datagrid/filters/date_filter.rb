class Datagrid::Filters::DateFilter < Datagrid::Filters::BaseFilter

  def initialize(grid, name, options, &block)
    super(grid, name, options, &block)
    if range?
      options[:multiple] = true
    end
  end

  def apply(grid_object, scope, value)
    if value.is_a?(Range)
      value = value.first.beginning_of_day..value.last.end_of_day
    end
    super(grid_object, scope, value)
  end

  def format(value)
    return nil if value.blank?
    return value if value.is_a?(Range)
    return value.to_date if value.respond_to?(:to_date)
    return value unless value.is_a?(String)
    #TODO: more smart date normalizer
    Date.parse(value)
  rescue ArgumentError
    nil
  end

  def format_values(value)
    result = super(value)
    if range? 
      if result.is_a?(Array)
        case result.size
        when 0
          nil
        when 1
          result.first
        when 2
          result
        else
          raise ArgumentError, "Can not create a date range from array of more than two: #{result.inspect}"
        end
      else
        # Simulate single point range
        result..result
      end

    else
      result
    end
  end

  def range?
    options[:range]
  end

  def default_filter_where(driver, scope, value)
    if range? && value.is_a?(Array)
      left, right = value
      if left
        scope = driver.greater_equal(scope, name, left)
      end
      if right
        scope = driver.less_equal(scope, name, right)
      end
      scope
    else 
      super(driver, scope, value)
    end
  end
end

