# typed: true
# frozen_string_literal: true

require "sorbet-runtime"

module Octoprint
  class Files
    # File information
    class File < T::Struct
      extend T::Sig

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
        data[:refs] = Refs.new(data[:refs]) if data[:refs]
        data[:origin] = Location.deserialize(data[:origin]) if data[:origin]
        data[:children]&.map! { |child| File.deserialize(child) }

        rename_keys(data, { display: :display_name, hash: :md5_hash })
        extras(data)

        new(**T.unsafe(data))
      end

      sig { params(data: T::Hash[Symbol, T.untyped], mapping: T::Hash[Symbol, Symbol]).void }
      def self.rename_keys(data, mapping)
        mapping.each do |old_key, new_key|
          data[new_key] = data.delete(old_key) if data[old_key]
        end
      end

      sig { params(data: T::Hash[Symbol, T.untyped]).void }
      def self.extras(data)
        extra_keys = data.keys - props.keys
        data[:extra] = data.delete_if { |key, _v| extra_keys.include?(key) }
      end
    end
  end
end
