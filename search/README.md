# Search performance testing

The `run-search-comparisons` script measures the performance of search/aggregation queries made directly against Discovery API versus the same queries made through the Research Catalog search interface.

To run the script:
`./run-search-comparison.sh [--env qa/production] [--delay MS] [--paths COUNT]`

- Enviroment is qa (qa-platform.nypl.org, qa-www.nypl.org/research/research-catalog) or production
- Delay refers to the gap in milliseconds between each request (simulating a human actually making requests rather than just drilling the API).
- Paths count refers to the number of unique search terms to generate and test.

ex. `./run-search-comparison.sh --env qa --delay 3000 --paths 500`
