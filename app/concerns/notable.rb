module Notable
  extend ActiveSupport::Concern

  included do
    has_many :notes, :through => :activities, :source => :event, :class_name => "Events::Note"
    after_destroy :remove_notes_from_solr_index

    private

    def remove_notes_from_solr_index
      notes.each {|note|
        note.solr_remove_from_index
      }
    end
  end
end