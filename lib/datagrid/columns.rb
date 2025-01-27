# frozen_string_literal: true

require "datagrid/utils"
require "active_support/core_ext/class/attribute"
require "datagrid/columns/column"

module Datagrid
  # Defines a column to be used for displaying data in a Datagrid.
  #
  #     class UserGrid < ApplicationGrid
  #       scope do
  #         User.order("users.created_at desc").joins(:group)
  #       end
  #
  #       column(:name)
  #       column(:group, order: "groups.name") do
  #         self.group.name
  #       end
  #       column(:active, header: "Activated") do |user|
  #         !user.disabled
  #       end
  #     end
  #
  # Each column is used to generate data for the grid.
  #
  # To create a grid displaying all users:
  #
  #     grid = UserGrid.new
  #     grid.header    # => ["Group", "Name", "Disabled"]
  #     grid.rows      # => [
  #                    #      ["Steve", "Spammers", true],
  #                    #      ["John", "Spoilers", true],
  #                    #      ["Berry", "Good people", false]
  #                    #    ]
  #     grid.data      # => Header & Rows
  #     grid.data_hash # => [
  #                    #      { name: "Steve", group: "Spammers", active: true },
  #                    #      { name: "John", group: "Spoilers", active: true },
  #                    #      { name: "Berry", group: "Good people", active: false },
  #                    #    ]
  #     }
  #
  # ## Column Value
  #
  # The value of a column can be defined by passing a block to `Datagrid.column`.
  #
  # ### Basic Column Value
  #
  # If no block is provided, the column value is generated automatically by sending the column name method to the model.
  #
  #     column(:name) # => asset.name
  #
  # Using <tt>instance_eval</tt>:
  #
  #     column(:completed) { completed? }
  #
  # Using the asset as an argument:
  #
  #     column(:completed) { |asset| asset.completed? }
  #
  # ### Advanced Column Value
  #
  # You can also pass the Datagrid object itself to define more complex column values.
  #
  # Using filters with columns:
  #
  #     filter(:category) do |value|
  #       where("category LIKE '%#{value}%'")
  #     end
  #
  #     column(:exactly_matches_category) do |asset, grid|
  #       asset.category == grid.category
  #     end
  #
  # Combining columns:
  #
  #     column(:total_sales) do |merchant|
  #       merchant.purchases.sum(:subtotal)
  #     end
  #     column(:number_of_sales) do |merchant|
  #       merchant.purchases.count
  #     end
  #     column(:average_order_value) do |_, _, row|
  #       row.total_sales / row.number_of_sales
  #     end
  #
  # ## Using Database Expressions
  #
  # Columns can use database expressions to directly manipulate data in the database.
  #
  #     column(:count_of_users, 'count(user_id)')
  #     column(:uppercase_name, 'upper(name)')
  #
  # ## HTML Columns
  #
  # Columns can have different formats for HTML and non-HTML representations.
  #
  #     column(:name) do |asset|
  #       format(asset.name) do |value|
  #         content_tag(:strong, value)
  #       end
  #     end
  #
  # ## Column Value Cache
  #
  # Enables grid-level caching for column values.
  #
  #     self.cached = true
  #
  # ## Ordering
  #
  # Columns can specify SQL ordering expressions using the `:order` and `:order_desc` options.
  #
  # Basic ordering:
  #
  #     column(:group_name, order: "groups.name") { self.group.name }
  #
  # In example above descending order is automatically inherited from ascending order specified.
  # When such default is not enough, specify both options together:
  #
  #     column(
  #       :priority,
  #       # models with null priority are always on bottom
  #       # no matter if sorting ascending or descending
  #       order: "priority is not null desc, priority",
  #       order_desc: "priority is not null desc, priority desc"
  #     )
  #
  # Disable order like this:
  #
  #     column(:title, order: false)
  #
  # Order by joined table
  # Allows to join specified table only when order is enabled
  # for performance:
  #
  #     column(:profile_updated_at, order: proc { |scope|
  #       scope.joins(:profile).order("profiles.updated_at")
  #     }) do |model|
  #       model.profile.updated_at.to_date
  #     end
  #
  # Order by a calculated value
  #
  #     column(
  #       :duration_request,
  #       order: "(requests.finished_at - requests.accepted_at)"
  #     ) do |model|
  #       Time.at(model.finished_at - model.accepted_at).strftime("%H:%M:%S")
  #     end
  #
  # ## Default Column Options
  #
  # Default options for all columns in a grid can be set using `default_column_options`.
  #
  #     self.default_column_options = { order: false }
  #
  # It can also accept a proc with the column instance as an argument:
  #
  #     self.default_column_options = ->(column) { { order: column.name == :id } }
  #
  # ## Columns Visibility
  #
  # Columns can be dynamically shown or hidden based on the grid's `column_names` accessor.
  #
  #     grid.column_names = [:id, :name]
  #
  # ## Dynamic Columns
  #
  # Columns can be defined dynamically on a grid instance or based on data.
  #
  # Adding a dynamic column:
  #
  #     grid.column(:extra_data) do |model|
  #       model.extra_data
  #     end
  #
  # ## Localization
  #
  # Column headers can be localized using the `:header` option or through i18n files.
  #
  #     column(:active, header: Proc.new { I18n.t("activated") })
  #
  # ## Preloading Associations
  #
  # Preload database associations for better performance.
  #
  # Automatic association preloading:
  #
  #     column(:group) do |user|
  #       user.group.name
  #     end
  #
  # Custom preloading:
  #
  #     column(:account_name, preload: { |s| s.includes(:account) })
  #
  # ## Decorator
  #
  # A decorator or presenter class can be used around each object in the `scope`.
  #
  #     decorate { UserPresenter }
  #     column(:created_at) do |presenter|
  #       presenter.user.created_at
  #     end
  module Columns
    # @!method default_column_options=(value)
    #   @param [Hash,Proc] value default options passed to {#column} method call.
    #     When a proc is passed, it will be called with the column instance as an argument,
    #     and expected to produce the options hash.
    #   @return [Hash,Proc] default options passed to {#column} method call, or a proc that returns them.
    #   @example Disable default order
    #     self.default_column_options = { order: false }
    #   @example Makes entire report HTML
    #     self.default_column_options = { html: true }
    #   @example Set the default header for all columns
    #     self.default_column_options = ->(column) { { header: I18n.t(column.name, scope: 'my_scope.columns') } }

    # @!method default_column_options
    #   @return [Hash,Proc] default options passed to {#column} method call, or a proc that returns them.
    #   @see #default_column_options=

    # @!method batch_size=(value)
    #   Specify a default batch size when generating CSV or just data.
    #   @param [Integer] value a batch size when generating CSV or just data. Default: 1000
    #   @return [void]
    #   @example Set batch size to 500
    #     self.batch_size = 500
    #   @example Disable batches
    #     self.batch_size = nil

    # @!method batch_size
    #   @return [Integer]
    #   @see #batch_size=

    # @visibility private
    # @param [Object] base
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        include Datagrid::Core

        class_attribute :default_column_options, instance_writer: false, default: {}
        class_attribute :batch_size, default: 1000
        class_attribute :columns_array, default: []
        class_attribute :cached, default: false
        class_attribute :decorator, instance_writer: false
      end
    end

    module ClassMethods
      # @param data [Boolean] if true returns only columns with data representation. Default: false.
      # @param html [Boolean] if true returns only columns with html columns. Default: false.
      # @param column_names [Array<String>] list of column names if you want to limit data only to specified columns
      # @return [Array<Datagrid::Columns::Column>] column definition objects
      # @example
      #   GridClass.columns(:id, :name)
      def columns(*column_names, data: false, html: false)
        filter_columns(columns_array, *column_names, data: data, html: html)
      end

      # Defines a new datagrid column
      # @param name [Symbol] column name
      # @param query [String, nil] a string representing the query to select this column (supports only ActiveRecord)
      # @param block [Block] proc to calculate a column value
      # @option options [Boolean, String] html Determines if the column should be present
      #   in the HTML table and how it is formatted.
      # @option options [String, Array<Symbol>] order Determines if the column can be sortable and
      #   specifies the ORM ordering method.
      #   Example: `"created_at, id"` for ActiveRecord, `[:created_at, :id]` for Mongoid.
      # @option options [String] order_desc Specifies a descending order for the column
      #   (used when `:order` cannot be easily reversed by the ORM).
      # @option options [Boolean, Proc] order_by_value Enables Ruby-level ordering for the column.
      #   Warning: Sorting large datasets in Ruby is not recommended.
      #   If `true`, Datagrid orders by the column value.
      #   If a block is provided, Datagrid orders by the block's return value.
      # @option options [Boolean] mandatory If `true`, the column will never be hidden by the `#column_names` selection.
      # @option options [Symbol] before Places the column before the specified column when determining order.
      # @option options [Symbol] after Places the column after the specified column when determining order.
      # @option options [Boolean, Proc] if conditions when a column is available.
      # @option options [Boolean, Proc] unless conditions when a column is not available.
      # @option options [Symbol, Array<Symbol>] preload Specifies associations
      #   to preload for the column within the scope.
      # @option options [Hash] tag_options Specifies HTML attributes for the `<td>` or `<th>` of the column.
      #   Example: `{ class: "content-align-right", "data-group": "statistics" }`.
      # @return [Datagrid::Columns::Column]
      def column(name, query = nil, **options, &block)
        define_column(columns_array, name, query, **options, &block)
      end

      # Returns column definition with given name
      # @return [Datagrid::Columns::Column, nil]
      def column_by_name(name)
        find_column_by_name(columns_array, name)
      end

      # Returns an array of all defined column names
      # @return [Array<Datagrid::Columns::Column>]
      def column_names
        columns.map(&:name)
      end

      # @!visibility private
      def respond_to(&block)
        Datagrid::Columns::Column::ResponseFormat.new(&block)
      end

      # Formats column value for HTML.
      # Helps to distinguish formatting as plain data and HTML
      # @param value [Object] Value to be formatted
      # @return [Datagrid::Columns::Column::ResponseFormat] Format object
      # @example
      #   column(:name) do |model|
      #     format(model.name) do |value|
      #       tag.strong(value)
      #     end
      #   end
      def format(value, &block)
        if block_given?
          respond_to do |f|
            f.data { value }
            f.html do
              instance_exec(value, &block)
            end
          end
        else
          # Ruby Object#format exists.
          # We don't want to change the behaviour and overwrite it.
          super
        end
      end

      # Defines a model decorator that will be used to define a column value.
      # All column blocks will be given a decorated version of the model.
      # @return [void]
      # @example Wrapping a model with presenter
      #   decorate { |user| UserPresenter.new(user) }
      # @example A shortcut for doing the same
      #   decorate { UserPresenter }
      def decorate(model = nil, &block)
        if !model && !block
          raise ArgumentError, "decorate needs either a block to define decoration or a model to decorate"
        end
        return self.decorator = block unless model
        return model unless decorator

        presenter = ::Datagrid::Utils.apply_args(model, &decorator)
        presenter = presenter.new(model) if presenter.is_a?(Class)
        block_given? ? yield(presenter) : presenter
      end

      # @!visibility private
      def inherited(child_class)
        super
        child_class.columns_array = columns_array.clone
      end

      # @!visibility private
      def filter_columns(columns_array, *names, data: false, html: false)
        names.compact!
        if names.size >= 1 && names.all? { |n| n.is_a?(Datagrid::Columns::Column) && n.grid_class == self.class }
          return names
        end

        names.map!(&:to_sym)
        columns_array.select do |column|
          (!data || column.data?) &&
            (!html || column.html?) &&
            (column.mandatory? || names.empty? || names.include?(column.name))
        end
      end

      # @!visibility private
      def define_column(columns, name, query = nil, **options, &block)
        check_scope_defined!("Scope should be defined before columns")
        block ||= lambda do |model|
          model.public_send(name)
        end

        position = Datagrid::Utils.extract_position_from_options(columns, options)
        column = Datagrid::Columns::Column.new(
          self, name, query, options, &block
        )
        columns.insert(position, column)
        column
      end

      # @!visibility private
      def find_column_by_name(columns, name)
        return name if name.is_a?(Datagrid::Columns::Column)

        columns.find do |col|
          col.name.to_sym == name.to_sym
        end
      end
    end

    # @!visibility private
    def assets
      append_column_preload(
        driver.append_column_queries(
          super, columns.select(&:query),
        ),
      )
    end

    # @param column_names [Array<String, Symbol>] list of column names
    #   if you want to limit data only to specified columns
    # @return [Array<String>] human readable column names. See also "Localization" section
    def header(*column_names)
      data_columns(*column_names).map(&:header)
    end

    # @param asset [Object] asset from datagrid scope
    # @param column_names [Array<String, Symbol>] list of column names
    #   if you want to limit data only to specified columns
    # @return [Array<Object>] column values for given asset
    def row_for(asset, *column_names)
      data_columns(*column_names).map do |column|
        data_value(column, asset)
      end
    end

    # @param asset [Object] asset from datagrid scope
    # @return [Hash] A mapping where keys are column names and
    #   values are column values for the given asset
    def hash_for(asset)
      result = {}
      data_columns.each do |column|
        result[column.name] = data_value(column, asset)
      end
      result
    end

    # @param column_names [Array<String,Symbol>] list of column names
    #   if you want to limit data only to specified columns
    # @return [Array<Array<Object>>] with data for each row in datagrid assets without header
    def rows(*column_names)
      map_with_batches do |asset|
        row_for(asset, *column_names)
      end
    end

    # @param column_names [Array<String, Symbol>] list of column names
    #   if you want to limit data only to specified columns.
    # @return [Array<Array<Object>>] data for each row in datagrid assets with header.
    def data(*column_names)
      rows(*column_names).unshift(header(*column_names))
    end

    # @return [Array<Hash{Symbol => Object}>] an array of hashes representing the rows in the filtered datagrid relation
    #
    # @example
    #   class MyGrid
    #     scope { Model }
    #     column(:id)
    #     column(:name)
    #   end
    #
    #   Model.create!(name: "One")
    #   Model.create!(name: "Two")
    #
    #   MyGrid.new.data_hash # => [{name: "One"}, {name: "Two"}]
    def data_hash
      map_with_batches do |asset|
        hash_for(asset)
      end
    end

    # @param column_names [Array<String,Symbol>]
    # @param options [Hash] CSV generation options
    # @return [String] a CSV representation of the data in the grid
    #
    # @example
    #   grid.to_csv
    #   grid.to_csv(:id, :name)
    #   grid.to_csv(col_sep: ';')
    def to_csv(*column_names, **options)
      require "csv"
      CSV.generate(
        headers: header(*column_names),
        write_headers: true,
        **options,
      ) do |csv|
        each_with_batches do |asset|
          csv << row_for(asset, *column_names)
        end
      end
    end

    # @param column_names [Array<Symbol, String>]
    # @param [Boolean] data return only data columns
    # @param [Boolean] html return only HTML columns
    # @return [Array<Datagrid::Columns::Column>] all columns selected in grid instance
    # @example
    #   MyGrid.new.columns # => all defined columns
    #   grid = MyGrid.new(column_names: [:id, :name])
    #   grid.columns # => id and name columns
    #   grid.columns(:id, :category) # => id and category column
    def columns(*column_names, data: false, html: false)
      self.class.filter_columns(
        columns_array, *column_names, data: data, html: html,
      ).select do |column|
        column.enabled?(self)
      end
    end

    # @param column_names [Array<String, Symbol>] list of column names
    #   if you want to limit data only to specified columns
    # @param [Boolean] html return only HTML columns
    # @return [Array<Datagrid::Columns::Column>] columns that can be represented in plain data(non-html) way
    def data_columns(*column_names, html: false)
      columns(*column_names, html: html, data: true)
    end

    # @param column_names [Array<String>] list of column names if you want to limit data only to specified columns
    # @param [Boolean] data return only data columns
    # @return all columns that can be represented in HTML table
    def html_columns(*column_names, data: false)
      columns(*column_names, data: data, html: true)
    end

    # Finds a column by name
    # @param name [String, Symbol] column name to be found
    # @return [Datagrid::Columns::Column, nil]
    def column_by_name(name)
      self.class.find_column_by_name(columns_array, name)
    end

    # Gives ability to have a different formatting for CSV and HTML column value.
    # @example Formating using Rails view helpers
    #   column(:name) do |model|
    #     format(model.name) do |value|
    #       tag.strong(value)
    #     end
    #   end
    # @example Formatting using a separated view template
    #   column(:company) do |model|
    #     format(model.company.name) do
    #       render partial: "companies/company_with_logo", locals: {company: model.company }
    #     end
    #   end
    # @return [Datagrid::Columns::Column::ResponseFormat] Format object
    def format(value, &block)
      if block
        self.class.format(value, &block)
      else
        # don't override Object#format method
        super
      end
    end

    # @param [Object] asset one of the assets from grid scope
    # @return [Datagrid::Columns::DataRow] an object representing a grid row.
    # @example
    #   class MyGrid
    #     scope { User }
    #     column(:id)
    #     column(:name)
    #     column(:number_of_purchases) do |user|
    #       user.purchases.count
    #     end
    #   end
    #
    #   row = MyGrid.new.data_row(User.last)
    #   row.id # => user.id
    #   row.number_of_purchases # => user.purchases.count
    def data_row(asset)
      ::Datagrid::Columns::DataRow.new(self, asset)
    end

    # Defines a column at instance level
    # @see Datagrid::Columns::ClassMethods#column
    def column(name, query = nil, **options, &block)
      self.class.define_column(columns_array, name, query, **options, &block)
    end

    # @!visibility private
    def initialize(*)
      self.columns_array = self.class.columns_array.clone
      super
    end

    # @return [Array<Datagrid::Columns::Column>] all columns
    #   that are possible to be displayed for the current grid object
    # @example
    #   class MyGrid
    #     filter(:search) {|scope, value| scope.full_text_search(value)}
    #     column(:id)
    #     column(:name, mandatory: true)
    #     column(:search_match, if: proc {|grid| grid.search.present? }) do |model, grid|
    #       search_match_line(model.searchable_content, grid.search)
    #     end
    #   end
    #
    #   grid = MyGrid.new
    #   grid.columns # => [ #<Column:name> ]
    #   grid.available_columns # => [ #<Column:id>, #<Column:name> ]
    #   grid.search = "keyword"
    #   grid.available_columns # => [ #<Column:id>, #<Column:name>, #<Column:search_match> ]
    def available_columns
      columns_array.select do |column|
        column.enabled?(self)
      end
    end

    # @param [String,Symbol] column_name column name
    # @param [Object] asset one of the assets from grid scope
    # @return [Object] a cell data value for given column name and asset
    def data_value(column_name, asset)
      column = column_by_name(column_name)
      cache(column, asset, :data_value) do
        raise "no data value for #{column.name} column" unless column.data?

        result = generic_value(column, asset)
        result.is_a?(Datagrid::Columns::Column::ResponseFormat) ? result.call_data : result
      end
    end

    # @param [String,Symbol] column_name column name
    # @param [Object] asset one of the assets from grid scope
    # @param [ActionView::Base] context view context object
    # @return [Object] a cell HTML value for given column name and asset and view context
    def html_value(column_name, context, asset)
      column = column_by_name(column_name)
      cache(column, asset, :html_value) do
        if column.html? && column.html_block
          value_from_html_block(context, asset, column)
        else
          result = generic_value(column, asset)
          result.is_a?(Datagrid::Columns::Column::ResponseFormat) ? result.call_html(context) : result
        end
      end
    end

    # @param [Object] model one of the assets from grid scope
    # @return [Object] a decorated version of given model if decorator is specified or the model otherwise.
    def decorate(model)
      self.class.decorate(model)
    end

    # @!visibility private
    def generic_value(column, model)
      cache(column, model, :generic_value) do
        presenter = decorate(model)
        unless column.enabled?(self)
          raise Datagrid::ColumnUnavailableError, "Column #{column.name} disabled for #{inspect}"
        end

        if column.data_block.arity >= 1
          Datagrid::Utils.apply_args(presenter, self, data_row(model), &column.data_block)
        else
          presenter.instance_eval(&column.data_block)
        end
      end
    end

    # @!visibility private
    def reset
      super
      @cache = {}
    end

    protected

    def append_column_preload(relation)
      columns.inject(relation) do |current, column|
        column.append_preload(current)
      end
    end

    def cache(column, asset, type)
      @cache ||= {}
      unless cached?
        @cache.clear
        return yield
      end
      key = cache_key(asset)
      raise(Datagrid::CacheKeyError, "Datagrid Cache key is #{key.inspect} for #{asset.inspect}.") unless key

      @cache[column.name] ||= {}
      @cache[column.name][key] ||= {}
      @cache[column.name][key][type] ||= yield
    end

    def cache_key(asset)
      if cached.respond_to?(:call)
        cached.call(asset)
      else
        driver.default_cache_key(asset)
      end
    rescue NotImplementedError
      raise Datagrid::ConfigurationError,
        <<~MSG
          #{self} is setup to use cache. But there was appropriate cache key found for #{asset.inspect}.
        MSG
    end

    def map_with_batches(&block)
      result = []
      each_with_batches do |asset|
        result << block.call(asset)
      end
      result
    end

    def each_with_batches(&block)
      if batch_size&.positive?
        driver.batch_each(assets, batch_size, &block)
      else
        assets.each(&block)
      end
    end

    def value_from_html_block(context, asset, column)
      args = []
      remaining_arity = column.html_block.arity
      remaining_arity = 1 if remaining_arity.negative?

      asset = decorate(asset)

      if column.data?
        args << data_value(column, asset)
        remaining_arity -= 1
      end

      args << asset if remaining_arity.positive?
      args << self if remaining_arity > 1

      context.instance_exec(*args, &column.html_block)
    end

    # Object representing a single row of data when building a datagrid table
    # @see Datagrid::Columns#data_row
    class DataRow < BasicObject
      def initialize(grid, model)
        @grid = grid
        @model = model
      end

      def method_missing(meth, *_args)
        @grid.data_value(meth, @model)
      end

      def respond_to_missing?(meth, include_private = false)
        !!@grid.column_by_name(meth) || super
      end
    end
  end
end
