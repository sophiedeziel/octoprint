# typed: true
# frozen_string_literal: true

module Octoprint
  class Settings
    module Legacy
      # Reads and writes values at a path of keys in nested settings hashes.
      #
      # @api private
      module HashPath
        class << self
          # Sets the value at a path, creating the missing parents
          #
          # @param hash [Hash]
          # @param path [Array<Symbol>]
          # @param value [Object]
          # @return [void]
          #: (Hash[Symbol, untyped], Array[Symbol], untyped) -> void
          def put(hash, path, value)
            *parents, leaf = path
            parents.inject(hash) { |child, parent| child[parent] ||= {} }[leaf] = value
          end

          # Removes the value at a path and yields it, then removes the parents left empty.
          # Does nothing when the path doesn't exist.
          #
          # @param hash [Hash]
          # @param path [Array<Symbol>]
          # @yieldparam value [Object] The removed value
          # @return [void]
          #: (Hash[Symbol, untyped], Array[Symbol]) { (untyped) -> void } -> void
          def take(hash, path, &)
            *parents, leaf = path
            container = parents.inject(hash) { |child, parent| child.is_a?(Hash) ? child[parent] : nil }
            return unless container.is_a?(Hash) && container.key?(leaf)

            yield container.delete(leaf)
            prune(hash, parents)
          end

          private

          #: (Hash[Symbol, untyped], Array[Symbol]) -> void
          def prune(hash, parents)
            parents.size.downto(1) do |depth|
              *above, key = parents.first(depth)
              container = above.inject(hash) { |child, parent| child[parent] }
              container.delete(key) if container[key].empty?
            end
          end
        end
      end
    end
  end
end
