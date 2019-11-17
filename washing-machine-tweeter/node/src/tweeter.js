'use strict'
const twitter = require('twitter')

exports.id = "tweeter"


const twitterClient = new twitter({
    consumer_key: process.env.TWITTER_CONSUMER_KEY,
    consumer_secret: process.env.TWITTER_CONSUMER_SECRET,
    access_token_key: process.env.TWITTER_ACCESS_TOKEN_KEY,
    access_token_secret: process.env.TWITTER_ACCESS_TOKEN_SECRET
});

const twitterEnabled = (process.env.TWITTER_ENABLED || "true") == "true"

exports.tweet = (text, res, next) => {
    if (twitterEnabled && (text != null)) {
        console.log("Tweeting: " + text)
        twitterClient.post('statuses/update', { status: text })
            .then(tweet => {
                console.log("Tweet successfully submitted")
                console.log(tweet)
                res.status(200).send('Sent tweet: ' + text)
            }).catch(next)
    } else {
        console.log("Tweeting disabled - would have tweeted: " + text)
        res.status(200).send('Not sending tweet: ' + text)
    }
}
