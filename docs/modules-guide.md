# AutoInitializable and Deserializable Modules Guide

This guide explains how to use the `AutoInitializable` and `Deserializable` modules to create new API classes efficiently and consistently.

## Overview

The OctoPrint gem provides two powerful modules that eliminate boilerplate code:

- **AutoInitializable**: Automatically generates initialization and typed attribute readers
- **Deserializable**: Provides a declarative DSL for transforming API responses into Ruby objects

Together, these modules replace the need for `T::Struct` inheritance and manual deserialization code.

## Quick Start

Here's a complete example of creating a new API class:

```ruby
module Octoprint
  class Printer
    include Deserializable
    include AutoInitializable

    # Declare attributes with types
    auto_attr :name, type: String, nilable: false
    auto_attr :state, type: String
    auto_attr :temperature, type: Integer
    auto_attr :bed_temperature, type: Integer
    auto_attr :display_name, type: String  # Will be renamed from API's "display" field
    auto_attr :metadata, type: Hash
    auto_attr :tools, type: Tool, array: true
    auto_attr :extra, type: Hash  # For unknown API fields

    # Generate initialization code
    auto_initialize!

    # Configure deserialization
    deserialize_config do
      rename display: :display_name           # Avoid Ruby method conflicts
      array :tools, Tool                     # Convert array of tool hashes
      collect_extras                         # Collect unknown fields
      
      transform do |data|
        # Custom transformation logic
        data[:metadata][:processed_at] = Time.now
      end
    end
  end
end
```

## AutoInitializable Module

### Basic Usage

```ruby
class SimpleClass
  include AutoInitializable

  auto_attr :name, type: String, nilable: false
  auto_attr :email, type: String
  auto_attr :age, type: Integer

  auto_initialize!
end

# Usage
instance = SimpleClass.new(name: "John", email: "john@example.com", age: 30)
instance.name   # => "John" (typed as String)
instance.email  # => "john@example.com" (typed as T.nilable(String))
instance.age    # => 30 (typed as T.nilable(Integer))
```

### auto_attr Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `type` | Class/Type | `T.untyped` | The type of the attribute |
| `nilable` | Boolean | `true` | Whether the attribute can be nil |
| `array` | Boolean | `false` | Whether this is an array of the specified type |
| `from` | Symbol | Same as name | The source key in initialization hash |

### Examples

```ruby
# Required string attribute
auto_attr :name, type: String, nilable: false

# Optional integer
auto_attr :age, type: Integer  # nilable: true by default

# Array of strings
auto_attr :tags, type: String, array: true

# Custom key mapping (API uses "display", we use "display_name")
auto_attr :display_name, type: String, from: :display

# Hash that's preserved as-is
auto_attr :metadata, type: Hash

# Nested object that gets converted from hash
auto_attr :profile, type: Profile

# Array of nested objects
auto_attr :tools, type: Tool, array: true
```

### Type Conversion

AutoInitializable automatically handles type conversion:

```ruby
# Basic Ruby types are preserved
auto_attr :data, type: Hash        # No conversion
auto_attr :items, type: Array      # No conversion  
auto_attr :text, type: String      # No conversion

# Custom classes are converted from hashes
auto_attr :profile, type: Profile  # Calls Profile.new(**hash_data)

# Arrays of custom classes
auto_attr :tools, type: Tool, array: true  # Maps each hash to Tool.new(**hash)
```

## Deserializable Module

### Basic Usage

```ruby
class ApiClass
  include Deserializable
  include AutoInitializable

  auto_attr :name, type: String
  auto_attr :value, type: Integer

  auto_initialize!

  deserialize_config do
    # Configuration goes here
  end
end

# Usage
api_data = { name: "test", value: 42 }
instance = ApiClass.deserialize(api_data)
```

### DSL Methods

#### `rename` - Key Renaming

Rename API fields to avoid Ruby method conflicts or follow conventions:

```ruby
deserialize_config do
  rename display: :display_name,    # Object#display conflict
         hash: :md5_hash,           # Object#hash conflict  
         class: :klass,             # Object#class conflict
         type: :item_type           # More descriptive name
end
```

