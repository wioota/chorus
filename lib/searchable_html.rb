module SearchableHtml
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def searchable_html(field, options = {})
      searchable options do
        text field, :stored => true do
          html = send field
          remove_tags html
        end
      end
    end

    private

    def remove_tags(html)
      result = ""
      doc = Nokogiri::HTML(html)
      doc.xpath("//text()").each do |node|
        if result.length > 0
          result += " "
        end
        result += node.to_s
      end
      result
    end
  end
end