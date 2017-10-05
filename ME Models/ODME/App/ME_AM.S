; Script for program MATRIX in file "M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Scripts\Cube_Analyst\ODME\APP\02MAT00C.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX
FILEI MATI[4] = "{SCENARIO_DIR}\Input\Subarea_D6HWY80A_PMPK.MAT"
FILEI MATI[3] = "{SCENARIO_DIR}\Input\Subarea_D6HWY80A_MDOP.MAT"
FILEI MATI[2] = "{SCENARIO_DIR}\Input\Subarea_D6HWY80A_EVOP.MAT"
FILEI MATI[1] = "{SCENARIO_DIR}\Input\Subarea_D6HWY80A_AMPK.MAT"
FILEO MATO[1] = "{SCENARIO_DIR}\Output\TBRPM_Subarea_OD.MAT",
 MO = 1, NAME = TOTAL

MW[1] = (Mi.1.1 + Mi.2.1 + Mi.3.1 + Mi.4.1) * 0.25

ENDRUN



; Script for program NETWORK in file "M:\PROJECTS\VETERANS ELTODV2.3 2017-0628_PDNE\SCRIPTS\CUBE_ANALYST\ODME\APP\02NET00E.S"
;;<<Default Template>><<NETWORK>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=NETWORK MSG='Add Counts to NET'
FILEO NETO = "{SCENARIO_DIR}\Output\User_Defined_SA_ver4.net"
FILEI LINKI[2] = "{SCENARIO_DIR}\Input\Profile_Counts_Dir_v2.dbf"
FILEI LINKI[1] = "{SCENARIO_DIR}\Input\User_Defined_SA_ver4_fixedLanes.net"

ENDRUN


; PILOT Script
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.

*Del "{SCENARIO_DIR}\Output\SUMMARY_{ALT}{YEAR}.DAT"
; End of PILOT Script

LOOP HR = 17, 18, 1

  LOOP LOOPID = 1, 50, 1

    IF (LOOPID=1)
      *Copy "{SCENARIO_DIR}\Output\TBRPM_Subarea_OD.MAT" "{SCENARIO_DIR}\Output\Seed_ODFlows_{ALT}{YEAR}.MAT"
    ELSE
      *Copy "{SCENARIO_DIR}\Output\MAT_LOOP_{ALT}{YEAR}.MAT" "{SCENARIO_DIR}\Output\Seed_ODFlows_{ALT}{YEAR}.MAT"
    ENDIF

; Script for program NETWORK in file "M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Scripts\Cube_Analyst\ODME\App\02NET00A.S"
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


; Script for program HIGHWAY in file "M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Scripts\Cube_Analyst\ODME\APP\02HWY00D.S"
;;<<Default Template>><<HIGHWAY>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=HIGHWAY PRNFILE="{CATALOG_DIR}\App\02HWY00A.PRN"
FILEI LOOKUPI[1] = "{SCENARIO_DIR}\Input\Hourly_Distribution_7_Anderson.csv"
FILEI TURNPENI = "{SCENARIO_DIR}\Input\subarea_turn_penalty.PEN"
FILEI MATI[1] = "{SCENARIO_DIR}\Output\Seed_ODFlows_{ALT}{YEAR}.MAT"
FILEI NETI = "{SCENARIO_DIR}\Output\Subarea_{ALT}{YEAR}_@HR@.net"
FILEO ESTMICPO[1] = "{SCENARIO_DIR}\output\ICP_{ALT}{YEAR}.ICP",
         FORMAT=1, ;format for Analyst Drive (1)
         COUNTVAR=lw.AADT, confvar=lw.conf, SCREENLINE=lw.screen
         ;COUNTVAR=lw.count_am, DEFAULTCONF={Default Conf} , SCREENLINE=lw.screen
FILEO ESTMDATO[1] = "{SCENARIO_DIR}\Output\Screenline_{ALT}{YEAR}.DAT"
FILEO NETO = "{SCENARIO_DIR}\Output\Network_{ALT}{YEAR}_@HR@.NET"

/*
LOOKUP LOOKUPI=1,
       NAME=VFACTORS_ORIG,
         LOOKUP[1]=FT, RESULT=UROAD,
         LOOKUP[2]=FT, RESULT=CONFAC,
         LOOKUP[3]=FT, RESULT=BPRLOS,
         LOOKUP[4]=FT, RESULT=BPREXP,
       FAIL[1]=0,FAIL[2]=0,FAIL[3]=0
FILEI LOOKUPI[1] = "{SCENARIO_DIR}\Input\VFACTORS_TOD.DBF"
*/

; Lookup Hourly distribtution
LOOKUP LOOKUPI=1, NAME=GETHRFACTOR, LOOKUP[1]=1, RESULT=2, 
                                    LOOKUP[2]=1, RESULT=3,
                                    INTERPOLATE=F

; Look up deceleration rate based on approach speed
LOOKUP,
 INTERPOLATE=Y, LIST=Y, NAME=DECEL,
        LOOKUP[1]=1,RESULT=2,
R = '30 4',
    '70 6.2'
    
PAR  MAXITERS={ITER}, relativegap=0, GAP={GAP}, AAD=0, RAAD=0, RMSE=0, ZONEMSG=100

TURNS N=1-99999

ARRAY TOLLVOL={ITER}, TOLLREVENUE={ITER}, TOLLVMT={ITER}

