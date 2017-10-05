;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX
FILEO MATO[1] = "{SCENARIO_DIR}\Output\Trip Table @HR@.MAT",
 MO = 1-3, NAME = SOV, HOV, TRK
FILEI MATI[1] = "{SCENARIO_DIR}\Output\EstimatedSta_{ALT}{YEAR}.MAT"

MW[1] = MI.1.1

ENDRUN
