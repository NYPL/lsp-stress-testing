# Stress Testing the Discovery API

## Requirements

1. Generate request paths CSV:

`PATHS_COUNT=1370 DOMAIN=example.tld ruby generate-api-paths.rb`

2. Run Jmeter:

`./run.sh my-test ./discovery-api-paths.csv`

Report will launch in a browser on completion (or when you ctrl-c the test).
