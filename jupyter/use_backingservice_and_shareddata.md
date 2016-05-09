
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
1. 启动jupyter应用  

    ```  
    oc run rstudio --image=registry.dataos.io/guestbook/jupyter --env GRANT_SUDO=true
    oc expose dc jupyter  --port=8888
    oc expose svc jupyter
    ```  
1. 将backingservcie实例mymongodb和jupyter应用绑定  

    ```  
    oc bind mymongodb jupyter
    ```  
1. 以上准备完成后通过jupyter router地址登陆jupyter，新建python notebook执行下列代码，backingservice和其他相关指令的详细说明见user-guide  

    ```  
    def del_mongo_id(mongo_doc):
    del mongo_doc['_id']
    return mongo_doc

    #连接mongo backingservice
    #获取连接信息
    !env|grep BSI_MYMONGO
    #连接只读共享数据库
    from pymongo import MongoClient
    import os
    share_data_uri = 'mongodb://' +  \
    os.environ["BSI_MYMONGODB_USERNAME"] +':' + \
    os.environ["BSI_MYMONGODB_PASSWORD"] +'@' + \
    os.environ["BSI_MYMONGODB_HOST"]     +':' + \
    os.environ["BSI_MYMONGODB_PORT"]     +'/' + \
    'aqi_demo'

    print(share_data_uri)
    conn = MongoClient(share_data_uri)
    db = conn['aqi_demo']
    coll = db['aqi_demo']
    test=coll.find_one()

    coll_data=[ del_mongo_id(i) for i in coll.find()   ]

    import json
    import pandas as pd
    coll_data=json.dumps(coll_data)
    coll_data=pd.read_json(coll_data,orient='records')
    source_cols = coll_data.columns
    coll_data.columns = [s.replace('.','-') for s in source_cols]
    data_records = coll_data[data_list].to_json(orient="records")

    city_name = json.loads(coll_data['city_name'].to_json(orient="values"))
    del coll_data['city_name']
    data_value =  json.loads(coll_data.to_json(orient="values"))
    data_list = coll_data.columns
    print(data_value)
    print(city_name)

    import datetime
    import numpy as np
    from plotly.offline import download_plotlyjs, init_notebook_mode, iplot
    import plotly.graph_objs as go
    init_notebook_mode()

    data = [
        go.Heatmap(
            z=data_value,
            x=data_list,
            y=city_name,
            colorscale='Viridis',
        )
    ]

    layout = go.Layout(
        title='AQI',
        xaxis = dict(ticks='', nticks=36),
        yaxis = dict(ticks='' )
    )

    fig = go.Figure(data=data, layout=layout)

    url = iplot(fig)

    ```  
