
#!/usr/bin/env bash
########################################################################################################################

########################################################################################################################
VERSION="v1.0.0 2019-11-25"
ORG_DEFAULT_NAME="devOrg"
ORG_DEFAULT_DURATION=30
ORG_SET_AS_DEFAULT=""

WITHOUT_INTERACTION=0
CREATE_TEMP=0
SILENT=0
OPEN_ORG=1
LOG_FILE=''

COLOR_HEADER='\033[0;34m'
COLOR_HINT='\033[1;33m'
COLOR_EXAMPLE='\033[90m'

COLOR_RESET='\033[0m' # No Color
#cd `dirname $0`/..

orgName="$ORG_DEFAULT_NAME"
setAsDefault="n"
orgDuration=0

function out ()
{
    string=$1
    shift

    if [[ $SILENT -eq 0 ]]
    then
        if [[ "$@" ]]
        then
            echo $@ "$string";
        else
            echo "$string";
        fi
    fi
}

# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -n|--name)
            CUSTOM_ORG_NAME="$2"
            shift # past argument
            shift # past value
        ;;
        -t|--temp)
            CREATE_TEMP=1
            shift # past argument

            if [[ ! "$1" =~ ^- ]]
            then
                TEMP_ORG_NAME="$1"
                shift # past value
            fi
        ;;
        -x|--expire-days)

            shift # past argument

            if [[ ! "$1" =~ ^[0-9]+$ ]] || [[ $1 -le 0 ]]
            then
                echo -e "${COLOR_HINT}Parameter -x|--expire-days requires an integer value > 0!${COLOR_RESET}"
                exit 1
            else
                orgDuration=$1
            fi

            shift # past value
        ;;
        -v|--version)
            echo "$VERSION"
            exit
        ;;
        -s|--silent)
            SILENT=1
            shift # past argument
        ;;
        -d|--set-org-as-default)
            setAsDefault="y"
            shift # past argument
        ;;
        -no|--do-not-open-org)
            OPEN_ORG=0
            shift # past argument
        ;;
        -w|--without-interaction)
            WITHOUT_INTERACTION=1
            shift # past argument
        ;;
        -h|--help|--hrlp)
            echo "Creating a scratch org for the current project \"$ORG_DEFAULT_NAME\""
            echo ""
            echo "This script is"
            #echo "  1. installing dependent package ($PACKAGE_DIA_BASE_VERSION)"
            echo "  1. pushing metadata"
            echo "  2. assigning permission sets"
            echo "  3. running setup script with test data creation"
            echo "  4. and opening the org"
            echo ""
            echo -e "${COLOR_HEADER}Flags${COLOR_RESET}"
            echo -e "  ${COLOR_HINT}-d|--set-org-as-default${COLOR_RESET}      Set new scratch org as default"
            echo -e "  ${COLOR_HINT}-h|--help${COLOR_RESET}                    Print this help and exit"
            echo -e "  ${COLOR_HINT}-n|--name${COLOR_RESET}                    Name aka alias of the scratch org"
            echo -e "  ${COLOR_HINT}-no|--do-not-open-org${COLOR_RESET}        Do not open org at the end"
            echo -e "  ${COLOR_HINT}-s|--silent${COLOR_RESET}                  Suppress any output"
            echo -e "  ${COLOR_HINT}-t|--temp${COLOR_RESET}                    Create a temporary scratch org with duration of 1 day and a temporary name by not setting the org as default"
            echo -e "  ${COLOR_HINT}-v|--version${COLOR_RESET}                 Print version and exit"
            echo -e "  ${COLOR_HINT}-w|--without-interaction${COLOR_RESET}     Run script without any interaction (only in combination with -t|--temp)"
            echo -e "  ${COLOR_HINT}-x|--expire-days${COLOR_RESET}             Lifetime of scratch org in days"
            echo ""
            echo -e "${COLOR_HEADER}Examples${COLOR_RESET}"
            echo -e "  $0 -t -n ManagerAssignment       ${COLOR_EXAMPLE}Create a temporary scratch org with name \"ManagerAssignment\"${COLOR_RESET}"
            echo -e "  $0 -t ManagerAssignment          ${COLOR_EXAMPLE}Create a temporary scratch org containing \"ManagerAssignment\" in its unique name${COLOR_RESET}"
            echo -e "  $0 -t -w -s                      ${COLOR_EXAMPLE}Create a temporary scratch org without any further interaction and output${COLOR_RESET}"
            exit
            ;;
            *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
        ;;
    esac
done

#echo "SILENT: $SILENT"
#echo "TEMP: $CREATE_TEMP"
#echo "WITHOUT_INTERACTION: $WITHOUT_INTERACTION"

if [[ $WITHOUT_INTERACTION -eq 1 ]]
then

    if [[ $CREATE_TEMP -eq 0 ]]
    then
        echo -e "${COLOR_HINT}Parameter -w|--without-interaction requires parameter -t|--temp to be set!${COLOR_RESET}"
        exit 1
    fi
else
    if [[ $SILENT -eq 1 ]]
    then
        echo -e "${COLOR_HINT}Parameter -s|--silent currently requires parameter -w|--without-interaction to be set!${COLOR_RESET}"
        exit 1
    fi
fi


out "----------------------------------------------------------------------"
out " Create a new scratch org and push metadata"
out "----------------------------------------------------------------------"
out "${COLOR_HINT}Add -h|--help for help${COLOR_RESET}" -e
out ""

