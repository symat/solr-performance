#!/bin/bash

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [ $# -ne 2 ]; then
        echo ""
        echo "Usage: ./run_banchmark.sh <number-of-threads> <operations-per-thread>"
        echo ""
        echo "- make sure you kinit before starting the benchmark"
        echo ""
        echo "- also please set the following environment variables: "
        echo "    export KNOX_HOST='solr-cluster-leader0.solr-kno.xcu2-8y8x.dev.cldr.work'"
        echo "    export SOLR_WORKER_HOST='solr-cluster-worker0.solr-kno.xcu2-8y8x.dev.cldr.work'"
        echo "    export KNOX_AUTH='user:password'"
        echo ""
        echo "- the following variables are optional, if you want to reply the cookies"
        echo "  sent back after the first curl operation (to set auth tokens)"
        echo "    export KNOX_COOKIE_PATH=./cookies.knox.txt"
        echo "    export SOLR_COOKIE_PATH=./cookies.solr.txt"
        exit 1
fi

THREADS=$1
OPS=$2


if [ -z "$KNOX_HOST" ]; then
        echo "please set KNOX_HOST environment variable!"
        exit 1
fi

if [ -z "$SOLR_WORKER_HOST" ]; then
        echo "please set SOLR_WORKER_HOST environment variable!"
        exit 1
fi

if [ -z "$KNOX_AUTH" ]; then
        echo "please set KNOX_AUTH environment variable!"
        exit 1
fi



function run_single_thread {
        CURRENT_THREAD=$1
        USE_KNOX=$2
        echo "starting thread ${CURRENT_THREAD}/${THREADS}, executing ${OPS} Solr operations"
        for ((i=1; i<=OPS; i++)); do
           ${COMMAND} -s 2>&1 >> /dev/null
           ECODE=$?
           if [ "${ECODE}" -ne "0" ]; then
                echo "error! command failed with exit code: ${ECODE}"
                echo "${COMMAND}"
                exit 1
           fi
        done
}


function run_threads {
        USE_KNOX=$1

        START_MILLIS=`date +%s%N | cut -b1-13`
        for ((i=1; i<=THREADS; i++)); do
             run_single_thread ${i} ${USE_KNOX} &
        done
        wait

        END_MILLIS=`date +%s%N | cut -b1-13`
        TOTAL_MILLIS=$((END_MILLIS-START_MILLIS))
        TOTAL_SEC=$((TOTAL_MILLIS / 1000))
        NUMBER_OF_OPS=$((THREADS*OPS))
        AVG_RESP_TIME_MS=$((TOTAL_MILLIS/OPS))
        OPS_PER_SEC=$((NUMBER_OF_OPS / TOTAL_SEC))

        echo ""
        echo "Run time: ${TOTAL_MILLIS} ms"
        echo "Number of threads: ${THREADS}"
        echo "Number of operations per thread: ${OPS}"
        echo "Total number of operations: ${NUMBER_OF_OPS}"
        echo "Average response time: ${AVG_RESP_TIME_MS} ms"
        echo "Throughput: ${OPS_PER_SEC} ops/sec"
}


echo ""
echo ""
echo "================================================"
echo "executing Solr queries directly, without knox:"
echo "================================================"
echo ""
echo ""

export COMMAND="curl -k --negotiate -u : https://${SOLR_WORKER_HOST}:8985/solr/books/select?q=*:*"

if [ -n "${SOLR_COOKIE_PATH}" ]; then
        echo "using file to store cookies: ${SOLR_COOKIE_PATH}"
        rm -f ${SOLR_COOKIE_PATH}
        COMMAND="${COMMAND} --cookie-jar ${SOLR_COOKIE_PATH} --cookie ${SOLR_COOKIE_PATH}"
fi
echo "using command:"
echo "${COMMAND}"
echo ""

run_threads 0


echo ""
echo ""
echo "================================================"
echo "executing Solr queries using knox:"
echo "================================================"
echo ""
echo ""

export COMMAND="curl -ik --user ${KNOX_AUTH} https://${KNOX_HOST}/solr-cluster/cdp-proxy-api/solr/books/select?q=*:*"

if [ -n "${KNOX_COOKIE_PATH}" ]; then
        echo "using file to store cookies: ${KNOX_COOKIE_PATH}"
        rm -f ${KNOX_COOKIE_PATH}
        COMMAND="${COMMAND} --cookie-jar ${KNOX_COOKIE_PATH} --cookie ${KNOX_COOKIE_PATH}"
fi
echo "using command:"
echo "${COMMAND}"
echo ""

run_threads 1
