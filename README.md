# WildFly Load Balancer with Reverse Proxy Setup

This project demonstrates how to set up a reverse proxy using WildFly's Undertow subsystem. The topology consists of a load balancer (LB), a domain controller (DC), and two backend servers (Backend1 and Backend2). The load balancer distributes traffic between the backend servers, ensuring high availability and scalability.

## Topology Overview

1. **Load Balancer (LB)**:
    - Acts as a reverse proxy using WildFly's Undertow subsystem.
    - Distributes incoming HTTP traffic to the backend servers.
    - Configured with a `standalone-load-balancer.xml` file.

2. **Domain Controller (DC)**:
    - Manages the domain configuration for the backend servers.
    - Configured with `host-master.xml` and `domain.xml`.

3. **Backend Servers (Backend1 and Backend2)**:
    - Serve application traffic.
    - Managed by the domain controller.
    - Configured with `host-slave.xml`.

## Configuration Details

### Load Balancer (`standalone-load-balancer.xml`)
- Configured as a reverse proxy using the Undertow subsystem.
- Defines two backend hosts (`backend1` and `backend2`) for load balancing.
- Uses the `reverse-proxy` handler to route traffic to the backends.
- Example configuration:
  ```xml
  <handlers>
        <reverse-proxy name="lb-handler" problem-server-retry="30" session-cookie-names="JSESSIONID" connections-per-thread="20">
             <host name="backend1" instance-id="backend1" path="/" scheme="http" outbound-socket-binding="backend1"/>
             <host name="backend2" instance-id="backend2" path="/" scheme="http" outbound-socket-binding="backend2"/>
        </reverse-proxy>
  </handlers>
  ```

### Domain Controller (`domain.xml` and `host-master.xml`)
- Manages the backend servers in a domain mode.
- Configures the backend group and socket bindings for communication.
- Example configuration:
  ```xml
  <server-groups>
        <server-group name="backend-group" profile="full">
             <socket-binding-group ref="standard-sockets"/>
        </server-group>
  </server-groups>
  ```

### Backend Servers (`host-slave.xml`)
- Connect to the domain controller for configuration management.
- Each backend server is identified by its name (`backend-one` and `backend-two`).
- Example configuration:
  ```xml
  <domain-controller>
        <remote security-realm="ManagementRealm">
             <discovery-options>
                  <static-discovery name="primary" protocol="remote+http" host="domain-controller" port="9990"/>
             </discovery-options>
        </remote>
  </domain-controller>
  ```

## Docker Compose Setup

The `docker-compose.yml` file orchestrates the deployment of the load balancer, domain controller, and backend servers. Key points:
- The load balancer listens on port `9980` for HTTP traffic.
- The domain controller exposes management ports (`9990`, `9999`).
- Backend servers expose HTTP and management ports.

### Example `docker-compose.yml` Configuration
```yaml
services:
  domain-controller:
     image: quay.io/wildfly/wildfly:23.0.2.Final
     volumes:
        - ./configs/dc/host-master.xml:/opt/jboss/wildfly/domain/configuration/host-master.xml
        - ./configs/dc/domain.xml:/opt/jboss/wildfly/domain/configuration/domain.xml
     ports:
        - "9990:9990"
        - "9999:9999"

  backend1:
     image: quay.io/wildfly/wildfly:23.0.2.Final
     volumes:
        - ./configs/backend1/host-slave.xml:/opt/jboss/wildfly/domain/configuration/host.xml
     ports:
        - "9081:8080"

  backend2:
     image: quay.io/wildfly/wildfly:23.0.2.Final
     volumes:
        - ./configs/backend2/host-slave.xml:/opt/jboss/wildfly/domain/configuration/host.xml
     ports:
        - "9080:8080"

  lb:
     image: quay.io/wildfly/wildfly:28.0.1.Final-jdk17
     volumes:
        - ./configs/lb/standalone-load-balancer.xml:/opt/jboss/wildfly/standalone/configuration/standalone-load-balancer.xml
     ports:
        - "9980:8080"
```

## How to Run

1. Clone the repository and navigate to the project directory.
2. Start the services using Docker Compose:
    ```bash
    docker-compose up
    ```
3. Access the load balancer at `http://localhost:9980`.

## Notes

- Ensure the backend servers are reachable by the load balancer.
- Modify the configurations as needed to suit your environment.
- Use the management interfaces (`9990`, `9999`) for monitoring and administration.

This setup provides a robust foundation for deploying a scalable and highly available application architecture using WildFly's Undertow reverse proxy.  