#!/bin/bash
# Run this script to deploy or redeploy the authentication proxy.
set -e

# Check that jq is installed; we use this tool to outputs.
jq --help >/dev/null || (echo "jq is not installed, 'brew install jq' to get it." && exit 1)

echo "Checking private API environment configuration...🏠"
GCP_PROJECT=$(gcloud config get-value project)
pushd ../js && PRIVATE_API_ENV_CONFIG=$(firebase functions:config:get | jq '.private_api') && popd
if [[ -z "$PRIVATE_API_ENV_CONFIG" ]]; then
    echo "Private API configuration secrets not set, creating now..."
    REGION=us-central1  # currently a hardcoded value
    POST_PICKUPS_URL=https://$REGION-$GCP_PROJECT.cloudfunctions.net/POST_pickups
    pushd ../js && firebase functions:config:set private_api.post_pickups_url=$POST_PICKUPS_URL && popd
else
    echo "Private API configuration secrets already set, skipping ahead to deployment..."
fi

echo "Deploy firebase functions...⚙️"
pushd ../js && firebase deploy --only functions:proxy_POST_PICKUPS && popd

# NOTE(aleksey): you use gcloud authentication when deploying the cloud function, but to actually
# hit the deployed services from your local machine, a Firebase Admin SDK token is required. Super
# weird.
#
# While not strictly necessary to succeed in running this script, I've added a check here to help
# prevent user surprise when the integration tests don't work.
if [[ ! -f "../js/serviceAccountKey.json" ]]; then
    echo "WARNING: the /js/serviceAccountKey.json file does not exist."
    echo "You will not be able to run integration tests until you create it!"
    echo "See further https://firebase.google.com/docs/admin/setup#initialize-sdk."
fi

echo "All done! To see the functions deployed visit https://console.firebase.google.com/project/$GCP_PROJECT/functions/list."