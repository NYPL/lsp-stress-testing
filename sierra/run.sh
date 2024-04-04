# Usage
# ./run.sh ENVNAME
# 
# ENVNAME may be anything; It's just used to name the log file and final report.
# Examples: "qa" or "qa-new-deployment"
#
# e.g.
# ./run.sh production

TIMESTAMP=$(date +"%Y%m%d%H%M")
ENVNAME=$1
CSV=$2
TOKEN=$3
LOGFILE=runs/sierra-api-log-$TIMESTAMP-$ENVNAME.jtl
REPORT=runs/sierra-api-log-dashboard-$TIMESTAMP-$ENVNAME

if [ -z $ENVNAME ]; then
  echo Usage: ./run.sh ENVNAME
  exit
fi

mkdir -f runs
echo Writing to $LOGFILE

echo Running $ENVNAME sierra-api jmeter test. Logging to $LOGFILE
HEAP="-Xms1g -Xmx1g -XX:MaxMetaspaceSize=256m" jmeter \
  -t ../generic-api-jmeter-test-plan.jmx \
  -n \
  -l $LOGFILE \
  -Jusers=10 \
  -Jduration=720 \
  -Jcsv=$CSV \
  -Jtoken=$TOKEN \
  -Jdomain=nypl-sierra-test.nypl.org

echo Finished. Logs are at $LOGFILE

echo Generating report to $REPORT
jmeter -g $LOGFILE -o $REPORT
echo Wrote report to $REPORT

open $REPORT/index.html
