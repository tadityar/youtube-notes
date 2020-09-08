FROM frolvlad/alpine-glibc:alpine-3.12_glibc-2.31

RUN apk add curl libstdc++
RUN curl -L -f -o "/usr/local/bin/hasura" "https://github.com/hasura/graphql-engine/releases/download/v1.3.0/cli-hasura-linux-amd64"
RUN chmod +x "/usr/local/bin/hasura"
RUN /usr/local/bin/hasura plugins install cli-ext
