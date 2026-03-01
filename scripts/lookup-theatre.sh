#!/usr/bin/env bash
#
# Looks up theatre details via Google Places API and caches results in theatre-details.json
#
# Usage:
#   ./lookup-theatre.sh "AMC Metreon 16 & IMAX" "San Francisco"
#   ./lookup-theatre.sh "Kinepolis Brussels & IMAX" "Brussels"
#
# Requires: curl, python3, GOOGLE_PLACES_API_KEY in .env
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CACHE_FILE="$ROOT_DIR/theatre-details.json"
ENV_FILE="$ROOT_DIR/.env"

# Load API key
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

if [ -z "${GOOGLE_PLACES_API_KEY:-}" ]; then
  echo "Error: GOOGLE_PLACES_API_KEY not set. Add it to .env or export it." >&2
  exit 1
fi

if [ $# -lt 1 ]; then
  echo "Usage: $0 <theatre-name> [city]" >&2
  exit 1
fi

THEATRE_NAME="$1"
CITY="${2:-}"

# Initialize cache file if it doesn't exist
if [ ! -f "$CACHE_FILE" ]; then
  echo '{}' > "$CACHE_FILE"
fi

# Check cache first (keyed by theatre name) — includes null entries for known misses
CACHED=$(python3 -c "
import json, sys
cache = json.load(open('$CACHE_FILE'))
key = sys.argv[1]
if key in cache:
    print(json.dumps(cache[key], indent=2))
else:
    print('MISS')
" "$THEATRE_NAME")

if [ "$CACHED" != "MISS" ]; then
  echo "Cache hit for: $THEATRE_NAME" >&2
  echo "$CACHED"
  exit 0
fi

# Build search query
QUERY="$THEATRE_NAME"
if [ -n "$CITY" ]; then
  QUERY="$THEATRE_NAME $CITY"
fi

echo "Looking up: $QUERY" >&2

# Call Google Places API, with Chinese fallback for known chains
RESPONSE=$(python3 -c "
import json, sys, urllib.request

key = sys.argv[1]
theatre_name = sys.argv[2]
city = sys.argv[3]
field_mask = 'places.displayName,places.formattedAddress,places.shortFormattedAddress,places.websiteUri,places.googleMapsUri,places.location,places.nationalPhoneNumber,places.id'

# Chinese chain name translations for fallback queries
CHINESE_CHAINS = {
    'Wanda': '万达影城',
    'MixC': '万象城',
    'CGV': 'CGV影城',
    'Bona': '博纳影城',
}

def search(query):
    data = json.dumps({'textQuery': query}).encode()
    req = urllib.request.Request(
        'https://places.googleapis.com/v1/places:searchText?key=' + key,
        data=data,
        headers={'Content-Type': 'application/json', 'X-Goog-FieldMask': field_mask}
    )
    resp = json.loads(urllib.request.urlopen(req).read())
    return resp.get('places', [])

# Try English query first
query = theatre_name + (' ' + city if city else '')
places = search(query)

# If no results, try Chinese fallback for known chains
if not places and city:
    for eng, cn in CHINESE_CHAINS.items():
        if eng.lower() in theatre_name.lower():
            cn_query = cn + 'IMAX ' + city
            print('Trying Chinese fallback: ' + cn_query, file=sys.stderr)
            places = search(cn_query)
            if places:
                break

print(json.dumps({'places': places}))
" "$GOOGLE_PLACES_API_KEY" "$THEATRE_NAME" "$CITY")

# Parse response and update cache
python3 -c "
import json, sys

response = json.loads(sys.argv[1])
theatre_name = sys.argv[2]
cache_file = sys.argv[3]

places = response.get('places', [])

if places:
    place = places[0]
    detail = {
        'google_places_id': place.get('id', ''),
        'google_name': place.get('displayName', {}).get('text', ''),
        'address': place.get('formattedAddress', ''),
        'short_address': place.get('shortFormattedAddress', ''),
        'website': place.get('websiteUri', ''),
        'google_maps_url': place.get('googleMapsUri', ''),
        'phone': place.get('nationalPhoneNumber', ''),
        'latitude': place.get('location', {}).get('latitude'),
        'longitude': place.get('location', {}).get('longitude'),
    }
else:
    # Cache a null entry so we don't search again
    print(f'No results found for: {theatre_name}', file=sys.stderr)
    detail = {
        'google_places_id': None,
        'google_name': None,
        'address': None,
        'short_address': None,
        'website': None,
        'google_maps_url': None,
        'phone': None,
        'latitude': None,
        'longitude': None,
    }

# Update cache
cache = json.load(open(cache_file))
cache[theatre_name] = detail
with open(cache_file, 'w') as f:
    json.dump(cache, f, indent=2, ensure_ascii=False)

print(json.dumps(detail, indent=2, ensure_ascii=False))
" "$RESPONSE" "$THEATRE_NAME" "$CACHE_FILE"
