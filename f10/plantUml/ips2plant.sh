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

WORKDIR="workdir"
MODEL_DIR="$WORKDIR/model"
COLLECTION_XML="ips2plantCollection.xml"
MODEL_TYPE="policy"
FILE_SUFFIX="ipspolicycmpttype"
PRODUCT_FILE_SUFFIX="ipsproductcmpttype"
CLASS_TAG="PolicyCmptType"
PRODUCT_CLASS_TAG="ProductCmptType2"
PUML_RESULT_FILE="output/ips-models.puml"
OPTIONS=""
CONNECTOR="--"

usage() {
    cat <<EOT

$0 - template

Usage: $0 [OPTIONS] <input>

Options:
  -o, --output               Output file path (should have .puml suffix). Default: $PUML_RESULT_FILE
  -p, --paths                Path(s) to model directories (mandatory).
                             For multiple paths: put them in double quotes and separated by space. Ex.: -p "one/path other/path"
  -k, --packages             Puts all classes in their packages
  -l, --length               Length of association connectors. Default: $CONNECTOR
  -r, --print-target-role    Print the targetRolePlural attribute on the composition arrow.
  -s, --add-super-type       Adds inheritance of super types that are NOT present under the scanned models.
  -a, --add-associations     Adds associations to classes that are NOT present under the scanned models.
  -pl, --package-limit        Limit the diagram to a package and it's associations
  -m, --model-type           [policy | product] default: policy
  -pr, --add-product         Adds association to product / policy
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
      -l|--length-type )            shift
                                    CONNECTOR="$1"
                                    shift
                                    ;;
      -r|--print-target-role )      OPTIONS="$OPTIONS --stringparam printTargetRole true"
                                    shift
                                    ;;
      -s|--add-super-type )         OPTIONS="$OPTIONS --stringparam addSuperType true"
                                    shift
                                    ;;
      -a|--add-associations )       OPTIONS="$OPTIONS --stringparam addAssociations true"
                                    shift
                                    ;;
      -pl| --package-limit )        shift
                                    OPTIONS="$OPTIONS --stringparam limit $1"
                                    shift
                                    ;;
      -pr|--add-product )           P_ASSOCIATION="true"
                                    shift
                                    ;;
      -k|--packages )               OPTIONS="$OPTIONS --stringparam packages true"
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

  if [[ "$PATHS_TO_DIR" == "" ]]; then
    echo "Paths to model directories is mandatory. Exiting"
    exit 3
  fi

  if [[ "$MODEL_TYPE" == "product" ]]; then
    FILE_SUFFIX=$PRODUCT_FILE_SUFFIX
    CLASS_TAG=$PRODUCT_CLASS_TAG
    if [[ "$P_ASSOCIATION" == "true" ]]; then
        OPTIONS="$OPTIONS --stringparam addPolicyCmptType true"
    fi
  elif [[ "$P_ASSOCIATION" == "true" ]]; then
    OPTIONS="$OPTIONS --stringparam addProductCmptType true"
  fi

  OPTIONS="$OPTIONS --stringparam connector $CONNECTOR"
}

retrieve_files() {
  echo "copying model files..."
  rm -rf $WORKDIR
  mkdir -p $MODEL_DIR

  for path in $PATHS_TO_DIR; do
    clean_path=$(echo "$path" | sed 's|/$||')
    echo "copying $clean_path to $MODEL_DIR"
    cp -r ${clean_path}/* $MODEL_DIR
  done
}

create_collection() {
  echo "creating collection xml..."
  touch $COLLECTION_XML
  echo '<?xml version="1.0" encoding="UTF-8"?>' > $COLLECTION_XML
  echo "<collection>" >> $COLLECTION_XML

  scan_modeldir_rec $MODEL_DIR
  echo "</collection>" >> $COLLECTION_XML
}

scan_modeldir_rec() {
  local basedir=$1
  local subdir=$2
  local prefix=$3

  echo "Basedir: $basedir"
  echo "Subdir: $subdir"
  echo "Prefix: $prefix"

  for file in $basedir/$subdir/*; do
    filename=${file##*/}
    if [[ -d $file ]]; then
      scan_modeldir_rec "$basedir" "$subdir/$filename" "$prefix$filename."
    else
      if [[ "${filename##*.}" = "$FILE_SUFFIX" ]]; then
        class="${prefix}${filename%*.*}"
        echo "Classname: $class"
        cat $file \
          | grep -v "<?xml" \
          |  sed 's/xmlns:xsi=".*"//' \
          |  sed 's|xmlns="http://www.faktorzehn.org"||' \
          |  sed "s/<$CLASS_TAG\(.*\)>/<$CLASS_TAG className=\"$class\"\1>/" \
          >> $COLLECTION_XML
      else
        echo "Skipping $filename"
      fi
    fi
  done
}

execute_xslt() {
  echo "executing xslt..."
  xsltproc $OPTIONS ips2plant.xsl $COLLECTION_XML >> $PUML_RESULT_FILE
}

start_puml() {
  echo "@startuml" > $PUML_RESULT_FILE
  echo "'Created with: $0 $@'" >> $PUML_RESULT_FILE
  echo "hide empty members" >> $PUML_RESULT_FILE
}

end_puml() {
  echo "@enduml" >> $PUML_RESULT_FILE
}

main() {
  args "$@"

  retrieve_files

  create_collection

  start_puml "$@"

  execute_xslt

  end_puml
}

main "$@"
