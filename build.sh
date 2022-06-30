#!/bin/bash

PLUGIN_NAME="server-rules"

cd scripting
spcomp $PLUGIN_NAME.sp -i include -o ../plugins/$PLUGIN_NAME.smx