#--------------------------------------------------------
# Scratch Org
#--------------------------------------------------------
if [[ "$CUSTOM_ORG_NAME" != "" ]]
then
    orgName=$CUSTOM_ORG_NAME
fi

if [ $CREATE_TEMP -eq 0 ]
then
    out "Scratch Org"
    out "    - ${COLOR_HEADER}Name:${COLOR_RESET} $orgName (enter other to overwrite or press enter) " -n -e
    read orgNameCustom
    out "    - ${COLOR_HEADER}Lifetime:${COLOR_RESET} $ORG_DEFAULT_DURATION days (enter other to overwrite or press enter) " -n -e
    read orgDuration
    out "    - ${COLOR_HEADER}Set as default scratch org${COLOR_RESET} (y or n, default is no) " -n -e
    read setAsDefault

    if [[ "$orgNameCustom" != "" ]] ; then orgName="$orgNameCustom" ; fi

    echo ""
else

    if [[ $orgDuration -le 0 ]] ; then orgDuration=1 ; fi

    # Temporary scratch org name
    if [[ "$CUSTOM_ORG_NAME" == "" ]]
    then
        tempOrgName=""
        if [[ "$TEMP_ORG_NAME" != "" ]]
        then
            tempOrgName="-""$TEMP_ORG_NAME""-"
        fi
        orgName="$ORG_DEFAULT_NAME""Temp""$tempOrgName`date +\"%s\"`"
    fi
fi

if [[ "$orgDuration" == "" ]] || [[ "$orgDuration" -le 0 ]] ; then orgDuration="$ORG_DEFAULT_DURATION" ; fi
if [[ "$setAsDefault" == "y" ]] ; then ORG_SET_AS_DEFAULT="-s" ; fi

setOrgDefaultMessage="not setting as default org"
if [[ "$ORG_SET_AS_DEFAULT" != "" ]] ; then setOrgDefaultMessage="set as default org"; fi

out "Creating scratch org \"$orgName\" with "
out "- duration of $orgDuration day(s)"
out "- $setOrgDefaultMessage"
out ""

if [[ $WITHOUT_INTERACTION -eq 0 ]]
then
    out "(press any key to continue or Ctrl + c to abort ...) " -n
    read
else
    out ""
fi

out "Please wait ..."
out "Start on `date`"
out ""

sfdx force:org:create -f config/project-scratch-def.json -a $orgName -d $orgDuration $ORG_SET_AS_DEFAULT
#if [[ $? -gt 0 ]] ; then echo "Exit from previous error"; exit 1; fi
out ""

#--------------------------------------------------------
# Install Packages
#--------------------------------------------------------
# DLRS (https://github.com/afawcett/declarative-lookup-rollup-summaries)
echo "Installing Package declarative-lookup-rollup-summaries 2.12 (this might take a while) ..."
result=`sfdx force:package:install -u $orgName --publishwait 5 --package 04t6g000008arl1AAA`

reportCmd=`echo "$result" | sed -n '/^sfdx force:package:install:report/p'`

if [[ "$reportCmd" != "sfdx"* ]]
then
    out "Unexpected result: $result"
    exit 1
fi

i=0
while true
do

    if [[ $(( i % 10 )) == 0 ]]
    then

        result=`$reportCmd`

        if [[ "$result" == "Successfully"* ]]
        then
            out "$result"
            break;
        fi
    fi

    out "." -n
    sleep 1
    i=$((i + 1))
done
out ""
#--------------------------------------------------------
# Metadata
#--------------------------------------------------------
out "Pushing metadata ..."

#sfdx force:source:deploy -p settings/FieldService.settings-meta.xml -u $orgName
#sfdx force:source:deploy -p settings/FieldService.settings-meta.xml -u $orgName
#sfdx force:source:deploy -p settings/FieldService.settings-meta.xml -u $orgName
#sfdx force:source:deploy -p settings/FieldService.settings-meta.xml -u $orgName
#sfdx force:source:deploy -p settings/FieldService.settings-meta.xml -u $orgName

sfdx force:source:deploy -p force-app/main/default/classes  -u $orgName
sfdx force:source:deploy -p force-app/main/default/triggers  -u $orgName


# Push metadata
sfdx force:source:push -u $orgName -g -f

#if [[ $? -gt 0 ]] ; then echo "Exit from previous error"; exit 1; fi
out ""

#--------------------------------------------------------
# Assign Permission Sets
#--------------------------------------------------------
out "Assigning permission sets ..."

#sfdx force:user:permset:assign -u $orgName -n DIA_Admin

out ""

#--------------------------------------------------------
# Run setup script
#--------------------------------------------------------
out "Run setup script ..."
#sfdx force:apex:execute -u $orgName -f ./anonymous-apex/setup-scratch-org.apex
#if [[ $? -gt 0 ]] ; then echo "Exit from previous error"; exit 1; fi
out ""


#--------------------------------------------------------
# Open scratch org
#--------------------------------------------------------
if [[ $OPEN_ORG -eq 1 ]]
then
    out "Open scratch org ..."
    sfdx force:org:open -u $orgName
   # if [[ $? -gt 0 ]] ; then echo "Exit from previous error"; exit 1; fi
    out ""
fi

out "Finished on `date`"