var Q         = require('../support/helper.js').Q;
var LoginPage = require('../support/login_page.js');

module.exports = function () {

  this.Given(/^un utilisateur$/, function (callback) {
    var assertions = [].concat(
      LoginPage.isLogged(false),
      LoginPage.displayedFields(true)
    );
    Q.all(assertions).should.notify(callback);
  });

  this.When(/^je m'identifie avec l'identifiant "([^"]*)" et le mot de passe "([^"]*)"$/, function (email, password, callback) {
    LoginPage.login(email, password).then(callback);
  });

  this.Then(/^j'accède à la page d'accueil$/, function (callback) {
    var assertions = [].concat(
      LoginPage.isLogged(true),
      LoginPage.displayedFields(false)
    );
    Q.all(assertions).should.notify(callback);
  });

  this.Then(/^je suis informé de l'échec de mon identification \("([^"]*)"\)$/, function (error, callback) {
    var assertions = [].concat(
      LoginPage.isLogged(false),
      LoginPage.displayedFields(true),
      LoginPage.displayedErrors(error)
    );
    Q.all(assertions).should.notify(callback);
  });

};
