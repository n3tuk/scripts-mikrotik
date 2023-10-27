#!/usr/bin/env bash
# shellcheck disable=SC2034 # Some variables used in other scripts
set -ueo pipefail

hosts_dir="hosts"
networks_dir="networks"
exports_dir="exports"

if [[ "${use_examples:-false}" == "true" ]]; then
  hosts_dir="examples"
  networks_dir="examples"
fi

export=${1:-router:netinstall}
host=${export/:*/}
export=${export/*:/}
export_file="${exports_dir}/${host}-${export}"

# netinstall-cli expects the script to have a extension of .scr rather than .rsc
if [[ "${export}" == "netinstall" ]]; then
  export_ext+="scr"
else
  export_ext+="rsc"
fi
