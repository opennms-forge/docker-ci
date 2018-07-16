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

initConfig() {
    if [ -z $MAVEN_PROXY ]; then
        echo "No Maven Proxy provided. Skipping"
    else
        # Ensure ~/.m2 exists
        if [ ! -d ~/.m2 ]; then
            mkdir ~/.m2
        fi
        echo "Maven Proxy provided: ${MAVEN_PROXY}"
        echo "Writing MAVEN_PROXY to ~/.m2/settings.xml"
        cp "${BAMBOO_HOME}/settings.xml.template" ~/.m2/settings.xml
        sed -i "s,<url>\${MAVEN_PROXY}</url>,<url>${MAVEN_PROXY}</url>," ~/.m2/settings.xml
    fi
}

startPostgres() {
    su postgres -c '/usr/pgsql-9.6/bin/postgres -D /var/lib/pgsql/data > /dev/null 2>&1 &'
    sleep 5
    psql -U postgres -h localhost -tAc "SELECT 1 FROM pg_roles WHERE rolname='opennms'" | grep -q 1 || psql -U postgres -h localhost -c 'create user opennms' || exit
}

startSshd() {
    /usr/sbin/sshd -D > /dev/null 2>&1 &
}

start() {
    initConfig
    startSshd
    startPostgres
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
while getopts sah flag; do
    case ${flag} in
        s)
            start
            ;;
        a) 
            initConfig
            startAgent
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
