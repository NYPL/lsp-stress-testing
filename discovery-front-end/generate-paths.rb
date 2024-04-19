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
  :hold => 0.26,
  :bib => 0.23,
  :homepage => 0.13,
  :subject_headings => 0.01
}

puts "Generating #{PAGES_COUNT} page paths, with the following target breakdown:"
makeup.each do |(k, v)|
  puts "  #{k.to_s}: #{(PAGES_COUNT * v).to_i}"
end

keywords = CSV.read('../data/search-keywords.csv')
  .map { |row| row.first }
  # Skip problematic searches until many-item-bib bug fixed
  .filter { |keyword| ! ['new york times', 'new yorker', 'new york daily news', 'san francisco chronicle', 'Times-Picayune', 'Times Picayune'].include? keyword }

target_searches = (makeup[:search] * PAGES_COUNT).to_i
raise "I would like to be working with #{target_searches} distinct keywrds but I have only #{keywords.size}" if keywords.size < target_searches

subject_headings = CSV.read('../data/subject-heading-urls.csv')

target_subject_headings = (makeup[:subject_headings] * PAGES_COUNT).to_i
raise "I would like to be working with #{target_subject_headings} distinct subject headings but I have only #{subject_headings.size}" if subject_headings.size < target_subject_headings

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

# Gather search patsh
keyword_pool = []
while page_counts[:search] < PAGES_COUNT * makeup[:search]
  keyword_pool = keywords.shuffle if keyword_pool.empty?
  keyword = keyword_pool.shift
  paths << "/research/collections/shared-collection-catalog/search?q=#{CGI.escape keyword}"
  page_counts[:search] += 1
end

# Gather bib paths
bnum_pool = []
while page_counts[:bib] < PAGES_COUNT * makeup[:bib]
  bnum_pool = bnums.shuffle if bnum_pool.empty?
  bnum = bnum_pool.shift
  paths << "/research/collections/shared-collection-catalog/bib/#{bnum}"
  page_counts[:bib] += 1
end

# Gather homepage paths (path)
while page_counts[:homepage] < PAGES_COUNT * makeup[:homepage]
  paths << "/research/collections/shared-collection-catalog/"
  page_counts[:homepage] += 1
end

# Gather multiple subject headings paths representing individual navigations:
term_pool = []
while page_counts[:subject_headings] < PAGES_COUNT * makeup[:subject_headings]
  term_pool = subject_headings.shuffle if term_pool.empty?
  term = term_pool.shift.first
  *, uuid, label = /subject_headings\/([^\?]+)\?label=(.+)/.match(term).to_a
  paths << "/research/collections/shared-collection-catalog/subject_headings/#{uuid}?label=#{label}"
  paths << "/research/collections/shared-collection-catalog/api/subjectHeadings/subject_headings/#{uuid}/context"
  paths << "/research/collections/shared-collection-catalog/api/subjectHeadings/subject_headings/#{uuid}/related"
  # Can't figure out how to build all these necessary params..
  # paths << "/research/collections/shared-collection-catalog/api/subjectHeading/#{term[1]?&sort=date&sort_direction=desc&per_page=6&shep_bib_count=66797&shep_uuid=#{term[0]}"
  page_counts[:subject_headings] += 1
end


paths.shuffle!

puts "Built #{paths.size} paths with #{page_counts.inject([]) { |a, (name, count)| a << "#{count} #{name}" }.join(', ')}"

outfile = 'scc-paths.csv'

puts "Writing to #{outfile}"
File.open(outfile, 'w') do |f|
  f.write(paths.join("\n"))
end
