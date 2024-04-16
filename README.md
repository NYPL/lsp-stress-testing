# LSP Stress Testing

This repo captures documentation and tools around stress testing LSP APIs and apps such as the Research Catalog, the discovery-api, and the Sierra API. It will show you how to generate a ton of traffic on a Oauth2 protected API such as the Sierra API using Jmeter on one or more computers.

## Usage

See the [discovery-api](./discovery-api) and [sierra-api](./sierra-api) sample projects.

### Create some paths to test

The generic testing script depends on a CSV containing a bunch of request paths to test at random. Ideally it should contain thousands of paths that are representative of typical usage of the API under testing.

See [discovery-api sample paths](./discovery-api/sample-paths.csv).

### Bearer tokens

If the API you want to run requires a Bearer token, here's how you can use them.

To create the access token:

 - Open Terminal
 - Run `curl -u ID:SECRET TOKENURL -d grant_type=client_credentials`
   - Swap out ID and SECRET for relevant creds
   - Swap out TOKENURL for the token URL appropriate for the environment. (Usually it ends in "/token".)
 - This should respond with something like the following:

```
{
  "access_token":"m4pz5DTysMEueL3D-wib4S83gHC4xtkATzV7-A",
  "token_type":"bearer",
  "expires_in":3600
}
```

 - In the above response, m4pz5DTysMEueL3D-wib4S83gHC4xtkATzV7-A is the access token. (Real tokens will be ~3 times longer.)

Our Bearer tokens tend to be valid for 60 mins (see `expires_in` above), so retrieve it immediately before testing and don't run your test beyond the expiration of the token.

### Generating request paths

The set of request paths you'll want to hit depend on the service and environment. See "generate-api-paths" scripts in sample projects for examples. Note that you may need to generate new CSVs for each environment tested because resource paths in one environment may not be available in a different environment due to data differences, which will introduce error noise in the tests.

### Using Jmeter

Install jmeter if you don’t already have it via:

`brew install jmeter`

A general purpose Jmeter test plan is included as [generic-api-jmeter-test-plan.jmx](./generic-api-jmeter-test-plan.jmx).

Invoke like:

```
HEAP="-Xms1g -Xmx1g -XX:MaxMetaspaceSize=256m" jmeter \
  -t ../random-api-endpoints.jmx \
  -n \
  -l $LOGFILE \
  -Jusers=10 \
  -Jduration=720 \
  -Jcsv=[path to CSV containing request paths] \
  -Jdomain=[domain of app]
```
