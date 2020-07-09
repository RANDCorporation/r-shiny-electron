#!/usr/bin/env bash
set -e

r_version=$1

# Download and extract the Windows binary install
# Requires innoextract
mkdir -p ./r-win
curl -o ./r-win/latest_r.exe \
  https://cloud.r-project.org/bin/windows/base/old/$r_version/R-$r_version-win.exe

cd ./r-win
innoextract -e latest_r.exe
mv app/* ../r-win
rm -r app latest_r.exe
