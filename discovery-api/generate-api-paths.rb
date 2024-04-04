require 'csv'
require 'httparty'
require 'json'
require 'cgi'

# Load keywords, use them to look up bibs
#
# Usage:
#
# PATHS_COUNT=1370 ruby generate-api-paths.rb
#

# Total number of paths to generate:
PATHS_COUNT = ENV['PATHS_COUNT'] ? ENV['PATHS_COUNT'].to_i : 1000
BASE_URL = ENV['BASE_URL'] ? ENV['BASE_URL'] : 'https://qa-platform.nypl.org'

# Distribution of page categories desired:
makeup = {
  :search => 0.61,
  :bib => 0.39
}

puts "Generating #{PATHS_COUNT} paths for #{BASE_URL}, with the following target breakdown:"
makeup.each do |(k, v)|
  puts "  #{k.to_s}: #{(PATHS_COUNT * v).to_i}"
end

keywords = CSV.read('../data/search-keywords.csv')
  .map { |row| row.first }
  # Skip problematic searches until many-item-bib bug fixed
  .filter { |keyword| ! ['new york times', 'new yorker', 'new york daily news', 'san francisco chronicle', 'Times-Picayune', 'Times Picayune'].include? keyword }

target_searches = (makeup[:search] * PATHS_COUNT).to_i
raise "I would like to be working with #{target_searches} distinct keywrds but I have only #{keywords.size}" if keywords.size < target_searches

bnums = []
keywords.shuffle.each do |keyword|
  puts "Fetching #{keyword}"
  raw_response = HTTParty.get("#{BASE_URL}/api/v0.1/discovery/resources?q=#{CGI.escape keyword}")
  # puts "Raw: #{raw_response}"
  response = JSON.parse raw_response
  bnums_to_add = response['itemListElement']
    .map { |el| el['result']['@id'] }
    .map { |id| id.sub /res:/, '' }
    .sample(20)
  puts "Adding for keyword #{keyword}: #{bnums_to_add}"
  bnums += bnums_to_add

  if bnums.size > PATHS_COUNT * makeup[:bib]
    puts "Done collecting bnums"
    break
  end
end

page_counts = makeup.keys.inject({}) { |h, k| h[k] = 0; h }

paths = []

# Gather search paths
keyword_pool = []
while page_counts[:search] < PATHS_COUNT * makeup[:search]
  keyword_pool = keywords.shuffle if keyword_pool.empty?
  keyword = keyword_pool.shift
  paths << "/api/v0.1/discovery/resources?q=#{CGI.escape keyword}"
  paths << "/api/v0.1/discovery/resources/aggregations?q=#{CGI.escape keyword}"
  page_counts[:search] += 1
end

# Gather bib paths
bnum_pool = []
while page_counts[:bib] < PATHS_COUNT * makeup[:bib]
  bnum_pool = bnums.shuffle if bnum_pool.empty?
  bnum = bnum_pool.shift
  paths << "/api/v0.1/discovery/resources/#{bnum}"
  page_counts[:bib] += 1
end

paths.shuffle!

puts "Built #{paths.size} paths with #{page_counts.inject([]) { |a, (name, count)| a << "#{count} #{name}" }.join(', ')}"

outfile = 'discovery-api-paths.csv'

puts "Writing to #{outfile}"
File.open(outfile, 'w') do |f|
  f.write(paths.join("\n"))
end
