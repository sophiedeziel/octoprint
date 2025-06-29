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
      data = { items: ["item1", "item2", "item3"] }
      instance = test_class.deserialize(data)

      expect(instance.items).to eq(["item1", "item2", "item3"])
    end
  end

  describe "helper methods" do
    describe "rename_keys" do
      it "renames keys according to mapping" do
        data = { old_key: "value1", another_key: "value2" }
        mapping = { old_key: :new_key }

        # Use the class method directly
        result = Octoprint::Deserializable::ClassMethods.instance_method(:rename_keys)
                   .bind_call(Class.new.extend(Octoprint::Deserializable::ClassMethods), data, mapping)

        expect(result).to eq({ new_key: "value1", another_key: "value2" })
        expect(data).to eq({ new_key: "value1", another_key: "value2" }) # Modifies original
      end

      it "handles missing keys gracefully" do
        data = { existing_key: "value" }
        mapping = { missing_key: :new_key }

        result = Octoprint::Deserializable::ClassMethods.instance_method(:rename_keys)
                   .bind_call(Class.new.extend(Octoprint::Deserializable::ClassMethods), data, mapping)

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
      expect(config.handle_extras?).to be(false)
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

    it "enables extras collection" do
      config.collect_extras
      expect(config.handle_extras?).to be(true)
    end
  end
end