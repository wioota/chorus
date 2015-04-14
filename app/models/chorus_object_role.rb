class ChorusObjectRole < ActiveRecord::Base
  belongs_to :user
  belongs_to :chorus_object
  belongs_to :role
end