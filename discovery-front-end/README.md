# Stress Testing the DFE

## Requirements

1. Generate request paths CSV:

`PAGES_COUNT=1370 DOMAIN=example.tld ruby generate-paths.rb`

2. Run Jmeter:

`./run.sh my-test ./scc-paths.csv`

Report will launch in a browser on completion (or when you ctrl-c the test).
