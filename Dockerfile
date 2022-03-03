FROM node as hugo
RUN mkdir /app
WORKDIR /app
COPY . .
RUN wget -q https://github.com/gohugoio/hugo/releases/download/v0.92.1/hugo_0.92.1_Linux-64bit.tar.gz && tar zxvf hugo_0.92.1_Linux-64bit.tar.gz
RUN npm ci && npm i -g postcss-cli && ./hugo -D --gc

FROM bitnami/nginx:latest
COPY --from=hugo /app/public /app
