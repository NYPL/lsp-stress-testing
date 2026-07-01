require 'csv'
require 'cgi'

PATHS_COUNT = ENV['PATHS_COUNT'] ? ENV['PATHS_COUNT'].to_i : 500
AVAILABLE_SCOPES = %w[all title contributor journal_title callnumber standard_number subject cql].freeze

# Load queries for particular search scopes
CQL_QUERIES = File.readlines('../data/cql.csv').map(&:strip).reject(&:empty?)
CALLNUMBER_QUERIES = File.readlines('../data/callnumber.csv').map(&:strip).reject(&:empty?)
STANDARD_NUMBER_QUERIES = File.readlines('../data/standard_number.csv').map(&:strip).reject(&:empty?)

scopes_to_use = ENV['SEARCH_SCOPE'] ? ENV['SEARCH_SCOPE'].split(',') : AVAILABLE_SCOPES

puts "Generating #{PATHS_COUNT} keywords for Discovery API and Research Catalog..."
puts "Using search scopes: #{scopes_to_use.join(', ')}"

# Load keywords from the root data directory
keywords = CSV.read('../data/search-keywords.csv')
  .map { |row| row.first }
  .reject { |keyword| ['new york times', 'new yorker', 'new york daily news', 'san francisco chronicle', 'Times-Picayune', 'Times Picayune'].include? keyword }

raise "Not enough keywords in CSV to generate #{PATHS_COUNT} paths." if keywords.size < PATHS_COUNT

# Take same pool of top keywords
overlap_keywords = keywords.first(PATHS_COUNT)

api_paths = []
rc_paths = []
scope_counts = Hash.new(0)

overlap_keywords.each do |keyword|
  current_scope = scopes_to_use.sample
  scope_counts[current_scope] += 1
  
  # Use a specific query if the scope is cql, standard_number, or callnumber. Otherwise use any old keyword
  actual_keyword = case current_scope
                   when 'cql'
                     CQL_QUERIES.sample
                   when 'callnumber'
                     CALLNUMBER_QUERIES.sample
                   when 'standard_number'
                     STANDARD_NUMBER_QUERIES.sample
                   else
                     keyword
                   end
  escaped = CGI.escape(actual_keyword)

  # Discovery API search and aggregate
  api_paths << ["/api/v0.1/discovery/resources?q=#{escaped}&search_scope=#{current_scope}", current_scope]
  api_paths << ["/api/v0.1/discovery/resources/aggregations?q=#{escaped}&search_scope=#{current_scope}", current_scope]
  
  # The RC is requesting both of the above on every search
  rc_paths << ["/research/research-catalog/search?q=#{escaped}&search_scope=#{current_scope}", current_scope]
end

api_out = ENV['API_OUT'] || '../discovery-api/api-search-paths.csv'
rc_out = ENV['RC_OUT'] || '../research-catalog/rc-search-paths.csv'

puts "Writing #{api_paths.size} paths to #{api_out}"
CSV.open(api_out, "w") do |csv|
  api_paths.each { |row| csv << row }
end

puts "Writing #{rc_paths.size} paths to #{rc_out}"
CSV.open(rc_out, "w") do |csv|
  rc_paths.each { |row| csv << row }
end

puts "Search paths generated"
puts "\nScope breakdown:"
scope_counts.each do |scope, count|
  puts "  #{scope}: #{count} keywords (#{count * 2} API paths, #{count} RC paths)"
end