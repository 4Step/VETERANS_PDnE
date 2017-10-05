# Extracts loaded network volumes for the specified links
# Links are specified by A-B nodes which identify the direction of flow along with Facility Types

# user settings
pull_link_filename <- "Pull_Link.csv"
year <- "2040"

loaded_filename <- paste0("LOADED_DY_", year, ".dbf")
out_filename <- paste0("Vol_Pull_", year,".csv")
summary_filename <- paste0("segment_summary_", year, ".csv")  

  
# fields to use
vol_fields <- paste0("V_HR",c(1:24),"_SOV")
vc_fields <- paste0("VC_HR",c(1:24))
csp_fields <- paste0("CSPD_HR",c(1:24))
toll_fields <- paste0("TOLL_HR",c(1:24))

# This is handled internally by the script
# DBF export loses period for VC_RATIO_HR<period> and R renames it to VC_RATIO_HR.<period>
# vc_fields_export <- c("VC_RATIO_HR", paste0("VC_RATIO_HR.",c(1:23)))

# Load libraries
library(dplyr)
library(tidyr)
library(foreign)
library(data.table)

# read files
df_pulllink <- read.csv(pull_link_filename) %>%
               mutate(key = paste(A, B, sep = "-"))
df_loadednet <- read.dbf(loaded_filename) %>%
                mutate(key = paste(A, B, sep = "-"))

# rename VC_HR fields (exporting from CUBE to dbf looses period for VC_RATIO_HR<period>)
# df_vc <- df_loadednet %>% select(key,vc_fields_export)
# colnames(df_vc) <- c("key",vc_fields)
# df_loadednet <- df_loadednet %>% select(-starts_with("VC_RATIO_HR")) %>%
#                 left_join(df_vc, by = "key")

# append pulllink directions to loaded network
df_loadednet <- df_loadednet %>% left_join(df_pulllink, by = "key") %>%
                select(key, Seg, Dir, LType, vol_fields, vc_fields, csp_fields, toll_fields) %>%
                filter(!is.na(Dir)) 

# Get volumes by segment, dir and compute EL shares by dir
df_vols <- df_loadednet %>% 
           mutate(LType_Dir = paste(LType, Dir, sep ="_")) %>%
           select( Seg, LType_Dir, vol_fields) %>% 
           gather(-LType_Dir, -Seg, key = Hour, value = Volume) %>%
           spread(LType_Dir, Volume) %>%
           mutate(Hour = as.numeric(gsub("\\D","",Hour)),
                  Corridor =  EL_NB + EL_SB + GU_NB + GU_SB,
                  Share_XL_NB = EL_NB / GU_NB,
                  Share_XL_SB = EL_SB / GU_SB,
                  key = paste(Seg,Hour,sep="-"))

old_names = c('EL_NB','EL_SB','GU_NB','GU_SB')

# Get VC Ratio by segment and dir
df_vc <- df_loadednet %>% 
          mutate(LType_Dir = paste(LType, Dir, sep ="_")) %>%
          select( Seg, LType_Dir, vc_fields) %>% 
          gather(-LType_Dir, -Seg, key = Hour, value = VC) %>%
          spread(LType_Dir, VC) %>%
          mutate(Hour = as.numeric(gsub("\\D","",Hour)),
                 key = paste(Seg,Hour,sep="-")) %>%
          setnames(old_names, paste0("VC_",old_names)) %>%
          select(-Seg, -Hour)
          
# Get Congested Speeds by segment and dir
df_speed <- df_loadednet %>% 
            mutate(LType_Dir = paste(LType, Dir, sep ="_")) %>%
            select( Seg, LType_Dir, csp_fields) %>% 
            gather(-LType_Dir, -Seg, key = Hour, value = Speeds) %>%
            spread(LType_Dir, Speeds) %>%
            mutate(Hour = as.numeric(gsub("\\D","",Hour)),
                   key = paste(Seg,Hour,sep="-")) %>%
            setnames(old_names, paste0("Speed_",old_names))%>%
            select(-Seg, -Hour)

# Get Toll
df_toll <- df_loadednet %>% 
            mutate(LType_Dir = paste(LType, Dir, sep ="_")) %>%
            select( Seg, LType_Dir, toll_fields) %>% 
            gather(-LType_Dir, -Seg, key = Hour, value = Toll) %>%
            spread(LType_Dir, Toll) %>%
            mutate(Hour = as.numeric(gsub("\\D","",Hour)),
                   key = paste(Seg,Hour,sep="-"))%>% 
            setnames(old_names, paste0("Toll_",old_names))%>%
            select(-Toll_GU_NB, -Toll_GU_SB) %>%
            select(-Seg, -Hour)


# Appends all data
df_all <- df_vols %>%
          left_join(df_vc, by = "key") %>%
          left_join(df_speed, by = "key") %>%
          left_join(df_toll, by = "key") %>%
          select( -key) %>%
          arrange( Seg, Hour)

excel_col_order <- df_all %>%
                   select(Seg, Hour,  
                          GU_NB, GU_SB, EL_NB, EL_SB, Corridor, 
                          Share_XL_NB, Share_XL_SB, 
                          VC_GU_NB, VC_GU_SB , VC_EL_NB, VC_EL_SB, 
                          Speed_GU_NB, Speed_GU_SB, Speed_EL_NB, Speed_EL_SB,
                          Toll_EL_NB, Toll_EL_SB)


# write output
write.csv(excel_col_order, out_filename, row.names = FALSE)

# View summary
x <- df_all %>% group_by(Seg) %>%
           summarise_all(sum)
write.csv(x, summary_filename)

