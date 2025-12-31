# Core Docker Commands
abbr dk 'docker'
abbr dkb 'docker build'
abbr dke 'docker exec'
abbr dkei 'docker exec -it'
abbr dki 'docker images'
abbr dkin 'docker inspect'
abbr dkl 'docker logs'
abbr dkL 'docker logs -f'
abbr dkps 'docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
abbr dkpsa 'docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
abbr dkr 'docker run'
abbr dkri 'docker run -it --rm'
abbr dkrm 'docker rm'
abbr dkrmi 'docker rmi'
abbr dks 'docker start'
abbr dkS 'docker restart'
abbr dkss 'docker stats'
abbr dkx 'docker stop'

# Docker Compose (modern `docker compose` syntax)
abbr dkc 'docker compose'
abbr dkcb 'docker compose build'
abbr dkcd 'docker compose down'
abbr dkce 'docker compose exec'
abbr dkcl 'docker compose logs'
abbr dkcL 'docker compose logs -f'
abbr dkcps 'docker compose ps --format table'
abbr dkcr 'docker compose run --rm'
abbr dkcu 'docker compose up'
abbr dkcU 'docker compose up -d'
abbr dkcS 'docker compose restart'
abbr dkcx 'docker compose stop'

# Container Management
abbr dkCls 'docker container ls --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
abbr dkCei 'docker container exec -it'
abbr dkCrm 'docker container rm'
abbr dkCpr 'docker container prune'

# Image Management
abbr dkIls 'docker image ls --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"'
abbr dkIpr 'docker image prune'
abbr dkIpl 'docker image pull'
abbr dkIrm 'docker image rm'

# Volume Management
abbr dkVls 'docker volume ls'
abbr dkVin 'docker volume inspect'
abbr dkVpr 'docker volume prune'
abbr dkVrm 'docker volume rm'

# Network Management
abbr dkNls 'docker network ls'
abbr dkNin 'docker network inspect'
abbr dkNpr 'docker network prune'
abbr dkNrm 'docker network rm'

# System Management
abbr dkdf 'docker system df'
abbr dkpr 'docker system prune'
abbr dkpra 'docker system prune -a'
