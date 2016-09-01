#!/bin/bash

LOCFG="./locfg.pl"
POWER_ON="./power_on.xml"
POWER_OFF="./power_off.xml"
POWER_STATUS="./power_status.xml"
ILO_USER="ilouser"
ILO_PASS="ilopass"

GREEN="\033[0;32m"
RED="\033[0;31m"
NO_COLOUR="\033[0m"

usage() {
  echo "Usage: power.sh [on|off|status] -l <cluster_name>"
  echo "      -h              help"
  echo "      -l              cluster name (e.g. cluster123)"
  echo ""
  echo "Logfile: ./power.log"
  echo "Cluster file: ./<cluster_name>.txt"
  exit 0
}

power_on() {
  perl ${LOCFG} -s ${1} -f ${POWER_ON} -u ${ILO_USER} -p ${ILO_PASS} >> ./power.log 2>&1 || { echo "ERROR: locfg.pl script failed"; exit 1 ; }
}

power_off() {
  perl ${LOCFG} -s ${1} -f ${POWER_OFF} -u ${ILO_USER} -p ${ILO_PASS} >> ./power.log 2>&1 || { echo "ERROR: locfg.pl script failed"; exit 1 ; }
}

power_status() {
  perl ${LOCFG} -s ${1} -f ${POWER_STATUS} -u ${ILO_USER} -p ${ILO_PASS} 2>&1 |tee -a ./power.log |awk -F = '/HOST_POWER=/{print $2}' |tr -d '"'
  if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    exit 1
  fi
}

labpower() {
  if [[ -f "./${2}.txt" ]]; then
    j=1
    echo "locfg.pl log file" > ./power.log
    echo "Executing power ${1} command for ${2}"

    if [[ "$1" == "status" ]]; then
      for i in $(cat ./${2}.txt); do
        if [[ "$i" =~ ^USER.* ]]; then
          ILO_USER=$(awk -F '=' '{print $2}' <<< ${i})
          continue
        fi
        if [[ "$i" =~ ^PASS.* ]]; then
          ILO_PASS=$(awk -F '=' '{print $2}' <<< ${i})
          continue
        fi
        STATUS=$(power_status $i) || { echo "ERROR: locfg.pl script failed"; exit 1 ; }
        echo -n "Power status of host ${j} (ILO ${i}) is    "
        if [[ ${STATUS} == "ON" ]]; then
          echo -e "[${GREEN}${STATUS}${NO_COLOUR}]"
        elif [[ ${STATUS} == "OFF" ]]; then
          echo -e "[${RED}${STATUS}${NO_COLOUR}]"
        else
          echo -e "[${RED}UNKNOWN${NO_COLOUR}]"
        fi
        ((j++))
      done
    else
      for i in $(cat ./${2}.txt); do
        if [[ "$i" =~ ^USER.* ]]; then
          ILO_USER=$(awk -F '=' '{print $2}' <<< ${i})
          continue
        fi
        if [[ "$i" =~ ^PASS.* ]]; then
          ILO_PASS=$(awk -F '=' '{print $2}' <<< ${i})
          continue
        fi
        echo "Powering ${1} host ${j} through ILO (${i})"
        power_$1 $i
        ((j++))
      done
    fi
  else
    echo "ERROR: Unknown cluster \"${2}\""
    exit 1
  fi
  exit 0
}

if [[ ! -f ${LOCFG} ]] || [[ ! -f ${POWER_ON} ]] || [[ ! -f ${POWER_OFF} ]]; then
  echo "ERROR: Check existence of needed files:"
  echo "       ./locfg.pl"
  echo "       ./power_on.xml"
  echo "       ./power_off.xml"
  exit 1
fi

if [[ "$1" == "on" || "$1" == "off" || "$1" == "status" ]]; then
  if [[ "$2" == "-l" ]]; then
    if [[ -n "$3" ]]; then
      labpower $1 $3
    else
      echo "ERROR: Unknown command, try option -h"
      exit 1
    fi
  else
    echo "ERROR: Unknown command, try option -h"
    exit 1
  fi
elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
else
  echo "ERROR: Unknown command, try option -h"
  exit 1
fi
