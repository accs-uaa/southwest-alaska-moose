# Evaluate whether tag is a redeploy or not

tagRedeploy <- function(tagList,redeployList) {
  tagStatus <- ifelse(tagList %in% redeployList, "redeploy","unique")
}

test$tagStatus<-tagRedeploy(test$tag_id,redeployList$tag_id)

test <- gpsData[120830,]


# For redeploys only, figure out whether they are "a" or "b"

codeRedeploy <- function(tagList, redeployList) {
  
  tag = tagList[["tag_id"]]
  
  date = tagList[["LMT_Date"]]
  
  redeploySubset <- subset(redeployList, tag_id == tag)
  
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

test$new_id<-codeRedeploy(test,redeployList)

test<-gpsData
test$tagStatus<-tagRedeploy(test$tag_id,redeployList$tag_id)
test<-subset(test,tagStatus=="redeploy")
test$new_id<-apply(X=test,MARGIN=1,FUN=codeRedeploy,redeployList=redeployList)
      