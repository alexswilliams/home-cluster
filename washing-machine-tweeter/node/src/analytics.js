'use strict'

const prometheus = require('./prometheus.js')

let costPerkWh = parseFloat(process.env.COST_PER_KWH || "0.1289")

let lastStartTime = null

function toPrintableTime(time) {
    return time.toLocaleTimeString('en-GB', {
        'hour12': false,
        'timeZone': 'Europe/London',
        'hour': '2-digit',
        'minute': '2-digit'
    })
}

function toPrintableDuration(millisecondsTotal) {
    const secondsTotal = Math.floor(millisecondsTotal / 1000)
    const minutesTotal = Math.floor(secondsTotal / 60)
    const minutesPastTheHour = minutesTotal % 60
    const hours = Math.floor(minutesTotal / 60)

    if (hours >= 1) { return '' + hours + 'h ' + minutesPastTheHour + 'm' }
    else { return '' + minutesPastTheHour + 'm' }
}

function toPrintableCost(penceTotal) {
    const pounds = penceTotal / 100
    return '£' + parseFloat(Math.round(pounds * 100) / 100).toFixed(2)
}

function toPrintablePower(whTotal) {
    const kWh = whTotal / 1000
    if (kWh >= 1) {
        return parseFloat(Math.round(kWh * 1000) / 1000).toFixed(3) + ' kWh'
    } else {
        return whTotal + ' Wh'
    }
}

exports.id = "analytics"

exports.registerStart = function (newStartTime) {
    lastStartTime = newStartTime
    console.log("[DEBUG] Registering new start time: " + lastStartTime.toISOString())
    return toPrintableTime(lastStartTime)
}

exports.researchWash = async endTime => {
    const retObj = { endTime: endTime, endTimePrintable: toPrintableTime(endTime) }
    if (lastStartTime != null) {
        console.log("[DEBUG] Processing wash between " + lastStartTime.toISOString() + " and " + endTime.toISOString())

        retObj.startTime = lastStartTime
        retObj.startTimePrintable = toPrintableTime(lastStartTime)
        // Reset so that if we miss the next start of a wash, we don't mistake future washes for it
        lastStartTime = null

        retObj.durationSeconds = endTime.getTime() - retObj.startTime.getTime()
        if (retObj.durationSeconds <= 0) return retObj
        retObj.durationPrintable = toPrintableDuration(retObj.durationSeconds)

        const whCounterAtStart = await prometheus.fetchWhCounter(retObj.startTime)
        const whCounterAtEnd = await prometheus.fetchWhCounter(endTime)
        if (whCounterAtStart && whCounterAtEnd && (whCounterAtEnd > whCounterAtStart)) {
            retObj.whCounter = {
                start: whCounterAtStart,
                end: whCounterAtEnd,
                difference: whCounterAtEnd - whCounterAtStart,
                printableDifference: toPrintablePower(whCounterAtEnd - whCounterAtStart),
                approxCostPence: ((whCounterAtEnd - whCounterAtStart) * costPerkWh * 100) / 1000,
                printableCost: toPrintableCost(((whCounterAtEnd - whCounterAtStart) * costPerkWh * 100) / 1000)
            }
        } else {
            return retObj
        }

    }
    return retObj
}
