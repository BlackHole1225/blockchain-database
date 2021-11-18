#!/bin/bash

TSTAMP=`date +%F-%H-%M-%S`
LOGSD="logs-clients-blockchaindb-$TSTAMP"
mkdir $LOGSD

set -x

size=${1:-4}
clients=${2:-4} 
workload=${3:-a}
distribution=${4:-ycsb_data}
ndrivers=${size}
nthreads=$(( ${clients} / ${ndrivers} ))
    
dir=$(pwd)
echo $dir
bin="$dir/../BlockchainDB/.bin/benchmark_bcdb"
defaultAddrs="192.168.20.2:50001"
loadPath="$dir/../temp/${distribution}/workload${workload}.dat"
runPath="$dir/../temp/${distribution}/run_workload${workload}.dat"

if [ ! -f ${bin} ]; then
    echo "Binary file ${bin} not found!"
    echo "Hint: "
    echo " Please build binaries by run command: make build "
    echo "exit 1 "
    exit 1
fi

for (( c=2; c<=${size}; c++ ))
do 
defaultAddrs="${defaultAddrs},192.168.20.$((1+ ${c})):50001"
done
echo "start test with bcdbnode addrs: ${defaultAddrs}"


nDURATIONS="1 5 10 15"
nGASLIMITS="10000000 100000000"
for GAS in $nGASLIMITS; do
    for TH in $nDURATIONS; do
        echo "Test start with node size: ${size}, client size: ${clients}, workload${workload}"
        ./restart_cluster_blockchaindb.sh
        ./start_blockchaindb.sh ${size} ${TH} ${GAS}
        sleep 6
        $bin --load-path=$loadPath --run-path=$runPath --ndrivers=$ndrivers --nthreads=$nthreads --server-addrs=${defaultAddrs} 2>&1 | tee $LOGSD/blockchaindb-blk-duration-${GAS}-${TH}.txt
    done
done
./restart_cluster_blockchaindb.sh
