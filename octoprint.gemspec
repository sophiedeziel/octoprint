# frozen_string_literal: true

require_relative "lib/octoprint/version"

Gem::Specification.new do |spec|
  spec.name          = "octoprint"
  spec.version       = Octoprint::VERSION
  spec.authors       = ["Sophie Déziel"]
  spec.email         = ["courrier@sophiedeziel.com"]

  spec.summary       = "Type-safe Ruby client for the OctoPrint REST API, with Sorbet signatures."
  spec.description   = "Ruby client for OctoPrint's REST API covering files, jobs, printer state and commands, " \
                       "printer profiles, connection, access control, settings, timelapse, logs, system " \
                       "commands and more. Typed with Sorbet; API errors map to typed exceptions."
  spec.homepage      = "https://github.com/sophiedeziel/octoprint"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.3"

  spec.metadata = {
    "allowed_push_host" => "https://rubygems.org",
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "#{spec.homepage}/tree/v#{spec.version}",
    "changelog_uri" => "#{spec.homepage}/blob/v#{spec.version}/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "documentation_uri" => "https://rubydoc.info/gems/octoprint/#{spec.version}",
    "rubygems_mfa_required" => "true"
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 7.1", "< 9"
  spec.add_dependency "faraday", ">= 2.2", "< 2.15"
  spec.add_dependency "faraday-multipart", ">= 1.0.3", "< 1.3.0"
  spec.add_dependency "sorbet-runtime", ">= 0.5.10908", "< 0.7.0"
  spec.add_dependency "zeitwerk", "~> 2.6"
end
