#!/bin/bash

PLUGIN_NAME="server-rules"

cd scripting
spcomp $PLUGIN_NAME.sp -o ../plugins/$PLUGIN_NAME.smx
