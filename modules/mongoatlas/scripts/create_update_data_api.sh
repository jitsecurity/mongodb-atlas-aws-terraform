#!/bin/bash
################################################################################
# Script Name: Create data-api for a specific instance
# Description: This script is responsible of:
#              1. Create data-api application (app services) in mongoDB.
#              2. enable it, while making sure create_user_on_auth=true (so JWT users will be created automatically)
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

function curl_with_auth () {
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
  echo "SENDING CURL REQUEST - cont url $url" >&2
  response=$(curl -sSL --show-error --fail -X "$method" "$url" \
    --header "authorization: Bearer $MONGO_TOKEN" \
    --header 'content-type: application/json' \
    --data-raw "$data" \
    --compressed)

  if [ $? -ne 0 ]; then
    echo "$response" >&2
    exit 1
  fi

  echo "$response"
}

function try_get () {
  # ----------------------------------
  # performs GET request, and tries to find specific key-value in the array of jsons or json.
  # if found, returns the relevant json. if not, empty string.
  # If no wanted key is supplied, we will just return the response, if empty array/json, will return empty result.
  # param1 - the url section (without the base URL) to perform
  # param2 - wanted key to search
  # param3 - wanted value to search
  #
  # returns: the relevant json. if not, empty string.
  # ----------------------------------
  url="$ATLAS_ADMIN_BASE_API_PATH/$1"
  wanted_key=$2
  wanted_value=$3
  response=$(curl -sSL --show-error --fail -X "GET" "$url" \
    --header "authorization: Bearer $MONGO_TOKEN" \
    --header 'content-type: application/json')

  if [ $? -ne 0 ]; then
    echo "$response" >&2
    exit 1
  fi
  # If key was not specified
  if [ -z "$wanted_key" ]; then
    # check if response is an empty JSON object or an empty array
    if [[ $(echo "$response" | jq 'length') -eq 0 ]]; then
      echo ""
    else
      echo "$response"
    fi
    return
  fi

  # Search for the relevant JSON object
  if [[ "$response" == "["*"]" ]]; then
    # Array of JSON objects
    matching_objects=$(echo "$response" | jq -r "map(select(.[\"$wanted_key\"] == \"$wanted_value\"))")
    if [ "$(echo "$matching_objects" | jq length)" -eq 0 ]; then
      echo ""
      return
    fi
    echo "$matching_objects" | jq '.[0]'
  else
    # Single JSON object
    if [[ $(echo "$response" | jq -r ".$wanted_key") == "$wanted_value" ]]; then
      echo "$response" | jq .
    else
      echo ""
    fi
  fi
}

echo "Searching if data-api app exists: $PROJECT_ID" >&2
path="groups/$PROJECT_ID/apps?product=data-api"
res=$(try_get $path "product" "data-api")
if [ -z "$res" ]; then
  # create data api app if one was not found.
  echo "Not found - Creating data api app for project id: $PROJECT_ID" >&2
  res=$(curl_with_auth "groups/$PROJECT_ID/apps?product=data-api" "POST" "{\"name\":\"data\",\"deployment_model\":\"LOCAL\",\"location\":\"$MONGO_LOCATION\",\"provider_region\":\"aws-$AWS_REGION\"}")
  if [ $? -ne 0 ]; then
    exit 1
  fi
fi


# Extract data api id and the client id
for item in $(echo "${res}" | jq -r 'select(.product == "data-api") | ._id, .client_app_id'); do
  if [[ -z "$data_api_id" ]]; then
    data_api_id="$item"
  else
    client_app_id="$item"
  fi
done

echo "Searching for existing data-api configuration: $PROJECT_ID" >&2
path="groups/$PROJECT_ID/apps/$data_api_id/data_api/config"
method="POST"
res=$(try_get $path)
if [ -n "$res" ]; then
  echo "Found, Will update." >&2
  method="PATCH"
fi

# enable data API
echo "Enabling data api for project id: $PROJECT_ID, data-api app id is: $data_api_id" >&2
enable_res=$(curl_with_auth $path $method '{
  "versions": [
    "v1"
  ],
  "run_as_system": false,
  "run_as_user_id": "",
  "run_as_user_id_script_source": "",
  "disabled": false,
  "validation_method": "NO_VALIDATION",
  "secret_name": "",
  "respond_result": false,
  "fetch_custom_user_data": false,
  "create_user_on_auth": true,
  "return_type": "JSON",
  "log_function_arguments": false
}')
if [ $? -ne 0 ]; then
  exit 1
fi
