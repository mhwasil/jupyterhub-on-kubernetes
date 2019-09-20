#openssl rand -hex 32
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update
RELEASE=testing
NAMESPACE=testing
helm upgrade --install $RELEASE jupyterhub/jupyterhub --namespace $NAMESPACE --version 0.8.2 --values config/config_empty.yaml