**Common Ruby method conflicts to avoid:**
- `display` → `display_name` (Object#display)
- `hash` → `md5_hash` or `content_hash` (Object#hash)
- `class` → `klass` or `item_class` (Object#class)
- `method` → `http_method` (Object#method)
- `send` → `send_data` (Object#send)

#### `nested` - Nested Objects

Convert nested hash data to specific classes:

```ruby
deserialize_config do
  nested :profile, Profile          # data[:profile] hash → Profile instance
  nested :location, Location        # data[:location] hash → Location instance
  nested :settings, PrinterSettings
end
```

#### `array` - Array Conversion

Convert arrays of hashes to arrays of objects:

```ruby
deserialize_config do
  array :tools, Tool        # Array of tool hashes → Array of Tool instances
  array :files, File        # Array of file hashes → Array of File instances
  array :tags, String       # Array of strings (no conversion needed)
end
```

#### `transform` - Custom Transformations

Apply custom logic to transform data:

```ruby
deserialize_config do
  transform do |data|
    # Add computed fields
    data[:full_name] = "#{data[:first_name]} #{data[:last_name]}"
    
    # Parse timestamps
    data[:created_at] = Time.parse(data[:created_at]) if data[:created_at]
    
    # Clean up data
    data[:description] = data[:description]&.strip
    
    # Conditional logic
    if data[:temperature] && data[:temperature] > 0
      data[:is_heated] = true
    end
  end
end
```

#### `collect_extras` - Unknown Fields

Collect any unknown API fields into an `:extra` hash for forward compatibility:

```ruby
auto_attr :extra, type: Hash  # Don't forget to declare this!

deserialize_config do
  collect_extras  # Unknown fields go into data[:extra]
end
```

### Complete Example

```ruby
module Octoprint
  class PrintJob
    include Deserializable
    include AutoInitializable

    # Basic attributes
    auto_attr :id, type: String, nilable: false
    auto_attr :name, type: String
    auto_attr :display_name, type: String  # Renamed from "display"
    auto_attr :status, type: String
    
    # Nested objects
    auto_attr :file, type: Files::File
    auto_attr :progress, type: Job::Progress
    
    # Arrays
    auto_attr :tags, type: String, array: true
    auto_attr :operations, type: Operation, array: true
    
    # Timestamps and metadata
    auto_attr :created_at, type: Time
    auto_attr :metadata, type: Hash
    auto_attr :extra, type: Hash

    auto_initialize!

    deserialize_config do
      # Rename conflicting keys
      rename display: :display_name
      
      # Convert nested objects
      nested :file, Files::File
      nested :progress, Job::Progress
      
      # Convert arrays
      array :operations, Operation
      array :tags, String
      
      # Collect unknown fields
      collect_extras
      
      # Custom transformations
      transform do |data|
        # Parse ISO8601 timestamp
        if data[:created_at].is_a?(String)
          data[:created_at] = Time.parse(data[:created_at])
        end
        
        # Add computed status
        data[:is_active] = %w[printing paused].include?(data[:status])
        
        # Ensure metadata exists
        data[:metadata] ||= {}
        data[:metadata][:processed_at] = Time.now
      end
    end
  end
end
```

## Creating a New Class Step-by-Step

### 1. Create the Class File

```ruby
# lib/octoprint/printer_status.rb
module Octoprint
  class PrinterStatus
    include Deserializable
    include AutoInitializable
    
    # Step 2: Add attributes here
    # Step 3: Add auto_initialize! here  
    # Step 4: Add deserialize_config here
  end
end
```

### 2. Analyze the API Response

Look at a sample API response to understand the data structure:

```json
{
  "name": "MK3S+",
  "display": "Prusa MK3S+",
  "state": "printing", 
  "temperature": 210,
  "bed_temp": 60,
  "progress": {
    "completion": 45.5,
    "time_left": 1800
  },
  "tools": [
    {"id": 0, "name": "Extruder", "temp": 210},
    {"id": 1, "name": "Extruder 2", "temp": 0}
  ],
  "metadata": {"firmware": "3.10.0"},
  "unknown_future_field": "some_value"
}
```

### 3. Declare Attributes

```ruby
# Basic fields
auto_attr :name, type: String, nilable: false
auto_attr :display_name, type: String  # Will rename from "display"
auto_attr :state, type: String
auto_attr :temperature, type: Integer
auto_attr :bed_temp, type: Integer

# Nested objects (create these classes separately)
auto_attr :progress, type: PrintProgress

# Arrays
auto_attr :tools, type: Tool, array: true

# Metadata and extras
auto_attr :metadata, type: Hash
auto_attr :extra, type: Hash  # For unknown fields

auto_initialize!
```

### 4. Configure Deserialization

```ruby
deserialize_config do
  # Rename problematic keys
  rename display: :display_name
  
  # Handle nested objects
  nested :progress, PrintProgress
  
  # Handle arrays
  array :tools, Tool
  
  # Collect unknown fields for future compatibility
  collect_extras
  
  # Any custom transformations
  transform do |data|
    # Convert temperature units if needed
    if data[:temperature] && data[:temp_unit] == "F"
      data[:temperature] = ((data[:temperature] - 32) * 5.0 / 9.0).round
    end
  end
end
```

### 5. Create Supporting Classes

Create any nested classes you referenced:

```ruby
# lib/octoprint/print_progress.rb
module Octoprint
  class PrintProgress
    include Deserializable
    include AutoInitializable

    auto_attr :completion, type: Float
    auto_attr :time_left, type: Integer

    auto_initialize!

    deserialize_config do
      # Simple class, no special configuration needed
    end
  end
end

# lib/octoprint/tool.rb
module Octoprint
  class Tool
    include Deserializable  
    include AutoInitializable

    auto_attr :id, type: Integer, nilable: false
    auto_attr :name, type: String
    auto_attr :temp, type: Integer

    auto_initialize!
  end
end
```

### 6. Add Tests

```ruby
# spec/octoprint/printer_status_spec.rb
RSpec.describe Octoprint::PrinterStatus do
  describe ".deserialize" do
    it "deserializes API response correctly" do
      api_data = {
        name: "MK3S+",
        display: "Prusa MK3S+", 
        state: "printing",
        temperature: 210,
        progress: { completion: 45.5, time_left: 1800 },
        tools: [{ id: 0, name: "Extruder", temp: 210 }],
        unknown_field: "future_value"
      }

      status = described_class.deserialize(api_data)

      expect(status.name).to eq("MK3S+")
      expect(status.display_name).to eq("Prusa MK3S+")  # Renamed
      expect(status.progress).to be_a(Octoprint::PrintProgress)
      expect(status.tools.first).to be_a(Octoprint::Tool)
      expect(status.extra).to eq({ unknown_field: "future_value" })
    end
  end
end
```

### 7. Integration

Add the class to the main API interface:

```ruby
# lib/octoprint.rb (or relevant API module)
module Octoprint
  class Client
    def printer_status
      response = request(:get, "/api/printer")
      PrinterStatus.deserialize(response)
    end
  end
end
```

## Best Practices

### 1. Always Use Both Modules Together

```ruby
# ✅ Correct
include Deserializable
include AutoInitializable

# ❌ Don't use just one
include AutoInitializable  # Missing deserialization
```

### 2. Handle Ruby Method Conflicts

Always rename fields that conflict with Ruby built-in methods:

```ruby
# ✅ Correct
auto_attr :display_name, type: String
deserialize_config do
  rename display: :display_name
end

# ❌ Problematic
auto_attr :display, type: String  # Conflicts with Object#display
```

### 3. Use collect_extras for Forward Compatibility

```ruby
# ✅ Good practice - handles future API changes
auto_attr :extra, type: Hash
deserialize_config do
  collect_extras
end
```

### 4. Order Matters in deserialize_config

Transformations are applied in this order:
1. `nested` - Convert nested objects
2. `array` - Convert array elements  
3. `rename` - Rename keys
4. `transform` - Custom transformations
5. `collect_extras` - Collect unknown fields

```ruby
# ✅ Logical order
deserialize_config do
  nested :profile, Profile     # 1. Convert nested objects first
  array :tags, Tag            # 2. Convert arrays
  rename display: :display_name # 3. Rename keys
  transform { |data| ... }    # 4. Custom logic
  collect_extras              # 5. Collect leftovers last
end
```

### 5. Use Descriptive Type Names

```ruby
# ✅ Clear and specific
auto_attr :creation_timestamp, type: Time
auto_attr :file_size_bytes, type: Integer
auto_attr :printer_settings, type: PrinterSettings

# ❌ Vague or confusing
auto_attr :time, type: Time
auto_attr :size, type: Integer  
auto_attr :settings, type: Hash
```

### 6. Add Comprehensive Tests

Test both the individual class and integration with the API:

```ruby
describe YourClass do
  describe ".deserialize" do
    it "handles complete data" do
      # Test with full API response
    end
    
    it "handles missing optional fields" do
      # Test with minimal data
    end
    
    it "renames conflicting keys" do
      # Test key renaming
    end
    
    it "converts nested objects" do
      # Test nested object conversion
    end
    
    it "collects unknown fields" do
      # Test extra field collection
    end
  end
end
```

## Migration from T::Struct

If you're migrating an existing `T::Struct` class:

### Before (T::Struct)
```ruby
class OldClass < T::Struct
  const :name, String
  const :email, T.nilable(String)
  
  def self.deserialize(data)
    new(
      name: data[:name],
      email: data[:email]
    )
  end
end
```

### After (AutoInitializable + Deserializable)
```ruby
class NewClass
  include Deserializable
  include AutoInitializable

  auto_attr :name, type: String, nilable: false
  auto_attr :email, type: String

  auto_initialize!

  deserialize_config do
    # Add any needed transformations
  end
end
```

## Troubleshooting

### Common Issues

1. **"undefined method" errors**: Make sure to call `auto_initialize!` after all `auto_attr` declarations

2. **Type conversion not working**: Check that your nested classes also include the modules

3. **Tests failing after adding `collect_extras`**: Make sure to declare the `extra` attribute:
   ```ruby
   auto_attr :extra, type: Hash
   ```

4. **Sorbet type errors**: Use `T.unsafe()` for complex metaprogramming or adjust type annotations

5. **Key not being renamed**: Ensure the `rename` is in `deserialize_config` and the target attribute exists

### Getting Help

- Check existing classes in `lib/octoprint/files/` for examples
- Look at the comprehensive test suite in `spec/octoprint/`
- Review this documentation for patterns and best practices

This modular approach makes the codebase more maintainable, type-safe, and easier to extend as the OctoPrint API evolves.