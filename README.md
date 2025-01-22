# Set up complete services in Local
## :exclamation: **Important**
> In order to facilitate Local development, sensitive information is not encrypted through kubeseal (Sealed Secret). It is necessary to avoid pushing sensitive information to this Repo in clear code.

### Preparatory work

1. Install [Docker](https://www.docker.com/)

2. Install [minikube](https://minikube.sigs.k8s.io/docs/start/?arch=%2Fmacos%2Farm64%2Fstable%2Fbinary+download)

    ```shell
    brew install minikube
    ```

3. Install [kubectl](https://kubernetes.io/zh-cn/docs/tasks/tools/install-kubectl-macos/#install-with-homebrew-on-macos)

    ```shell
    brew install kubectl
    ```

4. build keycloak image

    ```shell
    docker build -f keycloak/keycloak.dockerfile -t my-keycloak:latest --platform=linux/amd64 .
    ```

    Reference sources for encrypted sensitive data：https://github.com/MLukman/Keycloak-PII-Data-Encryption-Provider

### Steps

1. Start minikube

    ```shell
    minikube start --driver=docker
    ```

    `--driver=docker`：Specify driver as docker to use local images.
   
    If there are insufficient resources, you need to configure sufficient resources for your minikube cluster at startup.<br>
    Take the following configuration as an example：`3G` Memory + `CPU` x 2

    ```shell
    minikube start --memory 3096 --cpus 2
    ```

2. Enable minikube ingress

    If your minikube cluster is created for the first time,<br>You need to enable ingress before setting up the service.

    ```shell
    minikube addons enable ingress
    ```

    After enabling, you can check the ingress status through the following command：
    ```shell
    minikube addons list | grep ingress
    ```

3. Load local images to minikube

    ```shell
    minikube image load my-keycloak:latest
    minikube image load my-backend-api:latest
    ```

4. Apply `namespace` `secrets` `configmaps` `ingress` yaml files to minikube cluster

    ```shell
    kubectl apply -f local-minikube/namespace.yaml
    kubectl apply -f local-minikube/secrets/.
    kubectl apply -f local-minikube/configmaps/.
    kubectl apply -f local-minikube/ingress.yaml
    ```

5. Configure the ingress address to your Local hosts（ `/private/etc/hosts` ）

    ```shell
    xxx.xxx.xxx.xxx sso.localhost backend-api.localhost
    ```

    IP can be viewed from ingress.<br>Although the namespace is different, the IPs will basically be the same group.

    ```shell
    kubectl get ingress -n sso
    kubectl get ingress -n application
    ```

6. Apply deployment `postgres` to minikube cluster

    ```shell
    kubectl apply -f local-minikube/deployments/postgres.yaml

7. Apply deployment `keycloak` to minikube cluster

    ```shell
    kubectl apply -f local-minikube/deployments/keycloak.yaml
    ```

    Keycloak console account and password are both admin (configured in k8s `configmap` yaml).

8. Configure the Keycloak Realm

    Please refer to Keycloak official documentation.
    - [Keycloak Guides](https://www.keycloak.org/guides)

    Or directly import the configured json file into Realm.
    - `/keycloak/realm-demo.json`

9. Configure Oauth2 Proxy’s `client secret` & `cookie secret` in secret

    ```shell
    OAUTH2_PROXY_CLIENT_SECRET: {client-secret}
    OAUTH2_PROXY_COOKIE_SECRET: {cookie-secret}
    ```

    How to obtain these two secrets?
    - client secret：
        What is placed here is the secret generated by keycloak, which can be obtained from the client corresponding to keycloak (through keycloak admin console).<br>`Client` -> `{demo}` -> `Credentials`
    - cookie secret：
        Oauth2 Proxy will use this set of secrets for encryption when generating cookies.
        ```shell
        openssl rand -base64 32 | tr -- '+/' '-_'
        ```

10. Apply deployments `oauth2-proxy` `backend-api` to minikube cluster

    ```shell
    kubectl apply -f local-minikube/deployments/oauth2-proxy.yaml
    kubectl apply -f local-minikube/deployments/backend-api.yaml
    ```

11. Enable minikube tunnel

    ```shell
    minikube tunnel
    ```

    Why enable `minikube tunnel`?

    The ingress will obtain an external IP, but because this minikube cluster operates within the container through Docker.<br>If you cannot directly connect to the Internet using MacOS, you need to establish a channel through minikube tunnel and connect the cluster IP of the minikube environment to localhost.

    When starting minikube, there is actually a thoughtful reminder to enable the channel：<br>`After the addon is enabled, please run "minikube tunnel" and your ingress resources would be available at "127.0.0.1"`
