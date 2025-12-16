# Containerization Guide: Docker & Podman

## 1\. Introduction

Containerization has revolutionized software development and deployment. It involves encapsulating an application and its dependencies (code, runtime, system tools, libraries, and settings) into a single unit called a **container**. This ensures that the application runs quickly and reliably from one computing environment to another, solving the classic "it works on my machine" problem.

## 2\. Core Theories & Concepts

To understand Docker and Podman, it is essential to grasp the underlying concepts of container technology.

### 2.1 Containers vs. Virtual Machines (VMs)

  * **Virtual Machines:** Virtualize the **hardware**. Each VM runs a full operating system (Guest OS) on top of a Hypervisor. This makes them heavy, slow to boot, and resource-intensive.
  * **Containers:** Virtualize the **Operating System**. Containers share the host machine's OS kernel but have their own isolated userspace (filesystem, process tree, network stack). This makes them lightweight (megabytes vs. gigabytes) and instant to start.

### 2.2 Images & Layers

  * **Image:** A read-only template used to create containers. It is built from a set of instructions (Dockerfile).
  * **Layers:** Images are composed of layers. Each instruction in a Dockerfile adds a new layer.
  * **Union File System:** Docker uses a union file system to stack these layers into a single image. When you update an application, only the changed layers need to be rebuilt and downloaded.

### 2.3 OCI Standards (Open Container Initiative)

Both Docker and Podman adhere to OCI standards. This is critical because it means an image built with Docker can run on Podman, and vice versa.

  * **OCI Image Spec:** Defines the format of the container image.
  * **OCI Runtime Spec:** Defines how to unpack that image and run it.

-----

## 3\. Docker vs. Podman: A Deep Dive

While both tools perform the same primary function, their internal architecture differs significantly.

| Feature | Docker | Podman |
| :--- | :--- | :--- |
| **Architecture** | **Daemon-based**. Relies on a monolithic background process (`dockerd`) to manage all containers. | **Daemonless**. Uses a fork/exec model. The container is a direct child process of the user command. |
| **Security** | **Root-centric**. The daemon runs as root. Interacting with the daemon generally requires root privileges (or adding the user to the `docker` group, which is essentially root access). | **Rootless by default**. Allows unprivileged users to run containers. This is safer; if a container is compromised, the attacker does not automatically gain root access to the host. |
| **Orchestration** | **Docker Swarm**. Native clustering tool. | **Kubernetes-native**. Designed to work seamlessly with K8s. It can generate Kubernetes YAML manifests from running containers. |
| **Pods** | **No native "Pod" concept**. Groups containers via Compose. | **Native Pod support**. Can manage groups of containers (Pods) sharing the same network namespace, just like Kubernetes. |

-----

## 4\. Useful Commands

### 4.1 Dockerfile Instructions

These are the building blocks used inside a `Dockerfile` to create an image.

  * **`FROM <image>`**: Defines the base image (e.g., `FROM python:3.9-slim`). Must be the first line.
  * **`WORKDIR <path>`**: Sets the working directory inside the container. Subsequent commands run here.
  * **`COPY <src> <dest>`**: Copies files from your host machine to the container file system.
  * **`ADD <src> <dest>`**: Similar to COPY, but can extract tarballs and download URLs.
  * **`RUN <command>`**: Executes a command **during the build process** (e.g., installing packages). Creates a new layer.
  * **`CMD ["executable", "param1"]`**: The default command to run when the container starts. Can be overridden.
  * **`ENTRYPOINT ["executable"]`**: Configures the container to run as an executable. Difficult to override.
  * **`ENV <key>=<value>`**: Sets environment variables.
  * **`EXPOSE <port>`**: Documents which ports the container is intended to listen on.
  * **`USER <uid>`**: Switches to a specific user ID to run subsequent commands (good for security).

### 4.2 Essential Docker CLI Commands

These commands are typed in your terminal to manage images and containers.

**Build & Run**

  * `docker build -t my-app:v1 .` : Build an image from the current directory.
  * `docker run -d -p 8080:80 my-app:v1` : Run container in background (`-d`), mapping host port 8080 to container port 80.
  * `docker run -it ubuntu bash` : Run a container interactively with a shell.

**Management**

  * `docker ps` : List running containers.
  * `docker ps -a` : List all containers (including stopped ones).
  * `docker stop <container_id>` : Gracefully stop a container.
  * `docker rm <container_id>` : Remove a stopped container.
  * `docker images` : List locally stored images.
  * `docker rmi <image_id>` : Delete an image.
  * `docker system prune` : Clean up unused images, containers, and networks.

**Debugging**

  * `docker logs -f <container_id>` : View and follow the logs of a container.
  * `docker exec -it <container_id> bash` : Open a shell session *inside* a running container.
  * `docker inspect <container_id>` : View detailed metadata (JSON) about the container.

### 4.3 From Docker to Podman

Because Podman is OCI-compliant, the transition is often seamless.

**The Alias Method**
For most users, simply aliasing the command is enough to get started:

```bash
alias docker=podman
```

