# Get eligible trips

# Segments
sb_otaz <- list(seg1 = c(39,31,34),
                seg2 = c(39,31,34, 28,3,27,25,26, 4, 23, 24))

sb_dtaz <- list(seg1 = c(20,5,21,18,22,6,19,17,16, 13, 14, 12, 11, 9, 42, 10, 41,44),
                seg2 =c(11, 9, 42, 10, 41,44))

nb_otaz <- list(seg1 = c(43,45,40,8,42,10,9,11,12,13,14,16,17,18,19,6,21,22,20,5),
                seg2 = c(43,45,40,8,42,10,9,11,12,13,14))

nb_dtaz <- list(seg1 = c(32,33,28),
                seg2 = c(23,24,4,25,26,27,28,3,32,33,28))

# Read trip table

od_file <- "M:\\Projects\\Veterans ELToDv2.3 2017-0628\\Reporting\\ELTOD Output-CSV via Rscript\\OD_Trips_2040.CSV"
csv_out <- "M:\\Projects\\Veterans ELToDv2.3 2017-0628\\Reporting\\ELTOD Output-CSV via Rscript\\eligibleTrips_2040.csv"

df_od <- read.csv(od_file)
colnames(df_od) <- c("OD",c(1:45))
df_od <- df_od %>% gather(OD)
colnames(df_od) <- c("From", "To", "Trips")


sb_seg1 <- df_od %>% 
           filter(From %in% sb_otaz$seg1, To %in% sb_dtaz$seg1) %>%
           summarise(seg1 = sum(Trips))

sb_seg2 <- df_od %>% 
           filter(From %in% sb_otaz$seg2, To %in% sb_dtaz$seg2) %>%
           summarise(seg2 = sum(Trips))


nb_seg1 <- df_od %>% 
           filter(From %in% nb_otaz$seg1, To %in% nb_dtaz$seg1) %>%
           summarise(seg1 = sum(Trips))

nb_seg2 <- df_od %>% 
           filter(From %in% nb_otaz$seg2, To %in% nb_dtaz$seg2) %>%
           summarise(seg2 = sum(Trips))


eligibleTrips <- cbind(sb = c(sb_seg1, sb_seg2),
                       nb = c(nb_seg1, nb_seg2))

write.csv(eligibleTrips, csv_out)

