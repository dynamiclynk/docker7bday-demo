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