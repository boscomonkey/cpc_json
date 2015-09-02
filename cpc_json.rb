#!/usr/bin/env ruby

require 'nokogiri'

class CpcJson

  def test_filter(elt)	# recursively collect hashes of names to children
    if elt.elements.size < 2
      { elt.name => elt.text }
    else
      { elt.name => elt.elements.collect { |child| test_filter(child) } }
    end
  end

  def validate(xsd_fname, xml_fname)
    xsd = Nokogiri::XML::Schema(File.read(xsd_fname))
    doc = Nokogiri::XML(File.read(xml_fname))

    xsd.validate(doc).each do |error|
      puts error.message
    end
  end

  def parse(xml_fname)
    doc = Nokogiri::XML(File.read(xml_fname))
    root = doc.root
    item = root.elements.first
    parse_level2 item
  end

  def parse_level2(item)
    # cpcSectionNumber
    symbol = find_symbol item

    # cpcSectionName
    title = find_title item

    # cpcSubSections
    nodes = select_items item
    level3_items = nodes.collect {|node| parse_level3(node) }

    {
      'cpcSections' => [
        {
          'cpcSectionNumber' => symbol.text,
          'cpcSectionName'   => title.text,
          'cpcSubSections'   => level3_items
        }
      ]
    }
  end

  def parse_level3(item)
    title = find_title(item)
    nodes = select_items item
    level4_items = nodes.collect {|node| parse_level4(node) }
    {
      'cpcSubSectionName' => title.text,
      'cpcClasses'        => level4_items
    }
  end

  def parse_level4(item)
    symbol = find_symbol item
    title = build_title(item)
    nodes = select_items item
    level5_items = nodes.collect {|node| parse_level5(node) }
    {
      'cpcClassNumber' => symbol.text,
      'cpcClassName'   => title,
      'cpcSubClasses'  =>level5_items
    }
  end

  def parse_level5(item)
    symbol = find_symbol item
    title = build_title(item)

    puts "LEVEL5 DEBUG: link-file: #{item['link-file']}"

    {
      'cpcSubClassNumber' => symbol.text,
      'cpcSubClassName'   => title,
      'cpcGroups'         => []
    }
  end

  def build_title(item)
    node = find_title item
    title_strings = node.elements.collect {|title_part|
      title_part.elements.find {|child| child.name == 'text'}.text.strip
    }
    title_strings.join('; ')
  end

  def find_title(item)
    item.elements.find {|child|
      child.name == 'class-title' && child.elements
    }
  end

  def find_symbol(item)
    item.elements.find {|child|
      child.name == 'classification-symbol'
    }
  end

  def select_items(item)
    item.elements.select {|child| child.name == 'classification-item'}
  end

end


if __FILE__ == $0

  require 'minitest/autorun'

  class Test < Minitest::Test

    def test_parse
      cpc = CpcJson.new
      obj = cpc.parse 'test/fixtures/cpc-scheme-A.xml'

      assert_instance_of Hash, obj
      assert_instance_of Array, obj['cpcSections']

      sections = obj['cpcSections']

      first_section = sections[0]
      assert_equal "A", first_section['cpcSectionNumber']
      assert_equal "HUMAN NECESSITIES", first_section['cpcSectionName']

      subsections = first_section['cpcSubSections']
      assert_instance_of Array, subsections
      assert_equal 4, subsections.size, 'SHOULD BE 4 LEVEL THREE ITEMS'

      sub0 = subsections[0]
      assert_equal 'Agriculture', sub0['cpcSubSectionName']
      assert_equal 1, sub0['cpcClasses'].size

      class0 = sub0['cpcClasses'].first
      assert_instance_of Hash, class0
      assert_equal 'A01', class0['cpcClassNumber']
      assert_equal 'AGRICULTURE; FORESTRY; ANIMAL HUSBANDRY; HUNTING; TRAPPING; FISHING', class0['cpcClassName']

      subclasses = class0['cpcSubClasses']
      assert_instance_of Array, subclasses
      assert 11, subclasses.size

      subclass0 = subclasses[0]
      assert_instance_of Hash, subclass0
      assert_equal 'A01B', subclass0['cpcSubClassNumber']
      assert_equal 'SOIL WORKING IN AGRICULTURE OR FORESTRY; PARTS, DETAILS, OR ACCESSORIES OF AGRICULTURAL MACHINES OR IMPLEMENTS, IN GENERAL', subclass0['cpcSubClassName']

      groups = subclass0['cpcGroups']
      assert_instance_of Array, groups
      assert_equal 5, groups.size, 'NUMBER OF LEVEL 6 GROUPS IN cpc-scheme-A01B.xml'

      group0 = groups.first
    end

  end

  def execute_command_line
    xsd_fname = ARGV[0]
    xml_fname = ARGV[1]

    puts xsd_fname
    puts xml_fname

    cj = CpcJson.new
    cj.validate xsd_fname, xml_fname
  end

end
