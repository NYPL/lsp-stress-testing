# Usage
# ./run.sh ENVNAME [CSV] [DOMAIN] [PORT] [PROTOCOL]
# 
# ENVNAME may be anything; It's just used to name the log file and final report.
# Examples: "qa" or "qa-new-deployment"
#
# e.g.
# ./run.sh local-test ./discovery-api-paths.csv localhost 8082 http

TIMESTAMP=$(date +"%Y%m%d%H%M")
ENVNAME=$1
CSV=${2:-./discovery-api-paths.csv}
DOMAIN=${3:-localhost}
PORT=${4:-8082}
PROTOCOL=${5:-http}
USERS=${USERS:-10}
DURATION=${DURATION:-600}
RAMPUP=${RAMPUP:-1}
LOGFILE=discovery-api-log-$TIMESTAMP-$ENVNAME.jtl
REPORT=discovery-api-log-dashboard-$TIMESTAMP-$ENVNAME

if [ -z "$ENVNAME" ]; then
  echo "Usage: ./run.sh ENVNAME [CSV] [DOMAIN] [PORT] [PROTOCOL]"
  exit
fi

if [ ! -f "$CSV" ]; then
  echo "CSV file not found: $CSV"
  exit 1
fi

mkdir -p runs

ULIMIT_N=$(ulimit -n)
if [ "$ULIMIT_N" != "unlimited" ] && [ "$ULIMIT_N" -lt 10000 ]; then
  echo "Warning: open file limit is $ULIMIT_N; raising it for this run so jmeter isnt the bottleneck"
  ulimit -n 10000 2>/dev/null
fi

echo "Running $ENVNAME discovery-api jmeter test against $PROTOCOL://$DOMAIN:$PORT"
echo "Users: $USERS Duration: $DURATION Rampup: $RAMPUP CSV: $CSV (CSV loops for full duration)"
echo "Logging to ./runs/$LOGFILE"
HEAP="-Xms2g -Xmx2g -XX:MaxMetaspaceSize=256m" jmeter \
  -t ../generic-api-jmeter-test-plan.jmx \
  -n \
  -l "./runs/$LOGFILE" \
  -Jusers="$USERS" \
  -Jduration="$DURATION" \
  -Jrampup="$RAMPUP" \
  -Jcsv="$CSV" \
  -Jdomain="$DOMAIN" \
  -Jport="$PORT" \
  -Jprotocol="$PROTOCOL" \
  -Jhttpclient4.max_total_connections="$((USERS * 2))" \
  -Jhttpclient4.max_connections_per_route="$((USERS * 2))" \
  -Jjmeter.save.saveservice.response_data.on_error=true \
  -Jjmeter.save.saveservice.assertion_results_failure_message=true

echo "Finished. Logs are at runs/$LOGFILE"

jmeter -g "./runs/$LOGFILE" -o "runs/$REPORT"
echo "Wrote report to ./runs/$REPORT"

cd runs
zip -rq "$ENVNAME-$TIMESTAMP.zip" "$LOGFILE" "$REPORT"
cd -
echo "Sharable zip of log and report: runs/$ENVNAME-$TIMESTAMP.zip"

open "runs/$REPORT/index.html"
