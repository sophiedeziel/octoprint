# typed: true
# frozen_string_literal: true

require "sorbet-runtime"

module Octoprint
  class Files
    # References relevant to this file, left out in abridged version
    class Refs
      extend T::Sig
      include AutoInitializable
      
      auto_attr :resource
      auto_attr :download
      auto_attr :model

      auto_initialize!
    end
  end
end
