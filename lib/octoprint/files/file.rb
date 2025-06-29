# typed: true
# frozen_string_literal: true

require "sorbet-runtime"

module Octoprint
  class Files
    # File information
    class File < T::Struct
      extend T::Sig
      include Deserializable

      prop :name, String
      # Display is a reserved keyword in Ruby, so we need to rename it
      prop :display_name, T.nilable(String)
      prop :origin, Location
      prop :path, String
      prop :type, T.nilable(String)
      prop :type_path, T.nilable(T::Array[String])
      prop :refs, T.nilable(Refs)
      prop :display_layer_progress, T.nilable(Hash)
      prop :dashboard, T.nilable(Hash)
      prop :date, T.nilable(Integer)
      prop :gcode_analysis, T.nilable(Hash)
      prop :md5_hash, T.nilable(String)
      prop :size, T.nilable(Integer)
      prop :userdata, T.nilable(Hash)
      prop :children, T.nilable(T::Array[File])
      prop :prints, T.nilable(Hash)
      prop :statistics, T.nilable(Hash)
      prop :extra, T.nilable(Hash)

      sig { params(data: T::Hash[Symbol, T.untyped]).returns(File) }
      def self.deserialize(data)
        deserialize_nested(data, :refs, Refs)
        deserialize_nested(data, :origin, Location)
        deserialize_array(data, :children, File)
        
        rename_keys(data, { display: :display_name, hash: :md5_hash })
        extras(data)

        new(**T.unsafe(data))
      end

      sig { params(data: T::Hash[Symbol, T.untyped]).void }
      def self.extras(data)
        extra_keys = data.keys - props.keys
        data[:extra] = data.delete_if { |key, _v| extra_keys.include?(key) }
      end
    end
  end
end
