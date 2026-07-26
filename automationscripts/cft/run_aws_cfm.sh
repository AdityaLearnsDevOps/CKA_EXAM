#!/bin/bash

CFN_STACK_NAME=""
TEMPLATE_FILE_NAME=""
CAPABILITY_NAME=""

validate_template() {
    echo -e "\n ---------- Validating given template: $TEMPLATE_FILE_NAME ------------\n";
    aws cloudformation validate-template --template-body "file://${TEMPLATE_FILE_NAME}"
}

create_stack() {
    echo -e "\n ---------- Creating stack $CFN_STACK_NAME given template: $TEMPLATE_FILE_NAME ------------\n";
    aws cloudformation create-stack --stack-name $CFN_STACK_NAME --template-body "file://${TEMPLATE_FILE_NAME}"
}

create_iam_stack() {
    echo -e "\n ---------- Creating stack $CFN_STACK_NAME given template: $TEMPLATE_FILE_NAME ------------\n";
    aws cloudformation create-stack --capabilities $CAPABILITY_NAME --stack-name $CFN_STACK_NAME --template-body "file://${TEMPLATE_FILE_NAME}"
}

delete_stack() {
    echo -e "\n ---------- Deleting stack $CFN_STACK_NAME ------------\n";
    aws cloudformation delete-stack --stack-name $CFN_STACK_NAME
}

create_change_set(){
    echo -e "\n ---------- Creating change set stack $CFN_STACK_NAME, change set name $CFN_STACK_NAME, given template: $TEMPLATE_FILE_NAME ------------\n";
    aws cloudformation create-change-set --change-set-type CREATE --stack-name $CFN_STACK_NAME --change-set-name $CFN_STACK_NAME --template-body "file://${TEMPLATE_FILE_NAME}"
}

update_change_set(){
    echo -e "\n ---------- Creating change set stack $CFN_STACK_NAME, change set name $CFN_STACK_NAME, given template: $TEMPLATE_FILE_NAME ------------\n";
    aws cloudformation create-change-set  --stack-name $CFN_STACK_NAME --change-set-name $CFN_STACK_NAME --template-body "file://${TEMPLATE_FILE_NAME}"
}

describe_change_set(){
    echo -e "\n ---------- Describing change set stack $CFN_STACK_NAME &  change set name $CFN_STACK_NAME------------\n";
    aws cloudformation describe-change-set --stack-name $CFN_STACK_NAME --change-set-name $CFN_STACK_NAME 
}

execute_change_set(){
    echo -e "\n ---------- Executing change set stack $CFN_STACK_NAME & change set name $CFN_STACK_NAME ------------\n";
    aws cloudformation execute-change-set --stack-name $CFN_STACK_NAME --change-set-name $CFN_STACK_NAME 
}

delete_change_set(){
    echo -e "\n ---------- Deleting change set stack $CFN_STACK_NAME & change set name $CFN_STACK_NAME ------------\n";
    aws cloudformation delete-change-set --stack-name $CFN_STACK_NAME --change-set-name $CFN_STACK_NAME
}



help() {
    echo -e "Usage Syntax:\t./run_aws_cfm.sh <parameters> -t <template_file_name> -n <stack_name> [--cap <capability_name>] ";
    echo -e "Example: \t./run_aws_cfm.sh v -t CreateS3Bucket.yaml ";
    echo -e "Parameters can be the following:";
    echo -e "\tv\t=\tValidate Template";
    echo -e "\tc\t=\tCreate Stack with given template";
    echo -e "\tccap\t=\tCreate Stack with template providing a capability name for --capabilities argument";
    echo -e "\td\t=\tDelete Stack with given template (stackname mandatory)";
    echo -e "\tccs\t=\tCreate Change Set (dry-run purpose, default CS name: same as provided Stack Name)"; 
    echo -e "\tucs\t=\tUpdate Change Set (dry-run purpose, default CS name: same as provided Stack Name)"; 
    echo -e "\tdesccs\t=\tDescribe Change Set (dry-run purpose)"; 
    echo -e "\tecs\t=\tExecute Change Set (dry-run purpose)";
    echo -e "\tdcs\t=\tDelete Change Set (dry-run purpose)\n";
    echo -e "\thelp\t=\tShow Help\n"
    echo -e "Mandatory Arguments:";
    echo -e "\t-t\t=\tTemplate File Name";
    echo -e "Optional Arguments:";
    echo -e "\t-n\t=\tCloudFormation Stack Name (default: Template file name) (mandatory for delete)";
}

