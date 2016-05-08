
library(mongolite)
library(plyr)
library(ggplot2)
library("scales")
library("reshape”)

#通过DATAFoundry backingservice活取共享数据
env <- system2("env",stdout = T)
BSI_MYMONGODB_USERNAME <-strsplit( env[grep("^BSI_MYMONGODB_USERNAME",env)],"=")[[1]][2]
BSI_MYMONGODB_PASSWORD <-strsplit( env[grep("^BSI_MYMONGODB_PASSWORD",env)],"=")[[1]][2]
BSI_MYMONGODB_HOST     <-strsplit( env[grep("^BSI_MYMONGODB_HOST",env)],"=")[[1]][2]
BSI_MYMONGODB_PORT     <-strsplit( env[grep("^BSI_MYMONGODB_PORT",env)],"=")[[1]][2]
#获取共享数据
shared_data_uri <- paste0("mongodb://",BSI_MYMONGODB_USERNAME,
                          ":",BSI_MYMONGODB_PASSWORD,
                          "@",BSI_MYMONGODB_HOST,
                          ":",BSI_MYMONGODB_PORT,
                          "/aqi_demo")
con <- mongo(collection = "mtcar", url = shared_data_uri)
con$count()
mtcars_demo<-con$find()
mtcars_demo$carname <- rownames(mtcars_demo)
mtcars_demo.m<- melt(mtcars_demo)
mtcars_demo.m<- ddply(mtcars_demo.m, .(variable), transform,
                      rescale = rescale(value))
(p <- ggplot(mtcars_demo.m, aes(variable, carname)) +
  geom_tile(aes(fill = rescale),colour = "white") +
  scale_fill_gradient(low = "white",high = "steelblue"))
base_size <- 6
p +
  labs(x = "",  y = "") +
  scale_x_discrete(expand = c(0, 0)) +
  scale_y_discrete(expand = c(0, 0)) +
  theme(legend.position = "none",
        axis.ticks = element_blank(),
        axis.text.x = element_text(size = base_size*1.5 , angle = 0, hjust = 0, colour = "grey50"))
