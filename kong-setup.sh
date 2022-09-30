#!/bin/sh

curl -i -X POST \
--url http://localhost:8001/services/ \
--data 'name=task-service' \
--data 'url=http://110.74.194.123:6072' 

curl -i -X POST \
	--url http://localhost:8001/services/task-service/routes \
	--data 'name=task-api' \
	--data 'paths[]=/task' \
	--data 'strip_path=true'

curl -i -X POST \
--url http://localhost:8001/services/ \
--data 'name=user-service' \
--data 'url=http://110.74.194.123:6070' 

curl -i -X POST \
	--url http://localhost:8001/services/user-service/routes \
	--data 'name=user-api' \
	--data 'paths[]=/user' \
	--data 'strip_path=true'