# typed: true
# frozen_string_literal: true

module Octoprint
  class Files
    # Result of uploading a file or creating a folder
    class OperationResult
      extend T::Sig
      include Deserializable
      include AutoInitializable
      
      auto_attr :done
      auto_attr :effective_select
      auto_attr :effective_print
      auto_attr :files
      auto_attr :folder

      auto_initialize!

      sig { params(data: T::Hash[Symbol, T.untyped]).returns(OperationResult) }
      def self.deserialize(data)
        deserialize_nested(data, :folder, Files::Folder)
        
        # Handle the special case of files hash with Location keys
        if data[:files]
          new_files = {}
          data[:files].each do |key, value|
            location_key = Location.deserialize(key.to_s)
            new_files[location_key] = Files::File.deserialize(value)
          end
          data[:files] = new_files
        end
        
        new(**data)
      end
    end
  end
end
