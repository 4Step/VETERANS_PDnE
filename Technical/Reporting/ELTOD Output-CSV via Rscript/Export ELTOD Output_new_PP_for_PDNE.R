# Title: Export ELToD Ouput files
#
# Description: 
# Writes pull link volumes to excel.
# Styles and formulae can also be set from script but it's rather much 
# easier to use a predefined excel template and write to it. 
#  
# 
# Amar Sarvepalli, date:07-21-2017, venkat.sarvepalli@dot.state.fl.us
#
#======================================================================
# User settings
#=====================================================================

# model directory, scenarios and years
old_ppath     <- "M:\\Projects\\Veterans ELToDv2.2 2017"
new_ppath     <- "M:\\Projects\\Veterans ELToDv2.3 2017-0628_PDNE"
excel_path    <- "M:\\Projects\\Veterans ELToDv2.3 2017-0628_PDNE\\Analysis & Profiles"

#path <- c(old_ppath, new_ppath)

path <- c(new_ppath)

scenarios <- c("Y2020Rev", "Y2040Rev")
Years     <- c(2020, 2040)


# script files
script_dir    <- paste(new_ppath, "Reporting\\ELTOD Output-CSV via Rscript", sep = "\\")
setwd(script_dir)

# input files
filenames <- paste0("VOL",c(1:24),".csv")
pull_link <- "Pull_Link_Dir.csv"
excel_template <- "Template.xlsx"

# output excel files, segment starting rows
old_outfiles <- c("Output_2020A1.xlsx", "Output_2040A1.xlsx")
new_outfiles <- c("Output_2020A2.xlsx", "Output_2040A2.xlsx")
#outfiles <- list(old_outfiles, new_outfiles)
outfiles <- list(new_outfiles)

segments <- c(1,2)
seg_data_start_rows <- c(6, 51)
sheet_name = "Output"

#======================================================================
# Load libraries & read data files
#======================================================================
library(dplyr)
library(tidyr)
library(foreign)
library(data.table)
library(XLConnect)


for (p in 1:length(path)) {
  
  # load all files
  for (s in 1:length(scenarios)){
    for (f in 1:length(filenames)){
      
      # read all files 
      # df_vol <- read.csv(paste(path,scenarios[s],filenames[f], sep ="\\"))
      df_vol <- read.csv(paste(path[p],"Base",scenarios[s],filenames[f], sep ="\\"))
      
      # append scenario Year and Hour
      df_vol$Hour <- f
      df_vol$Year <- Years[s]
      
      # consolidate all data
      ifelse(f == 1 & s == 1, df <- df_vol, df <- rbind(df,df_vol)) 
    }
  }
  
  
  #======================================================================
  # Process data 
  #======================================================================
  df_pulllink <- read.csv(pull_link) %>%
    mutate(key = paste(A, B, sep = "-")) %>%
    select(-A, -B, -PULL)
  
  # select only specific columns
  df     <- df %>% 
    mutate(key = paste(A, B, sep = "-")) %>% 
    left_join(df_pulllink, by = "key")  %>%
    mutate(LType_Dir = paste(LType, Dir, sep ="_")) %>% 
    select(Year, Seg, Hour, LType_Dir,
           VOL = TOTAL_VOL, CSPD, TOLL, VC_RATIO) %>%          
    gather( -Year, -Seg, -LType_Dir, -Hour,  key = name, value = value ) %>%
    mutate(LType_Dir_name =  paste(LType_Dir, name, sep ="_")) %>%
    select(-LType_Dir, -name) %>%
    spread(LType_Dir_name, value) %>%
    mutate(EL_NB_SHARE = EL_NB_VOL / (GU_NB_VOL + EL_NB_VOL),
           EL_SB_SHARE = EL_SB_VOL / (GU_SB_VOL + EL_SB_VOL),
           Corridor = GU_NB_VOL + EL_NB_VOL + GU_SB_VOL + EL_SB_VOL) %>%
    arrange(Year, Seg, Hour)
  
  
  # select only specific columns          
  dir_ltype  <- c("GU_NB","GU_SB", "EL_NB", "EL_SB")
  dir_ELtype <- dir_ltype[3:4]
  df_order   <- c("Year", "Seg", "Hour", 
                  paste0(dir_ltype,"_VOL"), 
                  "Corridor",
                  paste0(dir_ELtype,"_SHARE"),
                  paste0(dir_ltype,"_VC_RATIO"), 
                  paste0(dir_ltype,"_CSPD"), 
                  paste0(dir_ELtype,"_TOLL"))
  
  df <- df %>% select(df_order)  
  
  
  #======================================================================
  # Write to Excel
  #======================================================================
  
  for(s in 1:length(scenarios)){
    for(d in segments){
      # create excel output
      excel_out <- paste(excel_path,outfiles[[p]][s], sep ="\\") 
      file.copy(excel_template, excel_out) 
      
      # Get data by segments
      df_seg <- df %>% 
        filter(Year == Years[s], Seg == segments[d]) %>%
        select(-Year, -Seg, -Hour)
      
      # write to excel
      writeWorksheetToFile(excel_out, data = df_seg,
                           sheet = sheet_name, 
                           # sheet = "sheet_name", 
                           startRow = seg_data_start_rows[d],
                           startCol = 2, 
                           header = FALSE, 
                           rownames = NULL,
                           styleAction = XLC$STYLE_ACTION.NONE,
                           clearSheets = FALSE)
    }
  }
}

