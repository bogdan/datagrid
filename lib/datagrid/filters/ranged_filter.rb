module Datagrid::Filters::RangedFilter
  

  def initialize(grid, name, options, &block)
    super(grid, name, options, &block)
    if range?
      options[:multiple] = true
    end
  end

  def parse_values(value)
    result = super(value)
    return result if !range? || result.nil?
    # Simulate single point range
    return result..result unless result.is_a?(Array)

    case result.size
    when 0
      nil
    when 1
      result.first
    when 2
      if result.first && result.last && result.first > result.last
        # If wrong range is given - reverse it to be always valid
        result.reverse
      else
        result
      end
    else
      raise ArgumentError, "Can not create a date range from array of more than two: #{result.inspect}"
    end

  end

  def range?
    options[:range]
  end

  def default_filter_where(scope, value)
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
      super(scope, value)
    end
  end


end
