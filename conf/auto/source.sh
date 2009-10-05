#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# This submodule of conf allows the user to define the modules which config
# should be auto saved and auto loaded.
# <p>
# It is the only module which _post_source() function should call conf_load()
# because other module should call conf_auto_load_decorator() to load a
# module configuration <b>if</b> the user wants it autoloaded.
# <p>
# See conf_auto/functions.sh for information about the additionnal API for
# conf.
# <p>
# See conf_auto/conf.sh for information about the conf overloads for this
# module.

# Loads the functions that extend the conf API and the conf overloads.
function conf_auto_source() {
    source $(module_get_path conf_auto)/functions.sh
    source $(module_get_path conf_auto)/conf.sh
}

# Sets conf_auto_conf_path and loads the module configuration.
# <p>
# Note: your modules should not call conf_load in their _post_source() func,
# it should call conf_auto_load_decorator() instead, see functions.sh for
# more details.
# @calls conf_load
function conf_auto_post_source() {
    conf_auto_conf_path="$HOME/.conf_auto"

    conf_load conf_auto
}