PROCESS PHASE=LINKREAD
; Get count locations

IF (LI.CNT_@HR@ >0 & LI.LOC < 40) 

     ; lw.AADT = li.{count_field} 
     lw.AADT = li.CNT_@HR@
     
     ; lw.AADT = li.CNT_PER_@HR@ 
     
     ; lw.AADT = max(li.CNT_PER_@HR@, 4000) ; set a minimum of 4000 (not sure why PM, period 2, fails if there are AADT less than 4K - something to do with seed but in what way?)

    /* 
    IF (LI.DIR_SB_NB = 1) 
       lw.AADT = li.{count_field} * GETHRFACTOR(1,@HR@)
       lw.count_@HR@ = round(li.{count_field} * GETHRFACTOR(1,@HR@))
    ENDIF
    IF (LI.DIR_SB_NB = 2) 
       lw.AADT = li.{count_field} * GETHRFACTOR(2,@HR@)
       lw.count_@HR@ = round(li.{count_field} * GETHRFACTOR(2,@HR@))
    ENDIF
    */
    
    lw.screen = li.LOC
    
    IF (li.FTYPE = 91) 
       lw.conf={Default Conf}
    ELSE 
      ; lw.conf=1000
      lw.conf={Default Conf}
    ENDIF
ENDIF    

FUNCTION  TC[1] = T0 * (1 + ({DAMPING} * LI.BPRCOEFFICIENT * (MIN(V/C,4.00) ^ LI.BPREXPONENT)))   ;(MINS) congested time for non-toll links
FUNCTION  TC[2] = (LW.CTOLL * LI.CARTOLL * 60); + LI.SVCMINUTES + (LI.SVCSECONDS / 60)             ;(MINS) time for toll links
FUNCTION  TC[3] = T0 * (1 + ({DAMPING} * LI.BPRCOEFFICIENT * (MIN(V/C,4.00) ^ LI.BPREXPONENT)))   ;(MINS) congested time toll acceleration links
FUNCTION  TC[4] = T0 * (1 + ({DAMPING} * LI.BPRCOEFFICIENT * (MIN(V/C,4.00) ^ LI.BPREXPONENT)))   ;(MINS) congested time toll deceleration links
FUNCTION  TC[5] = T0 * (1 + ({DAMPING} * LI.BPRCOEFFICIENT * (MIN(V/C,4.00) ^ LI.BPREXPONENT)))   ;(MINS) congested time for non-toll TRUCK ONLY links
;FUNCTION  TC[6] = T0 * (1 + ({DAMPING} * LI.BPRCOEFFICIENT * ((1 + (VOL[1] / MAX(V,1)))^LI.BPREXPONENT) * (MIN(V/C,4.00)^LI.BPRGAMMA)))   ;(MINS) congested time for non-toll FREEWAY LINKS
;FUNCTION  TC[7] = T0 * (1 + ({DAMPING} * LI.BPRCOEFFICIENT * ((1 + (VOL[1] / MAX(V,1)))^LI.BPREXPONENT) * (LI.BPRGAMMA^MIN(V/C,4.00))))   ;(MINS) congested time for non-toll CLASS I - IV ARTERIALS links
FUNCTION TC[6] = T0 * (1 + ({DAMPING} * LI.BPRCOEFFICIENT * (MIN(V/C,4.00) ^ LI.BPREXPONENT)))  ; (MINS) congested time for express links

FUNCTION  COST[1] = TIME                                                                          ;(MINS) congested COST for non-toll links
FUNCTION  COST[2] = TIME + ROUND((1 / (LW.SERVR - LW.ARRIVR)) * 60 * 1000) / 1000                 ;(MINS) congested COST for toll links
FUNCTION  COST[3] = TIME + ROUND(((LW.CGSTSPEED / {ACCELRATE}) / 60) / 2 * 1000) / 1000           ;(MINS) congested COST toll acceleration links MINS
FUNCTION  COST[4] = TIME + ROUND(((LW.CGSTSPEED / DECEL(1,LW.CGSTSPEED)) / 60) / 2 * 1000) / 1000 ;(MINS) congested COST toll deceleration links MINS
FUNCTION  COST[5] = TIME                                                                          ;(MINS) congested COST for non-toll TRUCK ONLY links
;FUNCTION  COST[6] = TIME                                                                          ;(MINS) congested COST for non-toll FREEWAY LINKS w/ TRUCKS
;FUNCTION  COST[7] = TIME                                                                          ;(MINS) congested COST for non-toll CLASS I - IV ARTERIALS w/ TRUCKS
; Added by Kapil Arya on 04-07-14 to model express lane using CTOLL method
FUNCTION COST[6] = TIME + (LW.CTOLL * LW.ELTOLL * 60) ; COST OF EXPRESS LANE IS TRAVEL TIME PLUS TIME EQUIVALENT OF TOLL

FUNCTION   V = VOL[1] ; TOTAL VOLUME

; basics

