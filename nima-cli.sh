#!/bin/bash
case "$1" in
    -rt|--run-test)
        if [ -z $2 ]
        then
            echo Running tests in default scratch org
            sfdx force:apex:test:run -l RunLocalTests -r human --wait 60 --verbose
            exit
        fi

        sfdx force:apex:test:run -l RunLocalTests -r human --wait 60 --verbose -u $2
    ;;
    -soi|--scratchorg-info)
        if [ -z $2 ] || [ -z $3 ]
        then
            echo "ℹ️    Usage: -soi|--scratchorg-info alias user"
            exit
        fi
        ORGALIAS=$2
        OUTPUTDIR=scratchorgdetails/$2

        if [ ! -d "$OUTPUTDIR" ]; then
            echo "Generating folder $OUTPUTDIR"
            mkdir -p $OUTPUTDIR
        fi

        if [ -z $2 ]
        then
            echo "Generating file scratch_org_info.json..."
            sfdx force:org:display --verbose --json -u $ORGALIAS > $OUTPUTDIR/scratch_org_info.json
            sfdx force:org:display --verbose -u $ORGALIAS
            echo "Done."

            echo "Generating file scratch_user_info.json..."
            sfdx force:user:display --json -u $ORGALIAS > $OUTPUTDIR/scratch_user_info.json
            sfdx force:user:display -u $ORGALIAS
            echo "Done."

            echo "Generating file scratch_auth_info.json..."
            sfdx force:org:open --json -r -u $ORGALIAS  > $OUTPUTDIR/scratch_auth_info.json
            echo "Done."

        else
            echo "Generating file scratch_user_info_$2.json..."
            sfdx force:user:display --json -u $2 > $OUTPUTDIR/scratch_user_info_$2.json
            echo "Done."
        fi
    ;;
    -sdevh|--set-devhub)
        if [ -z $2 ]
        then
            echo "ℹ️    -sdevh|--set-devhub alias"
            exit
        fi
        sfdx force:config:set defaultdevhubusername=$2
    ;;
    -sso|--set-scratchorg)
        if [ -z $2 ]
        then
            echo "ℹ️    -sso|--set-scratchorg alias"
            exit
        fi
        sfdx force:config:set defaultusername=$2
    ;;
    -c2dx|--convert-to-dx)
        if [ -z $2 ]
        then
            ROOTDIR='src'
        else
            ROOTDIR=$2
        fi
        sfdx force:mdapi:convert --rootdir $ROOTDIR
    ;;
    -c2mdapi|--convert-to-mdapi)
        if [ -z $2 ] || [ -z $3 ]
        then
            DEPLOYDIR='deploy'
            ROOTDIR='force-app/main/'
        else
            DEPLOYDIR=$2
            ROOTDIR=$3
        fi

        sfdx force:source:convert -r $ROOTDIR -d $DEPLOYDIR 
    ;;
    -cuser|--create-user)
        if [ -z $2 ] || [ -z $3 ]
        then
            echo "ℹ️    -cuser|--create-user org_alias user_alias"
            exit
        fi

        USERNAME=$3`openssl rand -base64 7  | sed s/[-+=/]//g | tr [A-Z] [a-z]`@foo.org

        echo "create $USERNAME"
        sfdx force:user:create -a $3_user --definitionfile ./config/$3-user-def.json username=$USERNAME -u $2
        echo "display details for new user $2_user"
        sfdx force:user:display -u $USERNAME
        sfdx force:org:open -r -u $USERNAME
    ;;
    -dscaratchorg|--delete-scratchorg)
        if [ -z $2 ]
        then
            echo "ℹ️    -dscaratchorg|--delete-scratchorg alias"
            exit
        fi

        sfdx force:org:delete -p -u $2

        OUTPUTDIR=scratchorgdetails/$2
        rm -rf $OUTPUTDIR
    ;;
    -login|--login-to-org)
        if [ -z $2 ]
        then
            echo 'ℹ️    Usage: -login|--login-to-org alias'
            exit
        else
            ALIAS=$2
        fi

        sfdx auth:web:login -a $ALIAS
        sfdx force:org:display -u $ALIAS --verbose
    ;;
    -logout|--logout-from-org)
        if [ -z $2 ]
        then
            echo 'ℹ️    Usage: -logout|--login-from-org alias'
            exit
        fi
        sfdx auth:logout --targetusername $2 -p
    ;;
    -cpkg|--create-package)
        if [ -z $2 ] || [ -z $3 ]
        then
            echo 'ℹ️    Usage: -cpkg|--create-package packageName packageVersion'
            exit
        fi
        sfdx force:package:version:create --package "$2" --installationkeybypass --wait 60 -a "$3" -n $3 --json -f config/project-scratch-def.json --codecoverage  --targetdevhubusername DevHub
    ;;
    -dpkg|--deploy-package)
        if [ -z $2 ] || [ -z $3 ]
        then
            echo 'ℹ️    Usage: -cpkg|--create-package packageId org_alias'
            exit
        fi
        sfdx force:package:install -p $2 -u $3 -w 1000 -r
    ;;
    -dlogs|--delete-logs)
        sfdx force:data:soql:query -q "SELECT Id FROM ApexLog" -r "csv" > out.csv
        sfdx force:data:bulk:delete -s ApexLog -f out.csv
    ;;
    -remexp|--remove-expired-orgs)
        sfdx force:org:list --clean
    ;;
    -h|--help)
        echo "ℹ️    Commands " 
        echo "ℹ️    Run all tests : -rt | --run-test " 
        echo "ℹ️    Get scratch org info : -soi | --scratchorg-info " 
        echo "ℹ️    Set default Devhub : -sdevh | --set-devhub " 
        echo "ℹ️    Set default scratch org : -sso | --set-scratchorg " 
        echo "ℹ️    Convert from mdapi to sfdx : -c2dx  |  --convert-to-dx " 
        echo "ℹ️    Convert from sfdx to mdapi :-c2mdapi| --convert-to-mdapi " 
        echo "ℹ️    Create username : -cuser  |  --create-user " 
        echo "ℹ️    Delete scrach org : -dscaratchorg  |  --delete-scratchorg " 
        echo "ℹ️    Login to org : -login  |  --login-to-org " 
        echo "ℹ️    Logout from org : -logout  |  --logout-from-org "
        echo "ℹ️    Deploy package to org : -dpkg  |  --deploy-package "
        echo "ℹ️    Delete all logs : -dlogs | --delete-logs "
        echo "ℹ️    Remove expired environments : -remexp | --remove-expired-orgs "
    ;;
    *)
        echo "ℹ️    Usage: -h|--help"
    ;;
esac
