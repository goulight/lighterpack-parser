# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LighterpackParser::Parser do
  let(:fixture_dir) { File.join(__dir__, 'fixtures') }

  describe '#parse' do
    context 'with b6q1kr.html' do
      let(:html) { File.read(File.join(fixture_dir, 'b6q1kr.html')) }
      let(:result) { described_class.new(html: html).parse }

      it 'extracts the list name' do
        expect(result.name).to eq('Ultimate Hike 2025')
      end

      it 'extracts categories as an array' do
        expect(result.categories).to be_a(Array)
        expect(result.categories.length).to be > 0
      end

      it 'extracts the first category correctly' do
        first_category = result.categories.first
        expect(first_category.name).to eq('Big 3 (Pack, Tent, Sleep System)')
        expect(first_category.items).to be_a(Array)
        expect(first_category.items.length).to be > 0
      end

      it 'extracts the first item correctly' do
        first_category = result.categories.first
        first_item = first_category.items.first

        expect(first_item.name).to eq('Bonfus Altus 38')
        expect(first_item.description).to eq('With vest styled straps')
        expect(first_item.weight).to be > 0
        expect(first_item.quantity).to eq(1)
        expect(first_item).to_not be_worn
        expect(first_item).to_not be_consumable
      end

      it 'includes total weight fields' do
        first_category = result.categories.first
        first_item = first_category.items.first

        expect(first_item.total_weight).to be > 0
        expect(first_item.total_weight).to eq(first_item.weight * first_item.quantity)

        if first_item.consumable
          expect(first_item.total_consumable_weight).to be > 0
          expect(first_item.total_consumable_weight).to eq(first_item.weight * first_item.quantity)
        else
          expect(first_item.total_consumable_weight).to be_nil
        end

        if first_item.worn
          expect(first_item.worn_quantity).to eq(1)
          expect(first_item.total_worn_weight).to be > 0
          expect(first_item.total_worn_weight).to eq(first_item.weight * 1)
        else
          expect(first_item.worn_quantity).to be_nil
          expect(first_item.total_worn_weight).to be_nil
        end
      end

      it 'sets worn_quantity to 1 for worn items regardless of quantity' do
        result.categories.each do |category|
          category.items.each do |item|
            if item.worn
              expect(item.worn_quantity).to eq(1),
                                            "Worn item #{item.name} should have worn_quantity=1, " \
                                            "got #{item.worn_quantity}"
              expect(item.total_worn_weight).to eq(item.weight * 1),
                                                "Worn item #{item.name} should have total_worn_weight = weight * 1"
            else
              expect(item.worn_quantity).to be_nil, "Non-worn item #{item.name} should have worn_quantity=nil"
            end
          end
        end
      end
    end

    context 'with adbf7c.html' do
      let(:html) { File.read(File.join(fixture_dir, 'adbf7c.html')) }
      let(:result) { described_class.new(html: html).parse }

      it 'extracts the list name' do
        expect(result.name).to be_truthy
      end

      it 'extracts categories as an array' do
        expect(result.categories).to be_a(Array)
      end
    end

    context 'with h23rxt.html' do
      let(:html) { File.read(File.join(fixture_dir, 'h23rxt.html')) }
      let(:result) { described_class.new(html: html).parse }

      it 'extracts the list name' do
        expect(result.name).to be_truthy
      end

      it 'extracts categories as an array' do
        expect(result.categories).to be_a(Array)
      end
    end
  end

  describe 'weight conversion' do
    let(:html) { File.read(File.join(fixture_dir, 'b6q1kr.html')) }
    let(:result) { described_class.new(html: html).parse }

    it 'converts weights to grams correctly' do
      result.categories.each do |category|
        category.items.each do |item|
          if item.weight > 0
            expect(item.weight).to be > 0, "Item #{item.name} should have weight > 0"
            expect(item.weight).to be < 1_000_000, "Item #{item.name} weight seems too large: #{item.weight}"
          end
        end
      end
    end
  end

  describe 'consumable flag extraction' do
    let(:html) { File.read(File.join(fixture_dir, 'b6q1kr.html')) }
    let(:result) { described_class.new(html: html).parse }

    it 'extracts consumable flag as boolean for all items' do
      result.categories.each do |category|
        category.items.each do |item|
          expect([true, false]).to include(item.consumable), "Consumable should be boolean for #{item.name}"
        end
      end
    end
  end

  describe 'worn flag extraction' do
    let(:html) { File.read(File.join(fixture_dir, 'b6q1kr.html')) }
    let(:result) { described_class.new(html: html).parse }

    it 'extracts worn flag as boolean for all items' do
      result.categories.each do |category|
        category.items.each do |item|
          expect([true, false]).to include(item.worn), "Worn should be boolean for #{item.name}"
        end
      end
    end
  end

  describe 'worn flag correctness for h23rxt.html' do
    let(:html) { File.read(File.join(fixture_dir, 'h23rxt.html')) }
    let(:result) { described_class.new(html: html).parse }
    let(:all_items) { result.categories.flat_map(&:items) }

    it 'correctly identifies Sea to Summit Ultrasil as worn' do
      ultrasil = all_items.find { |item| item.name&.include?('Sea to Summit Ultrasil') }
      expect(ultrasil).to be_truthy, 'Should find Sea to Summit Ultrasil item'
      expect(ultrasil.worn).to be(true), 'Sea to Summit Ultrasil should be worn'
      expect(ultrasil.consumable).to be(false), 'Sea to Summit Ultrasil should NOT be consumable'
    end

    it 'correctly identifies MacBook Pro as not worn' do
      macbook = all_items.find { |item| item.name&.include?('MacBook Pro') }
      expect(macbook).to be_truthy, 'Should find MacBook Pro item'
      expect(macbook.worn).to be(false), 'MacBook Pro should NOT be worn'
      expect(macbook.consumable).to be(false), 'MacBook Pro should NOT be consumable'
    end
  end

  describe 'consumable flag correctness for h23rxt.html' do
    let(:html) { File.read(File.join(fixture_dir, 'h23rxt.html')) }
    let(:result) { described_class.new(html: html).parse }
    let(:all_items) { result.categories.flat_map(&:items) }

    it 'correctly identifies Tandkräm as consumable' do
      tandkram = all_items.find { |item| item.name&.include?('Tandkräm (innehåll)') }
      expect(tandkram).to be_truthy, 'Should find Tandkräm item'
      expect(tandkram.consumable).to be(true), 'Tandkräm should be consumable'
      expect(tandkram.worn).to be(false), 'Tandkräm should NOT be worn'
    end

    it 'correctly identifies Dushtvål/Shampoo as consumable' do
      shampoo = all_items.find { |item| item.name&.include?('Dushtvål') || item.name&.include?('Shampoo') }
      expect(shampoo).to be_truthy, 'Should find Dushtvål/Shampoo item'
      expect(shampoo.consumable).to be(true), 'Dushtvål/Shampoo should be consumable'
      expect(shampoo.worn).to be(false), 'Dushtvål/Shampoo should NOT be worn'
    end

    it 'correctly identifies MacBook Pro as not consumable' do
      macbook = all_items.find { |item| item.name&.include?('MacBook Pro') }
      expect(macbook).to be_truthy, 'Should find MacBook Pro item'
      expect(macbook.consumable).to be(false), 'MacBook Pro should NOT be consumable'
    end
  end

  describe 'worn and consumable counts for h23rxt.html' do
    let(:html) { File.read(File.join(fixture_dir, 'h23rxt.html')) }
    let(:result) { described_class.new(html: html).parse }
    let(:all_items) { result.categories.flat_map(&:items) }
    let(:total_items) { all_items.length }
    let(:worn_count) { all_items.count(&:worn) }
    let(:consumable_count) { all_items.count(&:consumable) }

    it 'has reasonable counts of worn and consumable items' do
      expect(worn_count).to be >= 1, "Should have at least 1 worn item, got #{worn_count}"
      expect(worn_count).to be <= 5, "Should have at most 5 worn items (most items are not worn), got #{worn_count}"
      expect(consumable_count).to be >= 2, "Should have at least 2 consumable items, got #{consumable_count}"
      expect(consumable_count).to be <= 5,
                                  'Should have at most 5 consumable items ' \
                                  "(most items are not consumable), got #{consumable_count}"
      expect(total_items).to be > 10, "Should have many items total, got #{total_items}"
    end
  end

  describe 'quantity extraction' do
    let(:html) { File.read(File.join(fixture_dir, 'b6q1kr.html')) }
    let(:result) { described_class.new(html: html).parse }

    it 'extracts quantities as positive integers' do
      result.categories.each do |category|
        category.items.each do |item|
          expect(item.quantity).to be_a(Integer), "Quantity should be integer for #{item.name}"
          expect(item.quantity).to be > 0, "Quantity should be > 0 for #{item.name}"
        end
      end
    end
  end

  describe 'image URL extraction' do
    let(:html) { File.read(File.join(fixture_dir, 'b6q1kr.html')) }
    let(:result) { described_class.new(html: html).parse }

    it 'extracts image URLs correctly' do
      items_with_images = 0
      result.categories.each do |category|
        category.items.each do |item|
          if item.image_url
            expect(item.image_url).to start_with('http'), "Image URL should start with http for #{item.name}"
            items_with_images += 1
          end
        end
      end

      expect(items_with_images).to be > 0, 'At least some items should have image URLs'
    end
  end

  describe 'category description extraction' do
    let(:html) { File.read(File.join(fixture_dir, 'b6q1kr.html')) }
    let(:result) { described_class.new(html: html).parse }

    it 'extracts category descriptions when available' do
      result.categories.each do |category|
        expect(category.description).to be_nil.or(be_a(String)),
                                        "Description should be nil or string for category #{category.name}"
      end
    end
  end
end