;  T0 = LI.TOTALCOST
  T0 = LI.LINKCOST ; CHANGED BY KAPIL ARYA ON 04-08-14 TO BE REFLECTIVE OF FF TRAVEL TIME ON LINKS
  ;C  = LI.CAPACITY * LI.NUM_LANES * LI.UROADFACTOR / LI.CONFACAMP
  ; Daily ODME uses unlimited capacity
  C  = LI.CAPACITY * LI.NUM_LANES * {CAPHR_AM}
  IF (LI.TIME > 0) LW.CGSTSPEED = LI.DISTANCE / (LI.TIME / 60)   ; CONVERT TIME (MINS) TO HOURS

  IF (LI.FACL_TYPE = 48,96,97) ADDTOGROUP=1   ; TRUCK RESTRICTED ROADS
  IF (LI.FACL_TYPE = 80-89)    ADDTOGROUP=2   ; HOV LANES
  IF (LI.FACL_TYPE = 76)       ADDTOGROUP=3   ; TRUCK ONLY RAMPS/LANES
  IF (LI.FACL_TYPE = 49)       ADDTOGROUP=4   ; TRANSIT ONLY FACILITIES
; Added by Kapil Arya on 04-07-14 to model express lane using CTOLL method
  IF (LI.FACL_TYPE = 94)       ADDTOGROUP=5   ; EXPRESS LANES
  
  ; classify links based on presence/absence of tolls
  LINKCLASS = 1 ; no toll
  LW.RATE = 0

  IF (A = 5000-10000)
    LW.CTOLL = 0.062 ;{CTOLL1}
  ELSEIF (A = 10001 - 14000 )
    LW.CTOLL =  0.067 ;{CTOLL2}
  ELSEIF (A = 14001 - 16000)
    LW.CTOLL = 0.129 ;{CTOLL3}
  ELSEIF (A = 16001- 17000)
    LW.CTOLL = 0.135 ;{CTOLL4}
  ELSEIF (A = 17001 - 18000)
    LW.CTOLL = 0.149 ;{CTOLL5}
  ELSEIF (A = 18001 - 20000)
    LW.CTOLL = 0.078 ;{CTOLL6}
  ELSE
    LW.CTOLL = 0.06 ; {CTOLL}
  ENDIF

  IF (LI.TOLL > 0) 
    LINKCLASS = 2 ; with toll
    T0 = LI.LINKCOST

    IF (LI.TOLLTYPE = 1)
      LW.DELAY  = LI.SVCMINUTES + (LI.SVCSECONDS / 60)   ; CONVERT SECONDS TO (MINS)
      LW.SERVR  = 1 / (LW.DELAY / 60)                    ; CONVERT (MINS) DELAY TO HOURS AND INVERT (VPH PER LANE)
      LW.ARRIVR = 0
    ELSE
      LW.DELAY  = 0
      LW.SERVR  = 1000000                                ; PREVENT DIVIDE BY ZERO FOR RAMP BOOTHS
      LW.ARRIVR = 0
    ENDIF
  ENDIF

  IF (LI.TOLL_ACC > 0) 
    LINKCLASS=3 ; Toll Plaza Acceleration link
    LW.DELAY = ROUND(((LW.CGSTSPEED / {ACCELRATE}) / 60) / 2 * 1000) / 1000           ; (MINS) congested COST toll acceleration links
    LW.RATE = {ACCELRATE}
  ENDIF

  IF (LI.TOLL_DEC > 0) 
    LINKCLASS=4 ; Toll Plaza Deceleration link
    LW.DELAY = ROUND(((LW.CGSTSPEED / DECEL(1,LW.CGSTSPEED)) / 60) / 2 * 1000) / 1000 ; (MINS) congested COST toll deceleration links
    LW.RATE = DECEL(1,LW.CGSTSPEED)
  ENDIF

  IF (LI.TOLL > MAXPLZNO) MAXPLZNO = LI.TOLL

  IF (LI.FACL_TYPE = 76) LINKCLASS=5

; Added by Kapil Arya on 04-07-14 to model express lane using CTOLL method  
  IF (LI.FACL_TYPE = 94)       
    LINKCLASS=6   ; EXPRESS LANES
   ; IF (@PERIOD@ = 1) ; AM
      LW.ELTOLL = LI.DISTANCE *  0.15 ;{HOTTOLL_AM}
      
    /*  
    ELSEIF (@PERIOD@ = 2) ; MD
      LW.ELTOLL = LI.DISTANCE * {HOTTOLL_MD}
    ELSEIF (@PERIOD@ = 3) ; PM
      LW.ELTOLL = LI.DISTANCE * {HOTTOLL_PM}
    ELSEIF (@PERIOD@ = 4) ; EV
      LW.ELTOLL = LI.DISTANCE * {HOTTOLL_EV}
    ENDIF
    */
    
  ENDIF  

ENDPHASE

;=========================================================================================
;=== ILOOP (ASSIGNMENT) PHASE ===
;=========================================================================================
PHASE=ILOOP

; NORMAL TBRPM MODE
  PATHLOAD PATH=COST, DEC=2, VOL[1]=MI.1.1, PENI=1,  ESTMO=1, EXCLUDEGROUP=2-4          ;HOV 
  
ENDPHASE

;=========================================================================================
;=== ADJUST PHASE (WITH REPORTING)===
;=========================================================================================
; User Specified Functions
; Delay functions, one for congested travel time, the other for toll links convert to time equivalent

