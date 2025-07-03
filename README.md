# GKE Management Workspace

This workspace is set up for managing Google Kubernetes Engine (GKE) clusters.

## Tools Installed
- Google Cloud SDK (`gcloud`)
- Kubernetes CLI (`kubectl`)
- Helm (optional, for package management)

## Getting Started
1. Authenticate with Google Cloud using `gcloud init` (already completed).
2. Use `kubectl` to interact with your GKE clusters.
3. Use `helm` for managing Kubernetes packages (optional).
4. Store and version your configuration files and scripts in this repository.

## GitHub Integration
- This repository is initialized with git. Add your remote with:
  ```sh
  git remote add origin <your-github-repo-url>
  ```
- Push your changes:
  ```sh
  git add .
  git commit -m "Initial commit"
  git push -u origin master
  ```

## References
- [Google Cloud SDK Documentation](https://cloud.google.com/sdk/docs)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [kubectl Documentation](https://kubernetes.io/docs/reference/kubectl/)
- [Helm Documentation](https://helm.sh/docs/)
