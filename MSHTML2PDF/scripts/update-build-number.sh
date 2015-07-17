#!/bin/sh

echo "$SRCROOT/Info.plist"

version=`/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$SRCROOT/Info.plist"`

branch=$(expr $(git rev-parse --abbrev-ref HEAD))

echo $branch

buildNumber=$(expr $(git rev-list $branch --count) - $(git rev-list HEAD..$branch --count))

echo $buildNumber

echo "Updating build number to $buildNumber using branch '$branch'."
echo ${TARGET_BUILD_DIR}

echo "#import \"Version.h\"

NSString * const MSHTML2PDFVersionString = @\"$version ($buildNumber)\";" > ${SRCROOT}/html2pdf/Version.m
