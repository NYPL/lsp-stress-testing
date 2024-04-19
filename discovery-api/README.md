# Stress Testing the Discovery API

1. Generate request paths CSV:

```
bundle install
PATHS_COUNT=1000 BASE_URL=https://qa-platform.nypl.org ruby generate-api-paths.rb
```

This will create a CSV called `./discovery-api-paths.csv` with 1000 distinct, valid (non-404) discovery-api paths.

2. Run Jmeter:

Replace "my-test" with something descriptive about the deployment you're testing (e.g. 'discovery-api-new-es-domain')

`./run.sh my-test ./discovery-api-paths.csv`

Report will launch in a browser on completion (or when you ctrl-c the test).

A shareable zip will also be created that includes the report and raw log file. See command output for details.
