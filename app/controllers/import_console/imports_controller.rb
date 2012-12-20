class ImportConsole::ImportsController < ApplicationController
  before_filter :require_login
  before_filter :require_admin

  def require_login
    return if logged_in? && !expired?
    redirect_to url_for(:port => ChorusConfig.instance['server_port'], :controller => "/root", :action => "index")
  end

  def index
    @imports = Import.where(:finished_at => nil).map {|import| ImportManager.new(import)}
  end
end
