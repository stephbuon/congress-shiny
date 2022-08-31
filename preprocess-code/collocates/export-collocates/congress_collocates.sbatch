#!/bin/bash
#SBATCH -J collocates
#SBATCH -o collocates_%A-%a.out
#SBATCH --array=1-19999
#SBATCH -c 1
#SBATCH --mem=6G
#SBATCH -p htc,standard-mem-s,standard-mem-m,standard-mem-l,medium-mem-1-s,medium-mem-2,medium-mem-1-m,high-mem-1,high-mem-2

module purge
module load python

input_file="congress_app_data.csv"
py_script="congress_collocates.py"

work_directory="${SLURM_JOB_NAME}_${SLURM_ARRAY_JOB_ID}"
csv_chunk=$(printf "/dev/shm/csv_chunk.%d.%05d" ${SLURM_ARRAY_JOB_ID} ${SLURM_ARRAY_TASK_ID})
if [ ${SLURM_ARRAY_TASK_ID} -eq ${SLURM_ARRAY_TASK_MIN} ]; then
    mkdir -p ${work_directory}
    cd ${work_directory}
    cp ../${py_script} .
    tail -n +2 ../${input_file} > csv_no_header.csv
    head -1 ../${input_file} > csv_header
    touch no_header_done
else
    while [ ! -f ${work_directory}/no_header_done ]; do
       sleep 5
    done
    cd ${work_directory}
fi
cat csv_header \
    <(split --number=l/${SLURM_ARRAY_TASK_ID}/${SLURM_ARRAY_TASK_COUNT} \
            csv_no_header.csv) \
    > ${csv_chunk}

python ${py_script} ${csv_chunk} ${SLURM_ARRAY_TASK_ID}

rm ${csv_chunk}
