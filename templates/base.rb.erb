class BaseGrid

  include Datagrid

  self.default_column_options = {
    # Uncomment to disable the default order
    # order: false,
    # Uncomment to make all columns HTML by default
    # html: true,
  }
  # Enable forbidden attributes protection
  # self.forbidden_attributes_protection = true

  # Makes a date column
  # @param name [Symbol] Column name
  # @param args [Array] Other column helper arguments
  # @example
  #   date_column(:created_at)
  #   date_column(:owner_registered_at) do |model|
  #     model.owner.registered_at
  #   end
  def self.date_column(name, *args, &block)
    column(name, *args) do |model|
      format(block ? block.call(model) : model.public_send(name)) do |date|
        date&.strftime("%m/%d/%Y") || "&mdash;".html_safe
      end
    end
  end

  # Makes a boolean YES/NO column
  # @param name [Symbol] Column name
  # @param args [Array] Other column helper arguments
  # @example
  #   boolean_column(:approved)
  #   boolean_column(:has_tasks, preload: :tasks) do |model|
  #     model.tasks.unfinished.any?
  #   end
  def self.boolean_column(name, *args, &block)
    column(name, *args) do |model|
      value = block ? block.call(model) : model.public_send(name)
      value ? "Yes" : "No"
    end
  end

end
