#!/bin/bash
# Converted from Slurm script
source ~/.bashrc
conda activate rail-delay-pred

# Parallel execution wrapper
run_task() {
    export SLURM_ARRAY_TASK_ID=$1
    echo "Running task ID: $SLURM_ARRAY_TASK_ID"
    # #SBATCH --array=0-9
    #YOUR SBATCH ARGS
    # ...
    #YOUR SBATCH ARGS
    
    # source ~/.bashrc # Moved to top
    # conda activate rail-delay-pred # Moved to top
    
    EXPERIMENT_NAME='final'
    DATA_PATH='data/dataset'
    ITINERARIES_PATH='data/itineraries'
    EVAL_CONFIG_PATH='data/eval_configs/cfg.pkl'
    
    N_WORKERS=10
    TRAIN_RATIO=0.1
    VAL_RATIO=0.1
    
    MAX_DEPTH=13
    MIN_CHILD_WEIGHT=5.0
    SUBSAMPLE=1.0
    COLSAMPLE=0.8
    GAMMA=1.0
    
    LEARNING_RATE=0.04
    N_ESTIMATORS=1600
    REG_ALPHA=0.3
    REG_LAMBDA=1.0
    SEED=$SLURM_ARRAY_TASK_ID
    
    python3 -u -m src.algorithms.bc.xgboost_bc \
        "$EXPERIMENT_NAME" \
        "$DATA_PATH" \
        "$ITINERARIES_PATH" \
        "$EVAL_CONFIG_PATH" \
        "$N_WORKERS" \
        "$N_ESTIMATORS" \
        "$MAX_DEPTH" \
        "$LEARNING_RATE" \
        "$SUBSAMPLE" \
        "$COLSAMPLE" \
        "$MIN_CHILD_WEIGHT" \
        "$GAMMA" \
        "$REG_ALPHA" \
        "$REG_LAMBDA" \
        --train-ratio $TRAIN_RATIO \
        --val-ratio $VAL_RATIO \
        --eval-test \
        --seed "$SEED"
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

ITEMS=({0..9})
printf "%s\n" "${ITEMS[@]}" | xargs -P "$NPROCS" -I {} bash -c 'run_task "$@"' _ {}