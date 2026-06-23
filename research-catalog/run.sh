# Usage
# ./run.sh ENV REPORTNAME
# 
# ENV: either qa or production
# REPORTNAME: name for report and log file
#
# e.g.
# ./run.sh production my-report

TIMESTAMP=$(date +"%Y%m%d%H%M")
ENV=$1

if [ "$#" -eq 2 ]; then
  REPORTNAME="report"
  CSV=$2
else
  REPORTNAME=${2:-report}
  CSV=$3
fi

LOGFILE=runs/rc-log-$TIMESTAMP-$REPORTNAME.jtl
REPORT=runs/rc-log-dashboard-$TIMESTAMP-$REPORTNAME

if [ -z "$ENV" ] || [ -z "$CSV" ]; then
  echo "Usage: ./run.sh ENV [REPORTNAME] CSV_PATH"
  exit 1
fi

mkdir -p runs
echo Writing to $LOGFILE

if [ "$ENV" = "production" ]; then
  DOMAIN="www.nypl.org"
else
  DOMAIN="qa-www.nypl.org"
fi

echo Running $ENV Research Catalog jmeter test. Logging to $LOGFILE
HEAP="-Xms1g -Xmx1g -XX:MaxMetaspaceSize=256m" jmeter \
  -t ./rc.jmx \
  -n \
  -l $LOGFILE \
  -Jusers=10 \
  -Jduration=720 \
  -Jcsv=$CSV \
  -Jdomain=$DOMAIN

echo Finished. Logs are at $LOGFILE

echo Generating report to $REPORT
jmeter -g $LOGFILE -o $REPORT
echo Wrote report to $REPORT

open $REPORT/index.html
