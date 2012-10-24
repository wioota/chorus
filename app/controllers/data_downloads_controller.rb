class DataDownloadsController < ApplicationController
  def download_data
    send_data params[:content], :type => params[:mime_type], :filename => params[:filename]
  end
end
