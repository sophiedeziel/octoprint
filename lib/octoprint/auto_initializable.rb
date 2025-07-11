# typed: true
# frozen_string_literal: true

module Octoprint
  # AutoInitializable provides automatic initialization and typed attribute generation.
  #
  # This module eliminates repetitive initialization code by automatically generating:
  # - Typed instance variables from keyword arguments
  # - Sorbet-typed attr_reader methods
  # - Type conversion for nested objects
  #
  # @example Basic usage
  #   class User
  #     include AutoInitializable
  #
  #     auto_attr :name, type: String, nilable: false
  #     auto_attr :email, type: String
  #     auto_attr :age, type: Integer
  #
  #     auto_initialize!
  #   end
  #
  #   user = User.new(name: "John", email: "john@example.com", age: 30)
  #   user.name  # => "John" (typed as String)
  #   user.email # => "john@example.com" (typed as T.nilable(String))
  #
  # @example With custom classes and arrays
  #   class Profile
  #     include AutoInitializable
  #
  #     auto_attr :user, type: User
  #     auto_attr :tags, type: String, array: true
  #     auto_attr :metadata, type: Hash
  #
  #     auto_initialize!
  #   end
  #
  #   profile = Profile.new(
  #     user: { name: "John", email: "john@example.com" },  # Auto-converted to User
  #     tags: ["admin", "developer"],                       # Typed as T.nilable(T::Array[String])
  #     metadata: { created_at: Time.now }                  # Preserved as Hash
  #   )
  #
  # @example Type conversion behavior
  #   # Basic Ruby types (Hash, Array, String, Integer) are preserved as-is
  #   auto_attr :data, type: Hash        # No conversion, preserves original hash
  #
  #   # Custom classes are auto-converted from hash data
  #   auto_attr :user, type: User        # Calls User.new(**hash_data)
  #
  #   # Arrays of custom classes
  #   auto_attr :users, type: User, array: true  # Maps each hash to User.new(**hash)
  module AutoInitializable
    extend T::Sig
    extend T::Helpers

    # Class methods added when AutoInitializable is included.
    #
    # These methods provide the DSL for declaring auto-initialized attributes
    # and generating the corresponding initialization logic.
    module ClassMethods
      extend T::Sig

      # Declares an attribute that will be automatically initialized and typed.
      #
      # @param name [Symbol] The name of the attribute
      # @param type [Class, T.untyped] The type of the attribute (String, Integer, Hash, custom classes, etc.)
      # @param from [Symbol, nil] The source key in initialization hash (defaults to name)
      # @param array [Boolean] Whether this attribute is an array of the specified type
      # @param nilable [Boolean] Whether this attribute can be nil
      #
      # @example Basic attributes
      #   auto_attr :name, type: String, nilable: false
      #   auto_attr :email, type: String
      #   auto_attr :age, type: Integer
      #
      # @example Arrays
      #   auto_attr :tags, type: String, array: true
      #   auto_attr :users, type: User, array: true
      #
      # @example Custom key mapping
      #   auto_attr :display_name, type: String, from: :display
      #
      # @example Complex types
      #   auto_attr :metadata, type: Hash
      #   auto_attr :profile, type: Profile
      #
      # @note Basic Ruby types (Hash, Array, String, Integer, Float) are preserved without conversion.
      #   Custom classes will be instantiated from hash data using Class.new(**hash).
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

      # Generates the initialize method and typed attr_readers based on declared auto_attr calls.
      #
      # This method must be called after all auto_attr declarations to generate the actual
      # initialization code and Sorbet-typed attribute readers.
      #
      # @example
      #   class User
      #     include AutoInitializable
      #
      #     auto_attr :name, type: String
      #     auto_attr :age, type: Integer
      #
      #     auto_initialize!  # Must be called after auto_attr declarations
      #   end
      #
      # @note This method generates:
      #   - An initialize method that accepts keyword arguments
      #   - Type conversion for nested objects
      #   - Sorbet-typed attr_reader methods
      #   - Automatic validation that required attributes are provided
      sig { void }
      def auto_initialize!
        attrs = @auto_attrs || {}
        klass = self

        T.unsafe(self).define_method :initialize do |**kwargs|
          attrs.each do |name, config|
            source_key = config[:from]
            value = kwargs[source_key]

            # Skip if nil and nilable
            if value.nil?
              T.unsafe(self).instance_variable_set("@#{name}", nil)
              next
            end

            # Handle type conversion
            converted_value = if config[:type]
                                if config[:array] && value.is_a?(Array)
                                  # Handle array of objects
                                  value.map do |item|
                                    T.unsafe(klass).send(:convert_value, item, config[:type])
                                  end
                                else
                                  T.unsafe(klass).send(:convert_value, value, config[:type])
                                end
                              else
                                value
                              end

            T.unsafe(self).instance_variable_set("@#{name}", converted_value)
          end

          # Call parent initializer if it exists and has an initialize method
          return unless T.unsafe(self).class.superclass.instance_methods.include?(:initialize)

          super()
        end

        # Create simple attr_readers
        # Type signatures are provided by generated RBI files
        attrs.each_key do |name|
          T.unsafe(self).attr_reader name
        end
      end

      # Returns the hash of declared attributes and their configuration.
      #
      # @return [Hash<Symbol, Hash>] Hash mapping attribute names to their configuration
      #
      # @example
      #   User.auto_attrs
      #   # => {
      #   #   name: { type: String, from: :name, array: false, nilable: false },
      #   #   email: { type: String, from: :email, array: false, nilable: true }
      #   # }
      sig { returns(T::Hash[Symbol, T.untyped]) }
      def auto_attrs
        @auto_attrs || {}
      end

      private

      # Converts a value to the specified type if appropriate.
      #
      # This method handles type conversion for nested objects during initialization.
      # Basic Ruby types (Hash, Array, String, etc.) are preserved as-is to avoid
      # unwanted conversions. Custom classes are instantiated from hash data.
      #
      # @param value [Object] The value to potentially convert
      # @param type [Class] The target type for conversion
      # @return [Object] The converted value or original value if no conversion needed
      #
      # @example
      #   convert_value({ name: "John" }, User)     # => User.new(name: "John")
      #   convert_value({ key: "value" }, Hash)     # => { key: "value" } (unchanged)
      #   convert_value("text", String)             # => "text" (unchanged)
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
    end

    mixes_in_class_methods(ClassMethods)
  end
end
