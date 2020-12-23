#!/bin/bash

# load group
function load_group_list()
{
group_list=()
while read line
do
    group_list+=("$(echo -e "$line" | tr -d '[:space:]')")
done < $1
}


# create group
function create_groups()
{
load_group_list "groups.txt"
for group in ${group_list[@]};
do
    gname=$(cut -d: -f 1 <<<${group})
    gid=$(cut -d: -f 2 <<<${group})
    if getent group $gname > /dev/null 2>&1; then
        ginfo=`getent group $gname`
        gname_exist=$(cut -d: -f 1 <<<${ginfo})
        gid_exist=$(cut -d: -f 3 <<<${ginfo})
        if [ $gid != $gid_exist ];
        then
            echo "*** FATAL ERROR"
            echo "Group ID (${gname}:${gid}) you want to add "
            echo "    is different with existed group ID."
            echo "group:gid (new)   : ${gname}:${gid}"
            echo "group:gid (exist) : ${gname_exist}:${gid_exist}"
            exit 1
        fi
        echo "WARNING : ${gname}:${gid} already exist, skipped."
    elif getent group $gid > /dev/null 2>&1; then
        ginfo=`getent group $gid`
        gname_exist=$(cut -d: -f 1 <<<${ginfo})
        gid_exist=$(cut -d: -f 3 <<<${ginfo})
        echo "*** FATAL ERROR"
        echo "Group ID (${gname}:${gid}) you want to add "
        echo "    is duplicated with existed group ID."
        echo "group (new)   : ${gname}:${gid}"
        echo "group (exist) : ${gname_exist}:${gid_exist}"
        exit 1
    else
        groupadd -g ${gid} ${gname}
        echo "${gname}:${gid} is successfully created"
    fi
done
}

# load user
function load_user_list()
{
user_list=()
while read line
do
    user_list+=("$(echo -e "$line" | tr -d '[:space:]')")
done < $1
}

# create users
function create_users()
{
load_user_list "users.txt"
for user in ${user_list[@]};
do
    uname=$(cut -d: -f 1 <<< ${user})
    pass_plain=$(cut -d: -f 2 <<< ${user})
    uid=$(cut -d: -f 3 <<< ${user})
    gid=$(cut -d: -f 4 <<< ${user})
    comment=$(cut -d: -f 5 <<< "${user}")
    homedir=$(cut -d: -f 6 <<< ${user})
    logshell=$(cut -d: -f 7 <<< ${user})
    subgroup=$(cut -d: -f 8 <<< ${user})
    # check primary group exist
    FLAG_PRIMARY_GROUP="-g ${gid}"
    if ! getent group $gid > /dev/null 2>&1;
    then
        if [ ${uid} -eq ${gid} ];
        then
            FLAG_PRIMARY_GROUP=""
        else
            echo "*** FATAL ERROR"
            echo " gid (${gid}) is not found"
            exit 1
        fi
    fi
    # check secondary groups exist
    LIST_SEC_GROUP=(${subgroup//,/ })
    for grp in ${LIST_SEC_GROUP[@]};
    do
        if ! getent group $grp > /dev/null 2>&1;
        then
            echo "*** FATAL ERROR"
            echo " ${grp} is not found"
            exit 1
        fi
    done
    if [ -z $subgroup ];
    then
        FLAG_SECONDARY_GROUP=""
    else
        FLAG_SECONDARY_GROUP="-G ${subgroup}"
    fi
    # comment
    FLAG_COMMENT="-c ${comment}"
    if [ -z $comment ];
    then
        FLAG_COMMENT=""
    fi
    # secondary group
    FLAG_SECONDARY_GROUP="-G ${subgroup}"
    if [ -z $subgroup ];
    then
        FLAG_SECONDARY_GROUP=""
    fi
    if ! getent passwd $uname > /dev/null 2>&1;
    then
        if [ -d ${homedir} ];
        then
            echo "*** FATAL ERROR"
            echo " Home directory is already exist."
            echo " Please give non-existent dir. as home dir.."
            echo " ${uname} did not created"
            exit 1
        fi
        useradd -m -d ${homedir} -u ${uid} ${FLAG_PRIMARY_GROUP} ${FLAG_SECONDARY_GROUP} ${FLAG_COMMENT} -s ${logshell} -p `perl -e 'print crypt("${pass_plain}", "\$6\$[seed]");'` ${uname}
        echo "${uname}:${uid} is successfully created"
    else
        echo "WARNING ${uname}:${uid} already exist, skipped"
    fi
done
}
