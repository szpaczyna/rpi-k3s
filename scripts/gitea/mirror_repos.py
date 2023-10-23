import requests
import yaml
import logging

# Configure logging
logging.basicConfig(filename="import_repos.log", level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

# Load configuration from a YAML file
try:
    with open("config.yaml", "r") as config_file:
        config = yaml.safe_load(config_file)

    GITEA_USERNAME = config["GITEA_USERNAME"]
    GITEA_TOKEN = config["GITEA_TOKEN"]
    GITEA_DOMAIN = config["GITEA_DOMAIN"]
    GITEA_REPO_OWNER = config["GITEA_REPO_OWNER"]
    REPOS = config["REPOS"]
except Exception as e:
    logging.error(f"Error loading configuration: {str(e)}")
    raise

# Function to import a repository
def import_repo(url):
    try:
        repo_name = url.replace("https://github.com/", "").replace("/", "-").replace(".git", "")
        print(f"Importing repo from {url} to {repo_name}…")

        endpoint = f"https://{GITEA_DOMAIN}/api/v1/repos/migrate"
        headers = {
            "accept": "application/json",
            "Content-Type": "application/json"
        }
        data = {
            "clone_addr": url,
            "mirror": True,
            "private": False,
            "repo_name": repo_name,
            "repo_owner": GITEA_REPO_OWNER,
            "service": "git",
            "uid": 0,
            "wiki": True
        }

        response = requests.post(endpoint, auth=(GITEA_USERNAME, GITEA_TOKEN), headers=headers, json=data)

        if response.status_code == 200:
            logging.info(f"Repository {repo_name} imported successfully.")
        else:
            logging.error(f"Failed to import repository {repo_name}. Status code: {response.status_code}")
    except Exception as e:
        logging.error(f"Error importing repository {url}: {str(e)}")

# Loop through the repositories and import them
for url in REPOS:
    import_repo(url)
