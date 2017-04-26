var Q = require('q');
var chai = require('chai');
var chaiAsPromised = require('chai-as-promised');
chai.should();
chai.use(chaiAsPromised);

var expect = chai.expect;
var expectedConditions = protractor.ExpectedConditions;

function scroolClick(elt) {
  browser.executeScript('arguments[0].scrollIntoView(false)', elt);
  return elt.click();
};

function waitUntilReady(elm) {
  browser.wait(function() {
    return elm.isPresent();
  }, 10000);
  return browser.wait(function() {
    return elm.isDisplayed();
  }, 10000);
};

function getLength(list) {
  return Object.keys(list).length;
};

module.exports = {
  Q: Q,
  expect: expect,
  EC: expectedConditions,
  scroolClick: scroolClick,
  waitUntilReady: waitUntilReady,
  getLength: getLength
};
