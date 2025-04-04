
Task 2 - Containerizing python application with Docker and automating build and push process

-> Main goal:
    To containerize one of the applications from the 2-app/folder using Docker, build the Docker image, test it locally, and automate the process of building and pushing using GitHub Actions.
    
-> Choosing an Application
In the 2-app/ folder, there are two applications:
    - Python: calculator.py with dependencies listed in requirements.txt.
    - Node.js: note.js with dependencies listed in package.json.
I chose the Python application (calculator.py) for this task.

-> What I did – Step by Step
  To containerize the application, I wrote a Dockerfile that sets up the environment, installs dependencies, and runs the application.
  for python image
  FROM python:3.9-slim
  
  the working directory will be inside the container
  WORKDIR /app
  
  for the dependencies and the install them
  COPY requirements.txt .
  RUN pip install --no-cache-dir -r requirements.txt
  
  COPY calculator.py .
  
  Expose port 8080
  EXPOSE 8080

  to run the app
  CMD ["python", "calculator.py"]

    -> Local Testing
        Step 1: Build the Docker Image Locally
          To build the Docker image, I ran the following command: docker build -t calculator-app .
          
        Step 2: Run the Docker Container
          After building the image, I ran the container with: docker run -p 8080:8080 calculator-app (this command maps port 8080 from the host to port 8080 inside the container.)
          
        Step 3: Test the Application
            Once the container was running, I checked if the application worked as expected by checking the container's output. 
            There is a screenshot about this fact : (calculator-app.png)
            
      Step 4: Setting Up a Docker Registry
          - I created an account on Docker Hub.
          - I created a new repository on Docker Hub named calculator-app (repository-on-Docker-Hub.png)

      Step 5: Automating with GitHub Actions
          - I automated the process using GitHub Actions. The automation does the following:
                * builds the Docker image when changes are pushed to the main branch.
                * hags the Docker image with the commit hash.
                * pushes the image to Docker Hub.

                step 5.1: Creating the GitHub Actions Workflow
                      - I created a new file in .github/workflows/ called docker.yml and added the following configuration:

                              name: Build and Push Docker Image
                              
                              on:
                                push:
                                  branches:
                                    - main
                              
                              jobs:
                                build-and-push:
                                  runs-on: ubuntu-latest
                              
                                  steps:
                                  - name: Checkout code
                                    uses: actions/checkout@v3
                              
                                  - name: Log in to Docker Hub
                                    uses: docker/login-action@v3
                                    with:
                                      username: ${{ secrets.DOCKER_USERNAME }}
                                      password: ${{ secrets.DOCKER_PASSWORD }}
                              
                                  - name: Build Docker image
                                    run: docker build -t ${{ secrets.DOCKER_USERNAME }}/calculator-app:${{ github.sha }} .
                              
                                  - name: Push image to Docker Hub
                                    run: docker push ${{ secrets.DOCKER_USERNAME }}/calculator-app:${{ github.sha }}

                      step 5.2: Set Up GitHub Secrets
                          In the GitHub repository settings, I added two secrets:

                              DOCKER_USERNAME: My Docker Hub username(eugeniavacarciuc)

                              DOCKER_PASSWORD: My personal access token.

                              (GitHub-secrets.png)

-> Problems I Faced:
        While working on this task, I ran into a few issues. At first, the GitHub Actions workflow didn’t run because the docker.yml file was placed in the wrong folder (task2/.github/ instead of the main .github/ folder). After fixing that, the workflow failed due to incorrect indentation in the run: | block — YAML is very strict with spaces. Then, Docker login failed because I used my Docker Hub password instead of a personal access token, which is the recommended way. I also had some Git problems when trying to pull updates — the local and remote branches were different, and I had to deal with rebase conflicts and messages like “detached HEAD.” I solved them using commands like git rebase --abort, git checkout main, and git pull --rebase. During the rebase, I also got stuck in the Vim editor, so I changed the default Git editor to nano using git config --global core.editor "nano". These small challenges helped me learn a lot more about Git, GitHub Actions, and how to fix real errors during development.

Some useful screenshots:

->GitHub Actions – All Workflow Runs 
![Workflow Runs](screenshot-workflow-runs.png) (this screenshot shows the history of workflow runs, including both failed and successful executions.)
-> Successful GitHub Action Run
![Workflow Success](screenshot-workflow-success.png)

-> Docker Hub Repository
![DockerHub Repo](screenshot-dockerhub-repo.png)

  


