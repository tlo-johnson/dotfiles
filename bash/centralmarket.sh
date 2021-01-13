alias cm="cd ~/dev/central-market"
alias cmwp="cd ~/dev/central-market/centralmarket.com"
alias cmrs="cd ~/dev/central-market/react-service"
alias cm-connect-container="docker-command docker exec -it centralmarket.com bash"
alias rdcli="~/.config/yarn/global/node_modules/.bin/rdcli"

function cm-mr() {
  branch=$(g b | grep '*' | cut -d ' ' -f 2) && \
  run-tests && git fetch origin && git branch --no-track "$branch-mr" origin/feature/cmw-3338-react-product-migration && git switch "$branch-mr" && git merge --squash $branch && git commit -m "merge changes from $branch" && cm-continue-mr
}

function cm-continue-mr() {
  branch=$(g b | grep '*' | cut -d ' ' -f 2)
  if [[ ! $branch =~ -mr$ ]]; then
    echo 'you are going to have to manually merge this branch because it does not end in "-mr" as expected'
    exit 1
  fi
  run-tests && git push origin $branch
}

# central market aliases
alias cm-switch-branch='cd ~/dev/central-market/centralmarket.com && composer install && cd wp-content/themes/centralmarket-theme/ && npm ci && npm run prod && echo consider running "docker-command docker exec centralmarket.com wp plugin activate centralmarket-react-service"'

# central market urls
alias cm-request-fulfillment-bar="curl http://localhost:3000/batch -H 'content-type: application/json' -d '{\"state\": {},\"components\":{\"FulfillmentBar\":{\"component\":\"FulfillmentBar\",\"data\": {\"session\": {\"user\": {\"display_name\": \"Nenad\",\"memberships\": []},\"channels\": {\"curbside\": {\"store\": {\"id\": 420,\"address\": {\"company\": \"Austin Westgate\",\"address_1\": \"4477 SOUTH LAMAR\",\"address_2\": \"\",\"city\": \"AUSTIN\",\"state\": \"TX\",\"postcode\": \"78745\",\"country\": \"US\"},\"phone\": \"1-737-708-8377\",\"channels\": [\"curbside\",\"holiday-hotline\"],\"is_default\": false},\"schedule\": {\"type\": \"pickup\",\"timeslot\": {\"from\": \"2020-07-24T20:30:00-05:00\",\"until\": \"2020-07-24T21:00:00-05:00\",\"expires\": \"2020-07-24T14:38:59-05:00\"}},\"open_orders\": [{\"id\": 1024466,\"type\": \"delivery\",\"addon_until\": \"2020-07-27T14:00:00-05:00\",\"addons_available\": 4,\"store\": {\"id\": 491,\"address\": {\"company\": \"Houston\",\"address_1\": \"3815 WESTHEIMER\",\"address_2\": \"\",\"city\": \"HOUSTON\",\"state\": \"TX\",\"postcode\": \"77027\",\"country\": \"US\"}},\"timeslot\": {\"from\": \"2020-07-27T18:00:00-05:00\",\"until\": \"2020-07-27T19:00:00-05:00\"},\"delivery_address\": {\"address_1\": \"1504 Ben Taub Loop\"}}],\"cart_count\": 10}},\"max_add_on_items\": 10},\"buttonLabel\": \"edit\",\"topCtaMessage\": \"\",\"topCtaLinkTo\": \"\",\"bottomCtaMessage\": \"*Pricing and availability may change depending on fulfillment selection\"}}}}' | jq"
alias cm-request-sitewide-message="curl http://localhost:3000/batch -H 'content-type:application/json' -d '{\"state\":[],\"components\":{\"SitewideMessage\":{\"component\":\"SitewideMessage\",\"data\":{\"storeId\": 747,\"fulfillmentType\":\"pickup\"}}}}' | jq"
alias cm-request-block-collection="curl http://localhost:3000/batch -H 'content-type:application/json' -d '{\"state\":[],\"components\":{\"BlockCollection\":{\"component\":\"BlockCollection\",\"data\":{\"storeId\": 747}}}}' | jq"

