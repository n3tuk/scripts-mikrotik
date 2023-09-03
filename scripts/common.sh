#!/usr/bin/env bash

# Simple ANSI colours
AC_RED="\033[0;31m"
AC_GREEN="\033[0;32m"
AC_YELLOW="\033[0;33m"
AC_WHITE="\033[1;37m"
AC_END="\033[0m"

function fatal {
  (echo >&2 -e "${AC_RED}==>${AC_END} ${AC_RED}FATAL${AC_END} ${*}")
  exit 1
}

function error {
  (echo >&2 -e "${AC_YELLOW}==>${AC_END} ${*}")
}

function info {
  echo -e "${AC_GREEN}==>${AC_END} ${AC_WHITE}${*}${AC_END}"
}

function note {
  echo -e "${AC_GREEN}-->${AC_END} ${*}"
}

function sub-note {
  echo -e "${AC_GREEN} ->${AC_END} ${*}"
}
