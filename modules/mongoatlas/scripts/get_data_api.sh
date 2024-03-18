#!/bin/bash
################################################################################
# Description: Reads data api configurations to save to state.
# NOTE - if the state is dirty (data api / service is deleted) - this will cause recreation of data-api
#        This affects eventually other dependent services which will need to refresh their URLs from SSM.
#        It's recommended that dependent services will read at runtime the URLs (and cache it).
#
#
# Dependencies: curl, jq
################################################################################

# perform login and get access_token
echo "Performing login, url: $ATLAS_ADMIN_BASE_API_PATH/auth/providers/mongodb-cloud/login" >&2

response=$(curl -sSL --show-error --fail -X POST "$ATLAS_ADMIN_BASE_API_PATH/auth/providers/mongodb-cloud/login" \
--header 'content-type: application/json' \
--data-raw "$AUTH")
if [ $? -ne 0 ]; then
  echo "Login failed... $response" >&2
  exit 1
fi

MONGO_TOKEN=$(echo "$response" | jq -r '.access_token')

echo "Login finished successfully."  >&2

function curl_with_auth {
  # ----------------------------------
  # performs curl request with mongo token
  # param1 - the url section (without the base URL) to perform
  # param2 - method
  # param3 - the body of the request
  #
  # returns: the response from curl
  # ----------------------------------
  url="$ATLAS_ADMIN_BASE_API_PATH/$1"
  method="$2"
  data="$3"

  if [ -z "$data" ]; then
    response=$(curl -sSL --request "$method" -H "authorization: Bearer $MONGO_TOKEN" -H "content-type: application/json" "$url")
  else
    response=$(curl -sSL --request "$method" -H "authorization: Bearer $MONGO_TOKEN" -H "content-type: application/json" -d "$data" "$url")
  fi

  if [ $? -ne 0 ]; then
    echo "$response" >&2
    exit 1
  fi

  echo "$response"
}

# Get data-api configurations
echo "Getting data api for project id: $PROJECT_ID" >&2
data_api_res=$(curl_with_auth "groups/$PROJECT_ID/apps?product=data-api" "GET")
if [ $? -ne 0 ]; then
  exit 1
fi

# Extract data api id and the client id
data_api_id=$(echo "$data_api_res" | jq -r '.[] | select(.product == "data-api") | ._id')
client_app_id=$(echo "$data_api_res" | jq -r '.[] | select(.product == "data-api") | .client_app_id')

if [ -z "$data_api_id" ]; then
  echo "data_api_id is empty, this was the result from the get apps: $data_api_res" >&2
  exit 1
fi

echo "Getting data api configuration for : $PROJECT_ID and api id: $data_api_id" >&2
config_res=$(curl_with_auth "groups/$PROJECT_ID/apps/$data_api_id/data_api/config" "GET")
if [ $? -ne 0 ]; then
  exit 1
fi

# save to state
echo '{"data_api_id": "'$data_api_id'", "client_id":"'$client_app_id'", "data_api_configurations":"'$(echo "$config_res" | base64)'"}'
