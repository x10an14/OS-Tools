#!/bin/bash

sudo systemctl daemon-reload
sudo systemctl restart sshtunnel.service
sudo systemctl status sshtunnel.service

