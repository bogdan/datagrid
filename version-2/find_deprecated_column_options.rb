# frozen_string_literal: true

# Important in development to have all classes in memory
Rails.application.eager_load!

included_classes = ObjectSpace.each_object(Class).select do |klass|
  klass.included_modules.include?(Datagrid)
end

base_subclasses = ObjectSpace.each_object(Class).select do |klass|
  klass < Datagrid::Base
end
classes = [*included_classes, *base_subclasses].uniq

classes.flat_map(&:columns).select do |f|
  f.options[:url] || f.options[:class]
end.map do |f|
  [f.grid_class, f.name].join("#")
end
