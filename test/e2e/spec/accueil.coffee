"use strict"


helper = require('../helper')


describe 'Accueil ::', ->

  it 'name in navbar', ->
    helper.login('admin')
    userStatus = $('.user-status')
    userStatus.element(`by`.binding("user.prenom")).getText().then (name) ->
      expect(name).toBe('Ad Min')
    helper.login('premier_accueil')
    userStatus = $('.user-status')
    userStatus.element(`by`.binding("user.prenom")).getText().then (name) ->
      expect(name).toBe('Premier Accueil')
