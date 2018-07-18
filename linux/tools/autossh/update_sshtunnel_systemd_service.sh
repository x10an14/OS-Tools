#!/bin/bash

sudo systemctl daemon-reload
sudo service sshtunnel restart
sudo service sshtunnel status
