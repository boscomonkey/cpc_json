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

    # cpcSectionNumber
    symbol = item.elements.find {|child|
      child.name == 'classification-symbol'
    }

    # cpcSectionName
    title = item.elements.find {|child|
      child.name == 'class-title'
    }

    {
      'cpcSections' => [
        {
          'cpcSectionNumber' => symbol.text,
          'cpcSectionName'   => title.text,
          'cpcSubSections'   => []
        }
      ]
    }
  end

end


if __FILE__ == $0

  require 'minitest/autorun'

  class Test < Minitest::Test

    def test_parse
      cpc = CpcJson.new
      obj = cpc.parse 'data/cpc-scheme-A.xml'

      assert_instance_of Hash, obj
      assert_instance_of Array, obj['cpcSections']

      sections = obj['cpcSections']

      first = sections[0]
      assert_equal "A", first['cpcSectionNumber']
      assert_equal "HUMAN NECESSITIES", first['cpcSectionName']

      subsections = first['cpcSubSections']
      assert_instance_of Array, subsections
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
