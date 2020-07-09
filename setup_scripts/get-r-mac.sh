#!/usr/bin/env bash
set -e

r_version=$1

# Download and extract the main Mac Resources directory
# Requires xar and cpio, both installed in the Dockerfile
mkdir -p ./r-mac
curl -o ./r-mac/latest_r.pkg \
     https://cloud.r-project.org/bin/macosx/R-$r_version.pkg

cd ./r-mac
xar -xf latest_r.pkg

# R version 4.0.0+ has different .pkg contents
if [[ ! -f r.pkg ]]
then
  rm -r R-app.pkg Resources tcltk.pkg texinfo.pkg Distribution latest_r.pkg
  cat R-fw.pkg/Payload | gunzip -dc | cpio -i
  mv R.framework/Versions/Current/Resources/* .
  rm -r R-fw.pkg R.framework
else
  rm -r r-1.pkg Resources tcltk8.pkg texinfo5.pkg Distribution latest_r.pkg
  cat r.pkg/Payload | gunzip -dc | cpio -i
  mv R.framework/Versions/Current/Resources/* .
  rm -r r.pkg R.framework
fi

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
