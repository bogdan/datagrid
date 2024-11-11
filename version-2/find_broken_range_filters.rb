# Important in development to have all classes in memory
Rails.application.eager_load!

raise "Use version 2" if Datagrid::VERSION < "2.0.0"

included_classes = ObjectSpace.each_object(Class).select do |klass|
  klass.included_modules.include?(Datagrid)
end

base_subclasses = ObjectSpace.each_object(Class).select do |klass|
  klass < Datagrid::Base
end
classes = [*included_classes, *base_subclasses].uniq

classes.flat_map(&:filters).select do |f|
  f.respond_to?(:range?) && f.range? && f.block
end.map do |f|
  [f.grid_class, f.name].join("#")
end
