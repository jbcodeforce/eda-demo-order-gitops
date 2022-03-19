# Demo script

## Bootstrap the deployment

* Create a dedicated project named: `eda-order-demo`: `oc new-project eda-order-demo`
* Define topics in the `cp4i-eventstreams.es-demo` event streams cluster

    ```sh
    oc apply -f environments/herb/services/ibm-eventstreams/base/es-topics.yaml
    ```
* Copy `es-tls-user` certificate so app can authneticate with mutual TLS

    ```sh
    ./bootstrap/scripts/copySecrets.sh es-tls-user cp4i-eventstreams eda-order-demo
    ```
* Cope server side CA certificate

    ```sh
    ./bootstrap/scripts/copySecrets.sh es-demo-cluster-ca-cert cp4i-eventstreams eda-order-demo
    ```
* Deploy Apicurio registry

    ```sh
    oc apply -k bootstrap/apicurio
    # verify the state of the operator
    oc get -n openshift-operators subscription  apicurio-registry
    # Then deploy an registry
    oc apply -k ./environments/herb/services/apicurio/overlays
    ```

* Deploy the Order Microservice

    ```sh
    oc apply -k ./environments/herb/apps/eda-demo-order-ms
    ```

* Upload the OrderEvent to the schema registry

## Demonstrate Pub/Sub with order use cases

### Event Streams Operator and Cluster definitions

### Deployed Order Microservice APP 

Using microprofile reactive messaging to generate events

### Orders topic, access control, TLS user

es-tls-user