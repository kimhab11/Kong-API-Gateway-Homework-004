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
    version: '2.1'

services:
  #######################################
  # Postgres: Kong Database
  #######################################
  kong-database:
    image: postgres:9.6-alpine
    container_name: kong-db
    environment:
      POSTGRES_DB: kong
      POSTGRES_USER: kong
      POSTGRES_PASSWORD: kong
    networks:
      - default
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "kong"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: on-failure

  #######################################
  # Kong database migration
  #######################################
  kong-migrations:
    image: kong:latest
    command: kong migrations bootstrap
    depends_on:
      kong-database:
        condition: service_healthy
    env_file:
      - ./kong.env
    networks:
      - default
    restart: on-failure

  #######################################
  # Kong: The API Gateway
  #######################################
  kong:
    image: kong:latest
    container_name: kong-api
    depends_on:
      kong-database:
        condition: service_healthy
    env_file:
      - kong.env
    networks:
      - default
      - proxy
    ports:
      - "127.0.0.1:8001:8001"
    healthcheck:
      test: ["CMD", "kong", "health"]
      interval: 10s
      timeout: 10s
      retries: 10
    restart: on-failure

  #######################################
  # Konga database migration
  #######################################
  konga-prepare:
    image: pantsel/konga
    command: "-c prepare -a postgres -u postgresql://kong:kong@kong-db:5432/konga_db"
    networks:
      - default
    restart: on-failure
    depends_on:
      kong-database:
        condition: service_healthy

  #######################################
  # Konga: GUI of KONG Admin API
  #######################################
  konga:
    image: pantsel/konga
    env_file:
      - kong.env
    networks:
      - default
      - proxy
    restart: on-failure
    depends_on:
      kong-database:
        condition: service_healthy

networks:
  proxy:
    external: true
