# typed: true
# frozen_string_literal: true

module Octoprint
  class Files
    # Result of uploading a file or creating a folder
    class OperationResult
      extend T::Sig
      include Deserializable
      include AutoInitializable

      auto_attr :done, type: T::Boolean
      auto_attr :effective_select, type: T::Boolean
      auto_attr :effective_print, type: T::Boolean
      auto_attr :files, type: Hash
      auto_attr :folder, type: Folder

      auto_initialize!

      # Configure deserialization
      deserialize_config do
        nested :folder, Files::Folder

        # Custom transformation for files hash with Location keys
        transform do |data|
          if data[:files]
            new_files = {}
            data[:files].each do |key, value|
              location_key = Location.deserialize(key.to_s)
              new_files[location_key] = Files::File.deserialize(value)
            end
            data[:files] = new_files
          end
        end
      end
    end
  end
end
