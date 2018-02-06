#!/bin/sh

trap 'exit' SIGINT

if [ $(whoami) != root ]; then
    if [ ! -f $HOME/.google_authenticator ]; then
        echo Initialize google-authenticator
        /usr/local/bin/google-authenticator -t -d -W -u -f
    fi
fi
