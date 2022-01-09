#!/bin/bash

## If you don't want the script to automatically choose the Chrome version to
## use, set the CHROME_VERSION variable below
CHROME_VERSION="Brave-Browser"

# Chrome version is not set, the script will try to locate it by looping through
# all the possible chrome versions and checking if its user data dir exists
if [ -z "$CHROME_VERSION" ]; then
    CHROME_VERSIONS=(
        "chromium"
        "google-chrome"
        "google-chrome-beta"
        "google-chrome-unstable"
    )
    for version in "${CHROME_VERSIONS[@]}"; do
        if [ -d "$HOME/.config/$version" ]; then
            CHROME_VERSION="$version"
            break
        fi
    done
fi

# Chrome version was not set and it could not be automatically found either
if [ -z "$CHROME_VERSION" ]; then
    echo "unable to find Chrome version"
    exit 1
fi

# Check if the user data dir actually exists
CHROME_USER_DATA_DIR="$HOME/.config/BraveSoftware/$CHROME_VERSION/Profile 2"
# echo $CHROME_USER_DATA_DIR
if [ ! -d "$CHROME_USER_DATA_DIR" ]; then
    echo "unable to find Chrome user data dir"
    exit 1
fi

# Run a python script to read bookmarks data from an state file used by Chrome
DATA=$(python << END
import json
with open("$CHROME_USER_DATA_DIR/Bookmarks") as f:
    data = json.load(f)

# print(data["roots"]["bookmark_bar"]["children"])
for item in data["roots"]["bookmark_bar"]["children"]:
    print("%s_____%s" % (item["url"], item["name"]))
END
)

# Populate an associative array that maps bookmarks names to directories
declare -A bookmarks=()
while read -r line
do
    URL="${line%_____*}"
    NAME="${line#*_____}"
    bookmarks["$NAME"]="$URL"
done <<< "$DATA"

if [ -z "$@" ]; then
    # No argument passed, meaning that rofi was launched: show the bookmarks
    for bookmark in "${!bookmarks[@]}"; do
        echo $bookmark
    done
else
    # One argument passed, meaning that user selected a bookmark: launch Chrome
    NAME="${@}"
    brave-browser ${bookmarks[$NAME]} > /dev/null 2>&1
fi
