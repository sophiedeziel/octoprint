# typed: true
# frozen_string_literal: true

require "sorbet-runtime"

module Octoprint
  class Files
    # A folder in the file system
    class Folder
      extend T::Sig
      include Deserializable
      include AutoInitializable

      auto_attr :name, type: String
      # Display is a reserved keyword in Ruby, so we need to rename it
      auto_attr :display_name, type: String
      auto_attr :origin, type: Location
      auto_attr :path, type: String
      auto_attr :refs, type: Refs

      auto_initialize!

      # Configure deserialization
      deserialize_config do
        nested :refs, Refs
        rename display: :display_name
      end
    end
  end
end
