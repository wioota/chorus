class OracleInstance < DataSource
  validates :host, :presence => true
  validates :port, :presence => true
end