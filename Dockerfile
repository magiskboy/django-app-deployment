FROM python:3-alpine3.6

WORKDIR /opt/demo

COPY . .

EXPOSE 80

RUN apk update && apk upgrade && apk add --no-cache build-base python-dev py-pip jpeg-dev zlib-dev nginx

RUN cp demo.conf /etc/nginx/conf.d/demo && rm /etc/nginx/conf.d/default.conf && mkdir -p /run/nginx

RUN export LC_ALL="en_US.UTF-8" && pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

RUN nginx

ENTRYPOINT [ "./docker-entrypoint.sh" ]