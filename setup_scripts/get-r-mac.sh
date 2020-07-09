#!/usr/bin/env bash
set -e

# Download and extract the main Mac Resources directory
# Requires xar and cpio, both installed in the Dockerfile
mkdir -p ./r-mac
curl -o ./r-mac/latest_r.pkg \
     https://cloud.r-project.org/bin/macosx/R-4.0.2.pkg

cd ./r-mac
xar -xf latest_r.pkg
rm -r r-1.pkg Resources tcltk8.pkg texinfo5.pkg Distribution latest_r.pkg
cat r.pkg/Payload | gunzip -dc | cpio -i
mv R.framework/Versions/Current/Resources/* .
rm -r r.pkg R.framework

# need to make sure R is looking in the right place - packaged electron - for
# paths, otherwise the app will break unless user installs R on machine; this
# avoids that requirement by forcing R to use the R_HOME path in the env
# provided by the JS app to the R call (see src/index.js)
sed -i.bak '/^R_HOME_DIR=/d' bin/R
sed -i.bak 's#/Library/Frameworks/R.framework/Resources#${R_HOME}#g' bin/R
sed -i.bak '41i\
DYLD_LIBRARY_PATH="${R_HOME}/lib"\
export DYLD_LIBRARY_PATH\
' bin/R

rm bin/R.bak
chmod +x bin/R
