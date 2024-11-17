# frozen_string_literal: true

module Datagrid
  # @!visibility private
  class DeprecatedObject < BasicObject
    def initialize(real_object, &block)
      @real_object = real_object
      @block = block
    end

    def method_missing(method_name, ...)
      @block.call
      @real_object.public_send(method_name, ...)
    end

    def respond_to_missing?(method_name, include_private = false)
      @real_object.respond_to?(method_name, include_private)
    end
  end
end
