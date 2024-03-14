#!/bin/bash
################################################################################
# Description: Deletes all entries of IP from mongo
# NOTE - This part goes over all IPs that already exist in mongo, if any do not exist in the input list - delete them.
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

# Get current configured IP Access List in mongo.
echo "Getting ips for data-api: $PROJECT_ID" >&2
RESULT=$(curl_with_auth "groups/$PROJECT_ID/apps/$DATA_API_APP_ID/security/access_list" "GET")
if [ $? -ne 0 ]; then
  exit 1
fi

# Go over all ips and delete them from mongo
output=$(jq -r '.allowed_ips[] | "\(.["_id"]) \(.["address"])"' <<< "$RESULT")
while read -r _id address; do
  if [[ -n $address ]]; then
    echo "Removing $address from mongo. ">&2
    del_res=$(curl_with_auth "groups/$PROJECT_ID/apps/$DATA_API_APP_ID/security/access_list/$_id" "DELETE")
    if [ $? -ne 0 ]; then
      exit 1
    fi
  fi
done <<< "$output"