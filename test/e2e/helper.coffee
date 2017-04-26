"use strict"

fs = require('fs')

exports.admin = {
  email: "admin@test.com"
  password: "password"
  token: ""
}
exports.premier_accueil = {
  email: "premier.accueil@test.com"
  password: "password"
  token: ""
}
exports.gu_enregistrement = {
  email: "gu.enregistrement@test.com"
  password: "password"
  token: ""
}
exports.gu_orientation = {
  email: "gu.orientation@test.com"
  password: "password"
  token: ""
}
exports.baseUrl = 'http://localhost:9000/#'

exports.login = (userRole) ->
  browser.executeScript("localStorage.clear()")
  browser.executeScript("sessionStorage.clear()")
  browser.get(exports.baseUrl)
  email = exports[userRole].email
  password = exports[userRole].password
  pageReady = false
  element(`by`.model('basicLogin.email')).sendKeys(email)
  element(`by`.model('basicLogin.password')).sendKeys(password)
  $(".basic-login-proceed").click().then ->
    pageReady = true
  browser.wait -> pageReady

exports.takeScreenshot = (filename = 'exception') ->
  browser.takeScreenshot().then((png) ->
    writeScreenShot(png, filename+'.png')
  )

writeScreenShot= (data, filename) ->
  stream = fs.createWriteStream(filename)

  stream.write(new Buffer(data, 'base64'))
  stream.end()
