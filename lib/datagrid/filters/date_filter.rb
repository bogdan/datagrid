class Datagrid::Filters::DateFilter < Datagrid::Filters::BaseFilter

  # ActiveRecord Postgresql adapter can not handle BC dates
  # https://github.com/rails/rails/pull/6245
  MIN_DATE = Date.new(0) + 1.year
  # PostgreSQL/MySQL don't want to accept bigger date
  # TODO: determine why
  MAX_DATE = Date.parse('9999-12-31')

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

  def range?
    options[:range]
  end
end

