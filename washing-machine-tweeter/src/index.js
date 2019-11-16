const express = require('express')
const twitter = require('twitter')
const app = express()
const port = process.env.SERVER_PORT || 80

let ready = false

var client = new twitter({
  consumer_key: process.env.TWITTER_CONSUMER_KEY,
  consumer_secret: process.env.TWITTER_CONSUMER_SECRET,
  access_token_key: process.env.TWITTER_ACCESS_TOKEN_KEY,
  access_token_secret: process.env.TWITTER_ACCESS_TOKEN_SECRET
});


app.use((req, res, next) => {
    req.requestDate = new Date()
    const userAgent = req.headers['user-agent'] || 'Unknown'
    const url = req.url
    const ip = req.ip
    const method = req.method
    console.log(`[${req.requestDate}] Remote IP: ${ip}; Url: ${url}; Method: ${method}; User Agent: ${userAgent}`)
    next()
})

app.use(express.json())
app.use(express.urlencoded({ extended:true }))

app.get('/liveness', (req, res) => {
    res.status(200).send('OK')
})
app.get('/readiness', (req, res) => {
    if (!ready) {
        res.status(503).send('Service Unavailable')
    } else {
        res.status(200).send('OK')
    }
})


app.post('/washing-update', (req, res, next) => {
    console.log(req.body)

    const body = req.body
    const firingAlerts = body.alerts.filter(alert => alert.status == 'firing')

    if (firingAlerts.length == 0) {
        console.log("No alerts firing - aborting here")
        res.status(200).send("OK - no action taken")
        return
    }

    const alert = firingAlerts[0]
    let text = ''
    if (alert.labels.alertname == "Washing Machine Started") {
        text = 'Wash cycle started at ' + (new Date()).toLocaleTimeString()
    } else {
        text = 'Wash cycle finished at ' + (new Date()).toLocaleTimeString()
    }
    console.log("Tweeting: " + text)
    
    client.post('statuses/update', {status: text})
    .then(function (tweet) {
        console.log("Tweet successfully submitted")
        console.log(tweet)
    }).catch(next)
    
    res.status(200).send('Understood')
})

app.post('/test-tweet', (req, res, next) => {
    client.post('statuses/update', {status: 'Testing - ' + (new Date())})
    .then(function (tweet) {
        console.log(tweet)
        res.status(200).json(tweet)
    }).catch(next)
})

app.use((req, res) => { res.status(404).send('Not Found') })

app.listen(port, () => {
    console.log(`Started listening on port ${port}`)
    ready = true
})
