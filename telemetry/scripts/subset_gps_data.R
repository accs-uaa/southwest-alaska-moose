# Last updated: 29 March 2019

# Objective: Subset GPS data to remove autocorrelation between consecutive fixes. The points that remain will be used in our field planning process to verify that our sampling points provide adequate coverage of where moose are actually going.

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

# Create Date/Time column
# Convert to POSIX item
Sys.setenv(TZ="GMT") 
# DST-free timezone equivalent to UTC Date/Time columns
gps.data$DateTime <- paste(gps.data$UTC_Date,gps.data$UTC_Time, sep=" ")
gps.data$DateTime <- as.POSIXct(strptime(gps.data$DateTime, format="%Y-%m-%d %H:%M:%S",tz="GMT"))

# Calculate fix rate (time interval between two consecutive fixes)
# Check for outliers
# Fix rate should be 120 min (3 hours)
for (i in 2:nrow(gps.data)) {
  if (gps.data$CollarID[i] == gps.data$CollarID[i - 1]) {
    gps.data$FixRate[i] <-
      difftime(gps.data$DateTime[i], gps.data$DateTime[i - 1], units = "mins")
  }
}

rm(i)

# Summarize Fix Rate results
fix.summary <- gps.data %>%
  group_by(CollarID) %>%
  summarise(
    obs = length(CollarID),
    start.time = min(DateTime),
    end.time = max(DateTime),
    mean.fix = mean(FixRate,na.rm=TRUE), # first row is NA (no previous fix)
    sd.fix = sd(FixRate,na.rm=TRUE),
    max.fix = max(FixRate,na.rm=TRUE), 
    min.fix = min(FixRate,na.rm=TRUE)
  )

# At the very least, omit CollarIDs 30927, 30928
# Very few fixes, highly variable fix rates. Collar malfunctions?
gps.data <- gps.data %>% 
  filter(!CollarID %in% c("30927", "30928"))

# Other collars aren't perfect but will do for now


## Subset to 24 hours

# Add.start time to main df
fix.summary <- fix.summary %>% 
  select(CollarID,start.time)

gps.data <- inner_join(gps.data,fix.summary,by="CollarID")

# Convert start.time to POSIX
gps.data$start.time <- as.POSIXct(strptime(gps.data$start.time, format="%Y-%m-%d %H:%M:%S",tz="GMT"))

# For each row, calculate the difference between fix time & init time
# For now, interested in keeping one fix rate every day
# If fix rates were exactly one day apart, difference would be 1440 (24 h * 60 min)
# Taking the difference between the Fix


# Can overwrite FixRate column for this
subset.data <- gps.data %>% 
  mutate(FixRate = difftime(DateTime, start.time, units = "mins"),
         DaysSince = difftime(UTC_Date,as.Date(start.time),units="days"),
         FR_1440 = case_when(as.numeric(FixRate) == 0 ~ 0,
                             TRUE ~ abs(as.numeric(FixRate)- 1440*as.numeric(DaysSince))))

min.time <- subset.data %>% 
  group_by(CollarID,UTC_Date) %>% 
  summarize(
    min.time=min(FR_1440))

# Select only rows identified by min.time
subset.data <- semi_join(subset.data,min.time,by=c("CollarID","UTC_Date","FR_1440"="min.time"))

# FR_1440 column can be used to identify missed fix rates
# Given formula above, FR_1440 should be close to zero
# 6 outliers, but ignore for now

subset.data <- subset.data %>% 
  select(-c(FixRate,DaysSince,FR_1440))

rm(min.time,fix.summary)

# Export file for plotting in GIS
write.csv(subset.data,"collar_data/subset_data.csv",row.names=FALSE)