PHASE=ADJUST

  IF (TIME > 0) LW.CGSTSPEED = LI.DISTANCE / (TIME / 60)                  ; (MPH) CONVERT TIME (MINS) TO HRS

  IF (LI.CARTOLL > 0)
    _SVCSECONDS = '00' + LTRIM(STR(LI.SVCSECONDS,2,0))
    _SVCSECLEN  = STRLEN(_SVCSECONDS)-1
    _SVCSECONDS = SUBSTR(_SVCSECONDS,_SVCSECLEN,2)

    IF (LI.TOLL > _TOLLLINKS) _TOLLLINKS = LI.TOLL

    IF (LI.TOLLTYPE = 1)
      LW.ARRIVR = ROUND((V / LI.UROADFACTOR) * LI.CONFACAMP / LI.PLZALNSMin) ; (HRS)  Hourly Volume per toll lane ie. arrival rate in vehicles per hour
      LW.SERVT  = LI.SVCMINUTES + (LI.SVCSECONDS / 60)                    ; (MINS) Plaza lane service time in minutes per vehicle
      LW.SERVR  = 1 / (LW.SERVT / 60)                                     ; (HRS)  Plaza lane service rate in vehicle per hour

      IF ((LW.ARRIVR >= LW.SERVR) && (LW.SERVR > 1000))
        LW.ARRIVR = 0.99 * LW.SERVR                                       ; (HRS)  Prevent infinite or negative queue 
      ELSEIF (LW.ARRIVR >= LW.SERVR)
        LW.ARRIVR = 0.95 * LW.SERVR                                       ; (HRS)  Prevent infinite or negative queue
      ENDIF

      IF (LW.SERVR = 0) LW.SERVR = 1000                                   ; PREVENT DIVIDE BY ZERO
      _REV  = (ROUND(V * LI.PCTTRUCKS) * 3 * LI.CARTOLL) + (ROUND(V * (1 - LI.PCTTRUCKS)) * LI.CARTOLL)
      _UTIL = (V / (LW.SERVR / (LI.UROADFACTOR * LI.CONFACAMP)))

      LW.DELAY = ROUND(1 / ((LW.SERVR - LW.ARRIVR) / 60) * 1000) / 1000   ; CONVERT HOURLY RATES TO (MINS) OF DELAY
    ENDIF

    IF (LW.SERVR = 0) LW.SERVR = 1000                                     ; PREVENT DIVIDE BY ZERO

    TOLLVOL[ITERATION] = TOLLVOL[ITERATION] + V
    TOLLREVENUE[ITERATION] = TOLLREVENUE[ITERATION] + _REV
  ENDIF

  IF (LI.TOLL_ACC > 0) LW.DELAY = ROUND(((LW.CGSTSPEED / {ACCELRATE}) / 60) / 2 * 1000) / 1000           ;(MINS) congested COST toll acceleration links
  IF (LI.TOLL_DEC > 0) LW.DELAY = ROUND(((LW.CGSTSPEED / DECEL(1,LW.CGSTSPEED)) / 60) / 2 * 1000) / 1000 ;(MINS) congested COST toll deceleration links

  IF (LI.FACL_TYPE = 90-99) TOLLVMT[ITERATION] = TOLLVMT[ITERATION] + (LI.DISTANCE * V)

ENDPHASE

PHASE=CONVERGE
  IF (ITERATION < 6) BREAK ;Do not even test for Iterations 2-20
  IF ((GAP[ITERATION] < GAPCUTOFF) && (GAP[ITERATION-1] < GAPCUTOFF) && (GAP[ITERATION-2] < GAPCUTOFF))
     BALANCE = 1
  ENDIF
ENDPHASE

ENDRUN


; Script for program MATRIX in file "M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Scripts\Cube_Analyst\ODME\App\02MAT00A.S"
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


; Program ANALYST_DRIVE
RUN PGM="ANALYST_DRIVE", CTLFILE="M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Scripts\Cube_Analyst\ODME\App\02EST00A.CTL"
ENDRUN

; Script for program MATRIX in file "M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Scripts\Cube_Analyst\ODME\App\02MAT00B.S"
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


; Script for program NETWORK in file "M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Scripts\Cube_Analyst\ODME\App\02NET00B.S"
;;<<Default Template>><<NETWORK>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=NETWORK PRNFILE="M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Scripts\Cube_Analyst\ODME\App\02NET00B.PRN" MSG='Compute Validation Summaries'
FILEI LINKI[1] = "{SCENARIO_DIR}\Output\Network_{ALT}{YEAR}_@HR@.NET"
FILEO PRINTO[2] = "{SCENARIO_DIR}\Output\VOLCNT_{ALT}{YEAR}.DAT"
FILEO PRINTO[1] = "{SCENARIO_DIR}\Output\SUMMARY_{ALT}{YEAR}.DAT",
  APPEND=T

PHASE=LINKMERGE

;CNT_AMPRD=li.1.CNT15_AM

CNT_MDPRD=li.1.CNT_@HR@
;CNT_MDPRD= li.1.{count_field}

;CNT_PMPRD=li.1.CNT15_PM
;CNT_NTPRD=li.1.CNT15_NT
;CNT_DYPRD=li.1.CNT_AADT


_ReportTitle= '====================================  RMSE and Other Volume/Count Evaluation Summary ========================================'
              

;---Get Lane, Volume, CNT_AMPRD etc.
V_1=V_25
TOTAL_VOL=ROUND (V_1) ;(V_2);(V_1)


  if (CNT_MDPRD>0)
   print form=10.0, list= CNT_MDPRD,v_1 printo=2

   if (V_1>CNT_MDPRD)
   _posdiff=_posdiff+(V_1-CNT_MDPRD)
   elseif (V_1<CNT_MDPRD)
   _negdiff=_negdiff+(CNT_MDPRD-V_1)
   endif
  _totaldiff=-_negdiff+_posdiff
  endif


