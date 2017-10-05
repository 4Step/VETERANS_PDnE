

RUN PGM=MATRIX

FILEO PRINTO[1] = "M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Scripts\Cube_Analyst\ODME\Base\EC2019\Input\TLFD_17.csv"
; FILEI MATI[1] = "M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Base\Y2020Rev\PeakHour\Delay\Trip Table 8.MAT"
FILEI MATI[1] = "M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Scripts\Cube_Analyst\ODME\Base\EC2019\Input\Subarea_D6HWY80A_PMPK.MAT"
FILEI MATI[2] = "M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Base\Y2020Rev\PeakHour\Delay\SKIM17.MAT"
FILEO RECO[1] = "M:\Projects\Veterans ELToDv2.3 2017-0628_PDNE\Scripts\Cube_Analyst\ODME\Base\EC2019\Input\TLFD_17.dbf",
  FIELDS= time, TRIPS(16.8)

  
mw[1]=mi.1.1
mw[2]=mi.2.6

gps=20-1

array tl1=20

jloop
;group = min(max(round(mw[2]),1),15)
group = min(INT(mw[2]/1),gps) + 1
tl1[group]=tl1[group]+mw[1]

endjloop

if (i=zones)
  loop group=1,20
   ro.time=group
   ro.TRIPS=tl1[group]
   write reco=1
   print printo=1 list=ro.time(6.0), ro.trips(16.8)
  endloop
endif


FREQUENCY BASEMW=2 VALUEMW=1 RANGE=0-100-1

ENDRUN