helm repo update
RELEASE=testing
NAMESPACE=testing
#helm upgrade $RELEASE jupyterhub/jupyterhub --namespace $NAMESPACE --version 0.7.0 --values config/config.yaml
helm upgrade $RELEASE jupyterhub/jupyterhub --namespace $NAMESPACE --version 0.8.2 --values config/config_empty.yaml
