# WildFly Domain Cluster with SAML Authentication

This project demonstrates a complete WildFly domain cluster setup with SAML authentication capabilities using Keycloak/RH-SSO integration. The topology consists of a load balancer (LB), a domain controller (DC), and two backend servers with full SAML/SSO support.

## Features

- **SAML Authentication**: Complete SAML 2.0 integration with Keycloak/RH-SSO
- **Domain Mode Cluster**: WildFly domain controller managing multiple backend servers
- **Load Balancing**: Undertow reverse proxy distributing traffic across backends
- **Elytron Security**: Modern security subsystem with custom realms and authentication
- **Containerized Deployment**: Podman based with custom SAML-enabled images

## Architecture Overview

1. **Load Balancer (LB)**:

   - WildFly 28.0.1 with Undertow reverse proxy
   - Routes traffic to backend servers
   - Configured with `standalone-load-balancer.xml`

2. **Domain Controller (DC)**:

   - WildFly 23.0.2 with RH-SSO SAML adapter
   - Manages domain configuration with complete SAML setup
   - Configured with `host-master.xml` and `domain.xml`

3. **Backend Servers (Backend1 and Backend2)**:
   - WildFly 23.0.2 with RH-SSO SAML adapter integration
   - Domain-managed servers with SAML authentication
   - Configured with `host-slave.xml`

## SAML Authentication Configuration

The project includes complete SAML 2.0 authentication integration:

### Keycloak SAML Subsystem

- RH-SSO 7.6.0 SAML adapter integrated with WildFly
- Complete Elytron security domain configuration
- Custom security realms and authentication factories
- Support for SAML assertions and Single Sign-On (SSO)

### Key SAML Components

- **KeycloakDomain**: Custom security domain for SAML authentication
- **KeycloakSAMLRealm**: Custom realm with SAML integration
- **keycloak-http-authentication**: HTTP authentication factory for SAML
- **Secure Deployments**: Application-specific SAML configuration

## Project Structure

```
├── backup/                    # Backup configurations and archives
├── configs/
│   ├── dc/
│   │   ├── domain.xml        # Complete SAML-enabled domain configuration
│   │   └── host-master.xml   # Domain controller configuration
│   ├── backend1/
│   │   └── host-slave.xml    # Backend1 server configuration
│   ├── backend2/
│   │   └── host-slave.xml    # Backend2 server configuration
│   └── lb/
│       └── standalone-load-balancer.xml  # Load balancer configuration
├── deployments/              # Application deployments (helloworld.war)
├── docs/                     # Configuration templates and documentation
├── scripts/                  # Test and verification scripts
├── test-deploy/              # Test artifacts and deployment tools
├── compose.yml               # Podman Compose orchestration
├── Dockerfile.wildfly-keycloak  # Custom WildFly image with SAML support
└── README.md                 # This documentation
```

## Podman Compose Setup

The `compose.yml` file orchestrates the deployment of the load balancer, domain controller, and backend servers. Key points:

- The load balancer listens on port `9980` for HTTP traffic.
- The domain controller exposes management ports (`9990`, `9999`).
- Backend servers expose HTTP and management ports.

### Example `compose.yml` Configuration

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

### Prerequisites
- Podman and Podman Compose installed

### Quick Start

1. Clone the repository and navigate to the project directory:
   ```bash
   git clone <repository-url>
   cd lb-wildfly-domain-backends
   ```

2. Start all services using Podman Compose:
   ```bash
   podman compose up -d
   ```

3. Access the services:
   - Load Balancer: `http://localhost:9980`
   - SAML Test App: `http://localhost:9980/helloworld`
   - Domain Controller Management: `http://localhost:9990/console`

### Container Management

```bash
# Start services in detached mode
podman compose up -d

# View running containers
podman compose ps

# View logs
podman compose logs -f

# Stop services
podman compose down

# Restart services
podman compose restart
```

## Notes

- Ensure the backend servers are reachable by the load balancer.
- Modify the configurations as needed to suit your environment.
- Use the management interfaces (`9990`, `9999`) for monitoring and administration.

## Testing SAML Authentication

The cluster includes a sample `helloworld.war` application configured for SAML authentication:

### Deploy and Test Application

```bash
# Application is automatically deployed via domain configuration
curl http://localhost:9980/helloworld
```

Expected behavior:
- Access `http://localhost:9980/helloworld`
- Should receive 403 Forbidden (SAML authentication challenge)
- Configure Keycloak IdP to complete SAML flow

### Container Services

- **wildfly-lb**: Load balancer (port 9980)
- **domain-controller**: Domain controller with SAML (ports 9990, 9999)
- **backend1**: Backend server 1 (port 9081)
- **backend2**: Backend server 2 (port 9080)
- **network**: Custom bridge network for container communication

## Development and Testing

### Useful Scripts (in `scripts/` folder)
- `test-saml-*.sh`: Various SAML functionality tests
- `verify-*.sh`: Configuration verification scripts
- `saml-redirection-guide.sh`: SAML setup guidance

### Configuration Templates (in `docs/` folder)
- `domain-server.xml`: Remote server configuration template
- `domain_snippet.xml`: Configuration snippets

### Backup Files (in `backup/` folder)
- Previous configuration versions
- Original domain configurations

## Key Features

- ✅ **SAML 2.0 Authentication** - Complete Keycloak/RH-SSO integration
- ✅ **Domain Mode Cluster** - Centralized management with HA
- ✅ **Load Balancing** - Undertow reverse proxy with session affinity
- ✅ **Elytron Security** - Modern security subsystem
- ✅ **Containerized** - Podman ready with custom images
- ✅ **Production Ready** - Complete security domains and authentication

This setup provides enterprise-grade WildFly domain clustering with complete SAML authentication capabilities using Podman.
