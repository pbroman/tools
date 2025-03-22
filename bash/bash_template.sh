#!/usr/bin/env bash

##############################################
#
# Bash template
#
# Prerequisites:
#
##############################################

#set -x
set -e

usage() {
    cat <<EOT

$0 - template

Usage: $0 [OPTIONS] <input>

Options:
  -o, --output               Output file path. If none given, the output will be to stdout
  -h, --help                 Show this help
EOT
    exit 3
}


args() {
  while [[ "$1" != "" ]]; do
    case $1 in
      -o|--output )                 shift
                                    OUTPUT="$1"
                                    shift
                                    ;;
      -h|--help )                   usage
                                    ;;
      -*)                           echo "Unrecognized option $1"
                                    usage
                                    ;;
      *)                            [[ "${INPUT}" != "" ]] && echo "Duplicated input file argument: '${INPUT}' and '$1'" && usage
                                    INPUT="$1"
                                    shift
                                    ;;
    esac
  done

  if [[ "${INPUT}" == "" ]]; then
    usage
  fi
}

main() {

  args "$@"

  if [[ ! -f ${INPUT} ]]; then
    echo "input file '${INPUT}' not found"
    exit 1
  fi

  #mkdir -p workdir

}

main "$@"