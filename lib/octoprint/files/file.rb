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

      sig { params(data: T::Hash[Symbol, T.untyped]).returns(File) }
      def self.deserialize(data)
        deserialize_nested(data, :refs, Refs)
        deserialize_nested(data, :origin, Location)
        deserialize_array(data, :children, File)
        
        rename_keys(data, { display: :display_name, hash: :md5_hash })
        extras(data)

        new(**data)
      end

      sig { params(data: T::Hash[Symbol, T.untyped]).void }
      def self.extras(data)
        # Get all valid attribute names from auto_attrs
        valid_keys = auto_attrs.keys
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
  end
end
