if [ -z "$ACCESS_TOKEN" ]; then
  echo "No value found for \$ACCESS_TOKEN. Run with ACCESS_TOKEN=x ./generate-api-paths.sh \$URL \$CSV"
  exit 1
fi

if [ -z "$1" ]; then
  echo "Provide a URL to call for getting a list of bib ids."
  exit 1
fi

if [ -z "$2" ]; then
  echo "Provide the name of a CSV output file."
  exit 1
fi

if [ -z "$3" ]; then
  echo "Provide a total number of paths you'd like to generate."
  exit 1
fi

BASE_URL="$1"
CSV="$2"
TOTAL="$3"

COUNT=0
LIMIT=100

# start at a random position in the bib catalog
OFFSET=$RANDOM

echo "PATHS" >"$CSV" # first line in the csv file will be ignored by jmeter

while [ $COUNT -lt $TOTAL ]; do
  BIBS=$(curl -s -X 'GET' \
    $BASE_URL'/api/v0.1/bibs?offset='$OFFSET'&limit='$LIMIT'&deleted=false' \
    -H 'accept: application/json' \
    -H 'authorization: Bearer '$ACCESS_TOKEN)

  # go to a random offset in the bib catalog
  OFFSET=$RANDOM

  echo $BIBS | jq -r '.data[] | "/api/v0.1/bibs/\(.nyplSource)/\(.id)"' 2>/dev/null | tee -a "$CSV"

  # Include id and controlNumber searches as possible paths
  echo $BIBS | jq -r '.data[] | "/api/v0.1/bibs?id=\(.id)"' 2>/dev/null | tee -a "$CSV"
  echo $BIBS | jq -r '.data[] | "/api/v0.1/bibs?controlNumber=\(.controlNumber)"' 2>/dev/null | grep -v "=$" | tee -a "$CSV"

  COUNT=$(cat "$CSV" | wc -l)

  echo
  echo "Current count is ["$COUNT"/"$TOTAL"]. Sleeping for 3 seconds..."
  sleep 3
done

TRIMMED_CSV=$(cat "$CSV" | head -$TOTAL)

echo "$TRIMMED_CSV" >"$CSV"
