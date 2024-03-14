#!/bin/bash
################################################################################
# Script Name: Creates / updates data-api configuration
# Description: This script works both for update and create, it basically
# configures app service for an instance, relevant JWT token for authentication.
#
# This script uses a pattern of "get configuration", if not exist create else update
# this makes the script support both create and update
#
#
# Dependencies: curl, jq
################################################################################

# perform login and get access_token
ATLAS_ADMIN_BASE_API_PATH="https://services.cloud.mongodb.com/api/admin/v3.0"
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
  response=$(curl -sSL --show-error --fail -X "$method" "$url" \
    --header "authorization: Bearer $MONGO_TOKEN" \
    --header 'content-type: application/json' \
    --data-raw "$data" \
    --compressed)
  if [ $? -ne 0 ]; then
    exit 1
  fi

  echo "$response"
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
  response=$(curl -sSL --show-error --fail -X "GET" "$url" \
    --header "authorization: Bearer $MONGO_TOKEN" \
    --header 'content-type: application/json')


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

  if [ $? -ne 0 ]; then
    echo "$response" >&2
    exit 1
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

echo "Checking if DB $DB_INSTANCE_NAME is configured, project_id: $PROJECT_ID" >&2
path="groups/$PROJECT_ID/apps/$APP_ID/services"
res=$(try_get $path "name" "$DB_INSTANCE_NAME")
if [ -z "$res" ]; then
  # configure the service for the cluster
  echo "Not found, Enabling data api for cluster $DB_INSTANCE_NAME" >&2
  res=$(curl_with_auth $path "POST" "{\"name\": \"$DB_INSTANCE_NAME\", \"type\": \"mongodb-atlas\", \"config\": {\"clusterName\": \"$DB_INSTANCE_NAME\"}}")
  if [ $? -ne 0 ]; then
    exit 1
  fi
fi

service_id=$(echo "$res" | jq -r '._id')

# create or update the default rule


path="groups/$PROJECT_ID/apps/$APP_ID/services/$service_id/default_rule"
echo "Getting the default rule..." >&2
res=$(try_get $path)
default_rule_id=$(echo "$res" | jq -r '._id // ""')
if [ -z "$default_rule_id" ]; then
  echo "Not found, creating empty rule." >&2
  method="PUT"
  res=$(curl_with_auth $path "POST" '{
        "filters": [],
        "roles": []
        }')
  default_rule_id=$(echo "$res" | jq -r '._id')
fi

echo "Updating default rule $default_rule_id..." >&2
default_rule_res=$(curl_with_auth $path "PUT" '{
    "_id": "'$default_rule_id'",
    "filters": [
        {
            "name": "tenant id filter",
            "query": {
                "tenant_id": "%%user.data.tenantId"
            },
            "apply_when": {
                "%%true": true
            }
        }
    ],
    "roles": [
        {
            "name": "readAccessDataAPI",
            "apply_when": {},
            "read": true,
            "write": true,
            "insert": true,
            "delete": true,
            "search": true
        }
    ]
}')
if [ $? -ne 0 ]; then
  exit 1
fi

echo "Searching for existing secret jwt-public-key: $PROJECT_ID" >&2
path="groups/$PROJECT_ID/apps/$APP_ID/secrets"
res=$(try_get $path "name" "jwt-public-key")
method="POST"
if [ -n "$res" ]; then
  echo "Found, Will update." >&2
  secret_id=$(echo "$res" | jq -r '._id')
  path+="/$secret_id"
  method="PUT"
fi

# This adds frontegg public key as a secret, so it can be used for JWT auth.
echo "Performing $method on secret (JWT public key) for the JWT token: $PROJECT_ID" >&2
create_secret_res=$(curl_with_auth $path $method "{
  \"name\": \"jwt-public-key\",
  \"value\": \"$FRONTEGG_PUBLIC_KEY\"
}")
if [ $? -ne 0 ]; then
  exit 1
fi

echo "Searching for existing custom-token auth-provider: $PROJECT_ID" >&2
path="groups/$PROJECT_ID/apps/$APP_ID/auth_providers"
res=$(try_get $path "type" "custom-token")
method="POST"
if [ -n "$res" ]; then
  echo "Found, Will update." >&2
  id=$(echo "$res" | jq -r '._id')
  path+="/$id"
  method="PATCH"
fi

# This enables JWT token auth for data-api, configures the audience and public key of frontegg.
# Also this maps the tenantId in the token so it can be used for filtering.
echo "Enabling JWT auth for project id: $PROJECT_ID using $method" >&2
jwt_auth_res=$(curl_with_auth $path $method '{
  "name": "custom-token",
  "type": "custom-token",
  "disabled": false,
  "config": {
    "audience": [
      "'$FRONTEGG_AUD'"
    ],
    "requireAnyAudience": true,
    "signingAlgorithm": "RS256",
    "useJWKURI": false
  },
  "secret_config": {
    "signingKeys": [
      "jwt-public-key"
    ]
  },
  "metadata_fields": [
        {
            "required": true,
            "name": "'$TENANT_ID_FIELD_IN_JWT'",
            "field_name": "tenantId"
        },
        {
            "required": false,
            "name": "'$APP_SERVICES_USER_DISPLAY_FIELD_FROM_JWT'",
            "field_name": "name"
        }
    ]
}')
if [ $? -ne 0 ]; then
  exit 1
fi
auth_provider_id=$(echo "$jwt_auth_res" | jq -r '._id')