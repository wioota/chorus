require 'events/base'

module Events
  class GnipStreamImportCreated < Base
    has_targets :gnip_data_source, :dataset, :workspace
    has_activities :workspace, :dataset, :gnip_data_source
    has_additional_data :destination_table
  end
end