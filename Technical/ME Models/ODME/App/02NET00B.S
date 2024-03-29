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
