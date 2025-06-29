# typed: true
# frozen_string_literal: true

module Octoprint
  # Common type aliases for use with auto_attr
  module Types
    extend T::Sig
    
    # Basic types
    Hash = T::Hash[Symbol, T.untyped]
    StringArray = T::Array[String]
    
    # Nullable basic types
    NilableString = T.nilable(String)
    NilableInteger = T.nilable(Integer) 
    NilableFloat = T.nilable(Float)
    NilableHash = T.nilable(T::Hash[Symbol, T.untyped])
    NilableStringArray = T.nilable(T::Array[String])
  end
end