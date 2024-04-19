/***
 *
 *  Build a CSV with Sierra API paths (for use in Jmeter stress testing)
 *
 *  Usage:
 *    node generate-api-paths [--envfile .env-qa] [--count 100] [--outfile ./sierra-api-paths.csv]
 *
 */

const fs = require('fs')
const sierraWrapper = require('@nypl/sierra-wrapper')

const argv = require('minimist')(process.argv.slice(2), {
  default: {
    envfile: '.env-qa',
    outfile: 'sierra-api-paths.csv',
    count: 100
  }
})

/**
 * Establish desired makeup of CSV:
 *  - 30% bibs (of which 60% are updatedDate queries, 10% are deletedDate queries, etc)
 *  - 30% items
 *  - etc
 */
const OVERALL_MAKEUP = {
  bibs: 0.3,
  items: 0.3,
  holdings: 0.1,
  holds: 0.1,
  patrons: 0.2
}
const QUERY_TYPES = {
  updatedDateQueries: 0.6,
  deletedDateQueries: 0.1,
  identityQueries: 0.3
}

// Peg this to the range of highest activity for the Sierra instance:
const dateRange = ['2021-01-01T00:00:00-04:00', '2021-12-31T23:59:59-04:00']

/**
 *  Initialize an authenticated Sierra client (will use -holdings creds file if which === 'holdings')
 */
const sierraClient = async (which) => {
  let envfile = argv.envfile
  if (which === 'holdings') {
    envfile = envfile + '-holdings'
  }
  require('dotenv').config({ path: envfile, override: true })

  sierraWrapper.config({
    key: process.env.SIERRA_KEY,
    secret: process.env.SIERRA_SECRET,
    base: process.env.SIERRA_BASE
  })

  await sierraWrapper._reauthenticate()

  return sierraWrapper
}

let allPaths = []

const randomDateRange = () => {
  const msBounds = dateRange.map(Date.parse)
  const msBoundsDifference = msBounds[1] - msBounds[0]
  const msRange = [
    Math.round(Math.random() * msBoundsDifference + msBounds[0]),
    Math.round(Math.random() * msBoundsDifference + msBounds[0])
  ]
    .sort((d1, d2) => d1 < d2 ? -1 : 1)
  return msRange.map((ms) => new Date(ms).toISOString())
}

const randomOffset = (min, max) => {
  return Math.round(Math.random() * (max - min)) + min
}

const randomSort = (arr) => {
  return arr 
    .map(value => ({ value, sort: Math.random() }))
    .sort((a, b) => a.sort - b.sort)
    .map(({ value }) => value)
}

const randomSelection = (arr, count) => {
  const shuffled = randomSort(arr)
  return shuffled.slice(0, count)
}

const buildBibItemHoldingsPaths = async (recordType, queryType, count, fields) => {
  let paths = []
  while(paths.length < count) {
    const range = randomDateRange()
    if (queryType === 'updatedDateQueries') {
      const offset = randomOffset(0, 30)
      const updatedDate = '[' + range.join(',') + ']'
      const path = `/iii/sierra-api/v6/${recordType}?fields=${encodeURIComponent(fields)}&offset=${offset}&updatedDate=${encodeURIComponent(updatedDate)}&limit=200`

      paths.push(path)
    } else if (queryType === 'deletedDateQueries') {
      const offset = randomOffset(0, 4)
      const deletedDate = '[' + range.map((d) => d.replace(/T.*$/, '')) + ']'
      const path = `/iii/sierra-api/v6/${recordType}?fields=${encodeURIComponent(fields)}&offset=${offset}&deletedDate=${encodeURIComponent(deletedDate)}&limit=200`
      paths.push(path)
    } else if (queryType === 'identityQueries') {
      const updatedDate = '[' + range.join(',') + ']'
      const queryPath = `${recordType}?offset=0&updatedDate=${encodeURIComponent(updatedDate)}&limit=200`
      const client = await sierraClient(recordType)
      const resp = await client.get(queryPath)
      const randomIds = randomSelection(resp.entries.map((entry) => entry.id), 10)

      paths = paths.concat(randomIds.map((id) => {
        return `/iii/sierra-api/v6/${recordType}?id=${id}&fields=${encodeURIComponent(fields)}`
      }))
    }
  }
  console.log(`  Built ${paths.length} paths for ${recordType}, ${queryType}`)

  return paths
}

const buildItemsPaths = async () => {
  const recordType = 'items'
  console.log(`Building ${recordType} paths`)

  await Promise.all(
    Object.keys(QUERY_TYPES).map(async (queryType) => {
      const count = Math.ceil(argv.count * OVERALL_MAKEUP[recordType] * QUERY_TYPES[queryType])
      console.log(`  Generating ${count} ${recordType} ${queryType} paths`)

      const fields = 'default,fixedFields,varFields'

      const paths = await buildBibItemHoldingsPaths(recordType, queryType, count, fields)
      
      allPaths = allPaths.concat(paths)
    })
  )
  console.log(`  Done building ${recordType}`)
}

