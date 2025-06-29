# typed: true
# frozen_string_literal: true

require "sorbet-runtime"

module Octoprint
  class Files
    # A folder in the file system
    class Folder < T::Struct
      extend T::Sig
      include Deserializable
      
      prop :name, String
      # Display is a reserved keyword in Ruby, so we need to rename it
      prop :display_name, T.nilable(String), default: nil
      prop :origin, String
      prop :path, String
      prop :refs, Refs

      sig { params(data: T::Hash[Symbol, T.untyped]).returns(Folder) }
      def self.deserialize(data)
        deserialize_nested(data, :refs, Refs)
        rename_keys(data, { display: :display_name })
        new(data)
      end
    end
  end
end
