# Build
`docker build . -t opennms/bamboo-agent --build-arg BAMBOO_DOWNLOAD_ADDRESS=http://192.168.2.239:8085`

# Run
```
docker run --privileged \
    -p "5005:5005" \
    -e MAVEN_PROXY=http://qnaspro:8081/artifactory/remote-repos \
    -e BAMBOO_SERVER_ADDRESS=http://192.168.2.239:8085/agentServer \ 
    -e BAMBOO_SECURITY_TOKEN=5334a1efa9b6bdc56ccc820d6251ce65c196d2ad \ 
    --rm -it opennms/bamboo-agent -s
```

* `/entrypoint.sh -s` starts all required services (postgres, sshd, etc) and finally the bamboo agent.
* `/entrypoint.sh -a` only starts the bamboo agent without any other services.
* `-p "5005:5005"` can be ommitted, but may be useful when debugging failing Integration Tests

NOTE: The agent MUST ALWAYS be manually authenticated at the Bamboo Agent Page.

## Environment Variables

* `MAVEN_PROXY` optional can be used if you want to use a maven proxy. Please provide the full URL
* `BAMBOO_SERVER_ADDRESS` The agentAddress of the bamboo server, e.g. `https://bamboo.opennms.org/agentServer`
* `BAMBOO_SECURITY_TOKEN` The security token required to authenticate the agent with the bamboo server.
