require 'csv'
require 'httparty'
require 'json'
require 'cgi'

# Load keywords, use them to look up bibs

# Total number of paths to generate:
PAGES_COUNT = ENV['PAGES_COUNT'] ? ENV['PAGES_COUNT'].to_i : 1000

# Distribution of page categories desired:
makeup = {
  :search => 0.36,
  :bib => 0.23,
  :homepage => 0.13,
  :browse => 0.36
}

puts "Generating #{PAGES_COUNT} page paths, with the following target breakdown:"
makeup.each do |(k, v)|
  puts "  #{k.to_s}: #{(PAGES_COUNT * v).to_i}"
end

keywords = CSV.read('../data/search-keywords.csv')
  .map { |row| row.first }

target_searches = (makeup[:search] * PAGES_COUNT).to_i
raise "I would like to be working with #{target_searches} distinct keywords but I have only #{keywords.size}" if keywords.size < target_searches

bnums = []
keywords.shuffle.each do |keyword|
  puts "Fetching #{keyword}"
  raw_response = HTTParty.get("https://qa-platform.nypl.org/api/v0.1/discovery/resources?q=#{CGI.escape keyword}")
  # puts "Raw: #{raw_response}"
  response = JSON.parse raw_response
  bnums += response['itemListElement']
    .map { |el| el['result']['@id'] }
    .map { |id| id.sub /res:/, '' }
    .sample(20)

  if bnums.size > PAGES_COUNT * makeup[:bib]
    puts "Done collecting bnums"
    break
  end
end

page_counts = makeup.keys.inject({}) { |h, k| h[k] = 0; h }

paths = []

# Gather search paths
keyword_pool = []
while page_counts[:search] < PAGES_COUNT * makeup[:search]
  keyword_pool = keywords.shuffle if keyword_pool.empty?
  keyword = keyword_pool.shift
  paths << "/research/research-catalog/search?q=#{CGI.escape keyword}"
  page_counts[:search] += 1
end

# Gather bib paths
bnum_pool = []
while page_counts[:bib] < PAGES_COUNT * makeup[:bib]
  bnum_pool = bnums.shuffle if bnum_pool.empty?
  bnum = bnum_pool.shift
  paths << "/research/research-catalog/bib/#{bnum}"
  page_counts[:bib] += 1
end

# Gather homepage paths (path)
while page_counts[:homepage] < PAGES_COUNT * makeup[:homepage]
  paths << "/research/research-catalog/"
  page_counts[:homepage] += 1
end

# Gather browse paths
term_pool = []
while page_counts[:browse] < PAGES_COUNT * makeup[:browse]
  term_pool = keywords.shuffle if term_pool.empty?
  term = term_pool.shift
  # paths << "/research/research-catalog/browse/subjects/#{term}"
  paths << "/research/research-catalog/browse?q=#{term}"
  page_counts[:browse] += 1
end


paths.shuffle!

puts "Built #{paths.size} paths with #{page_counts.inject([]) { |a, (name, count)| a << "#{count} #{name}" }.join(', ')}"

outfile = 'rc-paths.csv'

puts "Writing to #{outfile}"
File.open(outfile, 'w') do |f|
  f.write(paths.join("\n"))
end
