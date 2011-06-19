#!/bin/bash
#

function setup_file() {
    local file="$1"

    function _setup_conditionally() {
        cond=$1
        shift
        if [[ ! $cond =~ $yes ]]; then
            local comment="# "
        fi
        config="$config\n${comment}$*"
    }

    local config=

    config="\n# Load and configure smartcd\nsource ~/.bash_arrays\nsource ~/.bash_varstash\nsource ~/.bash_smartcd"

    _setup_conditionally "$alias_cd"       "alias cd=smartcd"
    _setup_conditionally "$alias_pushd"    "alias pushd=smartpushd"
    _setup_conditionally "$alias_pushd"    "alias popd=smartpopd"
    _setup_conditionally "$enable_hook"    "setup_smartcd_prompt_hook"
    _setup_conditionally "$autoconfigure"  "VARSTASH_AUTOCONFIGURE=1"
    _setup_conditionally "$autoedit"       "VARSTASH_AUTOEDIT=1"
    _setup_conditionally "$automigrate"    "SMARTCD_AUTOMIGRATE=1"
    _setup_conditionally "$legacy"         "SMARTCD_LEGACY=1"

    # Add commented-out quiet settings so the user can enable them later
    _setup_conditionally ""                "SMARTCD_QUIET=1"
    _setup_conditionally ""                "VARSTASH_QUIET=1"

    if ! grep "alias cd=smartcd" "$file" >/dev/null 2>&1; then
        echo "Configuring $file"
        echo -e $config >> $file
    else
        echo "$file already appears to be configured, please check it for correctness"
        echo "This is what you configured:"
        echo -e $config
    fi

    unset -f _setup_conditionally
}

yes="^y"
echo "It looks like you're running $SHELL"
echo -n "Which shell would you like to configure? [$SHELL] "
read which_shell < /dev/tty
which_shell=${which_shell:=$SHELL}

if [[ $which_shell =~ 'bash' ]]; then
    possible_files=".bashrc .bash_profile .profile"
elif [[ $which_shell =~ 'zsh' ]]; then
    possible_files=".zshrc"
else
    echo "Unknown shell, sorry!  Only bash and zsh are supported at this time"
    exit 1
fi

echo
echo "[ alias cd=smartcd ]"
echo -n "Would you like to alias cd to smartcd?  This is the recommended way to run smartcd [Y/n] "
declare -l alias_cd
read alias_cd < /dev/tty
: ${alias_cd:=y}

echo
echo "[ alias pushd=smartpushd ]"
echo "[ alias popd=smartpopd   ]"
echo -n "Would you like to alias pushd and popd? [Y/n] "
declare -l alias_pushd
read alias_pushd < /dev/tty
: ${alias_pushd:=y}

echo
echo "[ setup_smartcd_prompt_hook ]"
echo "Would you like to enable prompt-command hooks?  (This is only recommended if you are an"
echo -n "\"autocd\" user, say no if you are unsure [y/N] "
declare -l enable_hook
read enable_hook < /dev/tty
: ${enable_hook:=n}

echo
echo "[ VARSTASH_AUTOCONFIGURE=1 ]"
echo -n "Would you like to automatically configure smartcd when you run stash or autostash manually? [y/N] "
declare -l autoconfigure
read autoconfigure < /dev/tty
: ${autoconfigure:=n}

if [[ $autoconfigure =~ $yes ]]; then
    echo
    echo "[ VARSTASH_AUTOEDIT=1 ]"
    echo -n "Would you also like to edit the smartcd config after it is automatically configured? [y/N] "
    declare -l autoedit
    read autoedit < /dev/tty
    : ${autoedit:=n}
fi

echo
echo "[ADVANCED USAGE]"

echo
echo "[ SMARTCD_AUTOMIGRATE=1 ]"
echo -n "Would you like to automigrate legacy smartcd scripts? [y/N] "
declare -l automigrate
read automigrate < /dev/tty
: ${automigrate:=n}

echo
echo "[ SMARTCD_LEGACY=1 ]"
echo -n "Would you like to allow legacy scripts to run in-place? (DISCOURAGED) [y/N] "
declare -l legacy
read legacy < /dev/tty
: ${legacy:=n}

echo
for file in $possible_files; do
    if [[ -f "$HOME/$file" ]]; then
        echo -n "I see you have a $file, would you like to set that up? [Y/n] "
        declare -l answer
        read answer < /dev/tty
        : ${answer:=y}
        if [[ $answer =~ $yes ]]; then
            setup_file "$HOME/$file"
            setup=1
        fi
    fi
done

if [[ -z $setup ]]; then
    echo -n "You did not configure any files, which file would you like to set up? "
    read filename < /dev/tty
    if [[ -n "$filename" ]]; then
        real_filename=$(readlink -f $(eval echo $filename))
        if [[ -f "$real_filename" ]]; then
            setup_file "$real_filename"
        else
            echo "Sorry, I can't find $filename"
        fi
    else
        echo "Ok, nevermind then"
    fi
fi