Parse_Args() {
    while [ $# -gt 0 ]; do 
        case $1 in 
            help)
                HELPINFO=true
                break
                ;;
            v) 
                # Validate Template
                shift # Grab values written after 'v' and read it in $1 
                if [[ $1 != "-t" ]] || [[ $1 == "" ]]; then
                    HELPINFO=true
                else 
                    shift
                    TEMPLATE_FILE_NAME=$1
                    #echo $TEMPLATE_FILE_NAME ## debug
                    validate_template
                fi
                break
                ;;
            c) 
                # Create stack 
                shift 
                if [[ $1 != "-t" ]] || [[ $1 == "" ]]; then
                    HELPINFO=true
                else 
                    shift
                    TEMPLATE_FILE_NAME=$1
                    filename_no_extension="${TEMPLATE_FILE_NAME%%.*}"  ## Case sensitive for the variable name, can't have "template_file_name" instead of "TEMPLATE_FILE_NAME"
                    ## If user gave a 2nd argument, then it must be "-name" otherwise show help
                    if [[ $2 != "" ]]; then
                        if [[ $2 == "-n" ]]; then 
                            CFN_STACK_NAME=$3 
                        else 
                            HELPINFO=true
                        fi
                    else 
                        CFN_STACK_NAME=$filename_no_extension
                    fi
                    #echo $CFN_STACK_NAME ## debug

                    create_stack
                fi
                break
                ;;
            ccap)
                # Create stack 
                shift 
                if [[ $1 != "-t" ]] || [[ $1 == "" ]]; then
                    HELPINFO=true
                else 
                    shift
                    TEMPLATE_FILE_NAME=$1
                    filename_no_extension="${TEMPLATE_FILE_NAME%%.*}"  ## Case sensitive for the variable name, can't have "template_file_name" instead of "TEMPLATE_FILE_NAME"
                    ## If user gave a 2nd argument, then it must be "-name" otherwise show help
                    if [[ $2 != "" ]]; then
                        if [[ $2 == "-n" ]]; then 
                            CFN_STACK_NAME=$3 
                        else 
                            HELPINFO=true
                        fi
                    else 
                        CFN_STACK_NAME=$filename_no_extension
                    fi
                    #echo $CFN_STACK_NAME ## debug
                    
                    ## Read the capabilities argument
                    ### If user gave a 3rd arg, then it must be "--cap" otherwise need to show help
                    if [[ $4 != "" ]]; then
                        if [[ $4 == "--cap" ]]; then
                            CAPABILITY_NAME=$5
                        else 
                            HELPINFO=true
                        fi
                    fi
                    

                    create_iam_stack
                fi
                break
                ;;
            d) 
                shift
                if [[ $1 != "-n" ]] || [[ $1 == "" ]]; then
                    echo "Please provide a CFN stack name. For more usage info, please refer below";
                    HELPINFO=true
                else 
                    shift
                    CFN_STACK_NAME=$1
                    #echo $CFN_STACK_NAME ## debug
                    delete_stack
                fi
                break
                ;;
            ccs)
                shift
                ## Referred same from create-stack
                if [[ $1 != "-t" ]] || [[ $1 == "" ]]; then
                    HELPINFO=true
                else 
                    shift
                    TEMPLATE_FILE_NAME=$1
                    filename_no_extension="${TEMPLATE_FILE_NAME%%.*}"  ## Case sensitive for the variable name, can't have "template_file_name" instead of "TEMPLATE_FILE_NAME"
                    ## If user gave a 2nd argument, then it must be "-name" otherwise show help
                    if [[ $2 != "" ]]; then
                        if [[ $2 == "-n" ]]; then 
                            CFN_STACK_NAME=$3 
                        else 
                            HELPINFO=true
                        fi
                    else 
                        CFN_STACK_NAME=$filename_no_extension
                    fi
                    create_change_set
                fi
                break
                ;;
           ucs)
                shift
                ## Referred same from create-stack
                if [[ $1 != "-t" ]] || [[ $1 == "" ]]; then
                    HELPINFO=true
                else 
                    shift
                    TEMPLATE_FILE_NAME=$1
                    filename_no_extension="${TEMPLATE_FILE_NAME%%.*}"  ## Case sensitive for the variable name, can't have "template_file_name" instead of "TEMPLATE_FILE_NAME"
                    ## If user gave a 2nd argument, then it must be "-name" otherwise show help
                    if [[ $2 != "" ]]; then
                        if [[ $2 == "-n" ]]; then 
                            CFN_STACK_NAME=$3 
                        else 
                            HELPINFO=true
                        fi
                    else 
                        CFN_STACK_NAME=$filename_no_extension
                    fi
                    update_change_set
                fi
                break
                ;;
            desccs)
                ## Referred same from delete-stack
                shift
                if [[ $1 != "-n" ]] || [[ $1 == "" ]]; then
                    echo "Please provide a CFN stack name. For more usage info, please refer below";
                    HELPINFO=true
                else 
                    shift
                    CFN_STACK_NAME=$1
                    #echo $CFN_STACK_NAME ## debug
                    describe_change_set
                fi
                break
                ;;
            ecs)
                ## Referred same from delete-stack
                shift
                if [[ $1 != "-n" ]] || [[ $1 == "" ]]; then
                    echo "Please provide a CFN stack name. For more usage info, please refer below";
                    HELPINFO=true
                else 
                    shift
                    CFN_STACK_NAME=$1
                    #echo $CFN_STACK_NAME ## debug
                    execute_change_set
                fi
                break
                ;;
            dcs)
                ## Referred same from delete-stack
                shift
                if [[ $1 != "-n" ]] || [[ $1 == "" ]]; then
                    echo "Please provide a CFN stack name. For more usage info, please refer below";
                    HELPINFO=true
                else 
                    shift
                    CFN_STACK_NAME=$1
                    #echo $CFN_STACK_NAME ## debug
                    delete_change_set
                fi
                break
                ;;
            *)
                echo "Unknown option $1. Please refer usage below."
                HELPINFO=true
                break
                ;;
        esac
    done
}
Parse_Args "$@" # Parameters will be accessible in the form of string array

if [ "$HELPINFO" == true ] || [ $# -eq 0 ]; then  # "-eq" is numeric comparison, "==" is string comparison 
    help
fi