#!/bin/bash -e

# Error codes
E_ILLEGAL_ARGS=126

# Help function used in error messages and -h option
usage() {
    echo ""
    echo "Docker entry script for Bamboo Agent service container"
    echo ""
    echo "-s: Start the Bamboo Agent"
    echo "-h: Show this help."
    echo ""
}

start() {
    startAgent
    if [ ! -f "bamboo-agent.cfg.xml" ]
    then
        echo ""
        echo "********************************************************************************"
        echo "* Startup of this agent failed"
        echo "* This is probably because a newer version is available"
        echo "* Retrying"
        echo "********************************************************************************"
        echo ""
        startAgent
    fi
}

startAgent() {
    cd "${BAMBOO_HOME}"
    java -Dbamboo.home="${BAMBOO_HOME}" -jar bamboo-agent-6.6.1.jar "${BAMBOO_SERVER_ADDRESS}" "${BAMBOO_SECURITY_TOKEN}"
}

# Evaluate arguments for build script.
if [[ "${#}" == 0 ]]; then
    usage
    exit ${E_ILLEGAL_ARGS}
fi

# Evaluate arguments for build script.
while getopts sh flag; do
    case ${flag} in
        s)
            start
            ;;
        h)
            usage
            exit
            ;;
        *)
            usage
            exit ${E_ILLEGAL_ARGS}
            ;;
    esac
done

# Strip of all remaining arguments
shift $((OPTIND - 1));

# Check if there are remaining arguments
if [[ "${#}" > 0 ]]; then
    echo "Error: To many arguments: ${*}."
    usage
    exit ${E_ILLEGAL_ARGS}
fi
