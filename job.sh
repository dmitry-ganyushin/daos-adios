#!/bin/bash
#COBALT -q presque
#COBALT -t 60
#COBALT -n 4
module use /soft/storage/daos/modulefiles
module load daos
module use /soft/modulefiles
module load gcc
module load cmake
module load spack
module load libfabric/1.12.1-gcc-10.2.0-k3r6nnt
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/ac.dganyushin/ADIOS2/lib64

mpirun -ppn 1 -f $COBALT_NODEFILE -genvall mkdir -p $DAOS_AGENT_DIR
mpirun -ppn 1 -f $COBALT_NODEFILE -genvall daos_agent -i -o $DAOS_AGENT_CONF -l $DAOS_AGENT_LOG -s ${DAOS_AGENT_DIR} &>/dev/null &
echo "wait for 3 seconds to make sure the daos agent is up..."
sleep 3
echo "daos agent is up!"
#export DAOS_POOL="ea978025-7d14-4af3-b669-04d0cb278d8e"
#export DAOS_POOL=4dd957e5-fc0b-4b76-9569-c7504ea31f0e
#export DAOS_POOL=719fd0ef-1998-4d89-bf4e-06ad5e9c1e35
export DAOS_POOL="51498878-70bc-44c8-996a-3d6c6ba82bbf"
#daos cont destroy pool0 cont0
#cid=$(daos cont create --type POSIX pool0 -l cont0)

cid=$(daos cont create --pool=$DAOS_POOL --type=POSIX)
echo "daos posix container has been created!"
export DAOS_CONT=$(echo $cid | cut -d' ' -f4)
export ADIOS_DAOS_CUUID=$DAOS_CONT
echo $ADIOS_DAOS_CUUID
export ADIOS_DAOS_UUID=$DAOS_POOL
echo $ADIOS_DAOS_UUID
export ADIOS_DAOS_GROUP="daos_server"
echo $ADIOS_DAOS_GROUP

NODES=$(wc -l < "$COBALT_NODEFILE")
for PROC_PER_NODE in 1 2 4 8 16 32 36
do
    mpirun -ppn $PROC_PER_NODE -f $COBALT_NODEFILE -genvall ./adios2_iotest -a 1 -c ./large_inputs.txt -d $NODES $PROC_PER_NODE 1 -w -x ./adios2_config.xml -t
    mpirun -ppn $PROC_PER_NODE -f $COBALT_NODEFILE -genvall ./adios2_iotest -a 2 -c ./large_inputs.txt -d $NODES $PROC_PER_NODE 1 -w -x ./adios2_config.xml -t

    mv "app1_perf.csv" "${NODES}_${PROC_PER_NODE}_write.csv"
    mv "app2_perf.csv" "${NODES}_${PROC_PER_NODE}_read.csv"

done

#daos cont destroy pool0 cont0
mpirun -ppn 1 -f $COBALT_NODEFILE -genvall killall daos_agent
exit
