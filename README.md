# Docker 7th Birthday Demo (Blazor + gRPC on Docker)

## Install Docker

> Windows

* [Docker for Windows](https://docs.docker.com/docker-for-windows/install/)

> Linux

* [Docker for Linux](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

> Mac

* [Docker for Mac](https://docs.docker.com/docker-for-mac/install/)

## Install VS 2019

> Windows & Mac

* [Visual Studio Downloads](https://visualstudio.microsoft.com/downloads/)

> Linux

* Download Visual Studio Code (same link as above)
  * (some extra configuration might be necessarry for a full debugging experience - Google & StackOverflow are your friends)
* Download the .NetCore 3.1.x SDK if it is not included in your VS 2019 install.
* You can verify what .NetCore versions are installed via this command from your command prompt or terminal _dotnet --list-sdks_
![alt text](demo-images/dotnet-versions.png "dotnet versions")

## Create Sample App

* Create a folder to store your application and Dockfile with in _ex. C:\code\blazor-doker-demo\)_
![alt text](demo-images/new-folder.png "New folder")
* From the command line or terminal run the following commands in the above created folder that will contain your project and Dockerfile _ex. (C:\code\blazor-docker-demo\\)_.
* You may open PowerShell or any command line terminal _I will be using PowerShell for this tutorial._
* Then execute the command _dotnet new_ to view a list of the installed templates.
![alt text](demo-images/dotnet-new.png "dotnet new")
* Next execute _dotnet new --update-check_ to check for template updates and run the command it provides if updates are available.
![alt text](demo-images/dotnet-updatecheck.png "dotnet new --update-check")
* Scroll through the list to see if you find the template named "blazorwasm". If you don't find the _blazorwasm_ template installed run the following command to install the Blazor templates  _dotnet new -i Microsoft.AspNetCore.Blazor.Templates::3.2.0-preview1.20073.1_
* Execute _dotnet new_ again to see a list of installed template and verify the blazor template is now instaled.
* Type _dotnet new blazorwasm_ in the project folder your created and you should see the following output.
![alt text](demo-images/dotnet-new-blazor.png "dotnet new blazor")

## Verfiy the app runs locally

To verify the app template you just installed runs. From the project folder using a commandline or terminal and type _dotnet build_ and press enter to ensure the newly created project builds without an errors.
![alt text](demo-images/dotnet-build.png "dotnet build")

If the application built successfuly we can try running the application by typing _dotnet run_ from the commandline or terminal. If successful you should see output like below.

![alt text](demo-images/dotnet-run.png "dotnet run")

Your browser should have openened automatically to the http address shown above, if not enter the http address shown. For me it was [http://localhost:5000](http://localhost:5000)

Once you browse to the URL you should see a webpage similiar to below from blazor app.

![alt text](demo-images/blazor-app.png "Blazor wasm app")

Alternatively you can open the .csproj with VisualStudio and launch the debugger from there which should open the browser to the same WebApp url.

Congrats! You have created the blazor application, next we add our messaging functionality.

![alt text](demo-images/yay.png "Yay!")

## Add messaging to our Blazor application

### Add a new nav item

Open the _Shared/NavMenu.razor_ file .razor files are specific to Blazor and are similiar to .cshtml Razor files but with support for Web Assembly by responding as a SPA instead of POST backs.

Add this razor code to the file after the _fetchdata_ `</li>`.

    <li class="nav-item px-3">
         <NavLink class="nav-link" href="messaging">
           <span class="oi oi-comment-square" aria-hidden="true"></span> Messaging
         </NavLink>
    </li>

Lets run the application to make sure our application navigation menu looks correct.

Also lets run the application so it will detect changes when we write code so we don't have to stop and re-run the application each time.

To do this from the commandline or terminal type the below from your application root directory.

    dotnet watch run

You should see the following output. To verify all is well browse to your application in my case it is [http://localhost:5000](http://localhost:5000)

![alt text](demo-images/dotnet-watch-run.png "dotnet watch run")

Yep the new menu is now available so now lets write the messaging code.
![alt text](demo-images/blazor-new-nav.png "New nav menu item")

Create a new Blazor Page under /Pages in your solution and name it _Messaging.razor_

### Add gRPC

## Run the app in a docker container

## Adding NGINX Configuration

We're going to be using NGINX to serve our application so our container size is minimal.

Inside our container however, as our app is a SPA (Single Page Application), we need to tell NGINX to route all requests to the _index.html_.

As NGINX configuration is all opt-in it doesn't handle different mime types unless we tell it to. Also we will need to add in a mime type for wasm as this is not included in NGINXs default mime type list.

In the root of the project add a new file called _nginx.conf_ and add in the following code.

    events { }
     http {
       include mime.types;
       types
       {
         application/wasm wasm;
       }

      server {
        listen 80;
          location / {
            root /usr/share/nginx/html;
            try_files $uri $uri/ /index.html =404;
          }
      }
    }

This is a minimal configuration which will allow our app to be served. If you want to run a production configuration then you should review [NGINX docs](https://nginx.org/en/docs/) site and review all the options you can configure.

Basically we've created a simple web server listening on port 80 with files being served from /usr/share/nginx/html. The try_files configuration tells NGINX to serve the index.html whenever it can't find the requested file on disk.

Above the server block we've included the default mime types _application/wasm wasm;_ as well as a custom mime type for wasm files.

### Add the Dockerfile

Use the contents below and add them to a new file named _Dockerfile_ without an extension in the application root.

    FROM mcr.microsoft.com/dotnet/core/sdk:3.1 AS build
    WORKDIR /src
    COPY docker7bday-demo.csproj .
    RUN dotnet restore "docker7bday-demo.csproj"
    COPY . .
    RUN dotnet build "docker7bday-demo.csproj" -c Release -o /app/build

    FROM build AS publish
    RUN dotnet publish "docker7bday-demo.csproj" -c Release -o /app/publish

    FROM nginx:alpine AS final
    WORKDIR /usr/share/nginx/html
    COPY --from=publish /app/publish/docker7bday-demo/dist .
    COPY nginx.conf /etc/nginx/nginx.conf

### First section

    FROM mcr.microsoft.com/dotnet/core/sdk:3.1 AS build
    WORKDIR /src
    COPY docker7bday-demo.csproj .
    RUN dotnet restore "docker7bday-demo.csproj"
    COPY . .
    RUN dotnet build "docker7bday-demo.csproj" -c Release -o /app/build

* The first block of statements is going to build our app. We're using Microsofts official .NET Core 3.1 SDK image as the base image for the build.

* Next we set the WORKDIR in the container to /src and then COPY the the csproj file from our project.

* Next we execute _dotnet restore_ before executing the docker COPY to copy the rest of the project files to the container.
  
* Finally, we build the project by executing docker RUN _dotnet build_ on our project file setting the build configuration _-c_ to Release.

### Second section

    FROM build AS publish
    RUN dotnet publish "docker7bday-demo.csproj" -c Release -o /app/publish

This section is pretty straightforward, we use the previous section as a base and then RUN the _dotnet publish_ command to publish the project inside of the container.

### Last section

    FROM nginx:alpine AS final
    WORKDIR /usr/share/nginx/html
    COPY --from=publish /app/publish/docker7bday-demo/dist .
    COPY nginx.conf /etc/nginx/nginx.conf

The section produces the final image.

The nginx:alpine image is used as a base and starts by setting the WORKDIR to /usr/share/nginx/html.

This is the directory where we'll serve our application from. The the COPY command is executed to copy over our published app from the previous publish section to the current working directory.

Finally, another COPY command is executed to copy over the _nginx.conf_ we created earlier to replace the default configuration file.

### Build the container

Execute the following command from a command prompt or termnial and make sure you are within your project root directory.

    docker build -t blazor-webassembly-with-docker .

By using the _docker build_ command with the -t switch allows us to tag the image with a friendly name so we can identify it later on. The trailing period (.) instructs docker to use the current directory to locate the _Dockerfile_.

The output from the build will look similiar to below.

[Build output](demo-images/build.txt)

## Test
