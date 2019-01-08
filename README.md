Jupyterhub deployment with Kubernetes (K8s) on Google Kubernetes Engine (GKE).
This project is part of [DigiKlausur project](https://github.com/DigiKlausur/jupyterhub-on-kubernetes) project to deploy jupyterhub on Kubernetes (Google Kubernetes Engine) for teaching.
We switched from [a single server jupyterhub](https://github.com/mhwasil/jupyterhub-on-gcloud) to Kubernetes since we have a big class consisting of almost 300 students. This deployment is currently running for a bachelor course WahrscheinlichkeitstheorieUndStatistik winter 18/19, Hochschule Bonn-Rhein-Sieg.

The installation tutorial is mostly based on the [zero-to-jupyterhub](https://zero-to-jupyterhub.readthedocs.io/) documentation.

Basic installation
============

* Requirements
	* A Google Cloud account (you may want to use 300$ free credit from google)
	* Enabling GKE
		* Visit the Kubernetes Engine page in the Google Cloud Platform Console.
		* Create or select a project.
		* Wait for the API and related services to be enabled. This can take several minutes.
		* Make sure that billing is enabled for your project.
		* more https://cloud.google.com/kubernetes-engine/docs/quickstart
	* Have a little understading on what Kubernetes, Node, Pod, Helm, Docker
* Installing jupyterhub on GKE
	* Open cloud shell on the top right
	* Install kubectl: gcloud components install kubectl
	* Set the zone
		* ZONE=europe-west1-b
		* gcloud config set compute/zone $ZONE
	* Create the cluster
		* CLUSTERNAME=e2-datahub
		* gcloud beta container clusters create $CLUSTERNAME --machine-type n1-standard-1 --num-nodes 2 --disk-size 50 --cluster-version latest --node-labels hub.jupyter.org/node-purpose=core
		* check the nodes are ready: kubectl get node
	* Create cluster admin
		* EMAIL=mhm.wasil@gmail.com
		* kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$EMAIL
	* Install helm
		* curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
		* kubectl --namespace kube-system create serviceaccount tiller
		* kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
		* helm init --service-account tiller
		* check helm installed: helm version
	* Secure helm
		* kubectl patch deployment tiller-deploy --namespace=kube-system --type=json --patch='[{"op": "add", "path": "/spec/template/spec/containers/0/command", "value": ["/tiller", "--listen=localhost:44134"]}]'
	* Install jupyterhub with helm
		* Create secretToken for jupyterhub and create config.yaml
			* openssl rand -hex 32
			* Create config.yaml and put the secretToken in there
		* Add jupyterhub to helm
			* helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
			* helm repo update
		* Install jupyterhub
			* Create RELEASE and NAMESPACE
				* RELEASE=mas-jhub
				* NAMESPACE=mas-jhub
			* Install jupyterhub
				* helm upgrade --install $RELEASE jupyterhub/jupyterhub --namespace $NAMESPACE --version 0.7.0 --values config.yaml
	* Updating the config
		* helm upgrade $RELEASE jupyterhub/jupyterhub --namespace $NAMESPACE --version 0.7.0 --values config.yaml

Advanced guide
============
* Creating image and push it to gcr.io
	* Create a docker file as in the directory user-image
	* Modify the Google project name in Makefile
	* Add some images and packages in Dockerfile if needed
	* Create docker file by: make
	* Check docker file present in your local pc or google cloud shell by: docker images
	* Push docker file to gcr.io: gcloud docker — push image_name
* Authentication
```
auth:
  type: github
  github:
    clientId: "4c4b0149fbee3d1eqw"
    clientSecret: "be560598fa89096f2e02f1ee72442d9b0eb277d5"
    callbackUrl: "http://notebooks.h-brs.de/hub/login"
```
* Automatic https
```
proxy:
  secretToken: ""
    https:
      hosts:
	- notebooks.mydomain.org
      letsencrypt:
	contactEmail: myemail@gmail.com
```
  * If https does not work, eg. the port is not open, try specifying the loadBalancer IP
* nbgitpuller
```
singleuser:
  lifecycleHooks:
    postStart:
      exec:
	command: ["gitpuller", "https://github.com/username/my-repo", "master", "my-repo"]
```
* Modifying load balancer	
  * Tweaking load balancer ip is useful when https port may not be open, and if it is the case create new ip and attach that ip to the load balancer.
  * You can change the load balancer ip by removing the old one and create new static ip and attach that new ip to the load balancer
  * Tell config.yaml this new ip
```
proxy:
  secretToken: ""
  service:
    type: LoadBalancer
    loadBalancerIP: a.b.c.d
```
* Configure node pools for core and user. This config has been used in the [Binder configuration](https://github.com/jupyterhub/mybinder.org-deploy/blob/master/docs/source/command_snippets.md).
  * a "core" pool, which runs the hub, etc.
  * a "user" pool, where user pods run.
  * example: "hub.jupyter.org/node-purpose": "core" and "user"
  * More issue can be found [here](https://github.com/jupyterhub/zero-to-jupyterhub-k8s/issues/717#issuecomment-401638527)
* Let's encrypt automatic https update
  * Restart autohttps pod since the automatic https does not work with the current image of kube-lego we are using. For more information see the following issue
    * https://github.com/jupyterhub/zero-to-jupyterhub-k8s/issues/1033 (restart autohttps pod)
    * https://github.com/jupyterhub/zero-to-jupyterhub-k8s/issues/963
  * Manual restart (the pod name may be different autohttps-.....)
```
    * kubectl exec autohttps-6cc94589d-8fdxj -c kube-lego reboot -n prod
    * kubectl exec autohttps-6cc94589d-8fdxj -c nginx reboot -n prod
```