_CNT_MDPRDsum=_CNT_MDPRDsum+CNT_MDPRD

; initialize arrays and variables
   ARRAY _err=13, _cns=13, _cnt=13, _RGP=13, _vols=13

   _RGP[1]=1, _RGP[2]=5000, _RGP[3]=10000, _RGP[4]=20000, _RGP[5]=30000, _RGP[6]=40000, _RGP[7]=50000,
   _RGP[8]=60000, _RGP[9]=70000, _RGP[10]=80000, _RGP[11]=90000, _RGP[12]=100000, _RGP[13]=500000
   IF (A=1)
     LOOP _iter=1,13
           _err[_iter]=0,_cnt[_iter]=0,_cns[_iter]=0,_vols[_iter]=0
     ENDLOOP

   ENDIF

; calculate and compartmentalize
   IF (CNT_MDPRD>0) VOLCNT=TOTAL_VOL/CNT_MDPRD, _TVOL=TOTAL_VOL, NETDIFF=TOTAL_VOL-CNT_MDPRD, ABSDIFF=ABS(NETDIFF), ERRORSQ=NETDIFF^2, PCTDIFF=100*NETDIFF/CNT_MDPRD _group=1

   IF (CNT_MDPRD>5000) _group=2
   IF (CNT_MDPRD>10000) _group=3
   IF (CNT_MDPRD>20000) _group=4
   IF (CNT_MDPRD>30000) _group=5
   IF (CNT_MDPRD>40000) _group=6
   IF (CNT_MDPRD>50000) _group=7
   IF (CNT_MDPRD>60000) _group=8
   IF (CNT_MDPRD>70000) _group=9
   IF (CNT_MDPRD>80000) _group=10
   IF (CNT_MDPRD>90000) _group=11
   IF (CNT_MDPRD>100000) _group=12

   IF (CNT_MDPRD>0)
     _ERR[_group]=ERRORSQ+_ERR[_group], _CNS[_group]=CNT_MDPRD+_CNS[_group], _CNT[_group]=_CNT[_group]+1, _VOLS[_group]=_TVOL+_VOLS[_group]
     _ERR[13]=ERRORSQ+_ERR[13], _CNS[13]=CNT_MDPRD+_CNS[13], _CNT[13]=_CNT[13]+1, _VOLS[13]=_TVOL+_VOLS[13]
   ENDIF

ENDPHASE

; =========================================================
; SUMMARY REPORTING
; =========================================================
PHASE=SUMMARY

if (_CNT_MDPRDsum>0)   ;condition on _CNT_MDPRDsum>0

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;+++ Loop to write out the Percent Root Mean Square Error
LOOP _iter=1,12

   if (_iter=1) _limit='45 - 55'
   if (_iter=2) _limit='35 - 45'
   if (_iter=3) _limit='27 - 35'
   if (_iter=4) _limit='24 - 27'
   if (_iter=5) _limit='22 - 24'
   if (_iter=6) _limit='20 - 22'
   if (_iter=7) _limit='18 - 20'
   if (_iter=8) _limit='17 - 18'
   if (_iter=9) _limit='16 - 17'
   if (_iter=10) _limit='15 - 16'
   if (_iter=11) _limit='14 - 15'
   if (_iter=12) _limit='LT 14  '
   
 if (_iter=1) print list="\n",_ReportTitle,"\n","\n",
 
 '                                                        Iteration:  ',@LOOPID@(L),"\n","\n",     
      ' **************************************** RMSE and Volume/Count By Volume Group ******************************************',"\n","\n",
      ;printo=1
      "                     Confidence Levels ; Default Conf =",{Default Conf}(7.0c)," ; Conf_P =",{CLP}(7.0c)," ; Conf_A = ",{CLA}(7.0c),"\n",
      printo=1 

_RptTitle2= ' Vol Grp    CNT_AADT  Range      Model RMSE(%)  Allow RMSE Range     Volume      CNT_AADT     Volume/CNT_AADT   No of Links'
_RptTitle2a=' -------    --------------      -------------  ----------------    ----------    ----------  -----------------  -----------'

  if (_iter=1) print list=_RptTitle2,"\n",_RptTitle2a," ", printo=1

  if (_cnt[_iter]>0) print,
 list="    ",_iter(2.0c),"    ",_RGP[_iter](7.0c),"-",_RGP[_iter+1](7.0c),"       ",sqrt(_err[_iter]/(_cnt[_iter]-1))/(_cns[_iter]/_cnt[_iter])*100(11.3),"%",
 "       ", _limit,"%",
 "      ",_vols[_iter](11.0c),
 "   ",_cns[_iter](11.0c),
 "          ",(_vols[_iter]/_cns[_iter])(5.2c),
 "          ",_cnt[_iter](5.0C), PRINTO=1

ENDLOOP

_iter=13

 if (_iter=13) _limit='32 - 39'

list="   ALL ","   ",_RGP[1](7.0c),"-",_RGP[_iter](7.0c),"       ",sqrt(_err[_iter]/(_cnt[_iter]-1))/(_cns[_iter]/_cnt[_iter])*100(11.3),"%",
 "       ", _limit,"%",
 "      ",_vols[_iter](11.0c),
 "   ",_cns[_iter](11.0c),
 "          ",(_vols[_iter]/_cns[_iter])(5.2c),
 "          ",_cnt[_iter](5.0C),"\n", PRINTO=1

