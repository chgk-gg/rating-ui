# frozen_string_literal: true

# Converts queries with named parameters (:first_name, :last_name) into queries with numbered parameters ($1, $2),
# returning both the modified query and an array of parameters.
# We need this only for SELECT queries and only for manually written ones,
# so we don't handle cases like `IN (:name)` or `VALUES (:name)`.
# To simplify parsing, we assume that there is a space before the named parameter,
# which is our style anyway.
module NamedParameters
  # @param query [String] SQL query with named parameters
  # @param params [Hash] Hash of parameters to replace in the query
  # @return [Array] Array containing the processed query and an array of parameters
  def self.convert_to_numbered(query, params)
    return [query, params] unless params.is_a?(Hash)

    params_list = []
    replacement_order = []

    query.scan(/ :([a-zA-Z_][a-zA-Z0-9_]*)/) do |match|
      param_name = match[0].to_sym
      raise ArgumentError, "Missing parameter: #{param_name}" unless params.key?(param_name)

      params_list << params[param_name]
      replacement_order << param_name
    end

    query = query.dup
    replacement_order.each_with_index do |param_name, index|
      query.sub!(":#{param_name}", "$#{index + 1}")
    end
    [query, params_list]
  end
end
