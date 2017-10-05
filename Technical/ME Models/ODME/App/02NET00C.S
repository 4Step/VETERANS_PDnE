; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=NETWORK PRNFILE="M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Scripts\Cube_Analyst\ODME\App\02NET00C.PRN" MSG='Profile Summary'
FILEO NETO = "{SCENARIO_DIR}\output\Loaded Network @HR@.NET"
FILEO PRINTO[1] = "{SCENARIO_DIR}\Output\POST_ME_{ALT}{YEAR}.CSV"
FILEI LINKI[1] = "{SCENARIO_DIR}\output\FINAL_HWYLOAD_AM_{ALT}{YEAR}_@HR@.NET"

  ;Print Header
  _Cnt=_Cnt+1

  IF (_CNT=1)
    PRINT CSV=T LIST='A,B,SCREENLINE,COUNT,ESTVOL,V/C' PRINTO=1
  ENDIF

  IF (li.1.{count_field}>0)
    VC=V_25/{count_field}
  ENDIF
  
  IF (li.1.{count_field}>0)
    PRINT CSV=T LIST=A,B,LOC,{count_field},V_25(10.0),VC,PRINTO=1
  ENDIF

ENDRUN
