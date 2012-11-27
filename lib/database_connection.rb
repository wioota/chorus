module DatabaseConnection
  def database
    if @database.is_a? Sequel::Database
      @database
    else
      @database = Sequel.connect(@database.to_s, :logger => Rails.logger)
    end
  end

  def database=(db)
    @database = db
  end
end
