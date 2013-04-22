module CommonDataSourceBehavior
  extend ActiveSupport::Concern

  included do
    attr_accessor :highlighted_attributes, :search_result_notes
    searchable_model do
      text :name, :stored => true, :boost => SOLR_PRIMARY_FIELD_BOOST
      text :description, :stored => true, :boost => SOLR_SECONDARY_FIELD_BOOST
    end

    def self.type_name
      'DataSource'
    end
  end

  def check_status!
    update_state_and_version

    touch(:last_checked_at)
    if online?
      touch(:last_online_at)
    end
    save!
  end

  def online?
    state == "online"
  end
end
