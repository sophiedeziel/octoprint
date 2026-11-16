# typed: true
# frozen_string_literal: true

require "sorbet-runtime"

module Octoprint
  class Files
    # References relevant to this file, left out in abridged version
    #
    # @example A file with an embedded thumbnail (OctoPrint 2.0)
    #   file = Octoprint::Files.get(filename: "benchy.gcode")
    #   file.refs.thumbnail  # => "http://octopi.local/downloads/thumbs/local/benchy.gcode"
    #   file.refs.thumbnails # => { "16x16" => "http://octopi.local/downloads/thumbs/local/benchy.gcode?size=16x16" }
    #
    # @!attribute [r] resource
    #   @return [String, nil] URL of the file or folder in the API
    # @!attribute [r] download
    #   @return [String, nil] Download URL. nil for folders and storages that can't be read (e.g. the printer)
    # @!attribute [r] model
    #   @return [String, nil] URL of the model the file was sliced from, if known
    # @!attribute [r] thumbnail
    #   @return [String, nil] URL of the largest thumbnail embedded in the file (OctoPrint 2.0)
    # @!attribute [r] thumbnails
    #   @return [Hash{String => String}, nil] Thumbnail URLs by size (`"16x16"`), from the `thumbnail_<size>` refs
    #     (OctoPrint 2.0)
    class Refs
      include Deserializable
      include AutoInitializable

      # Prefix of the refs of each thumbnail size: thumbnail_16x16
      THUMBNAIL_PREFIX = "thumbnail_"

      auto_attr :resource, type: String
      auto_attr :download, type: String
      auto_attr :model, type: String
      auto_attr :thumbnail, type: String
      auto_attr :thumbnails, type: Hash

      auto_initialize!

      deserialize_config do
        transform do |data|
          sizes = data.keys.select { |key| key.to_s.start_with?(THUMBNAIL_PREFIX) }
          next if sizes.empty?

          data[:thumbnails] = sizes.to_h { |key| [key.to_s.delete_prefix(THUMBNAIL_PREFIX), data.delete(key)] }
        end
      end
    end
  end
end
