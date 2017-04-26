#! /bin/bash

###########
# EXPORTS #
###########

#############
# VARIABLES #
#############

FRONTEND_DIR=$(pwd)
E2E_DIR="$FRONTEND_DIR/$(dirname $0)"
BACKEND_DIR="sief-back"
if [ "$CREATE_BACKUP" = "" ]
then
  CREATE_BACKUP=true
fi
if [ !$CREATE_BACKUP_FORCE ]
then
  CREATE_BACKUP_FORCE=false
fi

#############
# FUNCTIONS #
#############

# Check if the backend is running or not.
test_backend() {
  echo 'GET /' | 1>/dev/null 2>&1 nc localhost 5000
}

# Check if the frontend is running or not.
test_frontend() {
  echo 'GET /' | 1>/dev/null 2>&1 nc localhost 9000
}

# Check if the webdriver is running or not.
test_webdriver() {
  echo 'GET /wd/hub' | nc localhost 4444
}

# Run backend
run_backend() {
  # Backend is mandatory for e2e tests, install it submodule then start it
  git submodule update --remote sief-back
  # Go to backend directory
  cd $BACKEND_DIR
  # Init Virtual Env
  if [ ! -d "venv" ]
  then
    # Install virtualenv and dependancies
    echo "Creating VirtualEnv..."
    virtualenv -p /usr/bin/python3 venv
  fi
  . ./venv/bin/activate
  pip install -Ur requirements.txt

  # Rebuild solr
  echo "Building Solr..."
  ./manage.py solr clear -y
  ./manage.py solr build -y

  # /!\ make sure to set FRONT_DOMAIN according to the e2e connexion
  echo "Starting Backend..."
  # export
  export DISABLE_MAIL=true
  export FNE_TESTING_STUB=true
  export FPR_TESTING_STUB=true
  export AGDREF_NUM_TESTING_STUB=true
  export DNA_IDENTIFIANT_FAMILLE_TESTING_STUB=true

  1>$E2E_DIR/backend.log ./manage.py runserver 2>&1 &
  sleep 1

  # Go to E2E directory
  cd $E2E_DIR
}

# Run frontend
run_frontend () {
  echo "Starting frontend..."
  1>frontend.log grunt serve:dist 2>&1 &
  sleep 5
}

# Run webdriver
run_webdriver () {
  webdriver-manager update --standalone
  echo "Starting webdriver..."
  1>webdriver.log webdriver-manager start 2>&1 &
  sleep 1
}

##########
# SCRIPT #
##########

# Go to E2E directory
cd $E2E_DIR

# Untar firefox
# if [ ! -d "firefox" ]
# then
#   echo "Getting firefox 24..."
#   tar xf ../../firefox-24.0.tar.bz2
# fi

# Make sure the backend is not running
test_backend
if [ "$?" -eq 0 ]
then
  echo "Stopping Backend..."
  pkill -f "python3 ./manage.py"
  sleep 1
fi

# Create a dumped databases
if [ -d "db_backup/sief" ] && [ $CREATE_BACKUP_FORCE  ]
then
 echo "Cleaning directory..."
 rm -rf db_backup/sief
fi

if [ ! -d "db_backup/sief" ] && [ $CREATE_BACKUP ]
then
  echo "Saving the DataBase..."
  mongodump --quiet -d sief -o db_backup
fi

# Reset the DataBase
echo "Setting the E2E DataBase..."
mongorestore --quiet -d sief --drop db_dump/sief

# Make sure webdriver is up and running
test_webdriver
if [ "$?" -ne 0 ]
then
    run_webdriver
else
    echo "Webdriver already running"
fi

# Same thing for the frontend
test_frontend
if [ "$?" -ne 0 ]
then
    run_frontend
else
    echo "Frontend already running"
fi

# Run backend
run_backend

# Wait a bit for startup
echo -n "Waiting startup..."

test_webdriver
WAIT_WEBDRIVER=$?

test_frontend
WAIT_FRONTEND=$?

test_backend
WAIT_BACKEND=$?

while [ "$WAIT_WEBDRIVER" -ne 0 -o "$WAIT_FRONTEND" -ne 0 -o "$WAIT_BACKEND" -ne 0 ]
do
    sleep 4
    echo -n "."

    test_webdriver
    WAIT_WEBDRIVER=$?

    test_frontend
    WAIT_FRONTEND=$?

    test_backend
    WAIT_BACKEND=$?
done

sleep 5
