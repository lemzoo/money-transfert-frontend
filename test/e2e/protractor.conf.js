// Protractor configuration

exports.config = {
  seleniumAddress: 'http://localhost:4444/wd/hub',
  getPageTimeout: 60000,
  allScriptsTimeout: 60000,
  framework: 'custom',
  // path relative to the current config file
  frameworkPath: require.resolve('protractor-cucumber-framework'),
  multiCapabilities: [
    {
      'browserName': 'firefox',
      'version': '24'
    },
    {
      'browserName': 'chrome'
    }
  ],
  specs: [
    'features/**/*.feature',
  ],
  baseUrl: 'http://localhost:9000/',
  cucumberOpts: {
    require: 'features/**/*.js',
    tags: false,
    format: 'pretty',
    profile: false,
    'no-source': true
  }
}
