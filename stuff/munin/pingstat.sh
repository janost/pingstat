#!/bin/bash

PARAMS=${0#*pingstat_}
GRAPHTYPE=$(echo "$PARAMS" | cut -d _ -f 1)
TARGET=$(echo "$PARAMS" | cut -d _ -f 2)
# TODO: move these to configuration
PING_LAST_SECONDS=300
PINGSTAT_BASEURL="http://localhost:8000"
#
PING_MIN_WARNING=25
PING_MIN_CRITICAL=50
PING_AVG_WARNING=25
PING_AVG_CRITICAL=50
PING_MAX_WARNING=100
PING_MAX_CRITICAL=200

case $GRAPHTYPE in
  ping)
    if [ "$1" == "config" ]; then
      echo "graph_title Ping time - ${TARGET}, ${PING_LAST_SECONDS} sec"
      echo "graph_vlabel ms"
      echo "graph_info Ping time - ${TARGET}, ${PING_LAST_SECONDS} sec"
      echo "graph_category ping"
      echo "graph_args -l 0"
      echo "graph_scale no"
      echo "pavg.label Average ping"
      echo "pavg.warning ${PING_AVG_WARNING}"
      echo "pavg.critical ${PING_AVG_CRITICAL}"
      echo "pavg.info Average ping to ${TARGET}, ${PING_LAST_SECONDS} sec"
      echo "pmin.label Minimum ping"
      echo "pmin.warning ${PING_MIN_WARNING}"
      echo "pmin.critical ${PING_MIN_CRITICAL}"
      echo "pmin.info Minimum ping to ${TARGET}, ${PING_LAST_SECONDS} sec"
      echo "pmax.label Maximum ping"
      echo "pmax.warning ${PING_MAX_WARNING}"
      echo "pmax.critical ${PING_MAX_CRITICAL}"
      echo "pmax.info Maximum ping to ${TARGET}, ${PING_LAST_SECONDS} sec"
      echo "p99.label 99th percentile"
      echo "p99.warning ${PING_MAX_WARNING}"
      echo "p99.critical ${PING_MAX_CRITICAL}"
      echo "p99.info 99th percentile ping to ${TARGET}, ${PING_LAST_SECONDS} sec"
      echo "p98.label 98th percentile"
      echo "p98.warning ${PING_MAX_WARNING}"
      echo "p98.critical ${PING_MAX_CRITICAL}"
      echo "p98.info 98th percentile ping to ${TARGET}, ${PING_LAST_SECONDS} sec"
      echo "p97.label 97th percentile"
      echo "p97.warning ${PING_MAX_WARNING}"
      echo "p97.critical ${PING_MAX_CRITICAL}"
      echo "p97.info 97th percentile ping to ${TARGET}, ${PING_LAST_SECONDS} sec"
      echo "p96.label 96th percentile"
      echo "p96.warning ${PING_MAX_WARNING}"
      echo "p96.critical ${PING_MAX_CRITICAL}"
      echo "p96.info 96th percentile ping to ${TARGET}, ${PING_LAST_SECONDS} sec"
      echo "p95.label 95th percentile"
      echo "p95.warning ${PING_AVG_WARNING}"
      echo "p95.critical ${PING_AVG_CRITICAL}"
      echo "p95.info 95th percentile ping to ${TARGET}, ${PING_LAST_SECONDS} sec"
      echo "p90.label 90th percentile"
      echo "p90.warning ${PING_AVG_WARNING}"
      echo "p90.critical ${PING_AVG_CRITICAL}"
      echo "p90.info 90th percentile ping to ${TARGET}, ${PING_LAST_SECONDS} sec"
      echo "p50.label 50th percentile"
      echo "p50.warning ${PING_MIN_WARNING}"
      echo "p50.critical ${PING_MIN_CRITICAL}"
      echo "p50.info 50th percentile ping to ${TARGET}, ${PING_LAST_SECONDS} sec"
      exit 0
    fi

    JDATA=$(curl -H "Content-type: application/json" -H "Accept: application/json" ${PINGSTAT_BASEURL}/last/${PING_LAST_SECONDS})

    printf "pavg.value "
    printf "%.2f" $(echo ${JDATA} | jq ".[] | select(.target==\"${TARGET}\")[\"avg_ms\"]" | bc -l)
    echo
    printf "pmin.value "
    printf "%.2f" $(echo ${JDATA} | jq ".[] | select(.target==\"${TARGET}\")[\"min_ms\"]" | bc -l)
    echo
    printf "pmax.value "
    printf "%.2f" $(echo ${JDATA} | jq ".[] | select(.target==\"${TARGET}\")[\"max_ms\"]" | bc -l)
    echo
    printf "p50.value "
    printf "%.2f" $(echo ${JDATA} | jq ".[] | select(.target==\"${TARGET}\")[\"perc_50th\"]" | bc -l)
    echo
    printf "p90.value "
    printf "%.2f" $(echo ${JDATA} | jq ".[] | select(.target==\"${TARGET}\")[\"perc_90th\"]" | bc -l)
    echo
    printf "p95.value "
    printf "%.2f" $(echo ${JDATA} | jq ".[] | select(.target==\"${TARGET}\")[\"perc_95th\"]" | bc -l)
    echo
    printf "p96.value "
    printf "%.2f" $(echo ${JDATA} | jq ".[] | select(.target==\"${TARGET}\")[\"perc_96th\"]" | bc -l)
    echo
    printf "p97.value "
    printf "%.2f" $(echo ${JDATA} | jq ".[] | select(.target==\"${TARGET}\")[\"perc_97th\"]" | bc -l)
    echo
    printf "p98.value "
    printf "%.2f" $(echo ${JDATA} | jq ".[] | select(.target==\"${TARGET}\")[\"perc_98th\"]" | bc -l)
    echo
    printf "p99.value "
    printf "%.2f" $(echo ${JDATA} | jq ".[] | select(.target==\"${TARGET}\")[\"perc_99th\"]" | bc -l)
    echo
  ;;

  count)
    if [ "$1" == "config" ]; then
      echo "graph_title Ping count - ${TARGET}, ${PING_LAST_SECONDS} sec"
      echo "graph_vlabel Number of pings"
      echo "graph_info Ping count - ${TARGET}, ${PING_LAST_SECONDS} sec"
      echo "graph_category ping"
      echo "graph_args -l 0"
      echo "graph_scale no"
      echo "psucc.label Successful pings"
      echo "psucc.info Successful pings to ${TARGET}, ${PING_LAST_SECONDS} sec"
      echo "pfail.label Failed pings"
      echo "pfail.info Failed pings to ${TARGET}, ${PING_LAST_SECONDS} sec"
      exit 0
    fi

    JDATA=$(curl -H "Content-type: application/json" -H "Accept: application/json" ${PINGSTAT_BASEURL}/last/${PING_LAST_SECONDS})

    printf "psucc.value "
    printf "%.2f" $(echo ${JDATA} | jq ".[] | select(.target==\"${TARGET}\")[\"success_count\"]" | bc -l)
    echo
    printf "pfail.value "
    printf "%.2f" $(echo ${JDATA} | jq ".[] | select(.target==\"${TARGET}\")[\"failed_count\"]" | bc -l)
    echo
  ;;

  loss)
    if [ "$1" == "config" ]; then
      echo "graph_title Packet loss - ${TARGET}, ${PING_LAST_SECONDS} sec"
      echo "graph_vlabel percent"
      echo "graph_info Packet loss - ${TARGET}, ${PING_LAST_SECONDS} sec"
      echo "graph_category ping"
      echo "graph_args -l 0"
      echo "graph_scale no"
      echo "ploss.label Packet loss"
      echo "ploss.warning 1"
      echo "ploss.critical 5"
      echo "ploss.info Packet loss to ${TARGET}, ${PING_LAST_SECONDS} sec"
      exit 0
    fi

    JDATA=$(curl -H "Content-type: application/json" -H "Accept: application/json" ${PINGSTAT_BASEURL}/last/${PING_LAST_SECONDS})

    printf "ploss.value "
    printf "%.2f" $(echo ${JDATA} | jq ".[] | select(.target==\"${TARGET}\")[\"failed_percent\"]" | bc -l)
    echo
  ;;
esac
