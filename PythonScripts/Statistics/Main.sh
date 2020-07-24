# Main Script: Run All Scripts For Gemma Paper Work

# ----- Initialize Environment -----
# 1. Bash Settings
mkdir -p $HOME/Output/
mkdir -p $HOME/Logs/
export SCRIPT_DIR=$HOME/
export OUT_DIR=$HOME/Output/
export LOG_DIR=$HOME/Logs/
export DL_CACHE_DIR=''

# ----- Run Jython Scripts -----
# 1. GXA Experiment Information
export OUT_LOG=$LOG_DIR/GXA_Stats.LOG
python $SCRIPT_DIR/GXA_Stats.py 1> $OUT_LOG 2>&1

# 2. GEO Experiment Information
export OUT_LOG=$LOG_DIR/GSE_Stats.LOG
python $SCRIPT_DIR/GSE_Stats.py 1> $OUT_LOG 2>&1
