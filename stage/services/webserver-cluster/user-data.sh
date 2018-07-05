#!/bin/bash
cat > index.html <<EOF
<h1> Hello, World </h1>
<h1> IaC is Awesome!! - Girish </h1>
<p> DB address: ${db_address}</p>
<p> DB port: ${db_port}</p>
EOF
nohup busybox httpd -f -p "${server_port}" &
