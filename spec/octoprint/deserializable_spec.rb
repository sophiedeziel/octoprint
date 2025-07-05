# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Octoprint::Deserializable do
  describe "basic deserialization" do
    let(:test_class) do
      Class.new do
        include Octoprint::Deserializable
        include Octoprint::AutoInitializable

        auto_attr :name, type: String
        auto_attr :email, type: String

        auto_initialize!

        deserialize_config do
          # No special configuration needed for basic test
        end
      end
    end

    it "deserializes simple data" do
      data = { name: "John", email: "john@example.com" }
      instance = test_class.deserialize(data)

      expect(instance.name).to eq("John")
      expect(instance.email).to eq("john@example.com")
    end

    it "handles missing configuration gracefully" do
      simple_class = Class.new do
        include Octoprint::Deserializable
        include Octoprint::AutoInitializable

        auto_attr :name, type: String

        auto_initialize!
        # No deserialize_config called
      end

      data = { name: "Test" }
      instance = simple_class.deserialize(data)

      expect(instance.name).to eq("Test")
    end
  end

  describe "key renaming" do
    let(:test_class) do
      Class.new do
        include Octoprint::Deserializable
        include Octoprint::AutoInitializable

        auto_attr :display_name, type: String
        auto_attr :md5_hash, type: String
        auto_attr :klass, type: String

        auto_initialize!

        deserialize_config do
          rename display: :display_name, hash: :md5_hash, class: :klass
        end
      end
    end

    it "renames keys to avoid Ruby method conflicts" do
      data = { display: "John Doe", hash: "abc123", class: "User" }
      instance = test_class.deserialize(data)

      expect(instance.display_name).to eq("John Doe")
      expect(instance.md5_hash).to eq("abc123")
      expect(instance.klass).to eq("User")
    end

    it "handles missing keys gracefully" do
      data = { display: "Jane Doe" }
      instance = test_class.deserialize(data)

      expect(instance.display_name).to eq("Jane Doe")
      expect(instance.md5_hash).to be_nil
      expect(instance.klass).to be_nil
    end
  end

  describe "custom transformations" do
    let(:test_class) do
      Class.new do
        include Octoprint::Deserializable
        include Octoprint::AutoInitializable

        auto_attr :name, type: String
        auto_attr :processed_at, type: String
        auto_attr :full_name, type: String

        auto_initialize!

        deserialize_config do
          transform do |data|
            data[:processed_at] = "2023-01-01"
            data[:full_name] = "#{data[:first_name]} #{data[:last_name]}" if data[:first_name] && data[:last_name]
          end
        end
      end
    end

    it "applies custom transformations" do
      data = { name: "John", first_name: "John", last_name: "Doe" }
      instance = test_class.deserialize(data)

      expect(instance.name).to eq("John")
      expect(instance.processed_at).to eq("2023-01-01")
      expect(instance.full_name).to eq("John Doe")
    end
  end

  describe "collect_extras functionality" do
    let(:test_class) do
      Class.new do
        include Octoprint::Deserializable
        include Octoprint::AutoInitializable

        auto_attr :name, type: String
        auto_attr :email, type: String
        auto_attr :extra, type: Hash

        auto_initialize!

        deserialize_config do
          collect_extras
        end
      end
    end

    it "collects unknown fields into extra hash" do
      data = {
        name: "John",
        email: "john@example.com",
        unknown_field: "value",
        another_field: 123
      }
      instance = test_class.deserialize(data)

      expect(instance.name).to eq("John")
      expect(instance.email).to eq("john@example.com")
      expect(instance.extra).to eq({
                                     unknown_field: "value",
                                     another_field: 123
                                   })
    end

    it "handles case with no unknown fields" do
      data = { name: "John", email: "john@example.com" }
      instance = test_class.deserialize(data)

      expect(instance.name).to eq("John")
      expect(instance.email).to eq("john@example.com")
      expect(instance.extra).to be_nil
    end
  end

  describe "integration with existing classes" do
    it "works with Files::File deserialization" do
      data = {
        name: "test.gcode",
        display: "Test File",
        origin: "local",
        path: "test.gcode",
        hash: "abc123",
        refs: {
          resource: "http://example.com/files/test.gcode",
          download: "http://example.com/downloads/test.gcode"
        },
        unknown_field: "should be in extras"
      }

      instance = Octoprint::Files::File.deserialize(data)

      expect(instance.name).to eq("test.gcode")
      expect(instance.display_name).to eq("Test File")  # Renamed from display
      expect(instance.md5_hash).to eq("abc123")         # Renamed from hash
      expect(instance.path).to eq("test.gcode")
      expect(instance.refs).to be_an_instance_of(Octoprint::Files::Refs)
      expect(instance.refs.resource).to eq("http://example.com/files/test.gcode")
      expect(instance.extra).to eq({ unknown_field: "should be in extras" })
    end

    it "works with nested Location objects" do
      location_data = "local"
      location = Octoprint::Location.deserialize(location_data)

      expect(location).to eq(Octoprint::Location::Local)
    end
  end

  describe "array handling" do
    let(:test_class) do
      Class.new do
        include Octoprint::Deserializable
        include Octoprint::AutoInitializable

        auto_attr :items, type: String, array: true

        auto_initialize!

        deserialize_config do
          array :items, String
        end
      end
    end

    it "handles arrays of basic types" do
      data = { items: %w[item1 item2 item3] }
      instance = test_class.deserialize(data)

      expect(instance.items).to eq(%w[item1 item2 item3])
    end
  end

  describe "helper methods" do
    describe "rename_keys" do
      it "renames keys according to mapping" do
        data = { old_key: "value1", another_key: "value2" }
        mapping = { old_key: :new_key }

        # Use the class method directly
        klass = Class.new.extend(Octoprint::Deserializable::ClassMethods)
        result = Octoprint::Deserializable::ClassMethods.instance_method(:rename_keys)
                                                        .bind_call(klass, data, mapping)

        expect(result).to eq({ new_key: "value1", another_key: "value2" })
        expect(data).to eq({ new_key: "value1", another_key: "value2" }) # Modifies original
      end

      it "handles missing keys gracefully" do
        data = { existing_key: "value" }
        mapping = { missing_key: :new_key }

        klass = Class.new.extend(Octoprint::Deserializable::ClassMethods)
        result = Octoprint::Deserializable::ClassMethods.instance_method(:rename_keys)
                                                        .bind_call(klass, data, mapping)

        expect(result).to eq({ existing_key: "value" })
      end
    end

    describe "deserialize_nested" do
      let(:mock_class) do
        Class.new do
          def self.deserialize(data)
            "deserialized: #{data}"
          end
        end
      end

      it "uses deserialize method when available" do
        data = { field: "test_data" }
        klass = Class.new.extend(Octoprint::Deserializable::ClassMethods)

        klass.deserialize_nested(data, :field, mock_class)

        expect(data[:field]).to eq("deserialized: test_data")
      end

      it "handles nil values" do
        data = { field: nil }
        klass = Class.new.extend(Octoprint::Deserializable::ClassMethods)

        klass.deserialize_nested(data, :field, mock_class)

        expect(data[:field]).to be_nil
      end
    end
  end

  describe "configuration object" do
    let(:config) { Octoprint::Deserializable::DeserializationConfig.new }

    it "provides configuration methods" do
      expect(config.nested_objects).to eq({})
      expect(config.array_objects).to eq({})
      expect(config.key_mappings).to eq({})
      expect(config.transformations).to eq([])
    end

    it "stores nested configuration" do
      config.nested(:profile, String)
      expect(config.nested_objects).to eq({ profile: String })
    end

    it "stores array configuration" do
      config.array(:tags, String)
      expect(config.array_objects).to eq({ tags: String })
    end

    it "stores rename configuration" do
      config.rename({ display: :display_name, hash: :md5_hash })
      expect(config.key_mappings).to eq({ display: :display_name, hash: :md5_hash })
    end

    it "stores transformations" do
      transform_proc = proc { |data| data[:processed] = true }
      config.transform(&transform_proc)
      expect(config.transformations).to include(transform_proc)
    end

    it "supports collect_extras for backward compatibility" do
      # collect_extras is now a no-op but should not raise errors
      expect { config.collect_extras }.not_to raise_error
    end
  end

  describe "camelCase to snake_case conversion" do
    let(:test_class) do
      Class.new do
        include Octoprint::Deserializable
        include Octoprint::AutoInitializable

        auto_attr :first_name, type: String
        auto_attr :last_name, type: String
        auto_attr :heated_bed, type: T::Boolean
        auto_attr :phone_number, type: String

        auto_initialize!

        deserialize_config do
          # No special configuration needed - automatic camelCase conversion should work
        end
      end
    end

    it "automatically converts camelCase keys to snake_case" do
      # This test covers lines 303-304 and 329 in deserializable.rb
      data = {
        firstName: "John",
        lastName: "Doe",
        heatedBed: true,
        phoneNumber: "123-456-7890"
      }
      instance = test_class.deserialize(data)

      expect(instance.first_name).to eq("John")
      expect(instance.last_name).to eq("Doe")
      expect(instance.heated_bed).to be true
      expect(instance.phone_number).to eq("123-456-7890")
    end

    it "handles mixed camelCase and snake_case keys" do
      data = {
        firstName: "Jane",
        last_name: "Smith", # Already snake_case
        heatedBed: false
      }
      instance = test_class.deserialize(data)

      expect(instance.first_name).to eq("Jane")
      expect(instance.last_name).to eq("Smith")
      expect(instance.heated_bed).to be false
    end

    it "leaves non-camelCase keys unchanged" do
      data = {
        first_name: "Bob", # Already snake_case
        last_name: "Wilson"
      }
      instance = test_class.deserialize(data)

      expect(instance.first_name).to eq("Bob")
      expect(instance.last_name).to eq("Wilson")
    end
  end

  describe "edge cases in deserialization" do
    let(:test_class) do
      Class.new do
        include Octoprint::Deserializable
        attr_reader :value, :nested_obj, :array_items

        def initialize(value: nil, nested_obj: nil, array_items: [])
          @value = value
          @nested_obj = nested_obj
          @array_items = array_items
        end

        deserialize_config do
          nested :nested_obj, self
          array :array_items, self
        end
      end
    end

    it "handles falsy but not nil values in nested deserialization" do
      data = { nested_obj: false }
      result = test_class.deserialize(data)
      expect(result.nested_obj).to be false
    end

    it "handles falsy but not nil values in array deserialization" do
      data = { array_items: [false, 0, ""] }
      result = test_class.deserialize(data)
      expect(result.array_items).to eq([false, 0, ""])
    end

    it "handles objects without deserialize method in nested fields" do
      simple_class = Class.new do
        attr_reader :name

        def initialize(name:)
          @name = name
        end
      end

      test_class_with_simple = Class.new do
        include Octoprint::Deserializable
        attr_reader :simple_obj

        def initialize(simple_obj: nil)
          @simple_obj = simple_obj
        end

        deserialize_config do
          nested :simple_obj, simple_class
        end
      end

      data = { simple_obj: { name: "test" } }
      result = test_class_with_simple.deserialize(data)
      # Since simple_class doesn't have deserialize, it creates a new instance
      expect(result.simple_obj).to be_a(simple_class)
      expect(result.simple_obj.name).to eq("test")
    end

    it "handles array items that cannot be deserialized" do
      # Create a class that responds to :new but we'll pass non-hash items
      # to trigger the else branch on line 250
      simple_class = Class.new do
        def self.respond_to?(method_name, include_private: false)
          return false if method_name == :deserialize

          super
        end

        def self.new(**)
          # This would normally work for hash items
          "new_called"
        end
      end

      test_class_with_array = Class.new do
        include Octoprint::Deserializable
        attr_reader :items

        def initialize(items: [])
          @items = items
        end

        deserialize_config do
          array :items, simple_class
        end
      end

      # Test with non-hash items - since items are strings, not hashes,
      # the elsif condition fails and we hit the else branch (line 250)
      data = { items: %w[item1 item2 item3] }
      result = test_class_with_array.deserialize(data)

      # Items should remain unchanged since they can't be deserialized (line 250)
      expect(result.items).to eq(%w[item1 item2 item3])
    end

    it "handles array items that can be deserialized with new" do
      # Create a class that responds to :new but NOT to :deserialize to trigger the elsif branch on line 249
      simple_class = Class.new do
        attr_reader :name

        def self.respond_to?(method_name, include_private: false)
          return false if method_name == :deserialize

          super
        end

        def initialize(name:)
          @name = name
        end
      end

      test_class_with_array = Class.new do
        include Octoprint::Deserializable
        attr_reader :items

        def initialize(items: [])
          @items = items
        end

        deserialize_config do
          array :items, simple_class
        end
      end

      # Test with hash items - since items are hashes and class responds to :new,
      # we hit the elsif branch (line 249)
      data = { items: [{ name: "item1" }, { name: "item2" }] }
      result = test_class_with_array.deserialize(data)

      # Items should be converted to simple_class instances via new (line 249)
      expect(result.items).to be_an(Array)
      expect(result.items.length).to eq(2)
      expect(result.items.first).to be_a(simple_class)
      expect(result.items.first.name).to eq("item1")
      expect(result.items.last.name).to eq("item2")
    end

    it "handles classes without auto_attrs gracefully" do
      # Create a class that doesn't respond to auto_attrs
      test_class_without_auto_attrs = Class.new do
        include Octoprint::Deserializable
        attr_reader :name

        def initialize(**kwargs)
          @name = kwargs[:name]
        end
      end

      data = { name: "test", unknown_field: "value" }
      result = test_class_without_auto_attrs.deserialize(data)

      # With automatic extras collection, classes without :extra attribute
      # simply ignore unknown fields (no extras collection happens)
      expect(result.name).to eq("test")
    end
  end
end
