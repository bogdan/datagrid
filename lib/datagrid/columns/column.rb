# frozen_string_literal: true

module Datagrid
  module Columns
    class Column
      # Datagrid class holding an information of
      # how a column should be rendered in data/console/csv format and HTML format
      class ResponseFormat
        attr_accessor :data_block, :html_block

        # @!visibility private
        def initialize
          yield(self)
        end

        # @!visibility private
        def data(&block)
          self.data_block = block
        end

        # @!visibility private
        def html(&block)
          self.html_block = block
        end

        # @!visibility private
        def call_data
          data_block.call
        end

        # @!visibility private
        def to_s
          call_data.to_s
        end

        # @!visibility private
        def call_html(context)
          context.instance_eval(&html_block)
        end
      end

      # @attribute [r] grid_class
      #   @return [Class] grid class where column is defined
      # @attribute [r] name
      #   @return [Symbol] column name
      # @attribute [r] options
      #   @return [Hash<Symbol, Object>] column options
      attr_reader :grid_class, :name, :query, :options, :data_block, :html_block

      # @!visibility private
      def initialize(grid_class, name, query, options = {}, &block)
        @grid_class = grid_class
        @name = name.to_sym
        @query = query
        @options = options

        if options[:class]
          Datagrid::Utils.warn_once(
            "column[class] option is deprecated. Use {tag_options: {class: ...}} instead.",
          )
          self.options[:tag_options] = {
            **self.options.fetch(:tag_options, {}),
            class: options[:class],
          }
        end
        if options[:html] == true
          @html_block = block
        else
          @data_block = block

          @html_block = options[:html] if options[:html].is_a? Proc
        end
      end

      # @deprecated Use {Datagrid::Columns#data_value} instead
      def data_value(model, grid)
        # backward compatibility method
        grid.data_value(name, model)
      end

      # @deprecated Use {#header} instead
      def label
        options[:label]
      end

      # @return [String] column header
      def header
        if (header = options[:header])
          Datagrid::Utils.callable(header, self)
        else
          Datagrid::Utils.translate_from_namespace(:columns, grid_class, name)
        end
      end

      # @return [Object] column order expression
      def order
        return nil if options[:order] == false
        if options.key?(:order) && options[:order] != true
          options[:order]
        else
          driver.default_order(grid_class.scope, name)
        end
      end

      # @return [Boolean] weather column support order
      def supports_order?
        !!order || order_by_value?
      end

      # @!visibility private
      def order_by_value(model, grid)
        if options[:order_by_value] == true
          grid.data_value(self, model)
        else
          Datagrid::Utils.apply_args(model, grid, &options[:order_by_value])
        end
      end

      # @return [Boolean] weather a column should be ordered by value
      def order_by_value?
        !!options[:order_by_value]
      end

      def order_desc
        return nil unless order

        options[:order_desc]
      end

      # @return [Boolean] weather a column should be displayed in HTML
      def html?
        options[:html] != false
      end

      # @return [Boolean] weather a column should be displayed in data
      def data?
        data_block != nil
      end

      # @return [Boolean] weather a column is explicitly marked mandatory
      def mandatory?
        !!options[:mandatory]
      end

      # @return [Hash<Symbol, Object>] `tag_options` option value
      def tag_options
        options[:tag_options] || {}
      end

      # @deprecated Use {#tag_options} instead.
      def html_class
        Datagrid::Utils.warn_once(
          "Column#html_class is deprecated. Use Column#tag_options instead.",
        )
        options[:class]
      end

      # @return [Boolean] weather a `mandatory` option is explicitly set
      def mandatory_explicitly_set?
        options.key?(:mandatory)
      end

      # @param [Datagrid::Base] grid object
      # @return [Boolean] weather a column is available via `if` and `unless` options
      def enabled?(grid)
        ::Datagrid::Utils.process_availability(grid, options[:if], options[:unless])
      end

      # @return [String] column console inspection
      def inspect
        "#<#{self.class} #{grid_class}##{name} #{options.inspect}>"
      end

      # @return [String] column header
      def to_s
        header
      end

      # @!visibility private
      def html_value(context, asset, grid)
        grid.html_value(name, context, asset)
      end

      # @!visibility private
      def generic_value(model, grid)
        grid.generic_value(self, model)
      end

      # @!visibility private
      def append_preload(relation)
        return relation unless preload

        if preload.respond_to?(:call)
          return relation unless preload

          if preload.arity == 1
            preload.call(relation)
          else
            relation.instance_exec(&preload)
          end
        else
          driver.default_preload(relation, preload)
        end
      end

      # @return [Object] `preload` option value
      def preload
        preload = options[:preload]

        if preload == true && driver.can_preload?(grid_class.scope, name)
          name
        else
          preload
        end
      end

      protected

      def driver
        grid_class.driver
      end
    end
  end
end
