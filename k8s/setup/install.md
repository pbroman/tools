# Basic WSL k8s installment

## Presupposed

* docker is installed. If not, see https://gist.github.com/wholroyd/748e09ca0b78897750791172b2abb051 or https://gaganmanku96.medium.com/kubernetes-setup-with-minikube-on-wsl2-2023-a58aea81e6a3

## kubectl

See https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/

Short version:
```bash
# Download the latest Kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make it executable
chmod +x ./kubectl

# Move it to your user's executable PATH
sudo mv ./kubectl /usr/local/bin/
```

## Install minikube

See https://gaganmanku96.medium.com/kubernetes-setup-with-minikube-on-wsl2-2023-a58aea81e6a3

Short version: 
```bash
# Download the latest Minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Make it executable
chmod +x ./minikube

# Move it to your user's executable PATH
sudo mv ./minikube /usr/local/bin/

# Set the driver version to Docker
minikube config set driver docker

# Set cpus and memory, example
minikube config set cpus 4
minikube config set memory 5g

# Activate the changes and start minikube
minikube delete
minikube start

# Connect kubectl and minikube
kubectl config use-context minikube
minikube start

# verify
kubectl get pods -A
```

### Install minikube ingress addon

See https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/

```bash
minikube addons enable ingress

# verify
k get pods -n ingress-nginx
```

## Install helm (from script)

See https://helm.sh/docs/intro/install/

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

# Open it and read it through to see what it does, then
chmod 700 get_helm.sh

./get_helm.sh
```

## Install kube-prometheus-stack

See https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
For releases, see: https://github.com/prometheus-community/helm-charts/releases

```bash
# Get helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```
Since the node-exporter doesn't work in minikube, use this [kube-prometheus-stack-values.yaml file](kube-prometheus-stack-values.yaml) to deactivate it. (See the [default values.yaml](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml))

```bash
# Install
helm install [RELEASE_NAME] prometheus-community/kube-prometheus-stack --version [VERSION] --values [VALUES] --namespace [NAMESPACE] --create-namespace
# example
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack --version 73.2.0 --values kube-prometheus-stack-values.yaml --namespace monitoring --create-namespace
```
By success, the return commando will display some useful commands:
```bash
# check status
kubectl --namespace monitoring get pods -l "release=kube-prometheus-stack"

# Get Grafana 'admin' user password
kubectl --namespace monitoring get secrets kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
```
You may port-forward the grafana pod (below), but we'll add ingress to grafana and prometheus later anyhow. 
```bash
# Access Grafana local instance:
export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=kube-prometheus-stack" -oname)
kubectl --namespace monitoring port-forward $POD_NAME 3000

# call localhost:3000 and login with 'admin' and the password displayed above
```

## Install PostgreSQL

See https://fusionauth.io/docs/get-started/download-and-install/kubernetes/minikube

```bash
# Add PostgreSQL chart repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm repo list

# install libsecret and gnome-keyring
sudo apt install libsecret-1-0
sudo apt install gnome-keyring

# Install the postgresql chart
helm install pg-minikube --set auth.postgresPassword=<your-postgres-password> bitnami/postgresql  --namespace postgres --create-namespace
```

When successful, the installation returns this useful information:
```
PostgreSQL can be accessed via port 5432 on the following DNS names from within your cluster:

    pg-minikube-postgresql.postgres.svc.cluster.local - Read/Write connection

To get the password for "postgres" run:

    export POSTGRES_PASSWORD=$(kubectl get secret --namespace postgres pg-minikube-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)

To connect to your database run the following command:

    kubectl run pg-minikube-postgresql-client --rm --tty -i --restart='Never' --namespace postgres --image docker.io/bitnami/postgresql:17.5.0-debian-12-r10 --env="PGPASSWORD=$POSTGRES_PASSWORD" \
      --command -- psql --host pg-minikube-postgresql -U postgres -d postgres -p 5432

    > NOTE: If you access the container using bash, make sure that you execute "/opt/bitnami/scripts/postgresql/entrypoint.sh /bin/bash" in order to avoid the error "psql: local user with ID 1001} does not exist"

To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace postgres svc/pg-minikube-postgresql 5432:5432 & PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432
```


