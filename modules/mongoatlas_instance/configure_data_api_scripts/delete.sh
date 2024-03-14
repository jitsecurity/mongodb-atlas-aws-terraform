#!/bin/bash
################################################################################
# Description: Deletes data api configurations from mongo
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
  # performs curl request with mongo token, 404 errors are considered valid.
  # param1 - the url section (without the base URL) to perform
  # param2 - method
  # param3 - the body of the request
  #
  # returns: None
  # ----------------------------------
  url="$ATLAS_ADMIN_BASE_API_PATH/$1"
  method="$2"
  data="$3"
  http_code=$(curl -sSL --fail --output /dev/null -w "%{http_code}" -X "$method" "$url" \
    --header "authorization: Bearer $MONGO_TOKEN" \
    --header 'content-type: application/json' \
    --data-raw "$data" \
    --compressed)
  if [[ -n "$http_code" && "$http_code" =~ ^[0-9]+$ && "$http_code" -ge 400 && "$http_code" != "404" ]]; then
      echo "HTTP request failed with error code $http_code" >&2
      exit 1
  fi
}

# Take the state (STDIN)
IN=$(cat)
service_id=$(echo "${IN}" | jq -r '.service_id')
auth_provider_id=$(echo "${IN}" | jq -r '.auth_provider_id')
secret_id=$(echo "${IN}" | jq -r '.secret_id')

# perform delete
echo "Trying to delete data source (service) using service id: $service_id, project $PROJECT_ID" >&2
del_res=$(curl_with_auth "groups/$PROJECT_ID/apps/$APP_ID/services/$service_id" "DELETE")
if [ $? -ne 0 ]; then
  exit 1
fi
echo "disabling auth provider $auth_provider_id" >&2
del_req=$(curl_with_auth "groups/$PROJECT_ID/apps/$APP_ID/auth_providers/$auth_provider_id/disable" "PUT")
if [ $? -ne 0 ]; then
  exit 1
fi

echo "deleting auth provider $auth_provider_id" >&2
del_req=$(curl_with_auth "groups/$PROJECT_ID/apps/$APP_ID/auth_providers/$auth_provider_id" "DELETE")
if [ $? -ne 0 ]; then
  exit 1
fi

echo "deleting secret $secret_id" >&2
del_req=$(curl_with_auth "groups/$PROJECT_ID/apps/$APP_ID/secrets/$secret_id" "DELETE")
if [ $? -ne 0 ]; then
  exit 1
fi
exit 0
