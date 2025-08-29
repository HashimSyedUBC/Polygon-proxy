# Deploy Polygon Proxy Server to GCP Kubernetes

This guide walks you through deploying your Polygon proxy server to Google Cloud Platform using Google Kubernetes Engine (GKE).

## Prerequisites

1. **Google Cloud SDK installed**
   ```bash
   # Install gcloud CLI
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL
   gcloud init
   ```

2. **Docker installed**
3. **kubectl installed**
   ```bash
   gcloud components install kubectl
   ```

## Step 1: Setup GCP Project

```bash
# Set your project ID
export PROJECT_ID="your-project-id"
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

## Step 2: Create GKE Cluster

```bash
# Create a GKE cluster
gcloud container clusters create polygon-proxy-cluster \
    --zone=us-central1-a \
    --num-nodes=2 \
    --machine-type=e2-medium \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=5

# Get credentials for kubectl
gcloud container clusters get-credentials polygon-proxy-cluster --zone=us-central1-a
```

## Step 3: Build and Push Docker Image

```bash
# Build the Docker image
docker build -t gcr.io/$PROJECT_ID/polygon-proxy-server:latest .

# Push to Google Container Registry
docker push gcr.io/$PROJECT_ID/polygon-proxy-server:latest
```

## Step 4: Configure Secrets

```bash
# Encode your Polygon API key in base64
echo -n "your_polygon_api_key_here" | base64

# Edit k8s/secret.yaml and replace YOUR_BASE64_ENCODED_API_KEY with the output above
```

## Step 5: Update Deployment Configuration

Edit `k8s/deployment.yaml` and replace `YOUR_PROJECT_ID` with your actual GCP project ID.

## Step 6: Deploy to Kubernetes

```bash
# Apply all configurations
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Check deployment status
kubectl get pods
kubectl get services

# Get external IP (may take a few minutes)
kubectl get service polygon-proxy-service
```

## Step 7: Test Your Deployment

```bash
# Get the external IP
EXTERNAL_IP=$(kubectl get service polygon-proxy-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test health endpoint
curl http://$EXTERNAL_IP/health

# Test your API
curl "http://$EXTERNAL_IP/aggregates/AAPL/2023-01-01/2023-01-02"
```

## Monitoring and Scaling

```bash
# View logs
kubectl logs -l app=polygon-proxy-server

# Scale deployment
kubectl scale deployment polygon-proxy-server --replicas=3

# Check resource usage
kubectl top pods
```

## Cleanup

```bash
# Delete resources
kubectl delete -f k8s/
gcloud container clusters delete polygon-proxy-cluster --zone=us-central1-a
```

## Configuration Details

- **Replicas**: 2 pods for high availability
- **Resources**: 256Mi-512Mi memory, 250m-500m CPU per pod
- **Health checks**: HTTP probes on `/health` endpoint
- **Load balancer**: External IP with port 80 → 8090 mapping
- **Secrets**: Polygon API key stored securely in Kubernetes secrets

## Troubleshooting

```bash
# Check pod status
kubectl describe pods

# View events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check service endpoints
kubectl get endpoints
```
