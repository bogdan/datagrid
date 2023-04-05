require "datagrid/utils"
require "active_support/core_ext/class/attribute"

module Datagrid

  module Columns
    require "datagrid/columns/column"

    # @!method default_column_options=
    # @param value [Hash] default options passed to #column method call
    # @return [Hash] default options passed to #column method call
    # @example
    #   # Disable default order
    #   self.default_column_options = { order: false }
    #   # Makes entire report HTML
    #   self.default_column_options = { html: true }

    # @!method default_column_options
    # @return [Hash]
    # @see #default_column_options=

    # @!method batch_size=
    # @param value [Integer] Specify a default batch size when generating CSV or just data. Default: 1000
    # @return [Integer] Specify a default batch size when generating CSV or just data.
    # @example
    #   self.batch_size = 500
    #   # Disable batches
    #   self.batch_size = nil
    #

    # @!method batch_size
    # @return [Integer]
    # @see #batch_size=

    # @visibility private
    def self.included(base)
      base.extend         ClassMethods
      base.class_eval do
        include Datagrid::Core

        class_attribute :default_column_options, instance_writer: false, default: {}
        class_attribute :batch_size, default: 1000
        class_attribute :columns_array, default: []
        class_attribute :cached, default: false
        class_attribute :decorator, instance_writer: false
      end
      base.include InstanceMethods
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

      # Defines new datagrid column
      #
      # @param name [Symbol] column name
      # @param query [String, nil] a string representing the query to select this column (supports only ActiveRecord)
      # @param options [Hash<Symbol, Object>] hash of options
      # @param block [Block] proc to calculate a column value
      # @return [Datagrid::Columns::Column]
      #
      # Available options:
      #
      # * <tt>html</tt> - determines if current column should be present in html table and how is it formatted
      # * <tt>order</tt> - determines if this column could be sortable and how.
      #   The value of order is explicitly passed to ORM ordering method.
      #   Ex: <tt>"created_at, id"</tt> for ActiveRecord, <tt>[:created_at, :id]</tt> for Mongoid
      # * <tt>order_desc</tt> - determines a descending order for given column
      #   (only in case when <tt>:order</tt> can not be easily reversed by ORM)
      # * <tt>order_by_value</tt> - used in case it is easier to perform ordering at ruby level not on database level.
      #   Warning: using ruby to order large datasets is very unrecommended.
      #   If set to true - datagrid will use column value to order by this column
      #   If block is given - datagrid will use value returned from block
      # * <tt>mandatory</tt> - if true, column will never be hidden with #column_names selection
      # * <tt>url</tt> - a proc with one argument, pass this option to easily convert the value into an URL
      # * <tt>before</tt> - determines the position of this column, by adding it before the column passed here
      # * <tt>after</tt> - determines the position of this column, by adding it after the column passed here
      # * <tt>if</tt> - the column is shown if the reult of calling this argument is true
      # * <tt>unless</tt> - the column is shown unless the reult of calling this argument is true
      # * <tt>preload</tt> - spefies which associations of the scope should be preloaded for this column
      #
      # @see https://github.com/bogdan/datagrid/wiki/Columns
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
      #       content_tag(:strong, value)
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
      # @example
      #   decorate { |user| UserPresenter.new(user) }
      #
      #   decorate { UserPresenter } # a shortcut
      def decorate(model = nil, &block)
        if !model && !block
          raise ArgumentError, "decorate needs either a block to define decoration or a model to decorate"
        end
        return self.decorator = block unless model
        return model unless decorator
        presenter = ::Datagrid::Utils.apply_args(model, &decorator)
        presenter = presenter.is_a?(Class) ?  presenter.new(model) : presenter
        block_given? ? yield(presenter) : presenter
      end

      # @!visibility private
      def inherited(child_class)
        super(child_class)
        child_class.columns_array = self.columns_array.clone
      end

      # @!visibility private
      def filter_columns(columns_array, *names, data: false, html: false)
        names.compact!
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
          model.send(name)
        end
        position = Datagrid::Utils.extract_position_from_options(columns, options)
        column = Datagrid::Columns::Column.new(
          self, name, query, default_column_options.merge(options), &block
        )
        columns.insert(position, column)
        column
      end

      # @!visibility private
      def find_column_by_name(columns,name)
        return name if name.is_a?(Datagrid::Columns::Column)
        columns.find do |col|
          col.name.to_sym == name.to_sym
        end
      end

    end

    module InstanceMethods

      # @!visibility private
      def assets
        append_column_preload(
          driver.append_column_queries(
            super, columns.select(&:query)
          )
        )
      end

      # @param column_names [Array<String>] list of column names if you want to limit data only to specified columns
      # @return [Array<String>] human readable column names. See also "Localization" section
      def header(*column_names)
        data_columns(*column_names).map(&:header)
      end

      # @param asset [Object] asset from datagrid scope
      # @param column_names [Array<String>] list of column names if you want to limit data only to specified columns
      # @return [Array<Object>] column values for given asset
      def row_for(asset, *column_names)
        data_columns(*column_names).map do |column|
          data_value(column, asset)
        end
      end

      # @param asset [Object] asset from datagrid scope
      # @return [Hash] A mapping where keys are column names and values are column values for the given asset
      def hash_for(asset)
        result = {}
        self.data_columns.each do |column|
          result[column.name] = data_value(column, asset)
        end
        result
      end

      # @param column_names [Array<String>] list of column names if you want to limit data only to specified columns
      # @return [Array<Array<Object>>] with data for each row in datagrid assets without header
      def rows(*column_names)
        map_with_batches do |asset|
          self.row_for(asset, *column_names)
        end
      end

      # @param column_names [Array<String>] list of column names if you want to limit data only to specified columns
      # @return [Array<Array<Object>>] data for each row in datagrid assets with header.
      def data(*column_names)
        self.rows(*column_names).unshift(self.header(*column_names))
      end

      # Return Array of Hashes where keys are column names and values are column values
      # for each row in filtered datagrid relation.
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

      # @param column_names [Array<String>]
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
          headers: self.header(*column_names),
          write_headers: true,
          **options
        ) do |csv|
          each_with_batches do |asset|
            csv << row_for(asset, *column_names)
          end
        end
      end


      # @param column_names [Array<Symbol, String>]
      # @return [Array<Datagrid::Columns::Column>] all columns selected in grid instance
      # @example
      #   MyGrid.new.columns # => all defined columns
      #   grid = MyGrid.new(column_names: [:id, :name])
      #   grid.columns # => id and name columns
      #   grid.columns(:id, :category) # => id and category column
      def columns(*column_names, data: false, html: false)
        self.class.filter_columns(
          columns_array, *column_names, data: data, html: html
        ).select do |column|
          column.enabled?(self)
        end
      end

      # @param column_names [Array<String, Symbol>] list of column names if you want to limit data only to specified columns
      # @return columns that can be represented in plain data(non-html) way
      def data_columns(*column_names, **options)
        self.columns(*column_names, **options, data: true)
      end

      # @param column_names [Array<String>] list of column names if you want to limit data only to specified columns
      # @return all columns that can be represented in HTML table
      def html_columns(*column_names, **options)
        self.columns(*column_names, **options, html: true)
      end

      # Finds a column definition by name
      # @param name [String, Symbol] column name to be found
      # @return [Datagrid::Columns::Column, nil]
      def column_by_name(name)
        self.class.find_column_by_name(columns_array, name)
      end

      # Gives ability to have a different formatting for CSV and HTML column value.
      #
      # @example
      #   column(:name) do |model|
      #     format(model.name) do |value|
      #       content_tag(:strong, value)
      #     end
      #   end
      #
      #   column(:company) do |model|
      #     format(model.company.name) do
      #       render partial: "company_with_logo", locals: {company: model.company }
      #     end
      #   end
      # @return [Datagrid::Columns::Column::ResponseFormat] Format object
      def format(value, &block)
        if block_given?
          self.class.format(value, &block)
        else
          # don't override Object#format method
          super
        end
      end

      # @return [Datagrid::Columns::DataRow] an object representing a grid row.
      # @example
      #  class MyGrid
      #    scope { User }
      #    column(:id)
      #    column(:name)
      #    column(:number_of_purchases) do |user|
      #      user.purchases.count
      #    end
      #  end
      #
      #  row = MyGrid.new.data_row(User.last)
      #  row.id # => user.id
      #  row.number_of_purchases # => user.purchases.count
      def data_row(asset)
        ::Datagrid::Columns::DataRow.new(self, asset)
      end

      # Defines a column at instance level
      #
      # @see Datagrid::Columns::ClassMethods#column
      def column(name, query = nil, **options, &block)
        self.class.define_column(columns_array, name, query, **options, &block)
      end

      # @!visibility private
      def initialize(*)
        self.columns_array = self.class.columns_array.clone
        super
      end

      # @return [Array<Datagrid::Columns::Column>] all columns that are possible to be displayed for the current grid object
      #
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

      # @return [Object] a cell data value for given column name and asset
      def data_value(column_name, asset)
        column = column_by_name(column_name)
        cache(column, asset, :data_value) do
          raise "no data value for #{column.name} column" unless column.data?
          result = generic_value(column, asset)
          result.is_a?(Datagrid::Columns::Column::ResponseFormat) ? result.call_data : result
        end
      end

      # @return [Object] a cell HTML value for given column name and asset and view context
      def html_value(column_name, context, asset)
        column  = column_by_name(column_name)
        cache(column, asset, :html_value) do
          if column.html? && column.html_block
            value_from_html_block(context, asset, column)
          else
            result = generic_value(column, asset)
            result.is_a?(Datagrid::Columns::Column::ResponseFormat) ? result.call_html(context) : result
          end
        end
      end

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
        unless key
          raise(Datagrid::CacheKeyError, "Datagrid Cache key is #{key.inspect} for #{asset.inspect}.")
        end
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
        raise Datagrid::ConfigurationError, "#{self} is setup to use cache. But there was appropriate cache key found for #{asset.inspect}. Please set cached option to block with asset as argument and cache key as returning value to resolve the issue."
      end


      def map_with_batches(&block)
        result = []
        each_with_batches do |asset|
          result << block.call(asset)
        end
        result
      end

      def each_with_batches(&block)
        if batch_size && batch_size > 0
          driver.batch_each(assets, batch_size, &block)
        else
          assets.each(&block)
        end
      end

      def value_from_html_block(context, asset, column)
        args = []
        remaining_arity = column.html_block.arity
        remaining_arity = 1 if remaining_arity < 0

        asset = decorate(asset)

        if column.data?
          args << data_value(column, asset)
          remaining_arity -= 1
        end

        args << asset if remaining_arity > 0
        args << self if remaining_arity > 1

        context.instance_exec(*args, &column.html_block)
      end
    end

    # Object representing a single row of data when building a datagrid table
    # @see Datagrid::Columns::InstanceMethods#data_row
    class DataRow < BasicObject
      def initialize(grid, model)
        @grid = grid
        @model = model
      end

      def method_missing(meth, *args, &blk)
        @grid.data_value(meth, @model)
      end
    end
  end
end
