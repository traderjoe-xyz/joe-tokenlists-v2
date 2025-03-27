#!/bin/bash
set -e

# -----------------------------
# Validate JSON structure
# -----------------------------
echo "Validating JSON structure for tokenlists"
jq empty ./popular_tokenlist.json
jq empty ./verified_tokenlist.json


# -----------------------------
# Check required keys in JSON array
# -----------------------------
REQUIRED_KEYS=("chainId" "address" "decimals" "name" "symbol" "tags")
echo "Checking required keys for each token..."

for key in "${REQUIRED_KEYS[@]}"; do 
    if [ "$(jq ".[] | [has(\"$key\")] | contains([false])" popular_tokenlist.json)" == "true" ]; then
        echo "JSON validation failed: Missing key $key"
        exit 1
    fi
done
echo "All required keys are present in each token."

# -----------------------------
# Check allowed 'chainId' values
# -----------------------------
ALLOWED_CHAIN_IDS=(1 42161 421613 56 97 8453 10143 42161 43113 43114 80084 80094 1399811149 146)
# Convert bash array to jq array format
JQ_ALLOWED_CHAIN_IDS=$(printf "[%s]" "$(IFS=, ; echo "${ALLOWED_CHAIN_IDS[*]}")")

echo "Validating 'chainId' values..."
INVALID_CHAIN_IDS=$(jq "[.[].chainId] | map(select(. as \$id | ($JQ_ALLOWED_CHAIN_IDS | index(\$id)) == null))" popular_tokenlist.json)

if [ "$INVALID_CHAIN_IDS" != "[]" ]; then
  echo "Invalid 'chainId' value(s) found: $INVALID_CHAIN_IDS. Must be one of ${ALLOWED_CHAIN_IDS[*]}"
  exit 1
else
  echo "All 'chainId' values are valid in popular_tokenlist.json."
fi

INVALID_CHAIN_IDS=$(jq "[.[].chainId] | map(select(. as \$id | ($JQ_ALLOWED_CHAIN_IDS | index(\$id)) == null))" verified_tokenlist.json)

if [ "$INVALID_CHAIN_IDS" != "[]" ]; then
  echo "Invalid 'chainId' value(s) found: $INVALID_CHAIN_IDS. Must be one of ${ALLOWED_CHAIN_IDS[*]}"
  exit 1
else
  echo "All 'chainId' values are valid in verified_tokenlist.json."
fi



# -----------------------------
# Check logos folder and file names
# -----------------------------

ETH_ADDRESS_PATTERN="^0x[a-f0-9]{40}\.png$"

LOGOS_DIR="logos"

# Check if the logos directory exists
if [ ! -d "$LOGOS_DIR" ]; then
    echo "Error: Logos directory '$LOGOS_DIR' does not exist."
    exit 1
fi

# Iterate through each subdirectory in the logos folder
for dir in "$LOGOS_DIR"/*; do
    if [ -d "$dir" ]; then
        # ignore solana folder
        if [[ "$dir" == "logos/1399811149" ]]; then
            continue
        fi
        # Iterate through files in the subdirectory
        for file in "$dir"/*; do
            if [ -f "$file" ]; then
                filename=$(basename "$file")
                if [[ ! "$filename" =~ $ETH_ADDRESS_PATTERN ]]; then
                    echo "Invalid file found: $file"
                    exit 1
                fi
            else
                echo "Invalid entry found (not a file): $file"
                exit 1
            fi
        done
    fi
done

echo "Every logo is named correctly."

echo "All validations passed successfully."
