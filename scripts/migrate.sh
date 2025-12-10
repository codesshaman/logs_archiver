#!/bin/bash

container="$(grep "ADCM_NAME" .env | sed -r 's/.{,10}//')"

docker exec -it ${container} python /adcm/python/manage.py migrate

sleep 3

docker-compose -f ./docker-compose.yml down ${container}

docker-compose -f ./docker-compose.yml up -d ${container}