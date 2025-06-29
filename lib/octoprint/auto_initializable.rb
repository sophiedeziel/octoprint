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
          type: T.untyped,
          from: T.nilable(Symbol),
          array: T::Boolean,
          nilable: T::Boolean
        ).void
      end
      def auto_attr(name, type: T.untyped, from: nil, array: false, nilable: true)
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

        # Create typed attr_readers
        attrs.each do |name, config|
          # Generate the Sorbet type signature
          sorbet_type = generate_sorbet_type(config)
          
          # Define the typed attr_reader
          if sorbet_type
            # Use class_eval to define the signature and method together
            class_eval <<~RUBY, __FILE__, __LINE__ + 1
              extend T::Sig
              sig { returns(#{sorbet_type}) }
              attr_reader :#{name}
            RUBY
          else
            # Fallback to regular attr_reader if no type info
            attr_reader name
          end
        end
      end

      sig { returns(T::Hash[Symbol, T.untyped]) }
      def auto_attrs
        @auto_attrs || {}
      end

      private

      sig { params(value: T.untyped, type: T.untyped).returns(T.untyped) }
      def convert_value(value, type)
        return value unless value.is_a?(Hash)

        # Don't try to convert basic Ruby types like Hash, Array, String, etc.
        return value if [Hash, Array, String, Integer, Float, TrueClass, FalseClass].include?(type)

        # Check if type is a class that responds to new (for our custom classes)
        if type.is_a?(Class) && type.respond_to?(:new)
          type.new(**value)
        else
          value
        end
      end

      sig { params(config: T::Hash[Symbol, T.untyped]).returns(String) }
      def generate_sorbet_type(config)
        type = config[:type]
        
        # Handle the case where type is already a Sorbet type
        if type.is_a?(T::Types::Base) || type.is_a?(T::Private::Types::TypeAlias)
          return type.to_s
        end
        
        # Convert type to string representation
        base_type = case type
        when Class
          # For regular classes, use the class name
          type.name
        when String
          # For primitive types passed as strings
          type
        when Symbol
          # For primitive types passed as symbols
          type.to_s.capitalize
        when T.untyped
          "T.untyped"
        else
          # Default fallback
          "T.untyped"
        end
        
        # Handle array types
        if config[:array]
          base_type = "T::Array[#{base_type}]"
        end
        
        # Handle nilable types
        if config[:nilable]
          base_type = "T.nilable(#{base_type})"
        end
        
        base_type
      end
    end

    mixes_in_class_methods(ClassMethods)
  end
end