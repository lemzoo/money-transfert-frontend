"use strict"


helper = require('../helper')


logged_check_display = (logged) ->
  expect($("login-directive").isDisplayed()).toBe(!logged)
  expect($("content-directive").isDisplayed()).toBe(logged)


do_login = (remember_me) ->
  element(`by`.model('basicLogin.email')).sendKeys(helper.admin.email)
  element(`by`.model('basicLogin.password')).sendKeys(helper.admin.password)
  if remember_me
    element(`by`.model('basicLogin.remember_me')).click()
  return $(".basic-login-proceed").click()


describe 'Login ::', ->

  beforeEach ->
    browser.get(helper.baseUrl)
    browser.waitForAngular()
  afterEach -> browser.executeScript("localStorage.clear()")
  afterEach -> browser.executeScript("sessionStorage.clear()")

  it 'title', ->
    expect(browser.getTitle()).toEqual('SIEF - Système d\'Information des Etrangers en France')

  it 'simple admin login', (done) ->
    # Make sure login page is visible
    logged_check_display(false)
    # Test the login fields
    element(`by`.model('basicLogin.email')).isDisplayed().then (displayed) ->
      expect(displayed).toBeTruthy()
      element(`by`.model('basicLogin.password')).isDisplayed().then (displayed) ->
        expect(displayed).toBeTruthy()
        element(`by`.model('basicLogin.remember_me')).isDisplayed().then (displayed) ->
          expect(displayed).toBeTruthy()
          $(".basic-login-proceed").isDisplayed().then (displayed) ->
            expect(displayed).toBeTruthy()
            # Actually do the login
            do_login(false).then ->
              # Make sure we are connected
              logged_check_display(true)
              done()

  it 'simple no admin login', (done) ->
    helper.login('premier_accueil')
    # Make sure we are connected
    logged_check_display(true)
    done()

  it 'remember me', (done) ->
    # Register for the login WITH remember-me enabled
    do_login(true).then ->
      # Make sure we are connected
      logged_check_display(true)
      # Remove the session token
      browser.executeScript('sessionStorage.removeItem("token")').then ->
        # Reload the page, the remember should ask for a new token
        browser.refresh().then ->
          # Make sure we are connected
          logged_check_display(true)
          done()

  it 'logout', (done) ->
    # Register for the login WITH remember-me enabled
    do_login(true).then ->
      # Make sure we are connected
      logged_check_display(true)
      # Now do the logout by hand
      statusButton = $('.user-status')
      statusButton.isDisplayed().then (displayed) ->
        expect(displayed).toBeTruthy()
        statusButton.click().then ->
          logoutButton = $('.button-logout')
          logoutButton.isDisplayed().then (displayed) ->
            expect(displayed).toBeTruthy()
            logoutButton.click().then ->
              # Make sure we are on the login page
              logged_check_display(false)
              # Given the remember-me token has been removed too, reloading the page
              # should let us on the login page
              browser.refresh().then ->
                logged_check_display(false)
                done()

  it 'invalid token', (done) ->
    do_login(false)
    browser.executeScript('sessionStorage.setItem("token", "bad_token")')
    browser.refresh()
    browser.waitForAngular()
    logged_check_display(false)
    done()

  it 'invalid remember-me token', (done) ->
    browser.executeScript('localStorage.setItem("remember_me_token", "bad_token")').then ->
      browser.refresh().then ->
        logged_check_display(false)
        done()
