1.  登陆hub.dataos.io平台并订购Meteorological/capital_AQI_data数据项
1.  登陆datafoundry平台发布rstudio应用

    ```  
    oc run rstudio --image=registry.dataos.io/guestbook/rstudio
    oc expose dc rstudio --port=8787
    oc expose svc rstudio
    ```
1.  使用web浏览器登陆rstudio route地址执行如下代码

    ```  
    #登录datahub

    system("datahub_login datahub_username datahub_password")

    #创建datahub数据库池
    system("datahub dp create dptest file://$PWD")

    #拉取数据-各首府城市每日空气质量数
    system("datahub pull Meteorological/capital_AQI_data:test dptest")

    #对比各城市空气质量状况
    library(XML)  
    library("plyr")  
    library("curl")  
    library("scales")  
    library("ggplot2")  
    library("reshape")  

    #载入datahub数据
    aqi_data_capital<-read.csv("/home/rstudio/Meteorological_capital_AQI_data/test")

    #显示载入数据
    aqi_data_capital

    #数据二次加工
    aqi_data_capital$city_name <- with(aqi_data_capital, reorder(city_name, X2016.03.05))
    aqi_data_capital.m<- melt(aqi_data_capital)
    aqi_data_capital.m<- ddply(aqi_data_capital.m, .(variable), transform,
        rescale = rescale(value))

    #显示二次分析结果
    (p <- ggplot(aqi_data_capital.m, aes(variable, city_name)) +
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
