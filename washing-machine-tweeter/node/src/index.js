'use strict'

const express = require('express')
const alertSorter = require('./alertsorter.js')

const port = process.env.SERVER_PORT || 8080
let ready = false

console.log('Washing Machine -> Prometheus -> Alertmanager -> Twitter.  Starting...')

const application = express()


// All requests are of type text/plain - we don't send anything fancy back.
application.use((req, res, next) => {
    res.contentType('text/plain')
    next()
})

application.get('/liveness', (req, res) => {
    res.status(200).send('OK')
})
application.get('/readiness', (req, res) => {
    if (!ready) {
        console.log('Responding 503 to readiness probe')
        res.status(503).send('Service Unavailable')
    } else {
        res.status(200).send('OK')
    }
})

// Specifically below the probe endpoints - don't want to log those.
application.use((req, res, next) => {
    req.requestDate = new Date()
    const userAgent = req.headers['user-agent'] || 'Unknown'
    console.log(`[${req.requestDate.toISOString()}] Remote IP: ${req.ip}; Url: ${req.url}; Method: ${req.method}; User Agent: ${userAgent}`)
    next()
})

// Only bother deserialising the body if it gets this far.
application.use(express.json())

application.post('/washing-update', alertSorter.sortAlerts)

application.use((req, res) => { res.status(404).send('Not Found') })

application.listen(port, () => {
    console.log(`Listening on port ${port}`)
    ready = true
})
