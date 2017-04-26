[ ![Codeship Status for Scille/sief-front](https://codeship.com/projects/be190be0-d8a1-0132-6785-56577b4e3777/status?branch=master)](https://codeship.com/projects/78895)

SI AEF-front
==========

Partie front-end du projet SI-AEF (portail agent) de la DGEF.


1 - Prerequisites
-----------------

- nodejs 4.x
- npm
- bower

On debian, install curl:

```
sudo apt-get install curl
```

To install node.js and npm: [https://nodejs.org/en/download/package-manager/](https://nodejs.org/en/download/package-manager/)

To install grunt and bower:
```
sudo npm install -g grunt-cli@1.2.0 bower
```

2 - Install
-----------

From inside the project root directory:

```
npm install
bower install
```


3 - Configure
-------------

Go to `app/setting.coffee` to configure connection with the backend (mainly `API_DOMAIN` and `FRONT_DOMAIN`).


4 - Debug&Test
-----------------

Debug server with hot reload:

```
grunt serve
```

Unit tests:

```
grunt test
```

End-to-end tests

First install prerequisites and bootstrap (will start a backend if needed and load a test database):

```
sudo npm install -g protractor@4.0.14 cucumber
sudo webdriver-manager update
```

CREATE_BACKUP default true
CREATE_BACKUP_FORCE default false

Then:

```
npm run grunt:protractor
```

Or manually:
```
terminal 1: grunt serve
terminal 2: ./manage.py runserver -dr
terminal 3: webdriver-manager start
terminal 4: npm run protractor
```

5 - Release
-----------

Build release version:

```
grunt build
```

Release is available in `dist/` folder.

Serve release version:

```
grunt serve:dist
```
