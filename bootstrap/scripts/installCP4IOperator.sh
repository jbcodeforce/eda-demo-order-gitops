#!/bin/bash

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


install_operator() {
### function to create operator subscription
###          namespace for CR use in all namespaces
### parameters:
### $1 - operator name
    echo "#### Install Operator"
    case $1 in
    "ibm-eventstreams")
        oc apply -k $scriptDir/../ibm-eventstreams
        ;;
    *)
        echo operator not supported
        exit
    esac
}

wait_operator() {
echo "Waiting for operator $1 to be deployed..."
counter=0
desired_state="AtLatestKnown"
until [[ ("$(oc get -n openshift-operators subscription $1 -o jsonpath="{.status.state}")" == "${desired_state}") || ( ${counter} == 60 ) ]]
do
  ((counter++))
  echo -n "..."
  sleep 5
done
if [[ ${counter} == 60 ]]
then
  echo
  echo "[ERROR] - Timeout occurred while deploying the Operator"
  exit 1
else
  echo "Done"
fi
}


case $1 in
  "ibm-eventstreams")
      OPERATOR=ibm-eventstreams
      ;;
  *)
      echo operator not supported
      exit
  esac
  
# Assess if  presents
alreadyDefined=$(oc get -n openshift-operators subscription ${OPERATOR} | grep NotFound)
if [[ -n "$alreadyDefined" ]]
then
    install_operator ${OPERATOR}
    wait_operator ${OPERATOR}
else
   echo "Operator ${OPERATOR} already installed"
fi
