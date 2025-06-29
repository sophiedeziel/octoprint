# typed: true
# frozen_string_literal: true

module Octoprint
  module AutoInitializable
    extend T::Sig
    extend T::Helpers

    module ClassMethods
      extend T::Sig

      sig do
        params(
          name: Symbol,
          type: T.nilable(T.any(T::Class[T.anything], T.class_of(T::Struct))),
          from: T.nilable(Symbol),
          array: T::Boolean,
          nilable: T::Boolean
        ).void
      end
      def auto_attr(name, type: nil, from: nil, array: false, nilable: true)
        @auto_attrs ||= {}
        @auto_attrs[name] = {
          type: type,
          from: from || name,
          array: array,
          nilable: nilable
        }
      end

      sig { void }
      def auto_initialize!
        attrs = @auto_attrs || {}

        define_method :initialize do |**kwargs|
          attrs.each do |name, config|
            source_key = config[:from]
            value = kwargs[source_key]

            # Skip if nil and nilable
            if value.nil?
              instance_variable_set("@#{name}", nil)
              next
            end

            # Handle type conversion
            converted_value = if config[:type]
                                if config[:array] && value.is_a?(Array)
                                  # Handle array of objects
                                  value.map do |item|
                                    self.class.send(:convert_value, item, config[:type])
                                  end
                                else
                                  self.class.send(:convert_value, value, config[:type])
                                end
                              else
                                value
                              end

            instance_variable_set("@#{name}", converted_value)
          end

          # Call parent initializer if it exists and has an initialize method
          if self.class.superclass.instance_methods.include?(:initialize)
            super()
          end
        end

        # Create attr_readers
        attrs.each_key { |name| attr_reader name }
      end

      sig { returns(T::Hash[Symbol, T.untyped]) }
      def auto_attrs
        @auto_attrs || {}
      end

      private

      sig { params(value: T.untyped, type: T.any(T::Class[T.anything], T.class_of(T::Struct))).returns(T.untyped) }
      def convert_value(value, type)
        return value unless value.is_a?(Hash)

        # Check if type responds to new (is instantiable)
        if type.respond_to?(:new)
          type.new(**value)
        else
          value
        end
      end
    end

    mixes_in_class_methods(ClassMethods)
  end
end