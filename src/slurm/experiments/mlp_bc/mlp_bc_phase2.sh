#!/bin/bash
# Converted from Slurm script
source ~/.bashrc
conda activate rail-delay-pred

# Parallel execution wrapper
run_task() {
    export SLURM_ARRAY_TASK_ID=$1
    echo "Running task ID: $SLURM_ARRAY_TASK_ID"
    # #SBATCH --array=0-19
    #YOUR SBATCH ARGS
    # ...
    #YOUR SBATCH ARGS
    
    # source ~/.bashrc # Moved to top
    # conda activate rail-delay-pred # Moved to top
    
    EXPERIMENT_NAME='tuning_phase_2'
    DATA_PATH='data/dataset'
    ITI_PATH='data/itineraries'
    EVAL_CONFIG_PATH='data/eval_configs/cfg.pkl'
    
    LR_ARR=(0.003 0.001 0.0003 0.0001)
    BATCH_SIZE_ARR=(16 32 64 128 256)
    
    HIDDEN_DIMS=(128 256 512 1024 512 256 128)
    
    DROPOUT=0.0
    ACTIVATION='ReLU'
    WEIGHT_DECAY=0.001
    NB_EPOCHS=160
    CHECK_VAL_EVERY_N_EPOCH=4
    NUM_WORKERS=10
    MIN_EPOCHS=20
    PATIENCE=20
    VAL_RATIO=0.003
    
    IDX=${SLURM_ARRAY_TASK_ID}
    NUM_BS=${#BATCH_SIZE_ARR[@]}
    
    LR_IDX=$((IDX / NUM_BS))
    BS_IDX=$((IDX % NUM_BS))
    
    LR=${LR_ARR[$LR_IDX]}
    BATCH_SIZE=${BATCH_SIZE_ARR[$BS_IDX]}
    
    python3 -u -m src.algorithms.bc.mlp_bc \
        "$EXPERIMENT_NAME" \
        "$DATA_PATH" \
        "$ITI_PATH" \
        "$EVAL_CONFIG_PATH" \
        "$DROPOUT" \
        "$ACTIVATION" \
        "$BATCH_SIZE" \
        "$WEIGHT_DECAY" \
        "$LR" \
        "$NB_EPOCHS" \
        "$CHECK_VAL_EVERY_N_EPOCH" \
        "$NUM_WORKERS" \
        "$MIN_EPOCHS" \
        "$PATIENCE" \
        --hidden-dims "${HIDDEN_DIMS[@]}" \
        --val-ratio "$VAL_RATIO" \
        --use-local-features
}

export -f run_task

# Determine number of cores
if command -v nproc &> /dev/null; then
    NPROCS=$(nproc)
    NPROCS=$((NPROCS / 2))
    [ "$NPROCS" -lt 1 ] && NPROCS=1
else
    NPROCS=2
fi

ITEMS=({0..19})
printf "%s\n" "${ITEMS[@]}" | xargs -P "$NPROCS" -I {} bash -c 'run_task "$@"' _ {}