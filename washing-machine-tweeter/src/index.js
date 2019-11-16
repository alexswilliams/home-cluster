const express = require('express')
const twitter = require('twitter')
const app = express()
const port = process.env.SERVER_PORT || 80


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
    res.status(200).send('OK')
})


/*



[Sat Nov 16 2019 21:25:03 GMT+0000 (Coordinated Universal Time)] Remote IP: ::ffff:10.32.0.5; Url: /washing-update; Method: POST; User Agent: Alertmanager/0.19.0
{ receiver: 'washing-tweeter',
  status: 'firing',
  alerts:
   [ { status: 'firing',
       labels: [Object],
       annotations: {},
       startsAt: '2019-11-16T21:24:59.85362058Z',
       endsAt: '0001-01-01T00:00:00Z',
       generatorURL:
        '/prometheus/graph?g0.expr=clamp_min%28clamp_max%28max_over_time%28power_mw%7Balias%3D%22Washing+Machine%22%7D%5B30s%5D%29+%3E+2250+and+max_over_time%28power_mw%7Balias%3D%22Washing+Machine%22%7D%5B30s%5D+offset+30s%29+%3C%3D+2250%2C+1%29%2C+1%29&g0.tab=1',
       fingerprint: '61f151ac898456e3' } ],
  groupLabels: {},
  commonLabels:
   { alertname: 'Washing Machine Started',
     alias: 'Washing Machine',
     exported_job: 'tplink-scraper-washing-machine',
     id: '80060C33CFF513FA251AFF1AAAD9D3281B0B8D9F',
     instance: '10.254.1.20:20002',
     job: '88bl-pi-push-gateway',
     mac: 'D8:0D:17:6C:7D:35',
     rube_goldberg_pipeline_stage: 'washing-started' },
  commonAnnotations: {},
  externalURL: 'http://alertmanager-56c55b89d5-ttlvb:9093',
  version: '4',
  groupKey:
   '{}/{rube_goldberg_pipeline_stage=~"^(?:washing-started|washing-finished)$"}:{}' }
[object Object]
*/

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

app.listen(port, () => console.log(`Started listening on port ${port}`))
