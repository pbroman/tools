#!/usr/bin/env bash

##############################################
#
# Script converting .ipspolicycmpttype files to plantUml
#
# Prerequisites:
#   xsltproc is installed 
##############################################

#set -x
set -e

WORKDIR="ips2plantWorkdir"
COLLECTION_XML="ips2plantCollection.xml"
PATHS_TO_DIR="."
MODEL_TYPE="policy"
FILE_SUFFIX="ipspolicycmpttype"
PRODUCT_FILE_SUFFIX="ipsproductcmpttype"
CLASS_TAG="PolicyCmptType"
PRODUCT_CLASS_TAG="ProductCmptType2"
OPTIONS=""

usage() {
    cat <<EOT

$0 - template

Usage: $0 [OPTIONS] <input>

Options:
  -o, --output               Output file path (should have .puml suffix). If none given, the output will be to stdout
  -p, --paths-to-dir         Path(s) to root directory(ies) with .ipspolicycmpttype files. Default: '.'
                             For multiple paths: put them in double quotes and separated by space. Ex.: -p "one/path other/path"
  -r, --print-target-role    Print the targetRolePlural attribute on the composition arrow.
  -s, --add-super-type       Adds inheritance of super types.
  -m, --model-type           [policy | product] default: policy
  -a, --add-product          Adds association to product / policy
  -g, --group-classes        Group classes together using last directory in path
  -h, --help                 Show this help
EOT
    exit 3
}


args() {
  while [[ "$1" != "" ]]; do
    case $1 in
      -o|--output )                 shift
                                    PUML_RESULT_FILE="$1"
                                    shift
                                    ;;
      -p|--paths-to-dir )           shift
                                    PATHS_TO_DIR="$1"
                                    shift
                                    ;;
      -m|--model-type )             shift
                                    MODEL_TYPE="$1"
                                    shift
                                    ;;
      -r|--print-target-role )      OPTIONS="$OPTIONS --stringparam printTargetRole true"
                                    shift
                                    ;;
      -s|--add-super-type )         OPTIONS="$OPTIONS --stringparam addSuperType true"
                                    shift
                                    ;;
      -g| --group-classes )         OPTIONS="$OPTIONS --stringparam groupClasses true"
                                    shift
                                    ;;
      -a|--add-product )            P_ASSOCIATION="true"
                                    shift
                                    ;;
      -h|--help )                   usage
                                    ;;
      -*)                           echo "Unrecognized option $1"
                                    usage
                                    ;;
      *)                            echo "Unrecognized parameter $1"
                                    usage
                                    ;;
    esac
  done

  if [[ "$MODEL_TYPE" == "product" ]]; then
    FILE_SUFFIX=$PRODUCT_FILE_SUFFIX
    CLASS_TAG=$PRODUCT_CLASS_TAG
    if [[ "$P_ASSOCIATION" == "true" ]]; then
        OPTIONS="$OPTIONS --stringparam addPolicyCmptType true"
    fi
  elif [[ "$P_ASSOCIATION" == "true" ]]; then
    OPTIONS="$OPTIONS --stringparam addProductCmptType true"
  fi

}

retrieve_files() {
  echo "retrieving files..."
  rm -rf $WORKDIR

  for path in $PATHS_TO_DIR; do
    mydir="${path##*/}"
    echo " --- $mydir"
    mkdir -p $WORKDIR/$mydir
    find "$path" -not -path '*/target/*' -path '*model*' -name "*.$FILE_SUFFIX" -exec cp '{}' $WORKDIR/$mydir \;
  done
}

create_collection() {
  echo "creating collection xml..."
  touch $COLLECTION_XML
  echo '<?xml version="1.0" encoding="UTF-8"?>' > $COLLECTION_XML
  echo "<collection>" >> $COLLECTION_XML

  for dir in $WORKDIR/*; do
    echo "<dir name=\"${dir#*/}\">" >> $COLLECTION_XML
    for filename in $dir/* ; do
      class=${filename##*/}
      class=${class%*.*}
      echo $class
      cat $filename \
        | grep -v "<?xml" \
        |  sed 's/xmlns:xsi=".*"//' \
        |  sed 's|xmlns="http://www.faktorzehn.org"||' \
        |  sed "s/<$CLASS_TAG\(.*\)>/<$CLASS_TAG className=\"$class\"\1>/" \
        |  sed "s/\(<$CLASS_TAG.* supertype=\"\)[^\"]*\.\([^\"]\+\".*\)/\1\2/" \
        |  sed  "s/\(<$CLASS_TAG.* productCmptType=\"\)[^\"]*\.\([^\"]\+\".*\)/\1\2/" \
        |  sed  "s/\(<$CLASS_TAG.* policyCmptType=\"\)[^\"]*\.\([^\"]\+\".*\)/\1\2/" \
        |  sed "s/\(<Association.*target=\"\).*\.\(.*\".*>\)/\1\2/" \
        >> $COLLECTION_XML
    done
    echo "</dir>" >> $COLLECTION_XML
  done

  echo "</collection>" >> $COLLECTION_XML
}

execute_xslt() {
  echo "executing xslt..."
  if [[ "$PUML_RESULT_FILE" == "" ]]; then
    xsltproc $OPTIONS ips2plant.xsl $COLLECTION_XML
  else
    xsltproc $OPTIONS ips2plant.xsl $COLLECTION_XML > $PUML_RESULT_FILE
  fi
}

main() {
  args "$@"

  retrieve_files

  create_collection

  execute_xslt
}

main "$@"
