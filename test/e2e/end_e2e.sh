#! /bin/bash

###########
# EXPORTS #
###########


#############
# VARIABLES #
#############

FRONTEND_DIR=$(pwd)
E2E_DIR="$FRONTEND_DIR/$(dirname $0)"
BACKEND_DIR="$FRONTEND_DIR/../sief-back"

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

# Stop backend
stop_backend () {
  echo "Stopping Backend..."
  pkill -f "python3 ./manage.py"
  sleep 1
}

# Stop frontend
stop_frontend () {
  echo "Stopping Frontend..."
  #pkill -f "grunt"
  sleep 1
}

# Stop webdriver
stop_webdriver () {
  echo "Stopping Webdriver..."
  wget http://localhost:4444/selenium-server/driver/?cmd=shutDownSeleniumServer -O /dev/null
  sleep 1
}

# Rebuild solr
rebuild_solr () {
  # Go to backend directory
  cd $BACKEND_DIR
  . ./venv/bin/activate

  # Rebuild solr
  echo "Building Solr..."
  ./manage.py solr clear -y
  ./manage.py solr build -y
}


##########
# SCRIPT #
##########

# Make sure webdriver is not running
test_webdriver
if [ "$?" -eq 0 ]
then
  stop_webdriver
fi

# Same thing for the frontend
test_frontend
if [ "$?" -eq 0 ]
then
  stop_frontend
fi

# Same thing for the backend
test_backend
if [ "$?" -eq 0 ]
then
  stop_backend
fi

# Reset the DataBase
# Go to E2E directory
cd $E2E_DIR

if [ -d "db_backup/sief" ]
then
  echo "Restore the DataBase..."
  mongorestore --quiet -d sief --drop db_backup/sief

  echo "Cleaning directory..."
  rm -rf db_backup/
fi

rebuild_solr

sleep 5
