#!/usr/bin/env ruby

require 'nokogiri'

=begin

parser = ExchangeParser.new('index.html')
doc = parser.doc		# Document
html = parser.html		# Element
head = parser.head		# Element
body = parser.body		# Element
list = parser.foa_list		# Element
groups = parser.foa_groups	# NodeSet

=end
class ExchangeParser
  class << self
    def add_css_class(element, css_value)
      element['class'] = css_value
    end

    def find_descriptions(nodeOrNodeset)
      nodeOrNodeset.xpath(".//div[@class='program_highlights']/div[@class='foaDescription']/span[contains(@id, 'FoaDescriptionLabel')]")
    end

    def foa_title(node)
      node.at("h2[@class='hp']")
    end

    def partition_title(element)
      saved = element.text
      arry = saved.split /:/
      head = arry.shift
      tail = arry.join(':').strip	# remove prefix space if any

      element.content = ''

      span_head = Nokogiri::XML::Node.new 'span', element
      add_css_class span_head, 'foa_title_number'
      span_head.content = head
      element.add_child span_head

      span_sep = Nokogiri::XML::Node.new 'span', element
      span_sep.content = ': '
      element.add_child span_sep

      span_tail = Nokogiri::XML::Node.new 'span', element
      add_css_class span_tail, 'foa_title_summary'
      span_tail.content = tail
      element.add_child span_tail

      element	# allows chaining
    end
  end

  attr_reader :doc

  def initialize(html_fname)
    File.open(html_fname) {|f| @doc = Nokogiri::parse(f) }
  end

  def html
    @html ||= @doc.elements.first
  end

  def head
    @head ||= self.html.elements.first
  end

  def body
    @body ||= self.html.elements.last
  end

  def foa_list
    @list ||= self.body.xpath("//div[@class='foaList']")
  end

  def foa_groups
    @groups ||= self.body.xpath("//div[@class='foaGroup']")
  end

  def foa_titles
    @titles ||= self.body.xpath(".//a[contains(@id, 'FoaTitleHyperLink')]")
  end

end

if __FILE__ == $0
  require 'minitest/autorun'

  class ExchangeParserTest < Minitest::Test
    def setup
      @@parser ||= ExchangeParser.new('index.html')
    end

    def test_initialize
      refute_nil @@parser
    end

    def test_html
      assert_instance_of Nokogiri::XML::Element, @@parser.html
    end

    def test_head
      assert_instance_of Nokogiri::XML::Element, @@parser.head
    end

    def test_body
      assert_instance_of Nokogiri::XML::Element, @@parser.body
    end

    def test_foa_list
      list = @@parser.foa_list

      assert_instance_of Nokogiri::XML::NodeSet, list
      assert_equal 1, list.size
    end

    def test_foa_groups
      groups = @@parser.foa_groups

      assert_instance_of Nokogiri::XML::NodeSet, groups
      assert_equal 110, groups.size
    end

    def test_foa_titles
      titles = @@parser.foa_titles
      assert_equal 110, titles.size

      titles.each do |elt|
        txt = elt.text
        arr = txt.split ':'
        assert arr.size >= 2, "NOT ENOUGH COLONS: #{txt}"
      end
    end

    def test_class_method_foa_descriptions
      groups = @@parser.foa_groups
      descs = ExchangeParser.find_descriptions(groups)

      assert_equal 110, descs.size
    end

    def test_class_method_partition_title
      titles = @@parser.foa_titles
      orig_texts = titles.collect {|ttl| ttl.text}

      titles.each {|ttl| ExchangeParser.partition_title(ttl) }
      new_texts = titles.collect {|ttl| ttl.text}

      assert_equal [], orig_texts - new_texts, "NO OLD ONES"
      assert_equal [], new_texts - orig_texts, "NO NEW ONES"
    end

    def test_class_method_foa_title
      groups = @@parser.foa_groups
      group = groups[0]
      title_elt = ExchangeParser.foa_title(group)
      text = title_elt.text.strip

      assert_equal "DE-FOA-0000648: AMENDMENT 003 - Predictive Modeling for Automotive Lightweighting Applications and Advanced Alloy Development for Automotive and Heavy-Duty Engines", text.strip
    end

    def test_foa_title_contains_only_one_colon
      groups = @@parser.foa_groups
      groups.each do |group|
        title_elt = ExchangeParser.foa_title(group)
        text = title_elt.text.strip
        arry = text.split(/:/)
        assert arry.size >= 2, "colon count = #{arry.size} | #{text}"
      end
    end
  end

end

