# Main Script: Run Jython Script For Ontology Dump (via Gemma's JENA)

# ----- Initialize Environment -----
# 1. Bash Settings
unset HISTFILE
export HOME=''
export DATA_CACHE_DIR=''
export SCRIPT_DIR=$HOME/
mkdir -p $DATA_CACHE_DIR/Ontology/
mkdir -p $DATA_CACHE_DIR/Logs/
mkdir -p $DATA_CACHE_DIR/JythonLogs/

# 2. Java Settings
export JAVA_HOME=java-1.8.0
export JAVA_OPTS="-Xmx120g"

# 3. Gemma Settings
export PATH=$PATH
export GEMMA_LIB=''
export GEMMA_USER=''
export GEMMA_PASS=''

# 4. Jython Settings
export CLASSPATH=$CLASSPATH
export JYTHONPATH=$HOME/

# 5. Pyenv Settings
export PYENV_ROOT="$HOME/.pyenv"
export PATH=$PYENV_ROOT/bin:$PATH
eval "$(pyenv init -)"
pyenv shell jython-2.7.1

# ----- Run Scripts -----
# Ontology Tree Dump
export JYTHON_OUT_LOG=$DATA_CACHE_DIR/Logs/Ontology_Dump.LOG
export JYTHON_ERR_LOG=$DATA_CACHE_DIR/JythonLogs/Ontology_Dump.LOG
python -J-Xmx120g $SCRIPT_DIR/Ontology_Dump.py -u $GEMMA_USER -p $GEMMA_PASS 1> $JYTHON_OUT_LOG 2> $JYTHON_ERR_LOG
