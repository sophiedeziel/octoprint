# typed: true
# frozen_string_literal: true

module Octoprint
  module Deserializable
    extend T::Sig
    extend T::Helpers

    module ClassMethods
      extend T::Sig

      sig { params(data: T::Hash[Symbol, T.untyped], mapping: T::Hash[Symbol, Symbol]).returns(T::Hash[Symbol, T.untyped]) }
      def rename_keys(data, mapping)
        mapping.each do |old_key, new_key|
          data[new_key] = data.delete(old_key) if data.key?(old_key)
        end
        data
      end

      sig do
        params(
          data: T::Hash[Symbol, T.untyped],
          field: Symbol,
          klass: T.any(T::Class[T.anything], T.class_of(T::Struct), T.class_of(T::Enum))
        ).returns(T::Hash[Symbol, T.untyped])
      end
      def deserialize_nested(data, field, klass)
        if data[field] && klass.respond_to?(:deserialize)
          data[field] = klass.deserialize(data[field])
        elsif data[field] && klass.respond_to?(:new) && data[field].is_a?(Hash)
          data[field] = klass.new(**data[field])
        end
        data
      end

      sig do
        params(
          data: T::Hash[Symbol, T.untyped],
          field: Symbol,
          klass: T.any(T::Class[T.anything], T.class_of(T::Struct), T.class_of(T::Enum))
        ).returns(T::Hash[Symbol, T.untyped])
      end
      def deserialize_array(data, field, klass)
        if data[field].is_a?(Array)
          data[field] = data[field].map do |item|
            if klass.respond_to?(:deserialize)
              klass.deserialize(item)
            elsif klass.respond_to?(:new) && item.is_a?(Hash)
              klass.new(**item)
            else
              item
            end
          end
        end
        data
      end

    end

    mixes_in_class_methods(ClassMethods)
  end
end