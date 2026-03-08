# BharatSeva+ Platform  [![Deploy](https://github.com/BharatSeva/core/actions/workflows/deploy.yaml/badge.svg?branch=main)](https://github.com/BharatSeva/core/actions/workflows/deploy.yaml)

Central platform repository for **BharatSeva+**, containing all core services managed as Git submodules.  
This repository acts as the central control system for managing, updating, and organizing all modules.

---

## Getting Started

1. **Clone the repository**:  
```bash
git clone https://github.com/BharatSeva/bharatseva-plus-platform.git
cd bharatseva-plus-platform
```

2. **Initialize, update submodules and start the docker containers**:
```bash
make init
```

3. **Access the services**:  
- Client_Portal: [http://localhost/client/login](http://localhost/client/login)  
- HealthCare_Portal: [http://localhost/healthcare/login](http://localhost/healthcare/login)

## Available Make Commands
- `make init`: Initializes and updates all git submodules and starts the docker containers.
- `make start`: Starts the docker containers.
- `make stop`: Stops the docker containers.
- `make restart`: Restarts the docker containers.
- `make status`: Displays the status of the docker containers.
- `make rm-vol`: Removes all docker volumes associated with the project.

## Enjoy exploring the BharatSeva+ platform!