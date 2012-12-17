class ImportConsole::ImportsController < ApplicationController
  before_filter :require_admin

  def index
    @imports = Import.where(:finished_at => nil)
  end
end
