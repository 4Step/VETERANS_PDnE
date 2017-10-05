
path <- "C:\\projects\\Veterans_ExpressWay\\ODME\\Base\\data_prep"
setwd(path)
turn_pen <- "TURN_PK_40B.PEN"
subarea_nodes <- "Subarea_B40.dbf"

library(foreign)
library(dplyr)
library(tidyr)

nodes <- read.dbf(subarea_nodes)
tp <- read.table(turn_pen)

tp$v1_n <- 0
tp$v2_n <- 0
tp$v3_n <- 0

tp$v1_n <- nodes$N[match(tp$V1,nodes$OLD_NODE)]
tp$v2_n <- nodes$N[match(tp$V2,nodes$OLD_NODE)]
tp$v3_n <- nodes$N[match(tp$V3,nodes$OLD_NODE)]

tp <- tp[!is.na(tp$v1_n),c("v1_n","v2_n","v3_n","V4", "V5")]

write.table(tp, "subarea_turn_penalty.PEN", row.names = FALSE, col.names = FALSE,sep = "    ")