const buildBibsPaths = async () => {
  const recordType = 'bibs'
  console.log(`Building ${recordType} paths`)

  await Promise.all(
    Object.keys(QUERY_TYPES).map(async (queryType) => {
      const count = Math.ceil(argv.count * OVERALL_MAKEUP[recordType] * QUERY_TYPES[queryType])
      console.log(`  Generating ${count} ${recordType} ${queryType} paths`)

      const fields = 'default,fixedFields,varFields,normTitle,normAuthor,orders,locations'

      const paths = await buildBibItemHoldingsPaths(recordType, queryType, count, fields)
      
      allPaths = allPaths.concat(paths)
    })
  )
  console.log(`  Done building ${recordType}`)
}

const buildHoldingsPaths = async () => {
  const recordType = 'holdings'
  console.log(`Building ${recordType} paths`)

  await Promise.all(
    Object.keys(QUERY_TYPES).map(async (queryType) => {
      const count = Math.ceil(argv.count * OVERALL_MAKEUP[recordType] * QUERY_TYPES[queryType])
      console.log(`  Generating ${count} ${recordType} ${queryType} paths`)

      const fields = 'id,bibIds,bibIdLinks,itemIds,itemIdLinks,inheritLocation,allocationRule,accountingUnit,labelCode,serialCode1,serialCode2,serialCode3,serialCode4,claimOnDate,receivingLocationCode,vendorCode,updateCount,pieceCount,eCheckInCode,mediaTypeCode,updatedDate,createdDate,deletedDate,deleted,suppressed,fixedFields,varFields'

      const paths = await buildBibItemHoldingsPaths(recordType, queryType, count, fields)
      
      allPaths = allPaths.concat(paths)
    })
  )
  console.log(`  Done building ${recordType}`)
}

const buildPatronsPaths = async () => {
  const recordType = 'patrons'
  const count = Math.ceil(argv.count * OVERALL_MAKEUP[recordType])
  console.log(`Building ${count} ${recordType} paths`)

  const fields = 'id,names,barcodes,expirationDate,emails,patronType,homeLibraryCode,phones,moneyOwed,fixedFields'
  let paths = []
  while(paths.length < count) {
    const range = randomDateRange()
    const offset = 0
    const updatedDate = '[' + range.join(',') + ']'
    const path = `patrons?offset=${offset}&updatedDate=${encodeURIComponent(updatedDate)}&limit=200&deleted=false`
    console.log('Patron path: ', path)

    const client = await sierraClient()
    const resp = await client.get(path)
    const randomIds = randomSelection(resp.entries.map((entry) => entry.id), 10)

    paths = paths.concat(randomIds.map((id) => {
      return `/iii/sierra-api/v6/${recordType}?id=${id}&fields=${encodeURIComponent(fields)}`
    }))
  }

  allPaths = allPaths.concat(paths)
  console.log(`  Done building ${recordType}`)
}

const buildHoldsPaths = async () => {
  const recordType = 'holds'
  const count = Math.ceil(argv.count * OVERALL_MAKEUP[recordType])
  console.log(`Building ${count} ${recordType} paths`)

  let paths = []
  while(paths.length < count) {
    const range = randomDateRange()
    const offset = 0 // randomOffset(0, 30)
    const updatedDate = '[' + range.join(',') + ']'
    const path = `patrons?offset=${offset}&updatedDate=${encodeURIComponent(updatedDate)}&limit=200&deleted=false`

    const client = await sierraClient()
    const resp = await client.get(path)
    const randomPatronIds = randomSelection(resp.entries.map((entry) => entry.id), 10)

    paths = paths.concat(randomPatronIds.map((patronId) => {
      return `/iii/sierra-api/v6/patrons/${patronId}/holds?expand=record`
    }))
  }

  allPaths = allPaths.concat(paths)
  console.log(`  Done building ${recordType}`)
}

const run = async () => {
  await buildBibsPaths()
  await buildItemsPaths()
  await buildHoldingsPaths()
  await buildPatronsPaths()
  await buildHoldsPaths()
  
  console.log(`Finished building ${allPaths.length} paths`)

  // Shuffle:
  allPaths = randomSort(allPaths)
  // We rounded up a lot, so trim extras:
  allPaths = allPaths.slice(0, argv.count)

  fs.writeFileSync(argv.outfile, randomSort(allPaths).join('\n'))

  console.log(`Done. Wrote ${allPaths.length} paths to ${argv.outfile}`)
}

run()
