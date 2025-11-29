# Lighterpack Parser

A Ruby gem for parsing Lighterpack lists from HTML or URLs.

## Installation

This gem is used as a local dependency in the Packlista project. It's referenced in the backend `Gemfile`:

```ruby
gem 'lighterpack_parser', path: '../lighterpack-parser'
```

## Usage

### Parse from HTML string

```ruby
require 'lighterpack_parser'

html = File.read('path/to/lighterpack.html')
result = LighterpackParser::Parser.new(html: html).parse

# Result structure:
# {
#   name: "List Name",
#   description: "List description (optional)",
#   categories: [
#     {
#       name: "Category Name",
#       description: "Category description (optional)",
#       items: [
#         {
#           name: "Item Name",
#           description: "Item description",
#           weight: 476.0,  # in grams
#           quantity: 1,
#           image_url: "https://...",
#           consumable: false,
#           worn: false
#         }
#       ]
#     }
#   ]
# }
```

### Parse from URL

```ruby
require 'lighterpack_parser'

# Using the parser directly
result = LighterpackParser::Parser.new(url: 'https://lighterpack.com/r/b6q1kr').parse

# Or using the convenience method
result = LighterpackParser.parse_url('https://lighterpack.com/r/b6q1kr')
```

## Running Tests

To run the test suite:

```bash
cd lighterpack-parser
ruby -Ilib test/parser_test.rb
```

Or using minitest directly:

```bash
cd lighterpack-parser
ruby -Ilib -e "require 'minitest/autorun'; require_relative 'test/parser_test'"
```

## Test Fixtures

Test fixtures are stored in `test/fixtures/` and contain HTML from example Lighterpack lists:
- `b6q1kr.html` - Ultimate Hike 2025
- `adbf7c.html` - Example list 2
- `h23rxt.html` - Example list 3

To update fixtures, download fresh HTML:

```bash
curl -s "https://lighterpack.com/r/b6q1kr" > test/fixtures/b6q1kr.html
```

## Features

- Parses list name and description
- Extracts categories with descriptions
- Extracts items with:
  - Name and description
  - Weight (automatically converted to grams)
  - Quantity
  - Image URLs
  - Consumable flag
  - Worn flag
- Supports weight units: oz, lb, g, kg (all converted to grams)
- Handles both HTML strings and URLs

## Weight Conversion

The parser automatically converts all weights to grams:
- `oz` → multiply by 28.3495
- `lb` → multiply by 453.592
- `g` → use as-is
- `kg` → multiply by 1000

## Dependencies

- `nokogiri` - HTML parsing
- `httparty` - HTTP requests (when parsing from URL)

## Development

To install dependencies locally:

```bash
gem install nokogiri httparty
```

Or use bundler if you add a Gemfile:

```bash
bundle install
```
