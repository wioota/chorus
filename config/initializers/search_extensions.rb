module SearchExtensions
  def grouping_id
    "#{self.class.name} #{id}"
  end

  def type_name
    self.class.name
  end
end

module ActiveRecord
  class Base
    include SearchExtensions
  end
end

module Sunspot
  module Search
    class AbstractSearch

      def associate_grouped_comments_with_primary_records
        solr_response['docs'] = []
        docs = solr_response['docs']
        group = group(:grouping_id)
        return unless group && group.groups
        comments_for_object = Hash.new() { |hsh, key| hsh[key] = [] }
        group.groups.each do |group|
          docs << {'id' => group.value}
          group.hits.each do |group_hit|
            if group_hit.class_name =~ /^Event/
              comments_for_object[group.value] << {:highlighted_attributes => group_hit.highlights_hash}
            end
          end
        end

        hits.each do |hit|
          hit.comments = comments_for_object[hit.id]
        end
      end
    end

    class Hit
      attr_accessor :comments

      def id
        @stored_values['id']
      end

      def highlights_hash
        highlights.inject({}) do |hsh, highlight|
          hsh[highlight.field_name] ||= []
          hsh[highlight.field_name] << highlight.format
          hsh
        end
      end

      def result=(new_result)
        if(comments)
          new_result.search_result_comments = comments
        end
        @result = new_result
      end
    end
  end
end