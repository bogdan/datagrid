require "datagrid/utils"
require "active_support/core_ext/class/attribute"

module Datagrid

  module Columns
    require "datagrid/columns/column"

    def self.included(base)
      base.extend         ClassMethods
      base.class_eval do

        include Datagrid::Core

        class_attribute :default_column_options, :instance_writer => false
        self.default_column_options = {}

        class_attribute :batch_size

        class_attribute :columns_array
        self.columns_array = []

        class_attribute :dynamic_block, :instance_writer => false

        class_attribute :cached
        self.cached = false


        class_attribute :decorator, instance_writer: false

      end
      base.send :include, InstanceMethods
    end # self.included

    module ClassMethods

      ##
      # :method: batch_size=
      #
      # :call-seq: batch_size=(size)
      #
      # Specify a default batch size when generating CSV or just data
      # Default: 1000
      #
      #   self.batch_size = 500
      #   # Disable batches
      #   self.batch_size = nil
      #

      ##
      # :method: batch_size
      #
      # :call-seq: batch_size
      #
      # Returns specified batch_size configuration variable
      # See <tt>batch_size=</tt> for more information
      #

      ##
      # :method: default_column_options=
      #
      # :call-seq: default_column_options=(options)
      #
      # Specifies default options for `column` method.
      # They still can be overwritten at column level.
      #
      #   # Disable default order
      #   self.default_column_options = { :order => false }
      #   # Makes entire report HTML
      #   self.default_column_options = { :html => true }
      #

      ##
      # :method: default_column_options
      #
      # :call-seq: default_column_options
      #
      # Returns specified default column options hash
      # See <tt>default_column_options=</tt> for more information
      #

      # Returns a list of columns defined.
      # All column definistion are returned by default
      # You can limit the output with only columns you need like:
      #
      #   GridClass.columns(:id, :name)
      #
      # Supported options:
      #
      # * :data - if true returns only non-html columns. Default: false.
      def columns(*args)
        filter_columns(columns_array, *args)
      end

      # Defines new datagrid column
      #
      # Arguments:
      #
      #   * <tt>name</tt> - column name
      #   * <tt>query</tt> - a string representing the query to select this column (supports only ActiveRecord)
      #   * <tt>options</tt> - hash of options
      #   * <tt>block</tt> - proc to calculate a column value
      #
      # Available options:
      #
      #   * <tt>:html</tt> - determines if current column should be present in html table and how is it formatted
      #   * <tt>:order</tt> - determines if this column could be sortable and how.
      #     The value of order is explicitly passed to ORM ordering method.
      #     Ex: <tt>"created_at, id"</tt> for ActiveRecord, <tt>[:created_at, :id]</tt> for Mongoid
      #   * <tt>:order_desc</tt> - determines a descending order for given column
      #     (only in case when <tt>:order</tt> can not be easily reversed by ORM)
      #   * <tt>:order_by_value</tt> - used in case it is easier to perform ordering at ruby level not on database level.
      #     Warning: using ruby to order large datasets is very unrecommended.
      #     If set to true - datagrid will use column value to order by this column
      #     If block is given - datagrid will use value returned from block
      #   * <tt>:mandatory</tt> - if true, column will never be hidden with #column_names selection
      #   * <tt>:url</tt> - a proc with one argument, pass this option to easily convert the value into an URL
      #   * <tt>:before</tt> - determines the position of this column, by adding it before the column passed here
      #   * <tt>:after</tt> - determines the position of this column, by adding it after the column passed here
      #   * <tt>:if</tt> - the column is shown if the reult of calling this argument is true
      #   * <tt>:unless</tt> - the column is shown unless the reult of calling this argument is true
      #
      # See: https://github.com/bogdan/datagrid/wiki/Columns for examples
      def column(name, options_or_query = {}, options = {}, &block)
        define_column(columns_array, name, options_or_query, options, &block)
      end

      # Returns column definition with given name
      def column_by_name(name)
        find_column_by_name(columns_array, name)
      end

      # Returns an array of all defined column names
      def column_names
        columns.map(&:name)
      end

      def respond_to(&block) #:nodoc:
        Datagrid::Columns::Column::ResponseFormat.new(&block)
      end

      # Formats column value for HTML.
      # Helps to distinguish formatting as plain data and HTML
      #
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

      # Allows dynamic columns definition, that could not be defined at class level
      #
      #   class MerchantsGrid
      #
      #     scope { Merchant }
      #
      #     column(:name)
      #
      #     dynamic do
      #       PurchaseCategory.all.each do |category|
      #         column(:"#{category.name.underscore}_sales") do |merchant|
      #           merchant.purchases.where(:category_id => category.id).count
      #         end
      #       end
      #     end
      #   end
      #
      #   grid = MerchantsGrid.new
      #   grid.data # => [
      #             #      [ "Name",   "Swimwear Sales", "Sportswear Sales", ... ]
      #             #      [ "Reebok", 2083382,            8382283,          ... ]
      #             #      [ "Nike",   8372283,            18734783,         ... ]
      #             #    ]
      def dynamic(&block)
        previous_block = dynamic_block
        self.dynamic_block =
          if previous_block
            proc {
              instance_eval(&previous_block)
              instance_eval(&block)
            }
          else
            block
          end
      end

      # Defines a model decorator that will be used to define a column value.
      # All column blocks will be given a decorated version of the model.
      #
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

      def inherited(child_class) #:nodoc:
        super(child_class)
        child_class.columns_array = self.columns_array.clone
      end

      def filter_columns(columns, *args) #:nodoc:
        options = args.extract_options!
        args.compact!
        args.map!(&:to_sym)
        columns.select do |column|
          (!options[:data] || column.data?) && (!options[:html] || column.html?) && (column.mandatory? || args.empty? || args.include?(column.name))
        end
      end

      def define_column(columns, name, options_or_query = {}, options = {}, &block) #:nodoc:
        if options_or_query.is_a?(String)
          query = options_or_query
        else
          options = options_or_query
        end
        check_scope_defined!("Scope should be defined before columns")
        block ||= lambda do |model|
          model.send(name)
        end
        position = Datagrid::Utils.extract_position_from_options(columns, options)
        column = Datagrid::Columns::Column.new(self, name, query, default_column_options.merge(options), &block)
        columns.insert(position, column)
      end

      def find_column_by_name(columns,name) #:nodoc:
        return name if name.is_a?(Datagrid::Columns::Column)
        columns.find do |col|
          col.name.to_sym == name.to_sym
        end
      end

    end # ClassMethods

    module InstanceMethods

      def assets
        driver.append_column_queries(super, columns.select(&:query))
      end

      # Returns <tt>Array</tt> of human readable column names. See also "Localization" section
      #
      # Arguments:
      #
      #   * <tt>column_names</tt> - list of column names if you want to limit data only to specified columns
      def header(*column_names)
        data_columns(*column_names).map(&:header)
      end

      # Returns <tt>Array</tt> column values for given asset
      #
      # Arguments:
      #
      #   * <tt>column_names</tt> - list of column names if you want to limit data only to specified columns
      def row_for(asset, *column_names)
        data_columns(*column_names).map do |column|
          data_value(column, asset)
        end
      end

      # Returns <tt>Hash</tt> where keys are column names and values are column values for the given asset
      def hash_for(asset)
        result = {}
        self.data_columns.each do |column|
          result[column.name] = data_value(column, asset)
        end
        result
      end

      # Returns Array of Arrays with data for each row in datagrid assets without header.
      #
      # Arguments:
      #
      #   * <tt>column_names</tt> - list of column names if you want to limit data only to specified columns
      def rows(*column_names)
        map_with_batches do |asset|
          self.row_for(asset, *column_names)
        end
      end

      # Returns Array of Arrays with data for each row in datagrid assets with header.
      #
      # Arguments:
      #
      #   * <tt>column_names</tt> - list of column names if you want to limit data only to specified columns
      def data(*column_names)
        self.rows(*column_names).unshift(self.header(*column_names))
      end

      # Return Array of Hashes where keys are column names and values are column values
      # for each row in filtered datagrid relation.
      #
      # Example:
      #
      #     class MyGrid
      #       scope { Model }
      #       column(:id)
      #       column(:name)
      #     end
      #
      #     Model.create!(:name => "One")
      #     Model.create!(:name => "Two")
      #
      #     MyGrid.new.data_hash # => [{:name => "One"}, {:name => "Two"}]
      #
      def data_hash
        map_with_batches do |asset|
          hash_for(asset)
        end
      end

      # Returns a CSV representation of the data in the grid
      # You are able to specify which columns you want to see in CSV.
      # All data columns are included by default
      # Also you can specify options hash as last argument that is proxied to
      # Ruby CSV library.
      #
      # Example:
      #
      #   grid.to_csv
      #   grid.to_csv(:id, :name)
      #   grid.to_csv(:col_sep => ';')
      def to_csv(*column_names)
        options = column_names.extract_options!
        csv_class.generate(
          {:headers => self.header(*column_names), :write_headers => true}.merge!(options)
        ) do |csv|
          each_with_batches do |asset|
            csv << row_for(asset, *column_names)
          end
        end
      end


      # Returns all columns selected in grid instance
      #
      # Examples:
      #
      #   MyGrid.new.columns # => all defined columns
      #   grid = MyGrid.new(:column_names => [:id, :name])
      #   grid.columns # => id and name columns
      #   grid.columns(:id, :category) # => id and category column
      def columns(*args)
        self.class.filter_columns(columns_array, *args).select {|column| column.enabled?(self)}
      end

      # Returns all columns that can be represented in plain data(non-html) way
      def data_columns(*names)
        options = names.extract_options!
        options[:data] = true
        names << options
        self.columns(*names)
      end

      # Returns all columns that can be represented in HTML table
      def html_columns(*names)
        options = names.extract_options!
        options[:html] = true
        names << options
        self.columns(*names)
      end

      # Finds a column definition by name
      def column_by_name(name)
        self.class.find_column_by_name(columns_array, name)
      end

      # Gives ability to have a different formatting for CSV and HTML column value.
      #
      # Example:
      #
      #   column(:name) do |model|
      #     format(model.name) do |value|
      #       content_tag(:strong, value)
      #     end
      #   end
      #
      #   column(:company) do |model|
      #     format(model.company.name) do
      #       render :partial => "company_with_logo", :locals => {:company => model.company }
      #     end
      #   end
      def format(value, &block)
        if block_given?
          self.class.format(value, &block)
        else
          # don't override Object#format method
          super
        end
      end

      # Returns an object representing a grid row.
      # Allows to access column values
      #
      # Example:
      #
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
      # See Datagrid::Columns::ClassMethods#column for more info
      def column(name, options_or_query = {}, options = {}, &block) #:nodoc:
        self.class.define_column(columns_array, name, options_or_query, options, &block)
      end

      def initialize(*) #:nodoc:
        self.columns_array = self.class.columns_array.clone
        super
        instance_eval(&dynamic_block) if dynamic_block
      end

      # Returns all columns available for current grid configuration.
      #
      #   class MyGrid
      #     filter(:search) {|scope, value| scope.full_text_search(value)}
      #     column(:id)
      #     column(:name, :mandatory => true)
      #     column(:search_match, :if => proc {|grid| grid.search.present? }) do |model, grid|
      #       search_match_line(model.searchable_content, grid.search)
      #     end
      #   end
      #
      #   grid = MyGrid.new
      #   grid.columns # => [ #<Column:name> ]
      #   grid.available_columns # => [ #<Column:id>, #<Column:name> ]
      #   grid.search = "keyword"
      #   grid.available_columns # => [ #<Column:id>, #<Column:name>, #<Column:search_match> ]
      #
      def available_columns
        columns_array.select do |column|
          column.enabled?(self)
        end
      end

      # Return a cell data value for given column name and asset
      def data_value(column_name, asset)
        column = column_by_name(column_name)
        cache(column, asset, :data_value) do
          raise "no data value for #{column.name} column" unless column.data?
          result = generic_value(column, asset)
          result.is_a?(Datagrid::Columns::Column::ResponseFormat) ? result.call_data : result
        end
      end

      # Return a cell HTML value for given column name and asset and view context
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

      # Returns a decorated version of given model if decorator is specified or the model otherwise.
      def decorate(model)
        self.class.decorate(model)
      end

      def generic_value(column, model) #:nodoc:
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

      def csv_class
        if RUBY_VERSION >= "1.9"
          require 'csv'
          CSV
        else
          require "fastercsv"
          FasterCSV
        end
      end

      def value_from_html_block(context, asset, column)
        args = []
        remaining_arity = column.html_block.arity

        if column.data?
          args << data_value(column, asset)
          remaining_arity -= 1
        end

        args << asset if remaining_arity > 0
        args << self if remaining_arity > 1

        context.instance_exec(*args, &column.html_block)
      end
    end # InstanceMethods

    class DataRow

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
