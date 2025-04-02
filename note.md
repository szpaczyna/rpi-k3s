- grafana exclude regex
/^(?!.*/run.*$).*$/

- Get username:password from docker configuration. You could inject these some other way instead if you wanted.
-
CREDS=$(jq -r ".[\"auths\"][\"$THE_REGISTRY\"][\"auth\"]" .docker/config.json | base64 -d)

curl -s --user $CREDS https://$THE_REGISTRY/v2/_catalog | \
    jq -r '.["repositories"][]' | \
    xargs -I @REPO@ curl -s --user $CREDS https://$THE_REGISTRY/v2/@REPO@/tags/list | \
    jq -M '.["name"] + ":" + .["tags"][]'
