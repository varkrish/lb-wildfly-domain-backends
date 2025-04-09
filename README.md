# WildFly Load Balancer Project

This project sets up a WildFly-based domain controller acting as a reverse proxy to manage backend services efficiently and reduce the overall footprint. Below are the details of the topology and configuration.

---

## Topology Overview

The setup consists of the following components:

1. **Domain Controller (`dc-lb-domain-controller`)**:
    - Acts as the central management node.
    - Configured as a reverse proxy using Undertow's load-balancing capabilities.
    - Hosts the `domain.xml` configuration file, which defines the reverse proxy behavior.

2. **Backend Nodes (`dc-lb-backend1` and `dc-lb-backend2`)**:
    - These are the backend servers managed by the domain controller.
    - Serve application traffic routed through the domain controller.

3. **Networking**:
    - All services are connected via a `wildfly-net` bridge network.
    - Ports are exposed for HTTP, management, and Undertow communication.

---

## Docker Compose Configuration

The `docker-compose.yml` file defines the services and their configurations:

- **Domain Controller**:
  - Image: `quay.io/wildfly/wildfly:23.0.2.Final`
  - Ports:
     - `9990:9990` (Admin console)
     - `9999:9999` (Management native interface)
     - `9959:9959` (Undertow)
  - Volumes:
     - `configs/dc/domain.xml` for domain configuration.
  - Environment variables:
     - `JBOSS_BIND_ADDRESS=0.0.0.0`
     - `JAVA_OPTS` with custom JVM options.

- **Backends**:
  - Two backend nodes (`dc-lb-backend1` and `dc-lb-backend2`) are defined.
  - Each backend connects to the domain controller for management.

---

## Undertow Load Balancer Configuration

The Undertow reverse proxy is configured in the `domain.xml` file under the `undertow` subsystem:

```xml
<subsystem xmlns="urn:jboss:domain:undertow:12.0">
     <buffer-cache name="default"/>
     <server name="default-server">
          <http-listener name="default" socket-binding="undertow" enable-http2="true"/>
          <host name="default-host" alias="localhost">
                <location name="/" handler="lb-handler"/>
          </host>
     </server>
     <handlers>
          <reverse-proxy name="lb-handler" 
                             problem-server-retry="30" 
                             session-cookie-names="JSESSIONID"
                             connections-per-thread="20">
                <host name="backend1" instance-id="backend1" path="/" scheme="http" outbound-socket-binding="backend1"/>
                <host name="backend2" instance-id="backend2" path="/" scheme="http" outbound-socket-binding="backend2"/>
          </reverse-proxy>
     </handlers>
</subsystem>
```

### Key Configuration Details:
1. **Reverse Proxy Handler**:
    - The `reverse-proxy` handler (`lb-handler`) is defined to distribute traffic between the backends.
    - It uses `backend1` and `backend2` as load-balanced targets.

2. **Socket Bindings**:
    - The `undertow` socket binding is used for HTTP traffic.
    - Outbound socket bindings (`backend1` and `backend2`) define the backend hosts and ports.

3. **Load Balancing Features**:
    - `problem-server-retry`: Retries failed servers after 30 seconds.
    - `connections-per-thread`: Limits connections per thread to 20.

---

## Benefits of This Setup

- Centralized management of backend nodes via the domain controller.
- Efficient load balancing using Undertow's reverse proxy.
- Reduced resource footprint by consolidating management and proxying into a single node.

For more details, refer to the `docker-compose.yml` and `domain.xml` files in the `configs/dc` directory.  