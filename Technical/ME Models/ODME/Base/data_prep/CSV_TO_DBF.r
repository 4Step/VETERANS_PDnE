library(foreign)
library(dplyr)

path <- "M:\\Projects\\Veterans ELToDv2.3 2017-0628_PDNE\\Scripts\\Cube_Analyst\\ODME\\Base\\data_prep"

# PART - 1
# Convert to DBF
x <- read.csv(paste(path,"Profile_Counts_Dir_v2.CSV", sep = "\\"))
# write.dbf(x, paste(path,"Profile_Counts_Dir.dbf", sep = "\\"))


# PART - 2
# Compute hourly counts by direction
x <- x %>% mutate(AB = paste(A,B, sep = "-"),
                  Dir = ifelse(Dir_SB_NB == 1, "SB", "NB"))

# Read hourly distribution factors
hourly_factors <- read.csv(paste(path,"Hourly_Distribution_7_Anderson.CSV", sep = "\\")) %>% 
  gather(Dir, Fac, -X.Hours) %>%
  filter(Dir %in% c("Dir1", "Dir2")) %>%
  mutate(Dir = ifelse(Dir == "Dir1", "SB", "NB"))

# Compute hourly counts
hourly_counts <- expand.grid(AB = paste(x$A, x$B, sep = "-"), Hour = c(1:24), Dir = c("SB","NB")) %>%
     left_join(x, by = c("AB", "Dir")) %>%
     filter(!is.na(LOC_check)) %>%
     left_join(hourly_factors, by = c("Hour" = "X.Hours", "Dir" ))%>%
     mutate(CNT_Hour = round(Fac * CNT_2020,0)) %>%
     # muatate (Hour_Dir = paste(Hour, Dir, sep = "_")) %>%  # if both directional counts need to be computed
     select(A, B, Hour, CNT_Hour) %>%
     spread(Hour, CNT_Hour)


# Rename Columns
colnames(hourly_counts) <- c("A","B", paste("CNT", c(1:24), sep ="_"))


# PART - 3
# Compute AM, PM peak periods
hourly_counts <- hourly_counts %>% 
                 mutate(CNT_2020 = rowSums(select(.,contains("CNT"))),
                        CNT_PER_1 = round(CNT_7 + CNT_8 + CNT_9, -3),
                        CNT_PER_2 = round(CNT_16 + CNT_17 + CNT_18, -3),
                        CNT_PER_3 = CNT_2020 - (CNT_PER_1 + CNT_PER_2)
                        )

write.dbf(hourly_counts, paste(path,"Profile_Counts_Dir_v2.dbf", sep = "\\"))

