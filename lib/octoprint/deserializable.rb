# typed: true
# frozen_string_literal: true

module Octoprint
  # Deserializable provides declarative deserialization configuration for API responses.
  #
  # This module allows classes to define how they should be deserialized from API response
  # data using a clean, declarative DSL. It handles common patterns like key renaming,
  # nested object conversion, array deserialization, and custom transformations.
  #
  # @example Basic usage
  #   class User
  #     include Deserializable
  #     include AutoInitializable
  #
  #     auto_attr :name, type: String
  #     auto_attr :display_name, type: String
  #     auto_attr :profile, type: Profile
  #
  #     auto_initialize!
  #
  #     deserialize_config do
  #       rename display: :display_name            # Rename API keys
  #       nested :profile, Profile                 # Convert nested hash to Profile object
  #     end
  #   end
  #
  #   # API response: { name: "John", display: "John Doe", profile: { bio: "Developer" } }
  #   user = User.deserialize(api_data)
  #   user.name         # => "John"
  #   user.display_name # => "John Doe"
  #   user.profile      # => Profile instance
  #
  # @example Advanced usage with arrays and transformations
  #   class Post
  #     include Deserializable
  #     include AutoInitializable
  #
  #     auto_attr :title, type: String
  #     auto_attr :author, type: User
  #     auto_attr :tags, type: String, array: true
  #     auto_attr :metadata, type: Hash
  #     auto_attr :extra, type: Hash
  #
  #     auto_initialize!
  #
  #     deserialize_config do
  #       nested :author, User                     # Convert author hash to User
  #       array :tags, String                     # Array of strings (no conversion needed)
  #       collect_extras                          # Collect unknown fields into :extra
  #
  #       # Custom transformation
  #       transform do |data|
  #         data[:metadata][:processed_at] = Time.now
  #       end
  #     end
  #   end
  #
  # @example Manual deserialization (without DSL)
  #   class LegacyClass
  #     include Deserializable
  #
  #     def self.deserialize(data)
  #       # Manual processing
  #       rename_keys(data, { old_key: :new_key })
  #       deserialize_nested(data, :child, ChildClass)
  #       new(**data)
  #     end
  #   end
  module Deserializable
    extend T::Sig
    extend T::Helpers

    module ClassMethods
      extend T::Sig

      # Configures deserialization behavior using a declarative DSL.
      #
      # This method provides a clean, readable way to define how API response data
      # should be transformed into Ruby objects. The configuration is cached and
      # reused across deserialize calls.
      #
      # @param block [Proc] Configuration block evaluated in DeserializationConfig context
      # @yield [config] Provides DSL methods for configuring deserialization
      #
      # @example Basic configuration
      #   deserialize_config do
      #     rename display: :display_name          # Rename keys
      #     nested :profile, Profile              # Convert nested objects
      #     array :tags, Tag                     # Convert array elements
      #     collect_extras                       # Collect unknown fields
      #   end
      #
      # @see DeserializationConfig DSL methods available in the configuration block
      sig { params(block: T.nilable(T.proc.bind(DeserializationConfig).void)).void }
      def deserialize_config(&block)
        @deserialize_config ||= DeserializationConfig.new
        @deserialize_config.instance_eval(&block) if block
      end

      # Returns the current deserialization configuration.
      #
      # @return [DeserializationConfig, nil] The configuration object or nil if not configured
      # @api private
      sig { returns(T.nilable(DeserializationConfig)) }
      def deserialize_configuration
        @deserialize_config
      end

      # Deserializes API response data into a Ruby object.
      #
      # This method applies all configured transformations in order:
      # 1. Nested object conversions
      # 2. Array element conversions
      # 3. Key renaming
      # 4. Custom transformations
      # 5. Extra field collection (if enabled)
      # 6. Object instantiation
      #
      # @param data [Hash<Symbol, Object>] The API response data to deserialize
      # @return [Object] A new instance of the class with deserialized data
      #
      # @example
      #   api_data = { name: "John", display: "John Doe", profile: { bio: "Dev" } }
      #   user = User.deserialize(api_data)
      #   user.name         # => "John"
      #   user.display_name # => "John Doe" (renamed from display)
      #   user.profile      # => Profile instance (converted from hash)
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

        T.unsafe(self).new(**data)
      end

      # Helper methods (kept for backward compatibility and direct use)

      # Renames keys in a data hash according to the provided mapping.
      #
      # This is essential for handling API responses where field names conflict with
      # Ruby built-in methods or don't match Ruby conventions. Many APIs use field
      # names that would override important Object methods if used as attribute names.
      #
      # @param data [Hash<Symbol, Object>] The data hash to modify
      # @param mapping [Hash<Symbol, Symbol>] Mapping from old keys to new keys
      # @return [Hash<Symbol, Object>] The modified data hash
      #
      # @example Avoiding Ruby method conflicts
      #   data = { display: "John Doe", hash: "abc123", class: "User" }
      #   rename_keys(data, { display: :display_name, hash: :md5_hash, class: :klass })
      #   # data is now { display_name: "John Doe", md5_hash: "abc123", klass: "User" }
      #   # Avoids conflicts with Object#display, Object#hash, Object#class
      #
      # @note Common Ruby method conflicts include: display, hash, class, type, method, send
      sig do
        params(data: T::Hash[Symbol, T.untyped], mapping: T::Hash[Symbol, Symbol]).returns(T::Hash[Symbol, T.untyped])
      end
      def rename_keys(data, mapping)
        mapping.each do |old_key, new_key|
          data[new_key] = data.delete(old_key) if data.key?(old_key)
        end
        data
      end

      # Deserializes a nested object field within the data hash.
      #
      # Attempts to convert a nested hash or object into an instance of the specified class.
      # First tries calling the class's `deserialize` method, then falls back to `new(**hash)`.
      #
      # @param data [Hash<Symbol, Object>] The data hash containing the field
      # @param field [Symbol] The field name to deserialize
      # @param klass [Class] The target class for deserialization
      # @return [Hash<Symbol, Object>] The modified data hash
      #
      # @example
      #   data = { profile: { name: "John", age: 30 } }
      #   deserialize_nested(data, :profile, User)
      #   # data[:profile] is now a User instance
      sig do
        params(
          data: T::Hash[Symbol, T.untyped],
          field: Symbol,
          klass: T.untyped
        ).returns(T::Hash[Symbol, T.untyped])
      end
      def deserialize_nested(data, field, klass)
        if data[field] && klass.respond_to?(:deserialize)
          data[field] = T.unsafe(klass).deserialize(data[field])
        elsif data[field] && klass.respond_to?(:new) && data[field].is_a?(Hash)
          data[field] = T.unsafe(klass).new(**data[field])
        end
        data
      end

      # Deserializes an array field by converting each element to the specified class.
      #
      # Maps over each item in the array, attempting to deserialize hash items into
      # instances of the specified class. Non-hash items are left unchanged.
      #
      # @param data [Hash<Symbol, Object>] The data hash containing the array field
      # @param field [Symbol] The field name containing the array
      # @param klass [Class] The target class for array elements
      # @return [Hash<Symbol, Object>] The modified data hash
      #
      # @example
      #   data = { users: [{ name: "John" }, { name: "Jane" }] }
      #   deserialize_array(data, :users, User)
      #   # data[:users] is now [User("John"), User("Jane")]
      sig do
        params(
          data: T::Hash[Symbol, T.untyped],
          field: Symbol,
          klass: T.untyped
        ).returns(T::Hash[Symbol, T.untyped])
      end
      def deserialize_array(data, field, klass)
        if data[field].is_a?(Array)
          data[field] = data[field].map do |item|
            if klass.respond_to?(:deserialize)
              T.unsafe(klass).deserialize(item)
            elsif klass.respond_to?(:new) && item.is_a?(Hash)
              T.unsafe(klass).new(**item)
            else
              item
            end
          end
        end
        data
      end

      # Collects unknown fields into an :extra hash.
      #
      # Moves any fields that aren't defined as auto_attrs into a separate :extra
      # hash to preserve API data that doesn't have corresponding Ruby attributes.
      # This is useful for maintaining forward compatibility with API changes.
      #
      # @param data [Hash<Symbol, Object>] The data hash to process
      # @return [void]
      #
      # @example
      #   # Class has auto_attrs: [:name, :email]
      #   data = { name: "John", email: "john@example.com", unknown_field: "value" }
      #   handle_extras(data)
      #   # data is now { name: "John", email: "john@example.com", extra: { unknown_field: "value" } }
      sig { params(data: T::Hash[Symbol, T.untyped]).void }
      def handle_extras(data)
        # Get valid keys from AutoInitializable if included
        valid_keys = if T.unsafe(self).respond_to?(:auto_attrs)
                       T.unsafe(self).auto_attrs.keys
                     else
                       []
                     end

        # Debug: let's see what's happening
        # puts "Class: #{self.name}"
        # puts "Valid keys: #{valid_keys}"
        # puts "Data keys: #{data.keys}"

        extra_keys = data.keys - valid_keys

        return unless extra_keys.any?

        extras_hash = {}
        extra_keys.each do |key|
          extras_hash[key] = data.delete(key)
        end
        data[:extra] = extras_hash
      end
    end

    # Configuration object for declarative deserialization.
    #
    # This class provides the DSL methods available within deserialize_config blocks.
    # It stores the configuration for how data should be transformed during deserialization.
    #
    # @api private
    # @see Deserializable#deserialize_config
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

      # @return [Hash<Symbol, Class>] Mapping of field names to classes for nested object conversion
      # @api private
      sig { returns(T::Hash[Symbol, T.untyped]) }
      attr_reader :nested_objects

      # @return [Hash<Symbol, Class>] Mapping of field names to classes for array element conversion
      # @api private
      sig { returns(T::Hash[Symbol, T.untyped]) }
      attr_reader :array_objects

      # @return [Hash<Symbol, Symbol>] Mapping of old field names to new field names
      # @api private
      sig { returns(T::Hash[Symbol, Symbol]) }
      attr_reader :key_mappings

      # @return [Array<Proc>] Custom transformation blocks to apply to data
      # @api private
      sig { returns(T::Array[T.proc.params(data: T::Hash[Symbol, T.untyped]).void]) }
      attr_reader :transformations

      # Configures a field to be deserialized as a nested object.
      #
      # The field's hash value will be converted to an instance of the specified class
      # by calling either `klass.deserialize(hash)` or `klass.new(**hash)`.
      #
      # @param field [Symbol] The field name containing the nested hash
      # @param klass [Class] The class to instantiate for the nested object
      #
      # @example
      #   nested :profile, Profile      # data[:profile] hash becomes Profile instance
      #   nested :location, Location    # data[:location] becomes Location instance
      sig { params(field: Symbol, klass: T.untyped).void }
      def nested(field, klass)
        @nested_objects[field] = klass
      end

      # Configures a field to be deserialized as an array of objects.
      #
      # Each element in the array will be converted to an instance of the specified class
      # if it's a hash, otherwise left unchanged.
      #
      # @param field [Symbol] The field name containing the array
      # @param klass [Class] The class to instantiate for each array element
      #
      # @example
      #   array :users, User           # data[:users] array of hashes becomes array of User instances
      #   array :tags, Tag            # data[:tags] becomes array of Tag instances
      sig { params(field: Symbol, klass: T.untyped).void }
      def array(field, klass)
        @array_objects[field] = klass
      end

      # Configures key renaming for API response fields.
      #
      # This is essential when API field names conflict with Ruby built-in methods
      # or don't match Ruby naming conventions. Many APIs use field names that
      # would override important Object methods if used directly as attribute names.
      #
      # @param mappings [Hash<Symbol, Symbol>] Mapping from API field names to Ruby attribute names
      #
      # @example Avoiding Ruby method conflicts
      #   rename display: :display_name, hash: :md5_hash, class: :klass
      #   # "display" conflicts with Object#display (prints to stdout)
      #   # "hash" conflicts with Object#hash (returns object hash code)
      #   # "class" conflicts with Object#class (returns object's class)
      #
      # @example Converting API naming to Ruby conventions
      #   rename firstName: :first_name, lastName: :last_name
      #   # Convert camelCase API fields to snake_case Ruby attributes
      sig { params(mappings: T::Hash[Symbol, Symbol]).void }
      def rename(mappings)
        @key_mappings.merge!(mappings)
      end

      # Adds a custom transformation to be applied to the data.
      #
      # Transformations are applied after nested/array conversions and key renaming,
      # but before extra field collection. This allows for complex custom logic
      # that can't be expressed through the other DSL methods.
      #
      # @param block [Proc] Block that receives the data hash and can modify it
      # @yield [data] The data hash to transform
      #
      # @example
      #   transform do |data|
      #     data[:processed_at] = Time.now
      #     data[:full_name] = "#{data[:first_name]} #{data[:last_name]}"
      #   end
      sig { params(block: T.proc.params(data: T::Hash[Symbol, T.untyped]).void).void }
      def transform(&block)
        @transformations << block
      end

      # Enables collection of unknown fields into an :extra hash.
      #
      # Any fields in the API response that don't correspond to declared auto_attrs
      # will be collected into an :extra hash field. This preserves data for forward
      # compatibility with API changes.
      #
      # @example
      #   collect_extras
      #   # Unknown fields will be moved to data[:extra] = { unknown_field: "value" }
      sig { void }
      def collect_extras
        @handle_extras = true
      end

      # @return [Boolean] Whether extra field collection is enabled
      # @api private
      sig { returns(T::Boolean) }
      def handle_extras?
        @handle_extras
      end
    end

    mixes_in_class_methods(ClassMethods)
  end
end
