#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#--------------------------
##	@Synopsis	Bash modular application framework.
##	@Copyright	Copyright 2009, James Pic
##	@License	Apache, unless otherwise specified by a LICENSE file.
##
## The role of module.sh is to traverse application repository directories
## and try to load modules. Loading a module consist of:
## <pre>
## - finding source.sh
## - sourcing source.sh
## - running yourmodule_pre_source()
## - running yourmodule_source()
## - running yourmodule_post_source()
## </pre>
## <p>
## Modules are also able to blacklist themselves.
## <p>
## In order to find modules, this script expects repository paths either:
## <pre>
## - in the environment variable $MODULES_PATH (same format than $PATH)
## - as arguments of the source call (separate paths with space)
## - as arguments of module_pre_source (separate paths with space)
## </pre>
## <p>
## Each module must have a source.sh file which can contain this functions:
## <pre>
## - yourmodule_pre_source(): basically set up variables needed by _source()
## - yourmodule_source(): include all dependencies
## - yourmodule_post_source(): initialise the module, ie. default variables,
##   conf path, whatever...
## </pre>
## <p>
## Eventually, your module can have a yourmodule() function defined in source.sh
## to something meaningful. Think of it as an object constructor.
## <p>
## Submodules are simply subdirectories of modules which contain source.sh. See
## module_pre_source() for more info.
#--------------------------

# Check bash version. We need at least 4.0.x {{{
# Lets not use anything like =~ here because
# that may not work on old bash versions.
if [[ "$(awk -F. '{print $1 $2}' <<< $BASH_VERSION)" -lt 40 ]]; then
	echo "Sorry your bash version is too old!"
	echo "You need at least version 3.2 of bash"
	echo "Please install a newer version:"
	echo " * Either use your distro's packages"
	echo " * Or see http://www.gnu.org/software/bash/"
	return 2
fi
# }}}
if [[ -z $MODULES_PATH ]]; then # {{{
    echo "Sorry, MODULES_PATH is not defined and no path was supplied as argument"
    echo "MODULES_PATH should contain a list of paths like the PATH variable"
    echo "It should contain a list of directories containing modules"
    echo "Each directory should be separated by ':'"
    echo "A module should be a folder with a file called 'source.sh' in it."
	return 2
fi
# }}}

# string module name => string module absolute patH
declare -A module_paths
# list of module names
declare -a module_blacklist

function module() {
    module_pre_source $*
    module_source
    module_post_source
}

#--------------------------
## This function finds all modules and nested submodules in a given path and
## registers it.
## <p>
## With this example layout:
## <pre>
## /yourpath/
## /yourpath/foo/
## /yourpath/foo/source.sh
## /yourpath/foo/bar/source.sh
## </pre>
## <p>
## It will register:
## <pre>
## module "foo" with path "/yourpath/foo"
## module "foo_bar" with path "/yourpath/foo/bar"
## </pre>
## <p>
## It that example case, foo_bar functions should be prefixed by foo_bar_
## instead of just foo_.
## <p>
## The blacklist check is done just before adding the module to $module_paths.
## @param   Paths to find modules in, separated by space.
## @calls   <@function module_blacklist_check>
#--------------------------
function module_pre_source() {
    if [[ -z $1 ]]; then
        # make an array of MODULES_PATH
        declare -a paths=($(echo $MODULES_PATH | tr : " "))
    else
        declare -a paths=()

        for path in $*; do
            paths+=("$path")
        done
    fi

    local module_name=""
    local relative_path=""

    # register modules and paths for each path
    for path in ${paths[@]}; do        
    
        for module_path in `find $path -name source.sh -exec dirname {} \;`; do
            relative_path="${module_path#*$path/}"
            module_name="${relative_path//\//_}"
            
            # blacklist check
            if [[ $(module_blacklist_check $module_name) ]]; then
                continue
            fi
            
            # add to module_path if required
            if [[ ! "${!module_paths[@]}" =~ ^$module_name$ ]]; then
                module_paths[$module_name]=$module_path
            fi
        
        done
    done
}

