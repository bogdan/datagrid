
module Datagrid

  # Required to be ActiveModel compatible
  # @private
  module ActiveModel #:nodoc:
  
    def self.included(base)
      base.extend         ClassMethods
      base.class_eval do
        begin
          require 'active_model/naming'
          extend ::ActiveModel::Naming
        rescue LoadError
        end
      end
      base.send :include, InstanceMethods
    end # self.included
  
    module ClassMethods
  
      def param_name
        self.to_s.underscore.tr('/', '_')
      end

      # Returns the +i18n_scope+ for the class. Overwrite if you want custom lookup.
      def i18n_scope
        :datagrid
      end

      # When localizing a string, it goes through the lookup returned by this
      # method, which is used in Datagrid::ActiveModel#human_filter_name and
      # Datagrid::ActiveModel#human_column_name
      def lookup_ancestors
        self.ancestors.select {|x| x.respond_to?(:model_name)}
      end

      # Transforms filter names into a more human format, such as "Zee filter"
      # instead of "zee_filter".
      #
      #   ZeeGrid.human_filter_name("zee_filter") # => "Zee filter"
      #
      # Specify +options+ with additional translating options.
      def human_filter_name filter, options = {}
        translate_from_namespace :filters, filter, options
      end

      # Transforms column names into a more human format, such as "Zee kolumn"
      # instead of "zee_kolumn".
      #
      #   ZeeGrid.human_attribute_name("zee_column") # => "Zee kolumn"
      #
      # Specify +options+ with additional translating options.
      def human_column_name column, options = {}
        options[:default] = scope.klass.human_attribute_name(column, options)
        translate_from_namespace :columns, column, options
      end

      # This is just a generic version of teh above two. kinda copied from
      # ActiveModel::Translation#human_attribute_name()
      def translate_from_namespace scope, stuff, options = {}
        options   = { count: 1 }.merge!(options)
        parts     = stuff.to_s.split(".")
        stuff     = parts.pop
        namespace = parts.join("/") unless parts.empty?

        #
        # TODO: deprecated key
        #
        deprecated_key = :"#{i18n_scope}.#{param_name}.#{scope}.#{stuff}"
        if param_name.to_sym != model_name.i18n_key.to_sym && I18n.exists?(deprecated_key)
          Datagrid::Utils.warn_once(
            "Deprecated translation namespace '#{i18n_scope}.#{param_name}' for #{self}. Use '#{i18n_scope}.#{model_name.i18n_key}' instead."
          )
          return I18n.t(deprecated_key)
        end
        #
        #
        #

        if namespace
          defaults = lookup_ancestors.map do |klass|
            :"#{i18n_scope}.#{klass.model_name.i18n_key}.#{scope}/#{namespace}.#{stuff}"
          end
          defaults << :"#{i18n_scope}.#{namespace}.#{scope}.#{stuff}"
        else
          defaults = lookup_ancestors.map do |klass|
            :"#{i18n_scope}.#{klass.model_name.i18n_key}.#{scope}.#{stuff}"
          end
        end

        defaults << :"#{scope}.#{stuff}"

        # NOTE: could options[:default] be an array? if so, this is a bug
        # copied from ActiveModel::Translation#human_attribute_name()
        defaults << options.delete(:default) if options[:default]

        defaults << stuff.humanize

        options[:default] = defaults
        I18n.translate(defaults.shift, options)
      end

    end # ClassMethods
  
    module InstanceMethods
  
      def param_name
        self.class.param_name
      end

      def param_key
        param_name
      end

      def to_key
        [self.class.param_name]
      end

      def persisted?
        false
      end

      def to_model
        self
      end

      def to_param
        self.param_name
      end
    end # InstanceMethods
  
  end
    
  
end
