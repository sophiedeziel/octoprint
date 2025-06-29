# typed: true
# frozen_string_literal: true

module Octoprint
  module Deserializable
    extend T::Sig
    extend T::Helpers

    module ClassMethods
      extend T::Sig

      # DSL method to configure deserialization
      sig { params(block: T.proc.bind(DeserializationConfig).void).void }
      def deserialize_config(&block)
        @deserialize_config ||= DeserializationConfig.new
        @deserialize_config.instance_eval(&block) if block_given?
      end

      # Get the deserialization configuration
      sig { returns(T.nilable(DeserializationConfig)) }
      def deserialize_configuration
        @deserialize_config
      end

      # Main deserialize method that uses configuration
      sig { params(data: T::Hash[Symbol, T.untyped]).returns(T.untyped) }
      def deserialize(data)
        config = deserialize_configuration
        
        if config
          # Apply nested object deserializations
          config.nested_objects.each do |field, klass|
            deserialize_nested(data, field, klass)
          end
          
          # Apply array deserializations
          config.array_objects.each do |field, klass|
            deserialize_array(data, field, klass)
          end
          
          # Apply key renamings
          rename_keys(data, config.key_mappings) if config.key_mappings.any?
          
          # Apply custom transformations
          config.transformations.each do |transformation|
            transformation.call(data)
          end
          
          # Handle extras if configured
          handle_extras(data) if config.handle_extras?
        end
        
        new(**data)
      end

      # Helper methods (kept for backward compatibility and direct use)
      sig { params(data: T::Hash[Symbol, T.untyped], mapping: T::Hash[Symbol, Symbol]).returns(T::Hash[Symbol, T.untyped]) }
      def rename_keys(data, mapping)
        mapping.each do |old_key, new_key|
          data[new_key] = data.delete(old_key) if data.key?(old_key)
        end
        data
      end

      sig do
        params(
          data: T::Hash[Symbol, T.untyped],
          field: Symbol,
          klass: T.any(T::Class[T.anything], T.class_of(T::Struct), T.class_of(T::Enum))
        ).returns(T::Hash[Symbol, T.untyped])
      end
      def deserialize_nested(data, field, klass)
        if data[field] && klass.respond_to?(:deserialize)
          data[field] = klass.deserialize(data[field])
        elsif data[field] && klass.respond_to?(:new) && data[field].is_a?(Hash)
          data[field] = klass.new(**data[field])
        end
        data
      end

      sig do
        params(
          data: T::Hash[Symbol, T.untyped],
          field: Symbol,
          klass: T.any(T::Class[T.anything], T.class_of(T::Struct), T.class_of(T::Enum))
        ).returns(T::Hash[Symbol, T.untyped])
      end
      def deserialize_array(data, field, klass)
        if data[field].is_a?(Array)
          data[field] = data[field].map do |item|
            if klass.respond_to?(:deserialize)
              klass.deserialize(item)
            elsif klass.respond_to?(:new) && item.is_a?(Hash)
              klass.new(**item)
            else
              item
            end
          end
        end
        data
      end

      sig { params(data: T::Hash[Symbol, T.untyped]).void }
      def handle_extras(data)
        # Get valid keys from AutoInitializable if included
        valid_keys = if respond_to?(:auto_attrs)
          auto_attrs.keys
        else
          []
        end
        
        # Debug: let's see what's happening
        # puts "Class: #{self.name}"
        # puts "Valid keys: #{valid_keys}"
        # puts "Data keys: #{data.keys}"
        
        extra_keys = data.keys - valid_keys
        
        if extra_keys.any?
          extras_hash = {}
          extra_keys.each do |key|
            extras_hash[key] = data.delete(key)
          end
          data[:extra] = extras_hash
        end
      end
    end

    # Configuration class for deserialization
    class DeserializationConfig
      extend T::Sig

      sig { void }
      def initialize
        @nested_objects = {}
        @array_objects = {}
        @key_mappings = {}
        @transformations = []
        @handle_extras = false
      end

      sig { returns(T::Hash[Symbol, T.any(T::Class[T.anything], T.class_of(T::Struct), T.class_of(T::Enum))]) }
      attr_reader :nested_objects

      sig { returns(T::Hash[Symbol, T.any(T::Class[T.anything], T.class_of(T::Struct), T.class_of(T::Enum))]) }
      attr_reader :array_objects

      sig { returns(T::Hash[Symbol, Symbol]) }
      attr_reader :key_mappings

      sig { returns(T::Array[T.proc.params(data: T::Hash[Symbol, T.untyped]).void]) }
      attr_reader :transformations

      # DSL methods
      sig { params(field: Symbol, klass: T.any(T::Class[T.anything], T.class_of(T::Struct), T.class_of(T::Enum))).void }
      def nested(field, klass)
        @nested_objects[field] = klass
      end

      sig { params(field: Symbol, klass: T.any(T::Class[T.anything], T.class_of(T::Struct), T.class_of(T::Enum))).void }
      def array(field, klass)
        @array_objects[field] = klass
      end

      sig { params(mappings: T::Hash[Symbol, Symbol]).void }
      def rename(mappings)
        @key_mappings.merge!(mappings)
      end

      sig { params(block: T.proc.params(data: T::Hash[Symbol, T.untyped]).void).void }
      def transform(&block)
        @transformations << block
      end

      sig { void }
      def collect_extras
        @handle_extras = true
      end

      sig { returns(T::Boolean) }
      def handle_extras?
        @handle_extras
      end
    end

    mixes_in_class_methods(ClassMethods)
  end
end