alias cm-request-fulfillment-bar-dev="curl https://cm-react-service-dev-plnmiq5ora-uc.a.run.app/batch -H 'content-type: application/json' -d '{\"state\": {},\"components\":{\"FulfillmentBar\":{\"component\":\"FulfillmentBar\",\"data\": {\"session\": {\"user\": {\"display_name\": \"Nenad\",\"memberships\": []},\"channels\": {\"curbside\": {\"store\": {\"id\": 420,\"address\": {\"company\": \"Austin Westgate\",\"address_1\": \"4477 SOUTH LAMAR\",\"address_2\": \"\",\"city\": \"AUSTIN\",\"state\": \"TX\",\"postcode\": \"78745\",\"country\": \"US\"},\"phone\": \"1-737-708-8377\",\"channels\": [\"curbside\",\"holiday-hotline\"],\"is_default\": false},\"schedule\": {\"type\": \"pickup\",\"timeslot\": {\"from\": \"2020-07-24T20:30:00-05:00\",\"until\": \"2020-07-24T21:00:00-05:00\",\"expires\": \"2020-07-24T14:38:59-05:00\"}},\"open_orders\": [{\"id\": 1024466,\"type\": \"delivery\",\"addon_until\": \"2020-07-27T14:00:00-05:00\",\"addons_available\": 4,\"store\": {\"id\": 491,\"address\": {\"company\": \"Houston\",\"address_1\": \"3815 WESTHEIMER\",\"address_2\": \"\",\"city\": \"HOUSTON\",\"state\": \"TX\",\"postcode\": \"77027\",\"country\": \"US\"}},\"timeslot\": {\"from\": \"2020-07-27T18:00:00-05:00\",\"until\": \"2020-07-27T19:00:00-05:00\"},\"delivery_address\": {\"address_1\": \"1504 Ben Taub Loop\"}}],\"cart_count\": 10}},\"max_add_on_items\": 10},\"buttonLabel\": \"edit\",\"topCtaMessage\": \"\",\"topCtaLinkTo\": \"\",\"bottomCtaMessage\": \"*Pricing and availability may change depending on fulfillment selection\"}}}}' | jq"

alias cm-request-offercards-collection="curl http://localhost:3000/batch -H 'content-type: application/json' -d '{\"state\": {},\"components\":{\"OfferCardsCollection\":{\"component\":\"OfferCardsCollection\",\"data\": {}}}}' | jq"

alias cm-request-contentful-healthcheck="curl http://localhost:3000/batch -H 'content-type: application/json' -d '{\"state\": {},\"components\":{\"ContentfulHealthCheck\":{\"component\":\"ContentfulHealthCheck\",\"data\": {\"storeId\": 55}}}}' | jq"

alias cm-req-gigya-jwt="curl -d '' 'https://accounts.us1.gigya.com/accounts.getJWT?apiKey=3_r_zyuCT030rhYOE6aYM34BFcjRqWtghcND-6LXXhHIZQQb_1FjBW4m-rFZJxhW44&secret=4iwszWHDqVP2WsTiq6YBDeKjBditE%2Fi%2B&targetUID=9f6c28f206794bc58d6b84e0be0be3a1&userKey=AOJ2UxObsHDC'"

alias cm-req-gigya-login="curl 'https://accounts.us1.gigya.com/accounts.login' \
  -H 'Connection: keep-alive' \
  -H 'Pragma: no-cache' \
  -H 'Cache-Control: no-cache' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'Accept: */*' \
  -H 'Origin: https://cdns.us1.gigya.com' \
  -H 'Sec-Fetch-Site: same-site' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Referer: https://cdns.us1.gigya.com/' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  --data-raw 'loginID=adesegha.tolu%40heb.com&password=%5Cyp%22Pw%26zjE%25DRo00hHT%60%5Bz&sessionExpiration=-2&targetEnv=jssdk&include=profile%2Cdata%2Cemails%2Csubscriptions%2Cpreferences%2C&includeUserInfo=true&loginMode=standard&lang=en&APIKey=3_d4Y4rY5ynOp2vrqDSWPyhfrvJCBBwAIHkZlNAQaoil80sEuBACO_-Jx__ttZEQX6&source=showScreenSet&sdk=js_latest&authMode=cookie&pageURL=https%3A%2F%2Fcmqa.wpengine.com%2F&gmid=0NKtVsAuQ11hGfxnWEW5vceoGlqN-VpNtGbSNJeuWxM&ucid=Nd-RNZt6_MwJURxv22hi7Q&format=json' \
  --compressed"
