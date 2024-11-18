# frozen_string_literal: true

module Datagrid
  extend ActiveSupport::Autoload

  autoload :Core
  autoload :ActiveModel
  autoload :Filters
  autoload :Columns
  autoload :ColumnNamesAttribute
  autoload :Ordering
  autoload :Configuration

  autoload :Helper
  autoload :FormBuilder

  autoload :Engine

  # Main datagrid class allowing to define columns and filters on your objects
  #
  # @example
  #   class UsersGrid < Datagrid::Base
  #     scope { User }
  #
  #     filter(:id, :integer)
  #     filter(:name, :string)
  #
  #     column(:id)
  #     column(:name)
  #   end
  class Base
    include ::Datagrid::Core
    include ::Datagrid::ActiveModel
    include ::Datagrid::Filters
    include ::Datagrid::Columns
    include ::Datagrid::ColumnNamesAttribute
    include ::Datagrid::Ordering
  end
end
