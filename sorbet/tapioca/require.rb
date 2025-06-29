# typed: true
# frozen_string_literal: true

require "active_support/all"
require "dotenv/load"
require "faraday"
require "faraday/multipart"
require "pry"
require "rspec/its"
require "rspec/sorbet"
require "sorbet-runtime"
require "vcr"
require "zeitwerk"

# Load our gem and eager load all classes for DSL compilation
require_relative "../../lib/octoprint"

# Eager load all classes using Zeitwerk
Zeitwerk::Registry.loaders.each(&:eager_load) if defined?(Zeitwerk::Registry)
