require 'active_model'
require_relative '../database_connection'
require_relative '../chorus_api_validation_format'

class ExternalTable
  include ActiveModel::Validations
  include ChorusApiValidationFormat
  include DatabaseConnection

  def self.build(options)
    new(options)
  end

  attr_accessor :schema_name, :column_names, :column_types, :name, :location_url,
              :has_header, :delimiter, :file_pattern

  validates_presence_of :schema_name, :column_names, :column_types, :name, :location_url

  validate :delimiter_not_blank

  def initialize(options = {})
    self.database = options[:database]
    @schema_name = options[:schema_name]
    @column_names = options[:column_names]
    @column_types = options[:column_types]
    @name = options[:name]
    @location_url = options[:location_url]
    @file_pattern = options[:file_pattern]
    @has_header = options[:has_header]
    @delimiter = options[:delimiter]
  end

  def save
    return false unless valid?
    database.run("CREATE EXTERNAL TABLE \"#{schema_name}\".\"#{name}\"" +
                  " (#{map_columns}) LOCATION ('#{location_url}#{file_pattern_string}') FORMAT 'TEXT'" +
                  " (DELIMITER '#{delimiter}'#{header_sql})")
    true
  rescue Sequel::DatabaseError => e
    errors.add(:name, :TAKEN)
    false
  end

  private

  def file_pattern_string
    file_pattern ? "/#{file_pattern}" : ""
  end

  def header_sql
    has_header.to_s == 'true' ? ' HEADER' : ''
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