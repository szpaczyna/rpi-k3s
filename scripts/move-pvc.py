#!/usr/bin/env python
from kubernetes import client, config
from kubernetes.client.rest import ApiException


def read_pvc(namespace, pvc_name):
    try:
        return api_instance.read_namespaced_persistent_volume_claim(name=pvc_name, namespace=namespace)
    except ApiException as e:
        print(f"Error reading PVC: {e}")
        return None


def read_pv(pv_name):
    try:
        return api_instance.read_persistent_volume(name=pv_name)
    except ApiException as e:
        print(f"Error reading PV: {e}")
        return None


def patch_pv_reclaim_policy(pv_name, policy):
    try:
        patch_data = {"spec": {"persistentVolumeReclaimPolicy": policy}}
        api_instance.patch_persistent_volume(name=pv_name, body=patch_data)
    except ApiException as e:
        print(f"Error patching PV reclaim policy: {e}")


def delete_pvc(namespace, pvc_name):
    try:
        api_instance.delete_namespaced_persistent_volume_claim(name=pvc_name, namespace=namespace)
    except ApiException as e:
        print(f"Error deleting PVC: {e}")


def patch_pv_claim_ref(pv_name, namespace, pvc_name):
    try:
        patch_data = {"spec": {"claimRef": {"namespace": namespace, "name": pvc_name, "uid": None}}}
        api_instance.patch_persistent_volume(name=pv_name, body=patch_data)
    except ApiException as e:
        print(f"Error patching PV claimRef: {e}")


def apply_pvc_to_namespace(pvc_yaml, namespace):
    try:
        pvc_yaml = "\n".join(line for line in pvc_yaml.splitlines() if not any(
            ignored in line for ignored in ["uid:", "resourceVersion:", "namespace:", "selfLink:"]))
        api_instance.create_namespaced_persistent_volume_claim(namespace=namespace,
                                                               body=client.ApiClient().deserialize(pvc_yaml,
                                                                                                   'V1PersistentVolumeClaim'))
    except ApiException as e:
        print(f"Error applying PVC to namespace: {e}")


def get_pvc_uid(namespace, pvc_name):
    try:
        return api_instance.read_namespaced_persistent_volume_claim(name=pvc_name, namespace=namespace).metadata.uid
    except ApiException as e:
        print(f"Error getting PVC UID: {e}")
        return None


def main():
    config.load_kube_config()
    global api_instance
    api_instance = client.CoreV1Api()

    namespace1 = "your_namespace1"
    namespace2 = "your_namespace2"
    pvc = "your_pvc_name"
    pv = "your_pv_name"

    # Read PVC in namespace1
    pvc_obj = read_pvc(namespace1, pvc)

    if pvc_obj:
        # Save PVC to YAML
        with open("/tmp/pvc.yaml", "w") as file:
            file.write(client.ApiClient().sanitize_for_serialization(pvc_obj))

        # Read PV
        pv_obj = read_pv(pv)

        if pv_obj:
            # Save PV to YAML
            with open("/tmp/pv.yaml", "w") as file:
                file.write(client.ApiClient().sanitize_for_serialization(pv_obj))

            # Patch PV reclaim policy to Retain
            patch_pv_reclaim_policy(pv, "Retain")

            # Describe PV and print Reclaim policy
            pv_description = read_pv(pv)
            if pv_description:
                print(f"Reclaim policy: {pv_description.spec.persistent_volume_reclaim_policy}")

            # Delete PVC in namespace1
            delete_pvc(namespace1, pvc)

            # Patch PV claimRef to namespace2 and PVC name
            patch_pv_claim_ref(pv, namespace2, pvc)

            # Get PV details and print Reclaim policy and Namespace
            pv_details = read_pv(pv)
            if pv_details:
                print(f"Reclaim policy: {pv_details.spec.persistent_volume_reclaim_policy}")
                print(f"Namespace: {pv_details.spec.claim_ref.namespace}")

            # Patch PVC YAML and apply to namespace2
            with open("/tmp/pvc.yaml", "r") as file:
                pvc_yaml = file.read()
                apply_pvc_to_namespace(pvc_yaml, namespace2)

            # Get PVC UID in namespace2
            pvc_uid = get_pvc_uid(namespace2, pvc)

            if pvc_uid:
                # Patch PV claimRef UID with PVC UID
                patch_data = {"spec": {"claimRef": {"uid": pvc_uid, "name": None}}}
                api_instance.patch_persistent_volume(name=pv, body=patch_data)

                # Patch PV reclaim policy to Delete
                patch_pv_reclaim_policy(pv, "Delete")

                # Describe PV and print Reclaim policy
                pv_description = read_pv(pv)
                if pv_description:
                    print(f"Reclaim policy: {pv_description.spec.persistent_volume_reclaim_policy}")
        else:
            print(f"PV {pv} not found.")


if __name__ == "__main__":
    main()
