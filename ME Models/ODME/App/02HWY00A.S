;;<<Default Template>><<HIGHWAY>><<Default>>;;
; Do not change filenames or add or remove FILEI/FILEO statements using an editor. Use Cube/Application Manager.
RUN PGM=HIGHWAY PRNFILE="C:\projects\Veterans_ExpressWay\ODME\App\02HWY00A.PRN" MSG='Run AM Peak Period Hwy Assignment'
FILEI TURNPENI = "{SCENARIO_DIR}\Input\TURN_PK_{year}{Alt}.PEN"
FILEI MATI[1] = "{SCENARIO_DIR}\Input\Seed_ODFlows_{ALT}{YEAR}.MAT"
FILEI NETI = "{SCENARIO_DIR}\Input\Subarea_{ALT}{YEAR}.net"
FILEO ESTMICPO[1] = "{SCENARIO_DIR}\AM_ICP_{ALT}{YEAR}.ICP",
         FORMAT=1, ;format for Analyst Drive (1)
         COUNTVAR=lw.AADT, confvar=lw.conf, SCREENLINE=lw.screen
         ;COUNTVAR=lw.count_am, DEFAULTCONF={Default Conf} , SCREENLINE=lw.screen
FILEO ESTMDATO[1] = "{SCENARIO_DIR}\AM_Screenline_{ALT}{YEAR}.DAT"
FILEO NETO = "{SCENARIO_DIR}\AM_Network_{ALT}{YEAR}.NET"

/*
LOOKUP LOOKUPI=1,
       NAME=VFACTORS_ORIG,
         LOOKUP[1]=FT, RESULT=UROAD,
         LOOKUP[2]=FT, RESULT=CONFAC,
         LOOKUP[3]=FT, RESULT=BPRLOS,
         LOOKUP[4]=FT, RESULT=BPREXP,
       FAIL[1]=0,FAIL[2]=0,FAIL[3]=0
FILEI LOOKUPI[1] = "{CATALOG_DIR}\Base\VFACTORS_TOD.DBF"
*/

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
IF (LI.AADT>0) 
    lw.AADT = li.AADT
    lw.screen=li.SCREENLINE
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
  C  = LI.CAPACITY * LI.NUM_LANES * LI.UROADFACTOR / LI.CONFACAMP
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
  PATHLOAD PATH=COST, DEC=2, VOL[1]=MI.1.1, PENI=1-2,  ESTMO=1, EXCLUDEGROUP=2-4          ;HOV
  
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
