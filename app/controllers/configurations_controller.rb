require_relative '../../version'
require 'ldap_client'

class ConfigurationsController < ApplicationController
  skip_before_filter :require_login, :only => :version

  def show
    render :json => { :response => {
      :external_auth_enabled => LdapClient.enabled?,
      :gpfdist_configured => ChorusConfig.instance.gpfdist_configured?,
      :tableau_configured => ChorusConfig.instance.tableau_configured?,
      :file_sizes_mb_workfiles => ChorusConfig.instance['file_sizes_mb.workfiles'],
      :file_sizes_mb_csv_imports => ChorusConfig.instance['file_sizes_mb.csv_imports'],
      :file_sizes_mb_user_icon => ChorusConfig.instance['file_sizes_mb.user_icon'],
      :file_sizes_mb_workspace_icon => ChorusConfig.instance['file_sizes_mb.workspace_icon'],
      :file_sizes_mb_attachment => ChorusConfig.instance['file_sizes_mb.attachment'],
      :kaggle_configured => ChorusConfig.instance.kaggle_configured?,
      :gnip_configured => ChorusConfig.instance.gnip_configured?,
      :execution_timeout_in_minutes => ChorusConfig.instance['execution_timeout_in_minutes'],
      :default_preview_row_limit => ChorusConfig.instance['default_preview_row_limit'] || 100,
      :oracle_configured => ChorusConfig.instance.oracle_configured?
    }.merge!(alpine_config) }
  end

  def version
    render :inline => build_string
  end

  def build_string
    f = File.join(Rails.root, 'version_build')
    File.exists?(f) ? File.read(f) : Chorus::VERSION::STRING
  end

  private

  def alpine_config
    if ChorusConfig.instance.alpine_configured?
      {
        :alpine_url => ChorusConfig.instance['alpine.url'],
        :alpine_api_key => ChorusConfig.instance['alpine.api_key']
      }
    else
      {}
    end
  end
end
