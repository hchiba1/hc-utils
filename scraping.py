#!/usr/bin/env python3
import sys
import requests
from bs4 import BeautifulSoup

url = sys.argv[1]
res = requests.get(url)
soup = BeautifulSoup(res.content)
print(soup)