endif ; condition on _CNT_MDPRDsum>0

list="       Sum of positive differences =",_posdiff(10.0c), " ; Sum of negative differences =",_negdiff(10.0c)," ; Total difference =" _totaldiff(10.0c),"\n","\n",printo=1


ENDPHASE
ENDRUN


  ENDLOOP

; Script for program HIGHWAY in file "M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Scripts\Cube_Analyst\ODME\App\02HWY00B.S"
;;<<Default Template>><<HIGHWAY>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=HIGHWAY PRNFILE="M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Scripts\Cube_Analyst\ODME\App\02HWY00B.PRN" MSG='Post ME Run AM Peak Period Hwy Assignment'
FILEI LOOKUPI[1] = "{SCENARIO_DIR}\Input\Hourly_Distribution_7_Anderson.csv"
FILEI TURNPENI = "{SCENARIO_DIR}\Input\subarea_turn_penalty.PEN"
FILEO NETO = "{SCENARIO_DIR}\output\FINAL_HWYLOAD_AM_{ALT}{YEAR}_@HR@.NET"
FILEI NETI = "{SCENARIO_DIR}\Output\Subarea_{ALT}{YEAR}_@HR@.net"
FILEI MATI[1] = "{SCENARIO_DIR}\Output\MAT_LOOP_{ALT}{YEAR}.MAT"
      
PAR  MAXITERS={ITER}, relativegap=0, GAP={GAP}, AAD=0, RAAD=0, RMSE=0, ZONEMSG=100
TURNS N=1-99999  
ARRAY TOLLVOL={ITER}, TOLLREVENUE={ITER}, TOLLVMT={ITER}
;Look up deceleration rate based on approach speed

LOOKUP,
 INTERPOLATE=Y, LIST=Y, NAME=DECEL,
       LOOKUP[1]=1,RESULT=2,
R = '30 4',
    '70 6.2'
    
; Lookup Hourly distribtution
LOOKUP LOOKUPI=1, NAME=GETHRFACTOR, LOOKUP[1]=1, RESULT=2, 
                                    LOOKUP[2]=1, RESULT=3,
                                    INTERPOLATE=F

PROCESS PHASE=LINKREAD
; Get count locations
IF (LI.CNT_PER_@HR@ >0) 
    ; lw.AADT = li.CNT_@HR@
    lw.AADT = li.CNT_PER_@HR@
    
    /*
    IF (LI.DIR_SB_NB = 1) 
       lw.AADT = li.{count_field} * GETHRFACTOR(1,@HR@)
    ELSE 
       lw.AADT = li.{count_field} * GETHRFACTOR(2,@HR@)
    ENDIF
    */
    
    lw.screen=li.LOC
    lw.conf={Default Conf}
ENDIF    
    

FUNCTION  TC[1] = T0 * (1 + ({DAMPING} * LI.BPRCOEFFICIENT * (MIN(V/C,4.00) ^ LI.BPREXPONENT)))   ;(MINS) congested time for non-toll links
FUNCTION  TC[2] = (LW.CTOLL * LI.CARTOLL * 60); + LI.SVCMINUTES + (LI.SVCSECONDS / 60)             ;(MINS) time for toll links
FUNCTION  TC[3] = T0 * (1 + ({DAMPING} * LI.BPRCOEFFICIENT * (MIN(V/C,4.00) ^ LI.BPREXPONENT)))   ;(MINS) congested time toll acceleration links
FUNCTION  TC[4] = T0 * (1 + ({DAMPING} * LI.BPRCOEFFICIENT * (MIN(V/C,4.00) ^ LI.BPREXPONENT)))   ;(MINS) congested time toll deceleration links
FUNCTION  TC[5] = T0 * (1 + ({DAMPING} * LI.BPRCOEFFICIENT * (MIN(V/C,4.00) ^ LI.BPREXPONENT)))   ;(MINS) congested time for non-toll TRUCK ONLY links
;FUNCTION  TC[6] = T0 * (1 + ({DAMPING} * LI.BPRCOEFFICIENT * ((1 + (VOL[1] / MAX(V,1)))^LI.BPREXPONENT) * (MIN(V/C,4.00)^LI.BPRGAMMA)))   ;(MINS) congested time for non-toll FREEWAY LINKS
;FUNCTION  TC[7] = T0 * (1 + ({DAMPING} * LI.BPRCOEFFICIENT * ((1 + (VOL[1] / MAX(V,1)))^LI.BPREXPONENT) * (LI.BPRGAMMA^MIN(V/C,4.00))))   ;(MINS) congested time for non-toll CLASS I - IV ARTERIALS links
FUNCTION TC[6] = T0 * (1 + ({DAMPING} * LI.BPRCOEFFICIENT * (MIN(V/C,4.00) ^ LI.BPREXPONENT)))  ; (MINS) congested time for express links

