# typed: true
# frozen_string_literal: true

require "sorbet-runtime"

module Octoprint
  class Files
    # File information
    class File
      extend T::Sig
      include Deserializable
      include AutoInitializable

      auto_attr :name
      # Display is a reserved keyword in Ruby, so we need to rename it
      auto_attr :display_name
      auto_attr :origin
      auto_attr :path
      auto_attr :type
      auto_attr :type_path
      auto_attr :refs
      auto_attr :display_layer_progress
      auto_attr :dashboard
      auto_attr :date
      auto_attr :gcode_analysis
      auto_attr :md5_hash
      auto_attr :size
      auto_attr :userdata
      auto_attr :children
      auto_attr :prints
      auto_attr :statistics
      auto_attr :extra

      auto_initialize!

      # Configure deserialization
      deserialize_config do
        nested :refs, Refs
        nested :origin, Location
        array :children, File
        rename display: :display_name, hash: :md5_hash
        collect_extras
      end
    end
  end
end
