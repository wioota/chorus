class PgDatabase < Database

  has_many :schemas, :class_name => 'PgSchema', :as => :parent, :dependent => :destroy
end
