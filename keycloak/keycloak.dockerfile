FROM quay.io/keycloak/keycloak:26.0.7

COPY providers/keycloak-pii-data-encryption-2.1.jar /opt/keycloak/providers/keycloak-pii-data-encryption-2.1.jar

WORKDIR /opt/keycloak

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
