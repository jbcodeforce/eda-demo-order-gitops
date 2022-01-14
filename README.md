# Demo gitops for an event-driven solution

This gitops repository supports [the article about developer's experience](https://jbcodeforce.github.io/blogs/12-27-21/)
to develop an event-driven microservice solution.

## How it was created

We used KAM CLI to create the project with the following parameters:

Get Github access token, to be used in the KAM bootstrap command, in future steps.

![](./docs/github-access-tk.png)


```sh
kam bootstrap \
--service-repo-url https://github.com/jbcodeforce/eda-demo-order-ms \
--gitops-repo-url  https://github.com/jbcodeforce/eda-demo-order-gitops \
--image-repo image-registry.openshift-image-registry.svc:5000/ibmcase/ \
--output eda-demo-order-gitops \
--git-host-access-token <a-github-token> \
--prefix edademo --push-to-git=true
```

## What was added


* Added a bootstrap folder to define gitops and operator declaration and to create an ArgoCD project
* Defined a script to install IBM Catalogs and Cloud Pak for Integration components 
* Added scripts to deploy the gitops, pipelines operators: `scripts/installOperators.sh`
* Add deployment for the producer app in `environments/eda-demo-dev/app-eda-demo-order-ms`
* Added a lot of kustomize files for the different operators needed for the solution under the bootstrap folder: apicurio, elastic-search, sealed-secret...

## How to use it

* Login to the OpenShift Console, and get login token to be able to use `oc cli`

### Bootstrap GitOps

* If not done already, use the script to install GitOps and Pipeline operators: 

    ```sh
    cd bootstrap/scripts/
    ./installOperators.sh
    ```
    
Once the operators are running the command: `oc get pods -n openshift-gitops` should return
a list of pods like:

```sql
NAME                                                          READY   STATUS    RESTARTS   AGE
cluster-54b7b77995-7m5wg                                      1/1     Running   0          4h6m
kam-76f5ff8585-b742t                                          1/1     Running   0          4h6m
openshift-gitops-application-controller-0                     1/1     Running   0          4h5m
openshift-gitops-applicationset-controller-6948bcf87c-jdv2x   1/1     Running   0          4h5m
openshift-gitops-dex-server-64cbd8d7bd-76czz                  1/1     Running   0          4h5m
openshift-gitops-redis-7867d74fb4-dssr2                       1/1     Running   0          4h5m
openshift-gitops-repo-server-6dc777c845-gdjhr                 1/1     Running   0          4h5m
openshift-gitops-server-7957cc47d9-cmxvw                      1/1     Running   0          4h5m
```

* Install IBM product catalog

  ```sh
  ./bootstrap/scripts/installIBMCatalog.sh
  ```

* Obtain your [IBM license entitlement key](https://github.com/IBM/cloudpak-gitops/blob/main/docs/install.md#obtain-an-entitlement-key)
* Update the [OCP global pull secret of the `openshift-gitops` project](https://github.com/IBM/cloudpak-gitops/blob/main/docs/install.md#update-the-ocp-global-pull-secret)
with the entitlement key

    ```sh
    KEY=<yourentitlementkey>
    oc create secret docker-registry ibm-entitlement-key \
    --docker-username=cp \
    --docker-server=cp.icr.io \
    --namespace=cp4i \
    --docker-password=$KEY 
    ```

* Install the different IBM product operators as needed:

    ```sh
    # install cp4i namespace + navigator operator
    oc apply -f bootstrap/ibm-cp4i/cp4i-namespace.yaml
    oc apply -k bootstrap/ibm-cp4i
    # install event streams operator
    oc apply -k bootstrap/ibm-eventstreams
    # install apicurio operator
     oc apply -k bootstrap/apicurio
    # install sealed secrets operator and controller under sealed-secret namespace
    oc apply -k bootstrap/sealed-secret 
    ```

* Create ArgoCD project named `edademo`: 

```sh
oc project openshift-gitops
oc apply -k bootstrap/argocd-project
```

* Get the ArgoCD User Interface URL

```sh
oc get route openshift-gitops-server -o jsonpath='{.status.ingress[].host}'
```

* [Optional] Install any open source product operators used in this demonstration:

  ```sh
  # Elastic Search
  oc apply -k bootstrap/elastic-search/
  # Microcks to do API testing
  oc apply -k bootstrap/microcks-operator/operator/overlays/stable
  ```

### Deploy solution

* [Optional] Install manually the Cloud Pak for integration navigator operand.

    ```sh
    oc apply -f https://raw.githubusercontent.com/ibm-cloud-architecture/eda-gitops-catalog/main/cp4i-operators/platform-navigator/operands/cp4i-sample.yaml
    ```

  This can take up to 45 minutes to install, please wait. 
  

* Get the argocd admin password:

```sh
oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
```

* Start ArgoCD app of apps, to create instances of Event Streams, and the different services.

```sh
 oc apply -k config/argocd
```

The image below list the first ArgoCD apps:

![](./docs/argocd-apps.png)

* `edademo-dev-env` is for the namespace and service account user.
* `edademo-dev-services-app` is for creating an IBM event streams cluster named `dev` under the `edademo-dev` namespace, 
for configuring the Kafka topics, and scram and tls users.
* `edademo-dev-app-eda-demo-order-ms` is the order service producer argo app.

It may take some time to get Event streams started.

See the demonstration script to access to the Swagger API and to verify schema and events generated. 

## How to add more components

