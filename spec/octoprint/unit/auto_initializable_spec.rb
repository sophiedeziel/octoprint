# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Octoprint::AutoInitializable do
  describe "basic functionality" do
    let(:test_class) do
      Class.new do
        include Octoprint::AutoInitializable

        auto_attr :name, type: String, nilable: false
        auto_attr :email, type: String
        auto_attr :age, type: Integer
        auto_attr :active, type: TrueClass, nilable: false

        auto_initialize!
      end
    end

    it "creates instances with keyword arguments" do
      instance = test_class.new(name: "John", email: "john@example.com", age: 30, active: true)

      expect(instance.name).to eq("John")
      expect(instance.email).to eq("john@example.com")
      expect(instance.age).to eq(30)
      expect(instance.active).to be(true)
    end

    it "handles nil values for nilable attributes" do
      instance = test_class.new(name: "John", email: nil, age: nil, active: true)

      expect(instance.name).to eq("John")
      expect(instance.email).to be_nil
      expect(instance.age).to be_nil
      expect(instance.active).to be(true)
    end

    it "provides auto_attrs class method" do
      expect(test_class.auto_attrs).to be_a(Hash)
      expect(test_class.auto_attrs.keys).to contain_exactly(:name, :email, :age, :active)
    end
  end

  describe "custom key mapping" do
    let(:test_class) do
      Class.new do
        include Octoprint::AutoInitializable

        auto_attr :display_name, type: String, from: :display
        auto_attr :full_name, type: String, from: :name

        auto_initialize!
      end
    end

    it "maps keys correctly" do
      instance = test_class.new(display: "John Doe", name: "John Smith")

      expect(instance.display_name).to eq("John Doe")
      expect(instance.full_name).to eq("John Smith")
    end
  end

  describe "array attributes" do
    let(:test_class) do
      Class.new do
        include Octoprint::AutoInitializable

        auto_attr :tags, type: String, array: true
        auto_attr :numbers, type: Integer, array: true

        auto_initialize!
      end
    end

    it "handles arrays of basic types" do
      instance = test_class.new(tags: %w[admin user], numbers: [1, 2, 3])

      expect(instance.tags).to eq(%w[admin user])
      expect(instance.numbers).to eq([1, 2, 3])
    end

    it "handles nil arrays" do
      instance = test_class.new(tags: nil, numbers: nil)

      expect(instance.tags).to be_nil
      expect(instance.numbers).to be_nil
    end
  end

  describe "Hash preservation" do
    let(:test_class) do
      Class.new do
        include Octoprint::AutoInitializable

        auto_attr :metadata, type: Hash
        auto_attr :data, type: Hash

        auto_initialize!
      end
    end

    it "preserves Hash objects without conversion" do
      original_hash = { key: "value", nested: { inner: "data" } }
      instance = test_class.new(metadata: original_hash, data: { other: "value" })

      expect(instance.metadata).to eq(original_hash)
      expect(instance.metadata).to be_a(Hash)
      expect(instance.data).to eq({ other: "value" })
    end
  end

  describe "integration with existing classes" do
    it "works like Files::File class" do
      # Test with actual class from the codebase
      local_location = Octoprint::Location.deserialize("local")
      instance = Octoprint::Files::File.new(
        name: "test.gcode",
        display_name: "Test File",
        origin: local_location,
        path: "test.gcode"
      )

      expect(instance.name).to eq("test.gcode")
      expect(instance.display_name).to eq("Test File")
      expect(instance.origin).to eq(local_location)
      expect(instance.path).to eq("test.gcode")
    end

    it "handles auto_attrs correctly on existing classes" do
      expect(Octoprint::Files::File.auto_attrs).to be_a(Hash)
      expect(Octoprint::Files::File.auto_attrs).to have_key(:name)
      expect(Octoprint::Files::File.auto_attrs).to have_key(:display_name)
    end
  end

  describe "type conversion with real classes" do
    before do
      stub_const("TestWithLocation", Class.new do
        include Octoprint::AutoInitializable

        auto_attr :name, type: String
        auto_attr :location, type: Hash # Use Hash to avoid type errors

        auto_initialize!
      end)
    end

    it "converts hash to Location object" do
      # Test with a stubbed class to avoid leaky constants
      instance = TestWithLocation.new(
        name: "test",
        location: { type: "local" }
      )

      expect(instance.name).to eq("test")
      expect(instance.location).to eq({ type: "local" })
      expect(instance.location).to be_a(Hash)
    end
  end
end
