'use strict'

const tweeter = require('./tweeter.js')
const analytics = require('./analytics.js')

exports.id = "alertsorter"

exports.sortAlerts = async (req, res, next) => {
    const firingAlerts = req.body.alerts.filter(alert => alert.status == 'firing')
    if (firingAlerts.length == 0) {
        console.log("No alerts firing - aborting here")
        res.status(200).send("No action taken")
        return
    }
    const alert = firingAlerts[0]

    const firedAt = new Date(alert.startsAt)

    if (alert.labels.alertname == "Washing Machine Started") {
        const startTime = analytics.registerStart(firedAt)
        res.status(200).send("OK - not tweeting - registered start time of " + startTime)
    } else if (alert.labels.alertname == "Washing Machine Finished") {
        const washDetails = await analytics.researchWash(firedAt)
        console.log(washDetails)
        const text = detailsToText(washDetails)
        tweeter.tweet(text, res, next)
    } else {
        console.log("Unknown alert name: " + alert.labels.alertname)
        res.status(404).send("Unknown alert name")
    }
}

function detailsToText(washDetails) {
    let items = []
    if (washDetails.endTimePrintable) {
        items.push("Wash cycle finished at " + washDetails.endTimePrintable)
    }
    if (washDetails.durationPrintable) {
        items.push(" • Duration: " + washDetails.durationPrintable)
    }
    if (washDetails.whCounter) {
        if (washDetails.whCounter.printableDifference) {
            items.push(" • Energy Used: " + washDetails.whCounter.printableDifference)
        }
        if (washDetails.whCounter.printableDifference) {
            items.push(" • Approx Cost: " + washDetails.whCounter.printableCost)
        }
    }

    return items.join('\n')
}
