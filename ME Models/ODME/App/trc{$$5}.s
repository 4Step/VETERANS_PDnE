; Script for program MATRIX in file "M:\PROJECTS\VETERANS ELTODV2.3 2017-0628_PDNE\SCRIPTS\CUBE_ANALYST\ODME\APP\02MAT00E.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX
FILEI MATI[4] = "{SCENARIO_DIR}\Input\Subarea_D6HWY80A_PMPK.MAT"
FILEI MATI[3] = "{SCENARIO_DIR}\Input\Subarea_D6HWY80A_MDOP.MAT"
FILEI MATI[2] = "{SCENARIO_DIR}\Input\Subarea_D6HWY80A_EVOP.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\Input\Subarea_D6HWY80A_AMPK.MAT"
FILEO MATO[1] = "{SCENARIO_DIR}\Output\TBRPM_Subarea_OD.MAT",
 MO = 1, NAME = TOTAL

MW[1] = (Mi.1.1.T + Mi.2.1.T + Mi.3.1.T + Mi.4.1.T) * 0.25

ENDRUN


