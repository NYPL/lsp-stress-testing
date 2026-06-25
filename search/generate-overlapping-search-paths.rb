require 'csv'
require 'cgi'

PATHS_COUNT = ENV['PATHS_COUNT'] ? ENV['PATHS_COUNT'].to_i : 500

puts "Generating #{PATHS_COUNT} keywords for Discovery API and Research Catalog..."

# Load keywords from the root data directory
keywords = CSV.read('../data/search-keywords.csv')
  .map { |row| row.first }
  .reject { |keyword| ['new york times', 'new yorker', 'new york daily news', 'san francisco chronicle', 'Times-Picayune', 'Times Picayune'].include? keyword }

raise "Not enough keywords in CSV to generate #{PATHS_COUNT} paths." if keywords.size < PATHS_COUNT

# Take same pool of top keywords
overlap_keywords = keywords.first(PATHS_COUNT)

api_paths = []
rc_paths = []

overlap_keywords.each do |keyword|
  escaped = CGI.escape(keyword)
  
  # Discovery API search and aggregate
  api_paths << "/api/v0.1/discovery/resources?q=#{escaped}"
  api_paths << "/api/v0.1/discovery/resources/aggregations?q=#{escaped}"
  
  # The RC is requesting both on every search
  rc_paths << "/research/research-catalog/search?q=#{escaped}"
end

puts "Writing #{api_paths.size} paths to discovery-api/api-search-paths.csv"
File.write('../discovery-api/api-search-paths.csv', api_paths.join("\n"))

puts "Writing #{rc_paths.size} paths to research-catalog/rc-search-paths.csv"
File.write('../research-catalog/rc-search-paths.csv', rc_paths.join("\n"))

puts "Search paths generated"