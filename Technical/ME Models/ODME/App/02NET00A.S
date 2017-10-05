;;<<Default Template>><<NETWORK>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=NETWORK PRNFILE="M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Scripts\Cube_Analyst\ODME\App\02NET00A.PRN" MSG='Remove EL Links'
FILEO NETO = "{SCENARIO_DIR}\Output\Subarea_{ALT}{YEAR}_@HR@.net"
FILEI LINKI[1] = "{SCENARIO_DIR}\Output\User_Defined_SA_ver4.net"

PROCESS PHASE=LINKMERGE  

; Delete EL Links (along with ingress, egress to EL from GU)
IF (LI.1.FTYPE == 96 || LI.1.FTYPE == 97 || LI.1.FTYPE == 98 ) DELETE

ENDPROCESS

ENDRUN
