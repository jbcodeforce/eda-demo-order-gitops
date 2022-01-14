#!/bin/bash

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

install_operator() {
### function will create an operator subscription to the openshift-operators
###          namespace for CR use in all namespaces
### parameters:
### $1 - operator name
    echo "#### Install Operator"
    case $1 in
    "openshift-gitops-operator")
        oc apply -k $scriptDir/../gitops-operator 
        ;;
    "openshift-pipelines-operator")
        oc apply -k $scriptDir/../pipeline-operator 
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


# Assess if gitops presents
alreadyDefined=$(oc get -n openshift-operators subscription openshift-gitops-operator | grep NotFound)
if [[ -z "$alreadyDefined" ]]
then
    install_operator openshift-gitops-operator
    wait_operator openshift-gitops-operator
fi

# Assess if pipeline presents
alreadyDefined=$(oc get -n openshift-operators subscription openshift-pipelines-operator | grep NotFound)
if [[ -z "$alreadyDefined" ]]
then
    install_operator openshift-pipelines-operator
    wait_operator openshift-pipelines-operator
fi


