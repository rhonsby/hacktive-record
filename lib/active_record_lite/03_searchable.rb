require_relative 'db_connection'
require_relative '02_sql_object'

module Searchable
  def where(params)
    where_line = params.keys.map { |key| "#{key} = ?" }.join(' AND ')
    attribute_values = params.values

    results = DBConnection.execute(<<-SQL, *attribute_values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL

    results.map { |data| self.new(data) }
  end
end

class SQLObject
  extend Searchable
  # Mixin Searchable here...
end
