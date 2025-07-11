# frozen_string_literal: true

require_relative "lib/octoprint/version"

Gem::Specification.new do |spec|
  spec.name          = "octoprint"
  spec.version       = Octoprint::VERSION
  spec.authors       = ["Sophie Déziel"]
  spec.email         = ["courrier@sophiedeziel.com"]

  spec.summary       = "A comprehensive, type-safe Ruby wrapper for OctoPrint's REST API with full Sorbet integration."
  spec.description   = "A comprehensive, type-safe Ruby wrapper for OctoPrint's REST API with full Sorbet " \
                       "integration. Features include smart error handling, 100% test coverage, and support " \
                       "for Files, Jobs, Printer Profiles, Connections, Logs, and more."
  spec.homepage      = "https://github.com/sophiedeziel/octoprint"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sophiedeziel/octoprint"
  spec.metadata["changelog_uri"] = "https://github.com/sophiedeziel/octoprint/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "faraday", ">= 2.2", "< 2.14"
  spec.add_dependency "faraday-multipart", ">= 1.0.3", "< 1.2.0"
  spec.add_dependency "sorbet-runtime", "~> 0.5.10908"
  spec.add_dependency "zeitwerk", "~> 2.6"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
