# Lighterpack Parser

A Ruby gem for parsing Lighterpack lists from HTML or URLs.

Used by [Goulight](https://goulight.com). Source: [github.com/goulight/lighterpack-parser](https://github.com/goulight/lighterpack-parser).

## Installation

Add to your `Gemfile`:

```ruby
gem 'lighterpack-parser', '~> 1.0'
```

Then:

```bash
bundle install
```

Or install directly:

```bash
gem install lighterpack-parser
```

## Usage

`LighterpackParser::Parser#parse` (and `LighterpackParser.parse_url`) return a **`LighterpackParser::List`** object with readers `name`, `description`, and `categories`. Each category is a **`LighterpackParser::Category`**; each item is a **`LighterpackParser::Item`**.

Call **`#to_h`** on the list (or on categories/items) if you need nested hashes (for example JSON APIs).

### Parse from HTML string

```ruby
require 'lighterpack_parser'

html = File.read('path/to/lighterpack.html')
list = LighterpackParser::Parser.new(html: html).parse

list.name                    # => "List Name"
list.description             # => "List description" or nil
list.categories.first.name   # => "Category Name"

item = list.categories.first.items.first
item.name                    # => "Item Name"
item.description             # => "Item description" or nil
item.weight                  # => 476.0   # grams per unit
item.total_weight            # => 476.0   # weight * quantity (grams)
item.quantity                # => 1
item.image_url               # => "https://..." or nil
item.consumable              # => false
item.total_consumable_weight # => nil (or total grams if consumable)
item.worn                    # => false
item.worn_quantity           # => nil (or 1 if worn)
item.total_worn_weight       # => nil (or grams worn, weight × 1)

# Hash shape (matches nested #to_h):
list.to_h
# => {
#   name: "List Name",
#   description: nil,
#   categories: [
#     {
#       name: "Category Name",
#       description: nil,
#       items: [
#         {
#           name: "Item Name",
#           description: "Item description",
#           weight: 476.0,
#           total_weight: 476.0,
#           quantity: 1,
#           image_url: "https://...",
#           consumable: false,
#           total_consumable_weight: nil,
#           worn: false,
#           worn_quantity: nil,
#           total_worn_weight: nil
#         }
#       ]
#     }
#   ]
# }
```

### Parse from URL

```ruby
require 'lighterpack_parser'

list = LighterpackParser::Parser.new(url: 'https://lighterpack.com/r/b6q1kr').parse

# Or using the convenience method
list = LighterpackParser.parse_url('https://lighterpack.com/r/b6q1kr')
```

## Running Tests

To run the test suite:

```bash
rspec
```

## Test Fixtures

Test fixtures are stored in `spec/fixtures/` and contain HTML from example Lighterpack lists:

- `b6q1kr.html` - Ultimate Hike 2025
- `adbf7c.html` - Example list 2
- `h23rxt.html` - Example list 3

To update fixtures, download fresh HTML:

```bash
curl -s "https://lighterpack.com/r/b6q1kr" > spec/fixtures/b6q1kr.html
```

## Features

- Parses list name and description
- Extracts categories with descriptions
- Extracts items with:
  - Name and description
  - Weight per unit and total weight (automatically converted to grams)
  - Quantity
  - Image URLs
  - Consumable flag and total consumable weight when applicable
  - Worn flag, worn quantity, and total worn weight when applicable
- Supports weight units: oz, lb, g, kg (all converted to grams)
- Handles both HTML strings and URLs

## Weight Conversion

The parser automatically converts all weights to grams:

- `oz` → multiply by 28.3495
- `lb` → multiply by 453.592
- `g` → use as-is
- `kg` → multiply by 1000

## Development

To install dependencies locally:

```bash
bundle install
```
