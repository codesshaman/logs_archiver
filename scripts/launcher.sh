#!/bin/bash

source .env

01_get_global_list.sh ${FOLDER_PATH} | 02_send_dirs_to_remover.sh
