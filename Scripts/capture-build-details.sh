#!/bin/sh -e

#  capture-build-details.sh
#  Loop
#
#  Copyright © 2019 LoopKit Authors. All rights reserved.
#  Modified by dabear

echo "Gathering build details in ${SRCROOT}"
cd "${SRCROOT}"

plist="${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"

if [ -e .git ]; then
  rev=$(git rev-parse HEAD)
  plutil -replace no-bjorninge-mm-git-revision -string ${rev} "${plist}"
  
  branch=$(git branch | grep \* | cut -d ' ' -f2-)
  plutil -replace no-bjorninge-mm-git-branch -string "${branch}" "${plist}"

  remoteurl=$(git config --get remote.origin.url)
  plutil -replace no-bjorninge-mm-git-remote -string "${remoteurl}" "${plist}"
fi;
echo plutil -replace no-bjorninge-mm-srcroot -string "${SRCROOT}" "${plist}"
echo plutil -replace no-bjorninge-mm-build-date -string "$(date)" "${plist}"
echo plutil -replace no-bjorninge-mm-xcode-version -string "${XCODE_PRODUCT_BUILD_VERSION}" "${plist}"



