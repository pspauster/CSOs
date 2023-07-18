library(DBI)
library(RSQLite)
library(tidyverse)
library(sf)
library(mapview)

con <- dbConnect(SQLite(), "cso_1.db")

as.data.frame(dbListTables(con))

waterbodies1 <- dbReadTable(con, 'waterbodies')%>% 
  mutate(name = tolower(name),
         # long_stub = round(long, digits = 2),
         # lat_stub = round(lat, digits = 2)
         ) #%>% 
  #st_as_sf(coords = c("long", "lat"))

con2 <- dbConnect(SQLite(), "cso_2.db")

as.data.frame(dbListTables(con2))

waterbodies2 <- dbReadTable(con2, 'waterbodies') %>% 
  filter(wbid != "wbid") %>% 
  mutate(name = tolower(name),
         long = as.double(long),
         lat = as.double(lat),
         # long_stub = as.double(str_sub(long, 1, 6)),
         # lat_stub = as.double(str_sub(lat, 1, 5))
          ) #%>% 
  #st_as_sf(coords = c("long", "lat"))
  
nomatch1 <- anti_join(waterbodies1, waterbodies2, by = "name")

waterbodies <- left_join(waterbodies2, waterbodies1, by = c("name" = "name"), suffix = c("_2","_1")) %>% 
  bind_rows(waterbodies1 %>% filter(name %in% nomatch1$name)) %>% 
  mutate(db1 = if_else(name %in% waterbodies1$name, T, F),
         db2 = if_else(name %in% waterbodies2$name, T, F),
         long_2 = if_else(is.na(long_2), long, long_2),
         lat_2 = if_else(is.na(lat_2), lat, lat_2),
         wbid = if_else(is.na(wbid), as.character(row_number()), wbid))

advisories1 <- dbReadTable(con, 'advisories') %>% 
  mutate(name = tolower(waterbody),
         until = as.Date(until),
         date = if_else(is.na(date), until, as.Date(date))) %>%
  rename(expires = until) %>% 
  left_join(waterbodies %>% select(name, wbid), by = "name")

advisories2 <- dbReadTable(con2, 'advisories')%>% 
  mutate(wbid = as.character(wbid),
         expires = as.Date(expires),
         date = as.Date(date)
         )

advisories <- bind_rows(advisories1, advisories2) 

advisories_waterbodies <- advisories %>% 
  select(-name) %>% 
  left_join(waterbodies, by = "wbid") %>% 
  mutate(expires = as.Date(expires),
         date = as.Date(date))

saveRDS(advisories_waterbodies, "combined_advisories_waterbodies.rds")


