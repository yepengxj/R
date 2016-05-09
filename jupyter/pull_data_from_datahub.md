1.  登陆hub.dataos.io平台并订购Meteorological/capital_AQI_data数据项
1.  登陆datafoundry平台发布jupyter应用

    ```  
    oc run jupyter --image=registry.dataos.io/guestbook/jupyter --env GRANT_SUDO=TRUE
    oc expose dc jupyter --port=8888
    oc expose svc jupyter
    ```
1.  使用web浏览器登陆jupyter route地址，新建python notebook并执行如下代码,

    ```  
    !sudo /usr/bin/datahub --daemon

    #datahub客户端登录
    !/usr/bin/datahub_login datahub_username datahub_password

    #创建DATAHUB数据池
    !datahub dp create dptest file://$PWD

    #下载已订购数据-每日各首府城市空气质量报告
    !datahub pull Meteorological/capital_AQI_data:test dptest

    #数据分析
    import json
    import pandas as pd
    data = pd.read_csv('./Meteorological_capital_AQI_data/test')
    source_cols = data.columns
    [s.replace('.','-') for s in source_cols]
    data.columns = [s.replace('.','-') for s in source_cols]
    data_list = data.columns[1:]
    data_records = data[data_list].to_json(orient="records")

    data_value =  json.loads(data[data_list].to_json(orient="values"))
    city_name = json.loads(data.T.to_json(orient="values"))[0]

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