FUNCTION  COST[1] = TIME                                                                          ;(MINS) congested COST for non-toll links
FUNCTION  COST[2] = TIME + ROUND((1 / (LW.SERVR - LW.ARRIVR)) * 60 * 1000) / 1000                 ;(MINS) congested COST for toll links
FUNCTION  COST[3] = TIME + ROUND(((LW.CGSTSPEED / {ACCELRATE}) / 60) / 2 * 1000) / 1000           ;(MINS) congested COST toll acceleration links MINS
FUNCTION  COST[4] = TIME + ROUND(((LW.CGSTSPEED / DECEL(1,LW.CGSTSPEED)) / 60) / 2 * 1000) / 1000 ;(MINS) congested COST toll deceleration links MINS
FUNCTION  COST[5] = TIME                                                                          ;(MINS) congested COST for non-toll TRUCK ONLY links
;FUNCTION  COST[6] = TIME                                                                          ;(MINS) congested COST for non-toll FREEWAY LINKS w/ TRUCKS
;FUNCTION  COST[7] = TIME                                                                          ;(MINS) congested COST for non-toll CLASS I - IV ARTERIALS w/ TRUCKS
; Added by Kapil Arya on 04-07-14 to model express lane using CTOLL method
FUNCTION COST[6] = TIME + (LW.CTOLL * LW.ELTOLL * 60) ; COST OF EXPRESS LANE IS TRAVEL TIME PLUS TIME EQUIVALENT OF TOLL

FUNCTION   V = VOL[1] ; TOTAL VOLUME

; basics

;  T0 = LI.TOTALCOST
  T0 = LI.LINKCOST ; CHANGED BY KAPIL ARYA ON 04-08-14 TO BE REFLECTIVE OF FF TRAVEL TIME ON LINKS
  C  = LI.CAPACITY * LI.NUM_LANES * 10 ;LI.UROADFACTOR / LI.CONFACAMP
  IF (LI.TIME > 0) LW.CGSTSPEED = LI.DISTANCE / (LI.TIME / 60)   ; CONVERT TIME (MINS) TO HOURS

  IF (LI.FACL_TYPE = 48,96,97) ADDTOGROUP=1   ; TRUCK RESTRICTED ROADS
  IF (LI.FACL_TYPE = 80-89)    ADDTOGROUP=2   ; HOV LANES
  IF (LI.FACL_TYPE = 76)       ADDTOGROUP=3   ; TRUCK ONLY RAMPS/LANES
  IF (LI.FACL_TYPE = 49)       ADDTOGROUP=4   ; TRANSIT ONLY FACILITIES
; Added by Kapil Arya on 04-07-14 to model express lane using CTOLL method
  IF (LI.FACL_TYPE = 94)       ADDTOGROUP=5   ; EXPRESS LANES
  
  ; classify links based on presence/absence of tolls
  LINKCLASS = 1 ; no toll
  LW.RATE = 0

  IF (A = 5000-10000)
    LW.CTOLL = 0.062 ;{CTOLL1}
  ELSEIF (A = 10001 - 14000 )
    LW.CTOLL =  0.067 ;{CTOLL2}
  ELSEIF (A = 14001 - 16000)
    LW.CTOLL = 0.129 ;{CTOLL3}
  ELSEIF (A = 16001- 17000)
    LW.CTOLL = 0.135 ;{CTOLL4}
  ELSEIF (A = 17001 - 18000)
    LW.CTOLL = 0.149 ;{CTOLL5}
  ELSEIF (A = 18001 - 20000)
    LW.CTOLL = 0.078 ;{CTOLL6}
  ELSE
    LW.CTOLL = 0.06 ; {CTOLL}
  ENDIF

  IF (LI.TOLL > 0) 
    LINKCLASS = 2 ; with toll
    T0 = LI.LINKCOST

    IF (LI.TOLLTYPE = 1)
      LW.DELAY  = LI.SVCMINUTES + (LI.SVCSECONDS / 60)   ; CONVERT SECONDS TO (MINS)
      LW.SERVR  = 1 / (LW.DELAY / 60)                    ; CONVERT (MINS) DELAY TO HOURS AND INVERT (VPH PER LANE)
      LW.ARRIVR = 0
    ELSE
      LW.DELAY  = 0
      LW.SERVR  = 1000000                                ; PREVENT DIVIDE BY ZERO FOR RAMP BOOTHS
      LW.ARRIVR = 0
    ENDIF
  ENDIF

  IF (LI.TOLL_ACC > 0) 
    LINKCLASS=3 ; Toll Plaza Acceleration link
    LW.DELAY = ROUND(((LW.CGSTSPEED / {ACCELRATE}) / 60) / 2 * 1000) / 1000           ; (MINS) congested COST toll acceleration links
    LW.RATE = {ACCELRATE}
  ENDIF

  IF (LI.TOLL_DEC > 0) 
    LINKCLASS=4 ; Toll Plaza Deceleration link
    LW.DELAY = ROUND(((LW.CGSTSPEED / DECEL(1,LW.CGSTSPEED)) / 60) / 2 * 1000) / 1000 ; (MINS) congested COST toll deceleration links
    LW.RATE = DECEL(1,LW.CGSTSPEED)
  ENDIF

  IF (LI.TOLL > MAXPLZNO) MAXPLZNO = LI.TOLL

  IF (LI.FACL_TYPE = 76) LINKCLASS=5

