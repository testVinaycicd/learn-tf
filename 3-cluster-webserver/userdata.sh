#!/bin/bash
echo "hello world" > index.html
nohup busybox httpd -f -p 8080 &