# Main Script: Run All Python Scripts For GEO Dump

# ----- Initialize Environment -----
# 1. Bash Settings
unset HISTFILE
export HOME=''
export DL_CACHE_DIR=''
export SCRIPT_DIR=$HOME
mkdir -p $DL_CACHE_DIR/GeoData/GSE
mkdir -p $DL_CACHE_DIR/GeoData/Logs

# 2. Python Settings
export PYTHONPATH=$HOME

# 3. Pyenv Settings
export PYENV_ROOT="$HOME/.pyenv"
export PATH=$PYENV_ROOT/bin:$PATH
eval "$(pyenv init -)"
pyenv shell 3.7.5

# ----- Run Scripts -----
# Experiment (GSE) Metadata Dump
export PYTHON_LOG_FILE=$DL_CACHE_DIR/GeoData/Logs/GSE_Dump.LOG
python $SCRIPT_DIR/GSE_Dump.py > $PYTHON_LOG_FILE 2>&1
