; Script for program NETWORK in file "M:\PROJECTS\VETERANS ELTODV2.3 2017-0628_PDNE\SCRIPTS\CUBE_ANALYST\ODME\APP\02NET00E.S"
;;<<Default Template>><<NETWORK>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=NETWORK MSG='Add Dir to NET'
FILEO NETO = "{SCENARIO_DIR}\Output\User_Defined_SA_ver4.net"
FILEI LINKI[2] = "{SCENARIO_DIR}\Input\Profile_Counts_Dir_v2.dbf"
FILEI LINKI[1] = "{SCENARIO_DIR}\Input\User_Defined_SA_ver4.net"

ENDRUN


