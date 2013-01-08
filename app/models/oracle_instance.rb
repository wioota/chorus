class OracleInstance < ActiveRecord::Base
  attr_accessible :name, :db_name, :host, :port, :description

  validates :name, :presence => true
  validates :db_name, :presence => true
  validates :host, :presence => true
  validates :port, :presence => true
end