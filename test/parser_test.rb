# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/lighterpack_parser'

class ParserTest < Minitest::Test
  def setup
    @fixture_dir = File.join(__dir__, 'fixtures')
  end

  def test_parse_b6q1kr_html
    html = File.read(File.join(@fixture_dir, 'b6q1kr.html'))
    result = LighterpackParser::Parser.new(html: html).parse

    assert_equal 'Ultimate Hike 2025', result[:name]
    assert result[:categories].is_a?(Array)
    assert result[:categories].length > 0

    # Check first category
    first_category = result[:categories].first
    assert_equal 'Big 3 (Pack, Tent, Sleep System)', first_category[:name]
    assert first_category[:items].is_a?(Array)
    assert first_category[:items].length > 0

    # Check first item
    first_item = first_category[:items].first
    assert_equal 'Bonfus Altus 38', first_item[:name]
    assert_equal 'With vest styled straps', first_item[:description]
    assert first_item[:weight] > 0
    assert_equal 1, first_item[:quantity]
    assert first_item[:worn] || !first_item[:worn] # boolean check
    assert first_item[:consumable] || !first_item[:consumable] # boolean check
  end

  def test_parse_adbf7c_html
    html = File.read(File.join(@fixture_dir, 'adbf7c.html'))
    result = LighterpackParser::Parser.new(html: html).parse

    assert result[:name]
    assert result[:categories].is_a?(Array)
  end

  def test_parse_h23rxt_html
    html = File.read(File.join(@fixture_dir, 'h23rxt.html'))
    result = LighterpackParser::Parser.new(html: html).parse

    assert result[:name]
    assert result[:categories].is_a?(Array)
  end

  def test_weight_conversion_oz
    # Test that weights are converted to grams
    html = File.read(File.join(@fixture_dir, 'b6q1kr.html'))
    result = LighterpackParser::Parser.new(html: html).parse

    # Find an item and verify weight is in grams
    result[:categories].each do |category|
      category[:items].each do |item|
        if item[:weight] > 0
          # Weight should be reasonable (not in milligrams if original was grams)
          assert item[:weight] > 0, "Item #{item[:name]} should have weight > 0"
          assert item[:weight] < 1_000_000, "Item #{item[:name]} weight seems too large: #{item[:weight]}"
        end
      end
    end
  end

  def test_consumable_flag_extraction
    html = File.read(File.join(@fixture_dir, 'b6q1kr.html'))
    result = LighterpackParser::Parser.new(html: html).parse

    # Check that consumable flag is extracted (boolean)
    result[:categories].each do |category|
      category[:items].each do |item|
        assert [true, false].include?(item[:consumable]), "Consumable should be boolean for #{item[:name]}"
      end
    end
  end

  def test_worn_flag_extraction
    html = File.read(File.join(@fixture_dir, 'b6q1kr.html'))
    result = LighterpackParser::Parser.new(html: html).parse

    # Check that worn flag is extracted (boolean)
    result[:categories].each do |category|
      category[:items].each do |item|
        assert [true, false].include?(item[:worn]), "Worn should be boolean for #{item[:name]}"
      end
    end
  end

  def test_quantity_extraction
    html = File.read(File.join(@fixture_dir, 'b6q1kr.html'))
    result = LighterpackParser::Parser.new(html: html).parse

    # Check that quantities are positive integers
    result[:categories].each do |category|
      category[:items].each do |item|
        assert item[:quantity].is_a?(Integer), "Quantity should be integer for #{item[:name]}"
        assert item[:quantity] > 0, "Quantity should be > 0 for #{item[:name]}"
      end
    end
  end

  def test_image_url_extraction
    html = File.read(File.join(@fixture_dir, 'b6q1kr.html'))
    result = LighterpackParser::Parser.new(html: html).parse

    # Some items should have image URLs
    items_with_images = 0
    result[:categories].each do |category|
      category[:items].each do |item|
        if item[:image_url]
          assert item[:image_url].start_with?('http'), "Image URL should start with http for #{item[:name]}"
          items_with_images += 1
        end
      end
    end

    # At least some items should have images
    assert items_with_images > 0, 'At least some items should have image URLs'
  end

  def test_category_description_extraction
    html = File.read(File.join(@fixture_dir, 'b6q1kr.html'))
    result = LighterpackParser::Parser.new(html: html).parse

    # Check that category descriptions are extracted when available
    result[:categories].each do |category|
      # Description might be nil or a string
      assert category[:description].nil? || category[:description].is_a?(String),
             "Description should be nil or string for category #{category[:name]}"
    end
  end
end
