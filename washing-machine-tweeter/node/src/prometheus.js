'use strict'

const fetch = require('node-fetch')

const prometheusUrl = process.env.PROMETHEUS_URL || 'http://prometheus:9090'

const config = { timeout: 2000 }
const basicAuth = process.env.BASIC_AUTH
if (basicAuth) { config.headers = { 'Authorization': 'Basic ' + basicAuth } }

exports.id = "prometheus"

const whCounterQuery = 'scalar(max(total_wh{alias="Washing%20Machine"}))'
exports.fetchWhCounter = async time => {
    const url = `${prometheusUrl}/api/v1/query?query=${whCounterQuery}&time=${time.toISOString()}`
    try {
        const response = await fetch(url, config)
        const json = await response.json()
        console.log(json.data)
        if (json.status == 'success' && json.data.resultType == 'scalar') {
            return parseInt(json.data.result[1])
        }
        return null
    } catch (exception) {
        console.log("Couldn't execute WhCounter query against prometheus: " + exception)
        return null
    }
}
