#!/bin/bash
################################################################################
# Description: read data API configurations, we will just save responses as base64 and some ids.
#              Every change on one of the resources outside of terraform should trigger the update.
#              If secret content is changed through manually, we cannot identify it (as there's no modification time)
#
#              The state is going to be a json
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

function append_to_json() {
  # ----------------------------------
  # Creates a json and appends key/value to it.
  # param1 - the json to modify, if empty - will create new one
  # param2 - key to add
  # param3 - value to add
  #
  # returns: the json
  # ----------------------------------
  local json="$1"
  local key="$2"
  local value="$3"

  if [[ -z "$json" ]]; then
    json='{}'
  fi

  # Append the new key/value pair to the JSON object
  json=$(echo "$json" | jq --arg key "$key" --arg value "$value" '. + { ($key): $value }')

  echo "$json"
}

function try_get {
  # ----------------------------------
  # performs GET request, and tries to find specific key-value in the array of jsons or json.
  # if found, returns the relevant json. if not, empty string.
  # param1 - the url section (without the base URL) to perform
  # param2 - wanted key to search
  # param3 - wanted value to search
  #
  # returns: the relevant json. if not, empty string.
  # ----------------------------------
  url="$ATLAS_ADMIN_BASE_API_PATH/$1"
  wanted_key=$2
  wanted_value=$3
  response=$(curl -sSL --fail -X "GET" "$url" \
    --header "authorization: Bearer $MONGO_TOKEN" \
    --header 'content-type: application/json')

  if [ $? -ne 0 ]; then
    echo "$response" >&2
    exit 1
  fi

  if [ -z "$wanted_key" ]; then
    echo $response
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


echo "Searching if DB $DB_INSTANCE_NAME is configured, project_id: $PROJECT_ID" >&2
path="groups/$PROJECT_ID/apps/$APP_ID/services"
res=$(try_get $path "name" "$DB_INSTANCE_NAME")
if [ $? -ne 0 ]; then
  exit 1
fi
if [ -z "$res" ]; then
  echo "service not found..." >&2
  exit 1
fi

service_id=$(echo "$res" | jq -r '._id')
service_name=$(echo "$res" | jq -r '.name')
myjson=$(append_to_json "$myjson" "service_id" "$service_id")
myjson=$(append_to_json "$myjson" "service_name" "$service_name")

echo "Searching for existing secret jwt-public-key: $PROJECT_ID" >&2
path="groups/$PROJECT_ID/apps/$APP_ID/secrets"
res=$(try_get $path "name" "jwt-public-key")
if [ $? -ne 0 ]; then
  exit 1
fi
if [ -z "$res" ]; then
  echo "Secret not found..." >&2
  exit 1
fi

secret_id=$(echo "$res" | jq -r '._id')
secret_name=$(echo "$res" | jq -r '.name')
myjson=$(append_to_json "$myjson" "secret_id"  $secret_id)
myjson=$(append_to_json "$myjson" "secret_name"  $secret_name)

echo "Searching for existing custom-token auth-provider: $PROJECT_ID" >&2
path="groups/$PROJECT_ID/apps/$APP_ID/auth_providers"
res=$(try_get $path "type" "custom-token")
if [ $? -ne 0 ]; then
  exit 1
fi
if [ -z "$res" ]; then
  echo "auth provider not found..." >&2
  exit 1
fi

auth_provider_id=$(echo "$res" | jq -r '._id')

# Use the auth provider id we found to save the full configurations to state
path="groups/$PROJECT_ID/apps/$APP_ID/auth_providers/$auth_provider_id"
res=$(try_get $path)
if [ $? -ne 0 ]; then
  exit 1
fi

myjson=$(append_to_json "$myjson" "jwt_provider_result" "$(echo -n "$res")")

# We created the default rule before, so we just need to update it.
echo "Getting the default rule..." >&2
path="groups/$PROJECT_ID/apps/$APP_ID/services/$service_id/default_rule"
res=$(try_get $path)
if [ $? -ne 0 ]; then
  exit 1
fi
if [ -z "$res" ]; then
  echo "default rule not found..." >&2
  exit 1
fi

# This will be saved to state, full json
myjson=$(append_to_json "$myjson" "default_rule_result" "$(echo -n "$res")")

echo $myjson