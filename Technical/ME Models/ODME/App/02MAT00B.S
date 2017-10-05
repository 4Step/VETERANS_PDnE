;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Scripts\Cube_Analyst\ODME\App\02MAT00B.PRN" MSG='Develop input matrix for Assignment'
FILEO MATO[1] = "{SCENARIO_DIR}\Output\MAT_LOOP_{ALT}{YEAR}.MAT",
  MO=1-3 NAME=  ANALYST_OUT, ANALYST_IN, TOTAL
FILEI MATI[3] = "{SCENARIO_DIR}\Output\DemandAndConf_{ALT}{YEAR}.MAT"
FILEI MATI[2] = "{SCENARIO_DIR}\Output\Seed_ODFlows_{ALT}{YEAR}.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\Output\EstimatedSta_{ALT}{YEAR}.MAT"

MW[1] = MI.1.1 ; Analyst out
MW[2] = MI.3.1 ; Analyst in
MW[3] = MI.2.1 ; Seed trips

ENDRUN
