#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# This "lifestyle" module helps bash users to manage their breaks.
# <p>
# It is particularely good for your health if you use to drink coffee or
# smoke during your breaks. It may also help for laundry or whatever.
# <p>
# The minimal interval between breaks should be configured and saved
# before this module can do any good.
# <p>
# Then it is possible to use break_request() to ask for permission to
# take a break.
# <p>
# In case of rebellion then break_do() should be directly used.
# <p>
# Example usage:
# <pre>
# jpic@natacha:~$ break_conf_interactive 
# $break_interval [7200]: 4
# Changed break_interval to 4
# jpic@natacha:~$ break_request && break_request && sleep 5 && break_request
# Granted, enjoy
# Denied, get back to work.
# Granted, enjoy
# jpic@natacha:~$ cat /home/jpic/.break
# break_interval="4"
# break_previous="1254303082"
# </pre>

# This function should be called when the modhule is loaded. It will
# load the conf and functions submodules.
function break_source() {
    source $(module_get_path break)/functions.sh
}

# This function is responsible for putting the module in a useable state.
#
# It tryes to set some defaults.
function break_post_source() {
    break_interval=7200
    break_conf_path=${HOME}/.break
}
