
1.  backingservice相关功能是datafoundry平台基于openshift定制开发，
因此只能通过datafoundry台客户端工具登陆平台后使用  

    ```  
    oc login  
    ```  
1.  查看可以使用的backingservice  

    ```  
    oc get bs -n openshift  
    ```  
1. 获取backingservice plan id  

    ```  
    oc describe bs MongoDB -n openshift  
    Name:			MongoDB  
    Created:		3 weeks ago  
    Labels:			asiainfo.io/servicebroker=rdb  
    Annotations:		<none>   
    Description:		A MongoDB Instance  
    Status:			Active  
    Bindable:		true  
    Updateable:		false  
    displayName:		MongoDB  
    documentationUrl:	https://docs.mongodb.org/manual/  
    longDescription:	MongoDB unleashes the power of software and data for innovators everywhere  
    providerDisplayName:	asiainfoLDP  
    supportUrl:		https://www.mongodb.org/  
    ────────────────────  
    Plan:		Experimental  
    PlanID:		E28FB3AE-C237-484F-AC9D-FB0A80223F85  
    PlanDesc:	share a mongodb database in one instance  
    PlanFree:	true  
    Bullets:   
      20 GB of Disk   
      20 connections  
    PlanCosts:  
      CostUnit:	MONTHLY  
      Amount:   
        eur: 49   
        usd: 99   
      CostUnit:	1GB of messages over 20GB   
      Amount:   
        eur: 0.49   
        usd: 0.99  
    ────────────────────   
    Plan:		ShareandCommon   
    PlanID:		257C6C2B-A376-4551-90E8-82D4E619C852  
    PlanDesc:	share a mongodb database in one instance,but can select from database aqi_demo  
    PlanFree:	false   
    Bullets:  
      20 GB of Disk  
      20 connections  
    PlanCosts:  
      CostUnit:	MONTHLY  
      Amount:  
        eur: 49  
        usd: 99  
      CostUnit:	1GB of messages over 20GB  
      Amount:  
        eur: 0.49  
        usd: 0.99  
    No events.  
    ```    
1. 使用`ShareandCommon`计划创建backingservice实例  

    ```  
    oc new-backingserviceinstance mymongodb --backingservice_name=MongoDB  --planid=257C6C2B-A376-4551-90E8-82D4E619C852
    Backing Service Instance has been created.
    ```  
1. 启动Rstudio应用  

    ```  
    oc run rstudio --image=registry.dataos.io/guestbook/rstudio
    oc expose dc rstudio --port=8787
    oc expose svc rstudio
    ```  
1. 将backingservcie实例mymongodb和Rstudio应用绑定  

    ```  
    oc bind mymongodb rstudio
    ```  
1. 以上准备完成后通过rstudio router地址登陆rstudio，执行下列代码，backingservice和其他相关指令的详细说明见user-guide  

    ```  
    library(mongolite)
    library(plyr)
    library(ggplot2)
    library("scales")
    library("reshape")

    #通过DATAFoundry backingservice获取共享数据
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
    #查看共享数据的数据量
    con$count()
    #查看共享数据的数据内容
    mtcars_demo<-con$find()

    #进行数据分析
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

    ```  
