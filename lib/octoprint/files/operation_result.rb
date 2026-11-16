# typed: true
# frozen_string_literal: true

module Octoprint
  class Files
    # Result of uploading a file or creating a folder
    #
    # Follows the OctoPrint 2.0 shape: the uploaded file is in `file`. With the 1.x API, {Files::Legacy} picks it out
    # of the 1.x `files: {local: {...}}`.
    #
    # @example
    #   result = Octoprint::Files.upload("benchy.gcode")
    #   result.file.origin # => Octoprint::Location::Local
    #
    # @!attribute [r] done
    #   @return [Boolean, nil] Whether the processing after the upload is done (false while e.g. still slicing or
    #     streaming to the printer)
    # @!attribute [r] effective_select
    #   @return [Boolean, nil] Whether the uploaded file was selected. nil for a folder
    # @!attribute [r] effective_print
    #   @return [Boolean, nil] Whether printing the uploaded file started. nil for a folder
    # @!attribute [r] file
    #   @return [Files::File, nil] The uploaded file. nil for a folder
    # @!attribute [r] folder
    #   @return [Files::Folder, nil] The created folder. nil for a file
    class OperationResult
      include Deserializable
      include AutoInitializable

      auto_attr :done, type: T::Boolean
      auto_attr :effective_select, type: T::Boolean
      auto_attr :effective_print, type: T::Boolean
      auto_attr :file, type: Files::File
      auto_attr :folder, type: Folder

      auto_initialize!

      # Configure deserialization
      deserialize_config do
        nested :file, Files::File
        nested :folder, Files::Folder
      end

      # The uploaded file, by location, like the 1.x response
      #
      # @deprecated Use {#file}. OctoPrint 2.0 returns a single `file`.
      # @return [Hash{Location => Files::File}, nil] nil for a folder
      #: -> Hash[Location, Files::File]?
      def files
        Deprecation.warn_once("Files::OperationResult#files", "use #file instead")

        uploaded = file
        uploaded && { uploaded.origin => uploaded }
      end
    end
  end
end
