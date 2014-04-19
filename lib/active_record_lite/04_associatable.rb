require_relative '03_searchable'
require 'active_support/inflector'
require 'debugger'

# Phase IVa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.to_s.constantize
  end

  def table_name
    class_name.constantize.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    self.foreign_key = options[:foreign_key] || "#{name}_id".to_sym
    self.primary_key = options[:primary_key] || :id
    self.class_name  = options[:class_name]  || name.to_s.camelcase.singularize
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    self.primary_key = options[:primary_key] || :id
    self.foreign_key = options[:foreign_key] ||
      "#{self_class_name.to_s.downcase}_id".to_sym
    self.class_name  = options[:class_name]  || name.to_s.camelcase.singularize
  end
end

module Associatable
  # Phase IVb
  def belongs_to(name, options = {})
    define_method("#{name}") do
      options = BelongsToOptions.new(name, options)

      foreign_key = self.send(options.foreign_key)
      model_class = options.model_class

      self.class.assoc_options[name] = options

      model_class.where({
        "id" => foreign_key
      }).first
    end
  end

  def has_many(name, options = {})
    define_method("#{name}") do
      options = HasManyOptions.new(name, self.class, options)

      foreign_key = options.send(:foreign_key)
      model_class = options.model_class

      model_class.where({
        "#{foreign_key}" => self.id
      })
    end
  end

  def assoc_options
    # Wait to implement this in Phase V. Modify `belongs_to`, too.
    @options ||= {}
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
