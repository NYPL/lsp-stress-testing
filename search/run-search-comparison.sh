#!/bin/bash

# Usage: ./run-search-comparison.sh [--delay MS] [--paths COUNT]
# Example: ./run-search-comparison.sh --delay 3000 --paths 500

DELAY=${1:-0}
DELAY=0
export PATHS_COUNT=500

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --delay) DELAY="$2"; shift ;;
    --paths) export PATHS_COUNT="$2"; shift ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done

echo "------------------------------------------------"
echo "1. Generating search paths..."
echo "------------------------------------------------"
ruby ./generate-search-comparison-paths.rb

TIMESTAMP=$(date +"%Y%m%d%H%M")
mkdir -p runs

API_JTL="runs/api-$TIMESTAMP.jtl"
RC_JTL="runs/rc-$TIMESTAMP.jtl"
MERGED_JTL="runs/search-comparison-$TIMESTAMP.jtl"
REPORT_DIR="runs/search-comparison-report-$TIMESTAMP"

echo "------------------------------------------------"
echo "2. Running Discovery API tests..."
echo "------------------------------------------------"
HEAP="-Xms1g -Xmx1g -XX:MaxMetaspaceSize=256m" jmeter \
  -t ../generic-api-jmeter-test-plan.jmx \
  -n \
  -l $API_JTL \
  -Jusers=10 \
  -Jduration=600 \
  -Jcsv=$(pwd)/../discovery-api/api-search-paths.csv \
  -Jdomain=qa-platform.nypl.org \
  -Jdelay=$DELAY

echo "------------------------------------------------"
echo "3. Running Research Catalog tests..."
echo "------------------------------------------------"
HEAP="-Xms1g -Xmx1g -XX:MaxMetaspaceSize=256m" jmeter \
  -t ../research-catalog/rc.jmx \
  -n \
  -l $RC_JTL \
  -Jusers=10 \
  -Jduration=600 \
  -Jcsv=$(pwd)/../research-catalog/rc-search-paths.csv \
  -Jdomain=qa-www.nypl.org \
  -Jdelay=$DELAY

echo "------------------------------------------------"
echo "4. Grouping results..."
echo "------------------------------------------------"
# merge both JTLs. this also rewrites the "label" column based on the request URL
ruby -r csv -e '
  headers = CSV.open(ARGV[0], &:readline)
  CSV.open(ARGV[2], "w", write_headers: true, headers: headers) do |csv|
    [ARGV[0], ARGV[1]].each do |jtl|
      next unless File.exist?(jtl)
      CSV.foreach(jtl, headers: true) do |row|
        url = row["URL"].to_s
        
        if url.include?("/aggregations")
          row["label"] = "DiscoAPI aggregations"
        elsif url.include?("/api/v0.1/discovery/resources")
          row["label"] = "DiscoAPI search"
        elsif url.include?("/research/research-catalog/search")
          row["label"] = "RC search"
        else
          row["label"] = "Other request"
        end
        
        csv << row
      end
    end
  end
' $API_JTL $RC_JTL $MERGED_JTL

echo "------------------------------------------------"
echo "5. Generating combined dashboard..."
echo "------------------------------------------------"
jmeter -g $MERGED_JTL -o $REPORT_DIR
echo "Report generated at $REPORT_DIR"
open $REPORT_DIR/index.html
