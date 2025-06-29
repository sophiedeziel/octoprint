# typed: true
# frozen_string_literal: true

module Octoprint
  # Common type aliases for use with auto_attr and Sorbet signatures.
  #
  # This module provides convenient type aliases for commonly used types
  # in the OctoPrint API. These can be used with auto_attr or in regular
  # Sorbet type annotations.
  #
  # @example Using with auto_attr
  #   class User
  #     include AutoInitializable
  #     
  #     auto_attr :name, type: String, nilable: false
  #     auto_attr :email, type: Types::NilableString   # Alternative syntax
  #     auto_attr :tags, type: Types::StringArray
  #     auto_attr :metadata, type: Types::Hash
  #     
  #     auto_initialize!
  #   end
  #
  # @example Using in Sorbet signatures
  #   sig { params(data: Types::Hash).returns(Types::NilableString) }
  #   def process_data(data)
  #     data[:name]
  #   end
  module Types
    extend T::Sig
    
    # A hash with symbol keys and untyped values (common for API responses)
    # @example { name: "John", age: 30, active: true }
    Hash = T::Hash[Symbol, T.untyped]
    
    # An array of strings
    # @example ["tag1", "tag2", "tag3"]
    StringArray = T::Array[String]
    
    # A nullable string (can be String or nil)
    # @example "John Doe" or nil
    NilableString = T.nilable(String)
    
    # A nullable integer (can be Integer or nil)
    # @example 42 or nil
    NilableInteger = T.nilable(Integer)
    
    # A nullable float (can be Float or nil)
    # @example 3.14 or nil
    NilableFloat = T.nilable(Float)
    
    # A nullable hash (can be Hash or nil)
    # @example { key: "value" } or nil
    NilableHash = T.nilable(T::Hash[Symbol, T.untyped])
    
    # A nullable string array (can be Array<String> or nil)
    # @example ["tag1", "tag2"] or nil
    NilableStringArray = T.nilable(T::Array[String])
  end
end