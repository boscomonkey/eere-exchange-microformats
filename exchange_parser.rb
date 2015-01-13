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
  class Util
    def self.upgrade(html_fname)
      parser = ExchangeParser.new(html_fname)

      # add foa-documents-list
      lists = ExchangeParser.find_documents_list(parser.doc)
      lists.each {|elt|
        ExchangeParser.add_css_class elt, 'foa-documents-list'
      }

      # add foa-contacts-list
      contacts = ExchangeParser.find_contacts(parser.doc)
      contacts.each {|cc|
        ExchangeParser.add_css_class cc, 'foa-contacts-list'
      }

      # add foa-faq
      faqs = ExchangeParser.find_faq(parser.doc)
      faqs.each {|faq| ExchangeParser.add_css_class faq, 'foa-faq' }

      # add submission deadlines
      deadlines = ExchangeParser.find_submission_deadlines(parser.doc)
      deadlines.each {|dl|
        ExchangeParser.add_css_class dl, 'foa-deadlines'
      }

      # write modified html
      File.open("new.#{html_fname}", 'w') {|f| f << parser.doc.to_s }
    end
  end

  class << self
    def add_css_class(element, css_value)
      if old_css = element['class']
        arry = old_css.split(/\s+/)
        arry << css_value
        element['class'] = arry.sort.uniq.join(' ')
      else
        element['class'] = css_value
      end
    end

    def find_contacts(target)
      find_program_highlights(target)
        .xpath("div[contains(@id, 'divContacts')]/ul[@class='list']")
    end

    def find_descriptions(target)
      find_program_highlights(target).xpath("div[@class='foaDescription']/span[contains(@id, 'FoaDescriptionLabel')]")
    end

    def find_documents_list(target)
      find_program_highlights(target).
        xpath("div[contains(@id, 'FOAHighlightDocuments')]/ul[@class='list']")
    end

    def find_faq(target)
      ExchangeParser.find_program_highlights(target)
        .xpath("div[contains(@id, 'divFAQLink')]/p/a[@href]")
    end

    def find_program_highlights(target)
      target.xpath(".//div[@class='program_highlights']")
    end

    def find_submission_deadlines(target)
      ExchangeParser.find_program_highlights(target)
        .xpath("ul[@class='list']")
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

      span_head = Nokogiri::XML::Node.new 'span', element.document
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
      @@parser ||= new_parser
    end

    # called directly from test methods that need a totally new parser
    # instead of sharing one
    def new_parser
      ExchangeParser.new('index.html')
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

    def test_class_method_add_css_class
      grp = new_parser.foa_groups.first
      lists = ExchangeParser.find_documents_list(grp)

      assert_equal 1, lists.size

      lst = lists[0]
      assert_equal 'list', lst['class']

      ExchangeParser.add_css_class(lst, 'foa_documents_list')
      assert_equal 'foa_documents_list list', lst['class']

      # duplicate adds of the same class is ignored
      ExchangeParser.add_css_class(lst, 'foa_documents_list')
      assert_equal 'foa_documents_list list', lst['class']
    end

    def test_class_method_find_contacts
      # search under a nodeset
      groups = @@parser.foa_groups
      contacts = ExchangeParser.find_contacts(groups)
      assert_equal 107, contacts.size

      # search under 1 node
      grp = groups[0]
      contacts = ExchangeParser.find_contacts(grp)
      assert_equal 1, contacts.size
    end

    def test_class_method_find_descriptions
      groups = @@parser.foa_groups
      descs = ExchangeParser.find_descriptions(groups)

      assert_equal 110, descs.size
    end

    def test_class_method_find_documents_list
      groups = @@parser.foa_groups
      foa_docs = ExchangeParser.find_documents_list(groups)

      assert_equal 104, foa_docs.size
      assert_equal 'list', foa_docs.first['class']
    end

    def test_class_method_find_faq
      # search under a nodeset
      groups = @@parser.foa_groups
      faqs = ExchangeParser.find_faq(groups)
      assert_equal 83, faqs.size

      hrefs = faqs.collect {|faq| faq['href'] }
      assert_equal 77, hrefs.uniq.size

      # search under 1 node
      grp = groups[0]
      faq = ExchangeParser.find_faq(grp)
      assert_equal 1, faq.size
    end

    def test_class_method_find_submission_deadlines
      # search under a nodeset
      groups = @@parser.foa_groups
      deadlines = ExchangeParser.find_submission_deadlines(groups)
      assert_equal 110, deadlines.size

      # all should have the same type
      assert_equal ["ul"], deadlines.collect(&:name).uniq

      # search under 1 node
      grp = groups[0]
      deadline = ExchangeParser.find_submission_deadlines(grp)
      assert_equal 1, deadline.size
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

