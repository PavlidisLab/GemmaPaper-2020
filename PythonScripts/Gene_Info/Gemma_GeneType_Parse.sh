# Main Script: Run All Python Scripts For Gene Information

# ----- Initialize Environment -----
# 1. Bash Settings
export IN_DIR=''
export SCRIPT_DIR=$HOME
export OUT_DIR=$HOME/Output/Dependencies/
mkdir -p $OUT_DIR/GeneType/

# ----- Run Scripts -----
# 1. File Existence Check
cd $IN_DIR
if [ -f "gene_info" ]; then
    :
else
    exit 1
fi

# 2. Gene Information Parsing
# [A] Gene Type Dictionary and Table
python $SCRIPT_DIR/Gemma_GeneType_Parse.py