#--------------------------
## Source, run _pre_source() and _source() for each modules, uses blacklist.
## <p>
## This function loops over the $module_paths associative array and using the
## module name (array key) and module path (array value), it does the
## following for each module:
## <pre>
## - check blacklist
## - source source.sh
## - check blacklist
## - call _pre_source() function if it is declared
## - check blacklist
## - call _source() function if it is declared
## </pre>
## @calls   <@function module_blacklist_check>
#--------------------------
function module_source() {
    local module_name=""
    local module_path=""
    local module_source_path=""
    local module_source=""

    for module_name in ${!module_paths[@]}; do
        module_path="${module_paths[$module_name]}"
        module_source_path="${module_path}/source.sh"
        module_pre_source_function="${module_name}_pre_source"
        module_source_function="${module_name}_source"

        # blacklist check
        if [[ $(module_blacklist_check $module_name) ]]; then
            continue
        fi

        # source module source path
        source $module_source_path
        
        # blacklist check
        if [[ $(module_blacklist_check $module_name) ]]; then
            continue
        fi
        
        # run module pre_source function if it is declared
        if [[ $(declare -f $module_pre_source_function) ]]; then
            $module_pre_source_function
        fi
        
        # blacklist check
        if [[ $(module_blacklist_check $module_name) ]]; then
            continue
        fi
        
        # run module source function if it is declared
        if [[ $(declare -f $module_source_function) ]]; then
            $module_source_function
        fi
    done
}

#--------------------------
## Run _post_source() function for each module.
## <p>
## This function loops over the $module_paths associative array and using the
## module name (array key) and module path (array value), it does the
## following for each module:
## <pre>
## - check blacklist
## - call _post_source() function if it is declared.
## </pre>
## @calls   <@function module_blacklist_check>
#--------------------------
function module_post_source() {    
    local module_post_source_function=""

    for module_name in ${!module_paths[@]}; do
                
        # blacklist check
        if [[ $(module_blacklist_check $module_name) ]]; then
            continue
        fi

        module_post_source_function="${module_name}_post_source"

        if [[ $(declare -f $module_post_source_function) ]]; then
            $module_post_source_function
        fi

    done
}

#--------------------------
## This function will output "Yes" if the first parameter it is called with
## is in the blacklist array.
## It will keep quiet (not output anything) it the first parameter is not
## in the blacklist array.
## <p>
## Modules should not use $module_blacklist directly and should use this
## function to ensure that a module is blacklisted or not.
## <p>
## Example usage:
##
##     if [[ -n $(module_blacklist_check yourmodule) ]]; then
##         echo "yourmodule is blacklisted"
##     else
##         echo "yourmodule is not blacklisted"
##     fi
##
## @param   Module name
#--------------------------
function module_blacklist_check() {
    for module_name in $module_blacklist; do
        if [[ $module_name == $1 ]]; then
            echo "Yes"
            return 0
        fi
    done

    return 1
}

#--------------------------
## This function adds the first parameter to the blacklist.
## <p>
## User modules should not use the $module_blacklist array dirrectly and
## should add modules to the blacklist through this function.
## <p>
## User modules that do sanity checks should call this function if they
## cannot prepare to be useable.
## <p>
## Example usage:
## <pre>
## # add yourmodule to the blacklist
## module_blacklist_add yourmodule
## </pre>
## @param   Module name
#--------------------------
function module_blacklist_add() {
    for module_name in $module_blacklist; do
        if [[ $module_name == $1 ]]; then
            return 0
        fi
    done
    module_blacklist+=("$1")
}

#--------------------------
## This function takes a module name as first parameter and outputs its
## absolute path.
## <p>
## It provides a reliable way for a script in your module to know its own
## location on the file system.
## <p>
## Example usage:
## <pre>
## source $(module_get_path yourmodule)/functions.sh
## </pre>
## Example submodule usage:
## <pre>
## source $(module_get_path yourmodule_submodule)/functions.sh
## </pre>
## @param   Module name
#--------------------------
function module_get_path() {
    echo ${module_paths[$1]}
}

#--------------------------
## This function dumps all module variables.
#--------------------------
function module_debug() {
    echo "For MODULES_PATH: $MODULES_PATH"

    echo "List of loaded modules and paths:"

    for module_name in ${!module_paths[@]}; do
        echo " - ${module_name} from ${module_paths[$module_name]}"
    done

    echo "List of blacklisted modules:"

    for module_name in ${!module_blacklist[@]}; do
        echo " - ${module_name}"
    done
}
