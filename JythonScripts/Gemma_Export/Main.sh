# Main Script: Run All Scripts For Gemma Paper Work

# ----- Initialize Environment -----
# 1. Bash Settings
mkdir -p $HOME/Output/
mkdir -p $HOME/Logs/
export SCRIPT_DIR=$HOME/
export OUT_DIR=$HOME/Output/
export GENE_DIR=$OUT_DIR/Dependencies/
export LOG_DIR=$HOME/Logs/
export AUTO_JYTHON=''

# ----- Run Jython Scripts -----

if [ "$#" == "0" ]; then
  echo "USAGE: Main.sh -[1-5]; Option List:"
  echo "1 = Experiments"
  echo "2 = Platforms"
  echo "3 = Genes"
  echo "4 = Experiment Tags"
  echo "5 = Blacklists"
fi

while getopts "12345" OPT_STRING; do
  case "${OPT_STRING}" in
    1)
      echo "Case 1: Experiments"
      OUT_LOG=$LOG_DIR/EE_Export.LOG
      $AUTO_JYTHON $SCRIPT_DIR/EE_Export.py -u $GEMMA_USER -p $GEMMA_PASS 1> $OUT_LOG
    ;;

    2)
      echo "Case 2: Platforms"
      OUT_LOG=$LOG_DIR/AD_Export.LOG
      $AUTO_JYTHON $SCRIPT_DIR/AD_Export.py -u $GEMMA_USER -p $GEMMA_PASS 1> $OUT_LOG
    ;;

    3)
      echo "Case 3: Genes"
      OUT_LOG=$LOG_DIR/Gene_Export.LOG
      $AUTO_JYTHON $SCRIPT_DIR/Gene_Export.py -u $GEMMA_USER -p $GEMMA_PASS 1> $OUT_LOG
    ;;

    4)
      echo "Case 4: Experimental Tags"
      OUT_LOG=$LOG_DIR/EETag_Export.LOG
      $AUTO_JYTHON $SCRIPT_DIR/EETag_Export.py -u $GEMMA_USER -p $GEMMA_PASS 1> $OUT_LOG
    ;;

    5)
      echo "Case 5: Blacklists"
      OUT_LOG=$LOG_DIR/BL_Export.LOG
      $AUTO_JYTHON $SCRIPT_DIR/BL_Export.py -u $GEMMA_USER -p $GEMMA_PASS 1> $OUT_LOG
    ;;

    *)
    ;;

  esac
done

exit 0
