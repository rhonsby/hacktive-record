require_relative '04_associatable'

# Phase V
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options =
      through_options.model_class.assoc_options[source_name]

      source = DBConnection.execute(<<-SQL)
        SELECT
          #{source_options.table_name}.*
        FROM
          #{self.class.table_name}
        INNER JOIN
          #{through_options.table_name}
        ON
          #{self.class.table_name}.#{through_options.foreign_key} =
          #{through_options.table_name}.#{through_options.primary_key}
        INNER JOIN
          #{source_options.table_name}
        ON
          #{source_options.table_name}.#{source_options.primary_key} =
          #{through_options.table_name}.#{source_options.foreign_key}
        WHERE
          #{self.class.table_name}.#{through_options.foreign_key} =
          #{self.send(through_options.foreign_key)}
      SQL

      source_options.model_class.new(source.first)
    end
  end
end