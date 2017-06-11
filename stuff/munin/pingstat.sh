#!/bin/bash

PARAMS=${0#*pingstat_}
GRAPHTYPE=$(echo "$PARAMS" | cut -d _ -f 1)
TARGET=$(echo "$PARAMS" | cut -d _ -f 2)

case $GRAPHTYPE in
  ping)
    if [ "$1" == "config" ]; then
      echo graph_title Ping time - ${TARGET}
      echo graph_vlabel ms
      echo graph_info Ping time - ${TARGET}
      echo graph_category network
      echo graph_args -l 0
      echo graph_scale no
      echo pavg.label Average ping
      echo pavg.warning 25
      echo pavg.critical 50
      echo pavg.info Average ping to ${TARGET}
      echo pmin.label Minimum ping
      echo pmin.warning 25
      echo pmin.critical 50
      echo pmax.info Minimum ping to ${TARGET}
      echo pmax.label Maximum ping
      echo pmax.warning 100
      echo pmax.critical 200
      echo pmax.info Maximum ping to ${TARGET}
      exit 0
    fi

    JDATA=$(curl -H "Content-type: application/json" -H "Accept: application/json" http://localhost:8000/last/5)

    printf "pavg.value "
    printf "%.2f" $(echo ${JDATA} | jq ".[] | select(.target==\"${TARGET}\")[\"avg_ms\"]" | bc -l)
    echo
    printf "pmin.value "
    printf "%.2f" $(echo ${JDATA} | jq ".[] | select(.target==\"${TARGET}\")[\"min_ms\"]" | bc -l)
    echo
    printf "pmax.value "
    printf "%.2f" $(echo ${JDATA} | jq ".[] | select(.target==\"${TARGET}\")[\"max_ms\"]" | bc -l)
    echo
  ;;

  loss)
    if [ "$1" == "config" ]; then
      echo graph_title Packet loss - ${TARGET}
      echo graph_vlabel percent
      echo graph_info Packet loss - ${TARGET}
      echo graph_category network
      echo graph_args -l 0
      echo graph_scale no
      echo ploss.label Packet loss
      echo ploss.warning 1
      echo ploss.critical 5
      echo ploss.info Packet loss to ${TARGET}
      exit 0
    fi

    JDATA=$(curl -H "Content-type: application/json" -H "Accept: application/json" http://localhost:8000/last/5)

    printf "ploss.value "
    printf "%.2f" $(echo ${JDATA} | jq ".[] | select(.target==\"${TARGET}\")[\"failed_percent\"]" | bc -l)
    echo
  ;;
esac
