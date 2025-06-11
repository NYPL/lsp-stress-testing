# Stress Testing the BibService API

1. Get an ACCESS_TOKEN by following the steps [in main README](../README.md#bearer-tokens).

2. Generate request paths CSV:

```
ACCESS_TOKEN=<token> ./generate-api-paths.sh https://qa-platform.nypl.org paths.csv 1000
```

This will create a CSV called `./paths.csv` with 1000 randomized valid (non-404) bib service paths.

2. Run Jmeter:

`./run.sh bib-service ./paths.csv`

Report will launch in a browser on completion (or when you ctrl-c the test).

A shareable zip will also be created that includes the report and raw log file. See command output for details.
