- grafana exclude regex
/^(?!.*/run.*$).*$/

- Get username:password from docker configuration. You could inject these some other way instead if you wanted.

```sh
CREDS=$(jq -r ".[\"auths\"][\"$THE_REGISTRY\"][\"auth\"]" .docker/config.json | base64 -d)

curl -s --user $CREDS https://$THE_REGISTRY/v2/_catalog | \
    jq -r '.["repositories"][]' | \
    xargs -I @REPO@ curl -s --user $CREDS https://$THE_REGISTRY/v2/@REPO@/tags/list | \
    jq -M '.["name"] + ":" + .["tags"][]'
```

### Release version (release-please)
- `feat` bumps the minor version (0.6.8 -> 0.7.0), `fix` bumps the patch. `bump-patch-for-minor-pre-major` was removed from `release-please-config.json`, because it turned every `feat` into a patch below 1.0.0.
- Leave `.release-please-manifest.json` alone: it holds the last released version, not the next one.

### Force a particular release version
release-please reads `Release-As: x.y.z` from the body of a commit on `main`.
```
Release-As: x.y.z
```
- This repo squash-merges with an empty commit body, so the trailer in a PR description is dropped. Use one of:
  - rebase merge, with the trailer in the commit body
  - an empty commit on `main`: `git commit --allow-empty -m "chore: release x.y.z" -m "Release-As: x.y.z"`
  - repo setting "Default commit message" for squash merges set to "Pull request title and description"
- It applies to one release. Do not set `release-as` in the config: it stays in effect until removed.
