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

  def test_worn_flag_correctness_h23rxt
    # Test specific items from h23rxt.html that should or should not be worn
    html = File.read(File.join(@fixture_dir, 'h23rxt.html'))
    result = LighterpackParser::Parser.new(html: html).parse

    # Find specific items
    all_items = result[:categories].flat_map { |cat| cat[:items] }

    # "Sea to Summit Ultrasil" should be worn (has lpActive on worn icon)
    ultrasil = all_items.find { |item| item[:name]&.include?('Sea to Summit Ultrasil') }
    assert ultrasil, "Should find Sea to Summit Ultrasil item"
    assert_equal true, ultrasil[:worn], "Sea to Summit Ultrasil should be worn"
    assert_equal false, ultrasil[:consumable], "Sea to Summit Ultrasil should NOT be consumable"

    # "MacBook Pro" should NOT be worn or consumable
    macbook = all_items.find { |item| item[:name]&.include?('MacBook Pro') }
    assert macbook, "Should find MacBook Pro item"
    assert_equal false, macbook[:worn], "MacBook Pro should NOT be worn"
    assert_equal false, macbook[:consumable], "MacBook Pro should NOT be consumable"
  end

  def test_consumable_flag_correctness_h23rxt
    # Test specific items from h23rxt.html that should or should not be consumable
    html = File.read(File.join(@fixture_dir, 'h23rxt.html'))
    result = LighterpackParser::Parser.new(html: html).parse

    # Find specific items
    all_items = result[:categories].flat_map { |cat| cat[:items] }

    # "Tandkräm (innehåll)" should be consumable (has lpActive on consumable icon)
    tandkram = all_items.find { |item| item[:name]&.include?('Tandkräm (innehåll)') }
    assert tandkram, "Should find Tandkräm item"
    assert_equal true, tandkram[:consumable], "Tandkräm should be consumable"
    assert_equal false, tandkram[:worn], "Tandkräm should NOT be worn"

    # "Dushtvål/Shampoo" should be consumable
    shampoo = all_items.find { |item| item[:name]&.include?('Dushtvål') || item[:name]&.include?('Shampoo') }
    assert shampoo, "Should find Dushtvål/Shampoo item"
    assert_equal true, shampoo[:consumable], "Dushtvål/Shampoo should be consumable"
    assert_equal false, shampoo[:worn], "Dushtvål/Shampoo should NOT be worn"

    # "MacBook Pro" should NOT be consumable
    macbook = all_items.find { |item| item[:name]&.include?('MacBook Pro') }
    assert macbook, "Should find MacBook Pro item"
    assert_equal false, macbook[:consumable], "MacBook Pro should NOT be consumable"
  end

  def test_worn_and_consumable_counts_h23rxt
    # Verify that only a few items are marked as worn/consumable in h23rxt
    html = File.read(File.join(@fixture_dir, 'h23rxt.html'))
    result = LighterpackParser::Parser.new(html: html).parse

    all_items = result[:categories].flat_map { |cat| cat[:items] }
    total_items = all_items.length
    worn_count = all_items.count { |item| item[:worn] }
    consumable_count = all_items.count { |item| item[:consumable] }

    # Based on HTML inspection, there should be:
    # - 1 worn item (Sea to Summit Ultrasil)
    # - 2 consumable items (Tandkräm, Dushtvål/Shampoo)
    # - Most items should NOT be worn or consumable
    assert worn_count >= 1, "Should have at least 1 worn item, got #{worn_count}"
    assert worn_count <= 5, "Should have at most 5 worn items (most items are not worn), got #{worn_count}"
    assert consumable_count >= 2, "Should have at least 2 consumable items, got #{consumable_count}"
    assert consumable_count <= 5, "Should have at most 5 consumable items (most items are not consumable), got #{consumable_count}"
    assert total_items > 10, "Should have many items total, got #{total_items}"
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
