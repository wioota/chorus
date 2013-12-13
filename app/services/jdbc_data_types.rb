class JdbcDataTypes

  JDBC_TO_PRETTY_CATEGORY_NAME_MAP = HashWithIndifferentAccess.new(
      :string => 'STRING',
      :integer => 'WHOLE_NUMBER',
      :date => 'DATETIME',
      :datetime => 'DATETIME',
      :time => 'DATETIME',
      :boolean => 'BOOLEAN',
      :float => 'REAL_NUMBER',
      :decimal => 'REAL_NUMBER',
      :blob => 'OTHER',
      :enum => 'OTHER'
  )

  def self.pretty_category_name(type)
    JDBC_TO_PRETTY_CATEGORY_NAME_MAP[type]
  end
end