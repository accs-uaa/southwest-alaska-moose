# Objective: Recode GPS telemetry data so that redeployed collars are uniquely identified, based on deployment/redeployment dates identified in the deployment metadata table.
# Last updated: 16 Mar 2020

# Author: A. Droghini (adroghini@alaska.edu)
#         Alaska Center for Conservation Science

# Notes:
# Work in progress. Does what I need it to do for now, but there are several improvements that could be made:

# 1. Right now, makeRedeploysUnique only works if it is run on the subset of tags identified as "redeploy". This isn't ideal and there must be a way to shove tagRedeploy and codeRedeploy into a single function (see Attempt below). I've tried doing that but I run into problems when it comes to iterating it over the entire dataframe. I wanted to avoid using a for loop but couldn't figure out how to get apply to work for me when merging both functions 

# 2. Master function should also filter out all the redeploys coded as "error". For now, doing this as a separate line.

#3. makeRedeploysUnique only works if you have no more than one redeploy (i <= 2). Ideally, it would be able to iterate over any length of i and sequence through all letters of the alphabet to recode non-unique tags. 

#4. Would be more convenient if the user could specify the name of the tag ID and Date columns. Right now, tagID columns has to be called tag_id and date column has to be called LMT_Date. Same for redeployList- columns must be named tag_id, deploy_on_timestamp, and deploy_off_timestamp. Again, this is because I can't figure out how to have that work with the apply function.

# Evaluate whether tag was redeployed----
# The function takes two arguments: a vector of (non-unique) tag/collars IDs and a vector of collar IDs that have been redeployed
# It returns a tag status that specifies where the tag is unique or has been redeployed

tagRedeploy <- function(tagList,redeployList) {
  tagStatus <- ifelse(tagList %in% redeployList, "redeploy","unique")
}

# Uniquely code redeploys----
# This function appends letters to non-unique tag IDs (i.e. identified as "redeploy" by function tagRedeploy)
# Only works if there is one redeploy
# tagData is a dataframe that requires the following column names: tag_id, LMT_Date
# redeployData is a dataframe that requires the following column names: tag_id, deploy_on_timestamp, deploy_off_timestamp

makeRedeploysUnique <- function(tagData, redeployData) {
  
  tag = tagData[["tag_id"]]
  
  date = tagData[["LMT_Date"]]
  
  redeploySubset <- subset(redeployData, tag_id == tag)
  
  start =  redeploySubset[["deploy_on_timestamp"]]
  
  end =  redeploySubset[["deploy_off_timestamp"]]
  
  i = nrow(redeploySubset)
  
  if (date >= start[i-1] & date <= end[i-1]) {
    
    deployment_id = paste("M",tag,"a",sep="")
    
  } else if (date >= start[i]) {
    
    deployment_id = paste("M",tag,"b",sep="")
    
  } else {
    deployment_id = "error"
  }
  deployment_id  
} 

# Attempt at merging both functions together----
# I can't figure out a why to run this either on its own (only operates on first index) or as an apply function (has an extra argument)

failedFunction <- function(tagID,fixDate,redeployList,redeployID, dateOn, dateOff) {
  
  tagStatus <- ifelse(tagID %in% redeployID, "redeploy",paste0("M",tagID,sep=""))
  
  if (tagStatus == "redeploy"){
    
    redeploySubset <- subset(redeployList, redeployID == tagID)
    
    i = nrow(redeploySubset)
    
    if (fixDate >= dateOn[i-1] & fixDate <= dateOff[i-1]) {
      
      deployment_id = paste("M",tagID,"a",sep="")
      
    } else if (fixDate >= dateOn[i]) {
      
      deployment_id = paste("M",tagID,"b",sep="")
      
    } else {
      deployment_id = "error"
    }
  }
  else {
    deployment_id = tagStatus
  }
  deployment_id
}

rm(failedFunction)

# test$new_id <- failedFunction(test$tag_id,test$LMT_Date,redeployList,redeployList$tag_id,redeployList$deploy_on_timestamp,redeployList$deploy_off_timestamp)
# test$new_id<-apply(X=test,MARGIN=1,FUN=failedFunction,test$tag_id,test$LMT_Date,redeployList,redeployList$tag_id,redeployList$deploy_on_timestamp,redeployList$deploy_off_timestamp)
      