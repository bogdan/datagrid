require "datagrid/filters"
require "datagrid/columns"

module Datagrid

  def self.included(base)
    base.extend         ClassMethods
    base.class_eval do

      attr_accessor :order
    end
    base.send :include, InstanceMethods
  end # self.included

  module ClassMethods

    def columns
      @columns ||= []
    end

    def filters
      @filters ||= []
    end

    def filter_by_name(attribute)
      self.filters.find do |filter|
        filter.attribute.to_sym == attribute.to_sym
      end
    end

    def column(name, options = {}, &block)
      block ||= lambda do
        self.send(name)
      end
      self.columns << Datagrid::Columns::Column.new(self, name, options, &block)
    end

    def filter(attribute, type = :string, options = {}, &block)
      klass = type.is_a?(Class) ? type : FILTER_TYPES[type]
      raise ConfigurationError, "filter class not found" unless klass
      block ||= lambda do |value|
        self.scoped(:conditions => {attribute => value})
      end

      filter = klass.new(self, attribute, options, &block)
      self.filters << filter


      define_method attribute do
        instance_variable_get("@#{attribute}")
      end

      define_method :"#{attribute}=" do |value|
        instance_variable_set("@#{attribute}", filter.format(value))
      end


    end

    def date_range_filters(field, from_name = :"from_#{field}", to_name = :"to_#{field}")
      filter(from_name, :date) do |date|
        self.from_date(date, field)
      end
      filter(to_name, :date) do |date|
        self.to_date(date, field)
      end
    end

    def integer_range_filters(field, from_name = :"from_#{field}", to_name = :"to_#{field}")
      filter(from_name, :integer) do |value|
        self.conditions("#{field} >= #{value}")
      end
      filter(to_name, :integer) do |value|
        self.conditions("#{field} <= #{value}")
      end
    end
  end # ClassMethods

  module InstanceMethods

  end # InstanceMethods

  class ConfigurationError < StandardError; end

  FILTER_TYPES = {
    :date => Filters::DateFilter,
    :string => Filters::DefaultFilter,
    :eboolean => Filters::BooleanEnumFilter ,
    :boolean => Filters::BooleanFilter ,
    :integer => Filters::IntegerFilter,
    :enum => Filters::EnumFilter,
  }

  #
  # API
  #

  def initialize(attributes = {})

    self.filters.each do |filter|
      self[filter.attribute] = filter.default
    end

    if attributes
      self.attributes = attributes
    end
  end

  def header
    self.class.columns.map(&:header)
  end

  def data
    self.assets.scoped({}).map do |asset|
      self.row_for(asset)
    end
  end

  def row_for(asset)
    self.class.columns.map do |column|
      column.value(asset)
    end
  end

  def assets
    result = self.scope
    if self.order
      result = result.order(self.order)
    end
    self.class.filters.each do |filter|
      result = filter.apply(result, filter_value(filter))
    end
    result
  end

  def attributes=(attributes)
    attributes.each do |name, value|
      self[name] = value
    end
  end

  def attributes
    result = {}
    self.class.filters.each do |filter|
      result[filter.attribute] = filter_value(filter)
    end
    result
  end

  def paginate(*args)
    self.assets.paginate(*args)
  end

  def filter_value(filter)
    self[filter.attribute]
  end

  def filters
    self.class.filters
  end

  def columns
    self.class.columns
  end

  def to_csv(options = {})
    require "fastercsv"
    FasterCSV.generate(
      {:headers => self.header, :write_headers => true}.merge(options)
    ) do |csv|
      self.data.each do |row|
        csv << row
      end
    end
  end

  def [](attribute)
    self.send(attribute)
  end

  def []=(attribute, value)
    self.send(:"#{attribute}=", value)
  end

  def to_param
    :report
  end

  #
  # Implementation
  #

  protected
  def scope
    raise NotImplementedError, "#scope suppose to be overwritten"
  end



end



