"use strict"

var expect = require('./helper.js').expect;

// LoginPage //
var LoginPage = function() {

  //  LoginPage fields //

  var directive = $('login-directive');
  var loginElements = {
    email: directive.element(by.model('basicLogin.email')),
    password: directive.element(by.model('basicLogin.password')),
    remember_me: directive.element(by.model('basicLogin.remember_me')),
    login: directive.$('.basic-login-proceed')
  };


  // Check Functions //

  // Make sure login page is visible or not
  this.isLogged = function(logged) {
    var assertions = [];

    assertions.push(expect($('login-directive').isDisplayed()).to.eventually.equal(!logged));
    assertions.push(expect($('content-directive').isDisplayed()).to.eventually.equal(logged));

    return assertions;
  };

  // Make sure login fields are visible or not
  this.displayedFields = function(display) {
    var assertions = [];

    for (var elt in loginElements) {
      assertions.push(expect(loginElements[elt].isDisplayed()).to.eventually.equal(display));
    }

    return assertions;
  };

  // Make sure error fields are visible or not
  this.displayedErrors = function(error) {
    var assertions = [];

    //  Errors
    var errors = {
      empty_email: false,
      no_valid_email: false,
      wrong_email: false,
      empty_pwd: false,
      wrong_pwd: false
    };
    errors[error] = true;
    assertions.push(expect(directive.$('[ng-show="basicLoginForm.email.$error.required"].help-block').isDisplayed()).to.eventually.equal(errors['empty_email']));
    if (errors['empty_email']) {
      assertions.push(expect(directive.$('[ng-show="basicLoginForm.email.$error.required"].help-block').getText()).to.eventually.equal('Champ requis'));
    }
    assertions.push(expect(directive.$('[ng-show="basicLoginForm.email.$error.email"].help-block').isDisplayed()).to.eventually.equal(errors['no_valid_email']));
    if (errors['no_valid_email']) {
      assertions.push(expect(directive.$('[ng-show="basicLoginForm.email.$error.email"].help-block').getText()).to.eventually.equal('Entrez un email valide'));
    }
    assertions.push(expect(directive.$('[ng-show="basicLoginFailed"].help-block').isDisplayed()).to.eventually.equal(errors['wrong_email'] || errors['wrong_pwd']));
    if (errors['wrong_email'] || errors['wrong_pwd']) {
      assertions.push(expect(directive.$('[ng-show="basicLoginFailed"].help-block').getText()).to.eventually.equal('Mot de passe invalide'));
    }
    assertions.push(expect(directive.$('[ng-show="basicLoginForm.password.$error.required"].help-block').isDisplayed()).to.eventually.equal(errors['empty_pwd']));
    if (errors['empty_pwd']) {
      assertions.push(expect(directive.$('[ng-show="basicLoginForm.password.$error.required"].help-block').getText()).to.eventually.equal('Champ requis'));
    }

    return assertions;
  };


  // Action Functions //

  this.login = function(email, password, remember_me) {
    loginElements.email.clear()
    loginElements.email.sendKeys(email)
    loginElements.password.sendKeys(password)
    loginElements.remember_me.isSelected().then(function(selected) {
      if (selected !== remember_me) {
        loginElements.remember_me.click();
      }
    });
    return loginElements.login.click();
  };
};

module.exports = new LoginPage();
