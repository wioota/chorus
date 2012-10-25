module SearchableText
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def searchable_text(field, options = {})
      searchable options do
        text field, :stored => true do
          search_body
        end
        string :grouping_id
        string :type_name
        string :security_type_name
      end

      define_method :search_body do
        result = ""
        doc = Nokogiri::HTML(self.send field)
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
end