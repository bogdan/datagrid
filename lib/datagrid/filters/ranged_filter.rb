module RangedFilter
  
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
          (result.first || MIN_DATE)..(result.last || MAX_DATE)
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

  def minimum_value
    raise NotImplementedError, "#{self.class}#minimal_value suppose to be overwritten"
  end

  def maximum_value
    raise NotImplementedError, "#{self.class}#maximum_value suppose to be overwritten"
  end

end
