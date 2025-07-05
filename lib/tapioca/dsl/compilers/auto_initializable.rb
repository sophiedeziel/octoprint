# typed: false
# frozen_string_literal: true

module Tapioca
  module Dsl
    module Compilers
      # Tapioca compiler for classes using AutoInitializable module.
      #
      # This compiler generates RBI files with proper Sorbet type signatures
      # for classes that include the AutoInitializable module, replacing the
      # need for dynamic code generation at runtime.
      class AutoInitializable < Tapioca::Dsl::Compiler
        ConstantType = type_member { { upper: Module } }

        # Gather all classes that include AutoInitializable module.
        sig { override.returns(T::Enumerable[Module]) }
        def self.gather_constants
          # Ensure our classes are loaded (fallback if require.rb doesn't work)
          unless defined?(::Octoprint::AutoInitializable)
            gem_root = File.expand_path("../../../..", __dir__)
            require File.join(gem_root, "lib", "octoprint")

            Zeitwerk::Registry.loaders.each(&:eager_load) if defined?(Zeitwerk::Registry)
          end

          all_modules.select do |constant|
            constant.is_a?(Class) &&
              constant.respond_to?(:auto_attrs) &&
              constant.included_modules.any? { |mod| mod.name == "Octoprint::AutoInitializable" }
          end
        end

        # Generates RBI content for the AutoInitializable class.
        sig { override.void }
        def decorate
          auto_attrs = constant.auto_attrs
          return if auto_attrs.empty?

          root.create_path(constant) do |klass|
            auto_attrs.each do |name, config|
              sorbet_type = generate_sorbet_type(config)

              klass.create_method(
                name.to_s,
                return_type: sorbet_type,
                class_method: false
              )
            end
          end
        end

        private

        # Generates Sorbet type string for a configuration.
        def generate_sorbet_type(config)
          type = config[:type]

          # Handle the case where type is already a Sorbet type
          return type.to_s if type.respond_to?(:to_s) && (type.to_s.start_with?("T.") || type.to_s.start_with?("T::"))

          # Convert type to string representation
          base_type = case type
                      when Class
                        # For regular classes, use the class name
                        qualified_name_of(type)
                      when String
                        # For primitive types passed as strings
                        type
                      when Symbol
                        # For primitive types passed as symbols
                        type.to_s.capitalize
                      else
                        # Handle T.untyped case and other untyped cases
                        "T.untyped"
                      end

          # Handle array types
          base_type = "T::Array[#{base_type}]" if config[:array]

          # Handle nilable types
          base_type = "T.nilable(#{base_type})" if config[:nilable]

          base_type
        end
      end
    end
  end
end
