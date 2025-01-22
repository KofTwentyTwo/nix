#!/bin/bash

security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain > ./config/ca-certs.pem
security find-certificate -a -p /Library/Keychains/System.keychain >> ./config/ca-certs.pem
security find-certificate -a -p /Users/$(whoami)/Library/Keychains/login.keychain-db >> ./config/ca-certs.pem

