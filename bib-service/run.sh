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
LOGFILE=$ENVNAME-TIMESTAMP.jtl
REPORT=$ENVNAME-$TIMESTAMP

if [ -z $ENVNAME ]; then
  echo Usage: ./run.sh ENVNAME
  exit
fi

mkdir -f runs

echo Running $ENVNAME jmeter test. Logging to ./runs/$LOGFILE
HEAP="-Xms1g -Xmx1g -XX:MaxMetaspaceSize=256m" jmeter \
  -t ../generic-api-jmeter-test-plan.jmx \
  -n \
  -l ./runs/$LOGFILE \
  -Jusers=10 \
  -Jduration=10 \
  -Jcsv=$CSV \
  -Jtoken=$TOKEN \
  -Jdomain=qa-platform.nypl.org

echo Finished. Logs are at runs/$LOGFILE

jmeter -g ./runs/$LOGFILE -o runs/$REPORT
echo Wrote report to ./runs/$REPORT

cd runs
zip -rq $ENVNAME-$TIMESTAMP.zip $LOGFILE $REPORT
cd -
echo Sharable zip of log and report: runs/$ENVNAME-$TIMESTAMP.zip

open runs/$REPORT/index.html
