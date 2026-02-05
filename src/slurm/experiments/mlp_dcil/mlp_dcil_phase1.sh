#!/bin/bash
# Converted from Slurm script
source ~/.bashrc
conda activate rail-delay-pred

# Parallel execution wrapper
run_task() {
    export SLURM_ARRAY_TASK_ID=$1
    echo "Running task ID: $SLURM_ARRAY_TASK_ID"
    # #SBATCH --array=0-23
    #YOUR SBATCH ARGS
    # ...
    #YOUR SBATCH ARGS
    
    # source ~/.bashrc # Moved to top
    # conda activate rail-delay-pred # Moved to top
    
    EXPERIMENT_NAME='tuning_phase_1'
    DATA_PATH='data/dataset'
    ITINERARIES_PATH='data/itineraries'
    EVAL_CONFIG_PATH='data/eval_configs/cfg.pkl'
    DROPOUT=0.0
    ACTIVATION='ReLU'
    
    TRAJ_LEN=10
    SIM_BATCH_SIZE=100
    BUFFER_CAPACITY=30000
    NEW_SAMPLES_PER_EPOCH=10000
    
    NB_EPOCHS=1500
    ALPHA=0.5
    BETA=2.0
    
    BATCH_SIZE=32
    WEIGHT_DECAY=0.001
    
    CHECK_VAL_EVERY_N_EPOCH=10
    NUM_WORKERS=10
    MIN_EPOCHS=500
    PATIENCE=50
    VAL_RATIO=0.003
    
    HIDDEN_DIMS_ARR=(
        "64 128 256 128 64"
        "128 256 128"
        "128 256 512 256 128"
        "128 512 128"
        "128 256 512 1024 512 256 128"
        "256 512 1024 512 256"
        "256 512 1024 2048 1024 512 256"
        "512 1024 2048 1024 512"
    )
    LR_ARR=(0.001 0.0005 0.0001)
    
    IDX=$SLURM_ARRAY_TASK_ID
    HID_IDX=$((IDX / 3))
    LR_IDX=$((IDX % 3))
    
    HIDDEN_DIMS=${HIDDEN_DIMS_ARR[$HID_IDX]}
    LR=${LR_ARR[$LR_IDX]}
    
    python3 -u -m src.algorithms.dcil.mlp_dcil \
        "$EXPERIMENT_NAME" \
        "$DATA_PATH" \
        "$ITINERARIES_PATH" \
        "$EVAL_CONFIG_PATH" \
        "$DROPOUT" \
        "$ACTIVATION" \
        "$TRAJ_LEN" \
        "$SIM_BATCH_SIZE" \
        "$BUFFER_CAPACITY" \
        "$NEW_SAMPLES_PER_EPOCH" \
        "$NB_EPOCHS" \
        "$ALPHA" \
        "$BETA" \
        "$BATCH_SIZE" \
        "$LR" \
        "$WEIGHT_DECAY" \
        "$CHECK_VAL_EVERY_N_EPOCH" \
        "$NUM_WORKERS" \
        "$MIN_EPOCHS" \
        "$PATIENCE" \
        --hidden-dims $HIDDEN_DIMS \
        --val-ratio $VAL_RATIO \
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

ITEMS=({0..23})
printf "%s\n" "${ITEMS[@]}" | xargs -P "$NPROCS" -I {} bash -c 'run_task "$@"' _ {}