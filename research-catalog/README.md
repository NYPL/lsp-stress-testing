# Stress testing the Research Catalog (frontend)

## Requirements

1. Generate request paths CSV:

`PAGES_COUNT=1370 ruby generate-paths.rb`

2. Run Jmeter:

`./run.sh production my-report ./rc-paths.csv`

Report will launch in a browser on completion (or when you ctrl-c the test).
