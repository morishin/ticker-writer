# ticker-writer
Get JPY/BTC rate once a minute via https://coincheck.jp/api/ticker and write it to InfluxDB.

## RUN
### 1. docker-compose up
```shell
git clone git@github.com:morishin/ticker-writer.git
cd ticker-writer
DB_USER=<your username> DB_PASS=<your password> docker-compose up -d
open "http://`docker-machine ip`:8083/"
```
### 2. Type your username and password
<img width="512" alt="2016-06-26 13 28 18" src="https://cloud.githubusercontent.com/assets/1413408/16360491/f4681474-3ba1-11e6-83ca-265dc2cba56e.png">

### 3. Select DB and show data
<a href="https://gyazo.com/3d7b2d469b308e046e445ed8b6bfa07a"><img src="https://i.gyazo.com/3d7b2d469b308e046e445ed8b6bfa07a.gif" alt="https://gyazo.com/3d7b2d469b308e046e445ed8b6bfa07a" width="512" /></a>
