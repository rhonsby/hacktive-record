require_relative 'db_connection'
require_relative '01_mass_object'
require 'active_support/inflector'
require 'debugger'

class MassObject
  def self.parse_all(results)
    results.map { |data| self.new(data) }
  end
end

class SQLObject < MassObject
  def self.columns
    table_data = DBConnection.execute2("SELECT * FROM #{table_name}")
    col_names = table_data[0].map(&:to_sym)

    col_names.each do |col_name|
      define_method("#{col_name}") do
        attributes[col_name]
      end

      define_method("#{col_name}=") do |value|
        attributes[col_name] = value
      end
    end

    col_names
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.underscore.pluralize
  end

  def self.all
    results = DBConnection.execute("SELECT * FROM #{table_name}")
    results.map { |params| self.new(params) }
  end

  def self.find(id)
    obj = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL

    self.new(obj.first)
  end

  def attributes
    @attributes ||= {}
  end

  def insert
    col_names = (@columns).map(&:to_s).join(', ')
    attr_values = attribute_values
    question_marks = (["?"] * attr_values.count).join(', ')

    DBConnection.execute(<<-SQL, *attr_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
    DBConnection.last_insert_row_id
  end

  def initialize(params = {})
    @columns = self.class.columns

    params.each do |attr_name, value|
      sym = attr_name.to_sym

      unless @columns.include?(sym)
        raise "unknown attributes '#{attr_name}'"
      end

      attributes[sym] = value
    end
  end

  def save
    id ? update : insert
  end

  def update
    set = (@columns).map { |col_name| "#{col_name} = ?" }.join(', ')
    attr_values = attribute_values

    DBConnection.execute(<<-SQL, *attr_values)
      UPDATE
        #{self.class.table_name}
      SET
        #{set}
      WHERE
        id = #{self.id}
    SQL
  end

  def attribute_values
    @columns.map { |col| self.send(col) }
  end
end
