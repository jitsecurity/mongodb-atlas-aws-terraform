#!/bin/bash
################################################################################
# Description: Reads IPs that are restricting data-api access, and saving it to state
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

# Get allowed ips for data-api
echo "Getting ips for data-api: $PROJECT_ID for app id: $DATA_API_APP_ID" >&2
data_api_res=$(curl_with_auth "groups/$PROJECT_ID/apps/$DATA_API_APP_ID/security/access_list" "GET")
if [ $? -ne 0 ]; then
  exit 1
fi

# Extract "address" values from the response and build a comma-separated list
addresses=$(echo "$data_api_res" | jq -r '.allowed_ips[].address' | paste -sd "," -)

# save to state
echo '{"allowed_ips":"'$addresses'"}'
