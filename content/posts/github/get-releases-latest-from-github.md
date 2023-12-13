---
title: "Get the latest release information of the repos from GitHub"
date: 2023-12-12T13:24:14+08:00
tags: [github]
categories: [latest]
draft: false
---

#### 1. Requirements

* python >= 3.9
* pip install beautifulsoup4

#### 2. Create a python script

get_latest_info_from_github_repos.py

```python
import requests
from bs4 import BeautifulSoup

urls = [
    "https://github.com/geoserver/geoserver",
    "https://github.com/Leaflet/Leaflet",
    "https://github.com/Turfjs/turf/"
]

def get_latest_version(url) -> tuple:
    url = url + "/releases/latest"
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f'Request failed with status {response.status_code}')
    soup = BeautifulSoup(response.text, 'html.parser')
    version = soup.find('span', {'class': 'css-truncate-target'}).get_text(strip=True)
    datetime = soup.find('relative-time').get("datetime")
    return version, datetime


for url in urls:
    version = "UNKNOWN"
    datetime = "UNKNOWN"
    try:
        version, datetime = get_latest_version(url)
    except Exception as e:
        pass
    print(f'{url},{version},{datetime[0:10]}')
```

#### 3. Run the python script

```shell
python python get_latest_info_from_github_repos.py
 
https://github.com/geoserver/geoserver,2.24.0,2023-10-15
https://github.com/Leaflet/Leaflet,v1.9.4,2023-05-18
https://github.com/Turfjs/turf/,v6.5.0,2021-07-10

Process finished with exit code 0
```