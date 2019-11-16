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

app.post('/washing-update', (req, res, next) => {
    console.log(req.body)
    
    client.post('statuses/update', {status: 'Wash cycle finished at ' + (new Date()).toLocaleTimeString()})
    .then(function (tweet) {
        console.log(tweet);
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
