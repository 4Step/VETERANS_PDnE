;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX PRNFILE="M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Scripts\Cube_Analyst\ODME\App\02MAT00A.PRN" MSG='Set Up OD Matrix with Confidence'
FILEO PRINTO[1] = "{SCENARIO_DIR}\Output\CarsTripEnds_{ALT}{YEAR}.DAT"
FILEO MATO[1] = "{SCENARIO_DIR}\Output\DemandAndConf_{ALT}{YEAR}.MAT",
   MO=1,2 NAME=TRIPS,CONF
FILEI MATI[1] = "{SCENARIO_DIR}\Output\Seed_ODFlows_{ALT}{YEAR}.MAT"

MW[1]=mi.1.1
MW[2]=1 ; ADD KEY
MW[3]=mi.1.1.t 

prod1=rowsum(1) 
attr1=rowsum(3) 

conf_p={CLP}
conf_a={CLA}
prod2=0
prod3=0


print list=i(10.0),prod1(10.2),prod2(10.0),prod3(10.0),attr1(10.2),conf_p(10.0),conf_a(10.0), printo=1
;print form=10.0,list=i,prod,attr,conf_p,conf_a printo=1

ENDRUN
