require 'active_model'
require_relative '../chorus_api_validation_format'

class ExternalTable
  include ActiveModel::Validations
  include ChorusApiValidationFormat

  def self.build(options)
    new(options)
  end

  attr_accessor :column_names, :column_types, :name, :location_url,
                :delimiter, :file_pattern

  validates_presence_of :column_names, :column_types, :name, :location_url

  validate :delimiter_not_blank

  def initialize(options = {})
    @database = options[:database]
    @column_names = options[:column_names]
    @column_types = options[:column_types]
    @name = options[:name]
    @location_url = options[:location_url]
    @file_pattern = options[:file_pattern]
    @delimiter = options[:delimiter]
  end

  def save
    return false unless valid?
    @database.create_external_table(
        {
            :table_name => name,
            :columns => map_columns,
            :location_url => location_url + file_pattern_string,
            :delimiter => delimiter
        })
    true
  rescue GreenplumConnection::DatabaseError => e
    errors.add(:name, :TAKEN)
    false
  end

  private

  def file_pattern_string
    file_pattern ? "/#{file_pattern}" : ""
  end

  def map_columns
    (0...column_names.length).map { |i| "#{column_names[i]} #{column_types[i]}" }.join(", ")
  end

  def delimiter_not_blank
    if delimiter.nil? || delimiter.length != 1
      errors.add(:delimiter, :EMPTY)
    end
  end
end