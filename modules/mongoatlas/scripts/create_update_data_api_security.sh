#!/bin/bash
################################################################################
# Script Name: configure data-api security preferences - currently just allow list IPs
# Description: This script adjusts received IPs to the data-api
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

# Get current configured IP Access List in mongo.
echo "Getting ips for data-api: $PROJECT_ID" >&2
RESULT=$(curl_with_auth "groups/$PROJECT_ID/apps/$DATA_API_APP_ID/security/access_list" "GET")
if [ $? -ne 0 ]; then
  exit 1
fi


# Extract the ip list (comma seperated), and do the following:
# search it in mongo's actual list.
# If a requested IP was not found - add it as a new IP entry.
IFS=',' read -ra IPS <<< "$AWS_NAT_GW_IPS"
for ip in "${IPS[@]}"; do
  found=false
  _id=""
  while IFS= read -r line; do
    address=$(jq -r '.address' <<< "$line")
    _id=$(jq -r '._id' <<< "$line")
    if [ "$address" == "$ip" ]; then
      found=true
      break
    fi
  done <<< "$(echo "$RESULT" | jq -c '.allowed_ips[]')"

  if [ "$found" == false ]; then
    # the requested IP to add was not found, we will add it now.
    echo "IP $ip was not found, adding it." >&2
    add_res=$(curl_with_auth "groups/$PROJECT_ID/apps/$DATA_API_APP_ID/security/access_list" "POST" '{
      "address": "'$ip'"
    }')
    if [ $? -ne 0 ]; then
      exit 1
    fi
  fi
done

# This part goes over all IPs that already exist in mongo, if any do not exist in the input list - delete them.
output=$(jq -r '.allowed_ips[] | "\(.["_id"]) \(.["address"])"' <<< "$RESULT")
while read -r _id address; do
  if [[ -n $address ]]; then
    if [[ ! " ${IPS[@]} " =~ " ${address} " ]]; then
      echo "IP $address exists on mongo but not in requested list: $AWS_NAT_GW_IPS. will remove it.">&2
      del_res=$(curl_with_auth "groups/$PROJECT_ID/apps/$DATA_API_APP_ID/security/access_list/$_id" "DELETE")
      if [ $? -ne 0 ]; then
        exit 1
      fi
    fi
  fi
done <<< "$output"