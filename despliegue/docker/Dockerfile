FROM jenkins/jenkins:lts

USER root

# Actualizar e instalar utilidades necesarias
RUN apt-get update && \
    apt-get install -y apt-transport-https curl gnupg unzip lsb-release ca-certificates software-properties-common zip && \

    # Instalar OpenJDK 17 y Maven
    apt-get install -y openjdk-17-jdk maven && \
    
    # Instalar Docker CLI
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    echo "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \

    # Instalar AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install && \
    rm -rf awscliv2.zip aws && \

    # Instalar Azure CLI
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash && \

    # Instalar Terraform
    curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    echo "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update && \
    apt-get install -y terraform && \

    # Instalar Node.js 18 y npm
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \

    # Limpieza final
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Agregar jenkins al grupo docker
RUN groupadd docker && usermod -aG docker jenkins

USER jenkins
EXPOSE 8080
WORKDIR /var/jenkins_ho