#!/bin/bash
# Runs the integration tests locally.
set -e

# The 'WEB_API_KEY' environment variable must be set to the project's web API key.
# This value may be read from the settings page for the project:
# https://console.firebase.google.com/project/_/settings/general.
if [[ -z "$WEB_API_KEY" ]]; then
    echo "WEB_API_KEY environment variable not set, exiting." && exit 1
fi

# Check ports.
for PORT in 5001 8080 8081
do
    PORT_IN_USE=$(nc -z 127.0.0.1 $PORT && echo "IN USE" || echo "FREE")
    if [[ "$PORT_IN_USE" == "IN USE" ]]; then
        echo "Could not start script: port $PORT unavailable."
        echo "Before you run this script, ensure that ports 5001, 8080, and 8081 are free."
        exit 1
    fi
done

./reset_local_postgis_db.sh

echo "Starting private API POST_pickups emulator..."
pushd ../ 1>&0 && export RUBBISH_BASE_DIR=$(echo $PWD) && popd 1>&0
export RUBBISH_POSTGIS_CONNSTR="postgresql://rubbish-test-user:polkstreet@localhost:5432/rubbish"
functions-framework --source $RUBBISH_BASE_DIR/python/functions/main.py \
    --port 8081 --target POST_pickups --debug &

echo "Starting private API GET emulator..."
functions-framework --source $RUBBISH_BASE_DIR/python/functions/main.py \
    --port 8082 --target GET --debug &

echo "Sleeping for five seconds to give the emulators time to start up..."
sleep 5

echo "Running private API integration test..."
export GOOGLE_APPLICATION_CREDENTIALS=$RUBBISH_BASE_DIR/js/serviceAccountKey.json
PRIVATE_API_HOST="http://localhost:8081" \
    pytest $RUBBISH_BASE_DIR/python/functions/tests/tests.py -k POST_pickups

PRIVATE_API_HOST="http://localhost:8082" \
    pytest $RUBBISH_BASE_DIR/python/functions/tests/tests.py -k GET

echo "Starting authentication API emulator and running authentication proxy integration test..."
npm run-script --prefix $RUBBISH_BASE_DIR/js/ test:local

echo "Shutting down emulators..."
kill -s SIGSTOP %1 %2
