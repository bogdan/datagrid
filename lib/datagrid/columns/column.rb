
class Datagrid::Columns::Column

  attr_accessor :report, :options, :block, :name

  def initialize(report, name, options = {}, &block)
    self.report = report
    self.name = name
    self.options = options
    self.block = block
  end

  def value(object)
    value_for(object)
  end

  def value_for(object)
    object.instance_eval(&self.block)
  end

  def format
    self.options[:format]
  end

  def label
    self.options[:label]
  end

  def header
    self.options[:header] || 
      I18n.translate(self.name, :scope => "reports.#{self.report}.columns", :default => self.name.to_s.humanize )
  end

  def order
    if options.has_key?(:order)
      self.options[:order]
    else
      report.scope.column_names.include?(name.to_s) ? name : nil
    end
  end

  def desc_order
    order ? order.to_s + " DESC" : nil
  end

end
