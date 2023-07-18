library(tidyverse)

stub <- "https://www.nyc.gov/assets/dep/downloads/pdf/water/stormwater/spdes-bmp-cso-annual-report-"

years <- as.character(2010:2021)

walk(years, ~
       download.file(url = paste0(stub,.x,".pdf"), destfile = paste0("dep_reports/",.x)))

