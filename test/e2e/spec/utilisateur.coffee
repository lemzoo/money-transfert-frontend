"use strict"


helper = require('../helper')


userFieldsEnabled = [
  'utilisateur.telephone'
]
userFieldsDisabled = [
  'utilisateur.role',
  #'utilisateur.prenom',
  #'utilisateur.nom',
  'utilisateur.email',
  'utilisateur.site_affecte.id'
]

test_goto_user_profile = (role) ->
  helper.login(role)
  userStatus = $('.user-status')
  userStatus.click().then ->
    expect($('.button-profile').isDisplayed()).toBe(true)
    $('.button-profile').click().then ->
      for field in userFieldsEnabled
        expect(element(`by`.model(field)).isEnabled()).toBe(true)
      for field in userFieldsDisabled
        expect(element(`by`.model(field)).isEnabled()).toBe(false)
      expect($('.save-user').isEnabled()).toBe(false)

test_change_profile = (role) ->
  helper.login(role)
  browser.setLocation('profil')
  browser.waitForAngular()
#  expect(browser.getCurrentUrl()).toEqual(helper.baseUrl+'/profil')
  saveButton = $('.save-user')
  telephone = element(`by`.model('utilisateur.telephone'))
  telephone.clear().sendKeys('0123456789')
  expect(saveButton.isEnabled()).toBe(true)
  saveButton.click().then ->
    cancelBtn = $('.button-cancel')
    expect(confirmBtn.isEnabled()).toBe(true)
    expect(cancelBtn.isEnabled()).toBe(true)
    confirmBtn.click().then ->
      expect(browser.getCurrentUrl()).toEqual(helper.baseUrl+'/profil')
      saveButton = $('.save-user')
      telephone = element(`by`.model('utilisateur.telephone'))
      expect(telephone.getAttribute('value')).toBe('0123456789')
      expect(saveButton.isEnabled()).toBe(false)


describe 'Utilisateur ::', ->

  it 'Test goto user profile admin', ->
    test_goto_user_profile('admin')

  it 'Test goto user profile premier_accueil', ->
    test_goto_user_profile('premier_accueil')

  it 'Test goto user profile gu_enregistrement', ->
    test_goto_user_profile('gu_enregistrement')

  it 'Test goto user profile gu_orientation', ->
    test_goto_user_profile('gu_orientation')

  """
  it 'Test change profile admin', ->
    test_change_profile('admin')

  it 'Test change profile premier_accueil', ->
    test_change_profile('premier_accueil')

  it 'Test change profile gu_enregistrement', ->
    test_change_profile('gu_enregistrement')

  it 'Test change profile gu_orientation', ->
    test_change_profile('gu_orientation')

  it 'Test change profile remove telephone', ->
    helper.login('admin')
    browser.waitForAngular()
    browser.setLocation('profil')
    saveButton = $('.save-user')
    telephone = element(`by`.model('utilisateur.telephone'))
    telephone.clear()
    saveButton.click().then ->
      confirmBtn = $('.button-confirm')
      confirmBtn.click().then ->
        telephone = element(`by`.model('utilisateur.telephone'))
        expect(telephone.getAttribute('value')).toBe('')
  """

describe 'Utilisateurs access ::', ->

  it 'Test for Administrateur', ->
    helper.login('admin')
    browser.setLocation('utilisateurs').then ->
      expect(browser.getCurrentUrl()).toBe(helper.baseUrl+'/utilisateurs')
#    browser.setLocation('utilisateurs/'+''#{helper.validateurId}").then ->
#      expect(browser.getCurrentUrl()).toBe("#{helper.baseUrl}/utilisateurs/#{helper.validateurId}")

#   it 'Test for Validateur', ->
#     helper.login('Validateur')
#     browser.setLocation('utilisateurs').then ->
#       expect(browser.getCurrentUrl()).toBe("#{helper.baseUrl}/utilisateurs")
#     browser.setLocation("utilisateurs/#{helper.validateurId}").then ->
#       expect(browser.getCurrentUrl()).toBe("#{helper.baseUrl}/utilisateurs/#{helper.validateurId}")

#   it 'Test Validateur read only', ->
#     helper.login('Validateur')
#     browser.setLocation("utilisateurs/#{helper.observateurId}").then ->
#       for field in userFields
#         expect(element(`by`.model(field)).isEnabled()).toBe(false)

#   it 'Test for Administrateur', ->
#     helper.login('Administrateur')
#     browser.setLocation('utilisateurs').then ->
#       expect(browser.getCurrentUrl()).toBe("#{helper.baseUrl}/utilisateurs")

#   it 'Test Administrateur all powerfull', ->
#     input = "I'm the mighty admin."
#     helper.login('Administrateur')
#     browser.setLocation("utilisateurs/#{helper.observateurId}").then ->
#       for field in userFields
#         expect(element(`by`.model(field)).isEnabled()).toBe(true)
#       element(`by`.model('utilisateur.commentaire')).clear().sendKeys(input)
#       $('.save-user').click().then ->
#         # Reload page to make sure submit has worked
#         browser.get("#{helper.baseUrl}/utilisateurs/#{helper.observateurId}").then ->
#           element(`by`.model('utilisateur.commentaire')).getAttribute('value').then (comment) ->
#             expect(comment).toBe(input)


# describe 'Test list utilisateurs', ->

#   beforeEach ->
#     helper.login('Administrateur')
#     browser.setLocation('utilisateurs')

#   afterEach ->
#     browser.executeScript("window.localStorage.clear()")

#   it 'Test list count', ->
#     expect($$('.list-group-item').count()).toEqual(5)

#   it 'Test filter', ->
#     $(".search-field").sendKeys('observateur')
#     expect($$('.list-group-item').count()).toEqual(1)

#   it 'Test result per page', ->
#     $(".max-results-field")
#       .sendKeys(protractor.Key.chord(protractor.Key.CONTROL, "a"))
#       .sendKeys('2')
#     expect($$('.list-group-item').count()).toEqual(2)