; Added by Kapil Arya on 04-07-14 to model express lane using CTOLL method  
  IF (LI.FACL_TYPE = 94)       
    LINKCLASS=6   ; EXPRESS LANES
   ; IF (@PERIOD@ = 1) ; AM
      LW.ELTOLL = LI.DISTANCE *  0.15 ;{HOTTOLL_AM}
      
    /*  
    ELSEIF (@PERIOD@ = 2) ; MD
      LW.ELTOLL = LI.DISTANCE * {HOTTOLL_MD}
    ELSEIF (@PERIOD@ = 3) ; PM
      LW.ELTOLL = LI.DISTANCE * {HOTTOLL_PM}
    ELSEIF (@PERIOD@ = 4) ; EV
      LW.ELTOLL = LI.DISTANCE * {HOTTOLL_EV}
    ENDIF
    */
    
  ENDIF  

ENDPHASE
        
;=========================================================================================
;=== ILOOP (ASSIGNMENT) PHASE ===
;=========================================================================================
PHASE=ILOOP

; NORMAL TBRPM MODE
  PATHLOAD PATH=COST, DEC=2, VOL[1]=MI.1.1, PENI=1,  EXCLUDEGROUP=2-4      
  
ENDPHASE

;=========================================================================================
;=== ADJUST PHASE (WITH REPORTING)===
;=========================================================================================
; User Specified Functions
; Delay functions, one for congested travel time, the other for toll links convert to time equivalent

PHASE=ADJUST

  IF (TIME > 0) LW.CGSTSPEED = LI.DISTANCE / (TIME / 60)                  ; (MPH) CONVERT TIME (MINS) TO HRS

  IF (LI.CARTOLL > 0)
    _SVCSECONDS = '00' + LTRIM(STR(LI.SVCSECONDS,2,0))
    _SVCSECLEN  = STRLEN(_SVCSECONDS)-1
    _SVCSECONDS = SUBSTR(_SVCSECONDS,_SVCSECLEN,2)

    IF (LI.TOLL > _TOLLLINKS) _TOLLLINKS = LI.TOLL

    IF (LI.TOLLTYPE = 1)
      LW.ARRIVR = ROUND((V / LI.UROADFACTOR) * LI.CONFACAMP / LI.PLZALNSMin) ; (HRS)  Hourly Volume per toll lane ie. arrival rate in vehicles per hour
      LW.SERVT  = LI.SVCMINUTES + (LI.SVCSECONDS / 60)                    ; (MINS) Plaza lane service time in minutes per vehicle
      LW.SERVR  = 1 / (LW.SERVT / 60)                                     ; (HRS)  Plaza lane service rate in vehicle per hour

      IF ((LW.ARRIVR >= LW.SERVR) && (LW.SERVR > 1000))
        LW.ARRIVR = 0.99 * LW.SERVR                                       ; (HRS)  Prevent infinite or negative queue 
      ELSEIF (LW.ARRIVR >= LW.SERVR)
        LW.ARRIVR = 0.95 * LW.SERVR                                       ; (HRS)  Prevent infinite or negative queue
      ENDIF

      IF (LW.SERVR = 0) LW.SERVR = 1000                                   ; PREVENT DIVIDE BY ZERO
      _REV  = (ROUND(V * LI.PCTTRUCKS) * 3 * LI.CARTOLL) + (ROUND(V * (1 - LI.PCTTRUCKS)) * LI.CARTOLL)
      _UTIL = (V / (LW.SERVR / (LI.UROADFACTOR * LI.CONFACAMP)))

      LW.DELAY = ROUND(1 / ((LW.SERVR - LW.ARRIVR) / 60) * 1000) / 1000   ; CONVERT HOURLY RATES TO (MINS) OF DELAY
    ENDIF

    IF (LW.SERVR = 0) LW.SERVR = 1000                                     ; PREVENT DIVIDE BY ZERO

    TOLLVOL[ITERATION] = TOLLVOL[ITERATION] + V
    TOLLREVENUE[ITERATION] = TOLLREVENUE[ITERATION] + _REV
  ENDIF

  IF (LI.TOLL_ACC > 0) LW.DELAY = ROUND(((LW.CGSTSPEED / {ACCELRATE}) / 60) / 2 * 1000) / 1000           ;(MINS) congested COST toll acceleration links
  IF (LI.TOLL_DEC > 0) LW.DELAY = ROUND(((LW.CGSTSPEED / DECEL(1,LW.CGSTSPEED)) / 60) / 2 * 1000) / 1000 ;(MINS) congested COST toll deceleration links

  IF (LI.FACL_TYPE = 90-99) TOLLVMT[ITERATION] = TOLLVMT[ITERATION] + (LI.DISTANCE * V)

ENDPHASE

PHASE=CONVERGE
  IF (ITERATION < 6) BREAK ;Do not even test for Iterations 2-20
  IF ((GAP[ITERATION] < GAPCUTOFF) && (GAP[ITERATION-1] < GAPCUTOFF) && (GAP[ITERATION-2] < GAPCUTOFF))
     BALANCE = 1
  ENDIF
ENDPHASE

ENDRUN


; Script for program NETWORK in file "M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Scripts\Cube_Analyst\ODME\App\02NET00C.S"
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


; Script for program MATRIX in file "M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\SCRIPTS\CUBE_ANALYST\ODME\APP\02MAT00D.S"
;;<<Default Template>><<MATRIX>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=MATRIX
FILEO MATO[1] = "{SCENARIO_DIR}\Output\Trip Table @HR@.MAT",
 MO = 1-3, NAME = SOV, HOV, TRK
FILEI MATI[1] = "{SCENARIO_DIR}\Output\EstimatedSta_{ALT}{YEAR}.MAT"

MW[1] = MI.1.1

ENDRUN


ENDLOOP