**Podman-Specific Commands**
Podman offers features that Docker does not have directly:

  * **`podman pod create --name my-pod`**: Creates an empty pod.
  * **`podman run --pod my-pod -d nginx`**: Runs a container *inside* that pod.
  * **`podman generate kube <container_id> > pod.yaml`**: Generates a Kubernetes YAML file based on a running container/pod. This is incredibly useful for moving from local development to a K8s cluster.
  * **`podman auto-update`**: Automatically updates containers if a newer image is available in the registry (requires systemd integration).

-----

## 5\. Tutorial Examples

### 5.1 Basic: Installation Verification

To verify your installation without relying on the official `hello-world` image, you can use a lightweight image like `alpine` to print a test message. This confirms your system can pull images and execute commands.

**Docker:**

```bash
docker run alpine echo "Hello from Alpine"
```

**Podman:**

```bash
podman run alpine echo "Hello from Alpine"
```

### 5.2 Intermediate: Building a Python Web App

In this example, we will containerize a simple Python application.

**1. Create the application file (`app.py`)**

```python
# app.py
from http.server import BaseHTTPRequestHandler, HTTPServer

class SimpleHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'Hello from inside the container!')

server = HTTPServer(('0.0.0.0', 8000), SimpleHandler)
print("Server starting on port 8000...")
server.serve_forever()
```

**2. Create the `Dockerfile`**

```dockerfile
# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Expose port 8000
EXPOSE 8000

# Run app.py when the container launches
CMD ["python", "app.py"]
```

**3. Build the Image**

```bash
docker build -t my-python-app .
```

**4. Run the Container**
We map host port 8080 to container port 8000.

```bash
docker run -p 8080:8000 my-python-app
```

*You can now visit `http://localhost:8080` in your browser.*


This tutorial guides you through installing Podman on an Ubuntu VM, configuring it to run smoothly without root privileges ("rootless"), and running your Python application.

# PODMAN
### Phase 1: Installation & Setup

#### 1\. Install Podman

Update your package lists and install the Podman package.

```bash
sudo apt-get update
sudo apt-get install -y podman
```

Check the version to verify it was installed:

```bash
podman --version
```

#### 2\. Fix the "Lingering" Warning

As you saw in your logs (`WARN... cgroupv2 manager`), Podman needs your user session to stay active even if you aren't logged in, so it can manage background containers.

Run this command to enable "lingering" for your current user:

```bash
loginctl enable-linger $USER
```

*(You do not need `sudo` for this if it's for your own user, but if it fails, try `sudo loginctl enable-linger $(whoami)`).*

#### 3\. Fix the "Short Name" Error (Permanent Fix)

Podman is strict about where it downloads images. By default, it doesn't assume you want "Docker Hub" when you type `python:3.9`. You have two choices:

  * **Option A:** Always type `docker.io/python:3.9`
  * **Option B (Recommended):** Configure Podman to look at Docker Hub automatically.

To do Option B, edit the registries configuration file:

```bash
sudo nano /etc/containers/registries.conf
```

Scroll to the bottom (or look for `unqualified-search-registries`) and ensure it looks like this:

```toml
unqualified-search-registries = ["docker.io"]
```

*Save the file (Ctrl+O, Enter) and Exit (Ctrl+X).*

-----

### Phase 2: Building Your Project

Now we will build the Python project you shared earlier.

#### 1\. Prepare the Dockerfile

Since we configured the registry in step 3 above, you can leave your Dockerfile exactly as it is\!

**Dockerfile:**

```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY . /app
EXPOSE 8000
CMD ["python", "app.py"]
```

#### 2\. Build the Image

Build the image using `podman build`. Note that Podman doesn't need `sudo`.

```bash
podman build -t my-python-app .
```

*Success Indicator:* You should see `STEP 5/5: CMD ["python", "app.py"]` followed by a Commit ID.

-----

### Phase 3: Running and Testing

#### 1\. Run the Container

We will run the container in "detached" mode (`-d`) so it runs in the background, and we will map the port (`-p`).

```bash
podman run -d -p 8000:8000 --name my-container my-python-app
```

  * `-d`: Detached mode (runs in background).
  * `--name`: Gives the container a friendly name so it's easier to stop later.
  * `-p 8000:8000`: Maps port 8000 on the VM to port 8000 in the container.

#### 2\. Verify it is running

Check the status of your containers:

```bash
podman ps
```

You should see your container listed with status `Up`.

#### 3\. Test the Response

Since this is a VM, you can test it locally using `curl`:

```bash
curl http://localhost:8000
```

**Expected Output:**

> Hello from inside the container\!

-----

### Phase 4: Managing Containers (Cheatsheet)

Here are the common commands you will need to manage your app.

| Action | Command |
| :--- | :--- |
| **Stop the app** | `podman stop my-container` |
| **Start it again** | `podman start my-container` |
| **Remove the container** | `podman rm my-container` |
| **View logs** | `podman logs my-container` |
| **Remove the image** | `podman rmi my-python-app` |

### Troubleshooting: "Permission Denied" on Port 80

If you try to change your code to run on port **80** (standard HTTP), Podman will fail.

  * **Reason:** Regular users (non-root) cannot use ports below 1024.
  * **Fix:** Keep your app on port 8000 inside the container. If you need to expose it on port 80 to the outside world, you typically use Nginx or Apache as a reverse proxy, or use `sudo podman ...` (though running as root defeats the security benefits of Podman).

