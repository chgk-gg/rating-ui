# frozen_string_literal: true

module Cacheable
  extend ActiveSupport::Concern

  def exec_query_for_single_value(query:, params: nil, default_value: nil, cache: false)
    exec_query_with_cache(query, params, cache:).rows.first.first
  rescue NoMethodError
    default_value
  end

  def exec_query_for_single_row(query:, params: nil, cache: false)
    exec_query_with_cache(query, params, cache:).rows.first
  end

  def exec_query_for_hash_array(query:, params: nil, cache: false)
    exec_query_with_cache(query, params, cache:).to_a
  end

  def exec_query_for_hash(query:, params: nil, group_by:, cache: false)
    exec_query_with_cache(query, params, cache:)
      .each_with_object(Hash.new { |h, k| h[k] = [] }) do |row, hash|
        hash[row.delete(group_by)] << row
      end
  end

  def exec_query(query:, params: nil, result_class:, cache: false)
    exec_query_with_cache(query, params, cache:)
      .map { |row| result_class.new(row) }
  end

  def build_placeholders(start_with:, count:)
    start_with.upto(count + start_with - 1).map { |index| "$#{index}" }.join(", ")
  end

  private

  def cache_namespace
    ""
  end

  def exec_query_with_cache(query, params, cache: false)
    query, params = NamedParameters.convert_to_numbered(query, params) if params.is_a?(Hash)
    return run_query(query, params) unless cache

    # caller_locations(1, 1) is exec_query_smth
    # caller_locations(2, 1) is a method from, e.g., ReleaseQueries module, which is what we are looking for
    cache_key = "#{cache_namespace}/#{caller_locations(2, 1).first.label}/#{params&.join("/")}"

    Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      run_query(query, params)
    end
  end

  def run_query(query, params)
    if params.present?
      ActiveRecord::Base.connection.exec_query(query, "", params)
    else
      ActiveRecord::Base.connection.exec_query(query)
    end
  end
end
