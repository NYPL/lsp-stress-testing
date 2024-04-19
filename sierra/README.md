# Stress Testing the Sierra API

1. Create a creds file:

`cp .env-sample .env-qa`

2. Generate request paths CSV:

`node generate-api-paths.js --envfile .env-qa --outfile ./sierra-api-paths.csv`

3. Get a Bearer token.

See instructions [in main README](../README.md#bearer-tokens).

4. Run Jmeter:

`./run.sh my-test ./sierra-api-paths.csv BEARER_TOKEN`
