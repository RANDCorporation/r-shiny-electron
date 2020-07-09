#!/bin/bash
# Setup script for electron shiny
# This script provides all required setup to pack mac and windows electron
# services to run a R Shiny application
# TODO: add arg for R version to pull (note: can only grab 3.5.2 or earlier
#       if building win from Mac due to innoextract util lag behind Inno Setup)
# TODO: possibly add some cleanup to remove files/dirs that dont need to be
#       packed into the dist
# TODO: look into whether shiny can be run when packaged into asar, or implement
#       the asarUnpack option in package.json
usage () {
  echo "setup - setup tools used prior to building R Shiny Electron app"
  echo " "
  echo "setup [options] [arguments]"
  echo " "
  echo "options:"
  echo "-h      show help"
  echo "-m      setup for mac build"
  echo "-w      setup for windows build"
  echo "-l      shiny app requires latex for rendering markdown reports"
  echo "-r      specify R version, optional and if not specified pulls latest"
  echo " "
  echo "example:"
  echo ""
  echo "setup -mw"
}
while getopts "mwlr:h" opt;
do
  case ${opt} in
    m) build_mac=1;;
    w) build_win=1;;
    l) add_latex=1;;
    r) r_version=${OPTARG};;
    h) usage; exit;;
    *) usage; exit;;
  esac
done

if [ -z $build_mac ]
then
  build_mac=0
fi

if [ -z $build_win ]
then
  build_win=0
fi

if [ -z $add_latex ]
then
  add_latex=0
fi

if [ -z $r_version ]
then
  echo "Must provide R version, e.g., '4.0.2'"
  exit 1
fi

if [[ $build_mac == 0 && $build_win == 0 ]]
then
  echo "Must setup either mac (-m) or windows (-w). exiting."
  exit 1
fi

if [[ $build_mac == 1 && $build_win == 1 && $add_latex == 1 ]]
then
  echo "For shiny apps with latex dependency, can only build either Mac or Win"
  echo "on a Mac or Win machine respectively."
  exit 1
fi

#==============================================================================
#==============================================================================
# MAC SETUP
#==============================================================================
#==============================================================================
if [[ $build_mac == 1 ]]
then
  # get R binary for mac if not already pulled
  if [[ ! -f ./r-mac/bin/R ]]
  then
    ./setup_scripts/get-r-mac.sh $r_version
  else
    echo "R binary already exists for mac or not needed, skipping."
  fi

  # get pandoc and tinytex if shiny app requires latex/markdown rendering
  if [[ ! -d ./pandoc && $add_latex == 1 ]]
  then
    ./setup_scripts/get-pandoc-mac.sh
  else
    echo "pandoc dir already exists or not needed, skipping."
  fi
fi
#==============================================================================
#==============================================================================
# WIN SETUP
#==============================================================================
#==============================================================================
if [[ $build_win == 1 ]]
then
  # get R binary for mac if not already pulled
  if [[ ! -f ./r-win/bin/x64/R.exe ]]
  then
    ./setup_scripts/get-r-win.sh $r_version
  else
    echo "R binary already exists for win or not needed, skipping."
  fi

  # get pandoc and tinytex if shiny app requires latex/markdown rendering
  if [[ ! -d ./pandoc && $add_latex == 1 ]]
  then
    ./setup_scripts/get-pandoc-win.sh
  else
    echo "pandoc dir already exists or not needed, skipping."
  fi
fi

#==============================================================================
#==============================================================================
# R PACKAGES
#==============================================================================
#==============================================================================
if [[ $OSTYPE == "darwin"* ]]
then
  export R_HOME_DIR="$PWD/r-mac/"
  echo "Checking if need to fetch R packages required by shiny app."

  if [[ $build_mac == 1 ]]
  then
    ./r-mac/bin/R --vanilla --slave --file=./setup_scripts/add-cran-binary-pkgs.R --args mac
  fi

  if [[ $build_win == 1 ]]
  then
      ./r-mac/bin/R --vanilla --slave --file=./setup_scripts/add-cran-binary-pkgs.R --args win
  fi

  if [[ ! -d ./tinytex && $add_latex == 1 ]]
  then
    ./r-mac/bin/R --vanilla --slave --file=./setup_scripts/get-tinytex.R --args mac
  fi
elif [[ $OSTYPE == "cygwin" || $OSTYPE == "msys" ]]
then
  echo "Checking if need to fetch R packages required by shiny app."
  if [[ $build_mac == 1 ]]
  then
    ./r-win/bin/R --vanilla --slave --file=./setup_scripts/add-cran-binary-pkgs.R --args mac
  fi

  if [[ $build_win == 1 ]]
  then
    ./r-win/bin/R --vanilla --slave --file=./setup_scripts/add-cran-binary-pkgs.R --args win
  fi

  if [[ ! -d ./tinytex && $add_latex == 1 ]]
  then
    ./r-win/bin/R --vanilla --slave --file=./setup_scripts/get-tinytex.R --args win
  fi
else
  echo "OS not properly detected."
  echo "If are you using OS other mac or win, check 'setup.sh' and modify as needed."
fi
