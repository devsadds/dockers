ARG IMAGE_BASE
FROM $IMAGE_BASE
ARG IMAGE_TAG
ARG IMAGE_NAME
ENV $IMAGE_TAG \
	$IMAGE_NAME \
	$IMAGE_MAINTAINER

RUN echo "build $IMAGE_NAME:$IMAGE_TAG. IMAGE_MAINTAINER = $IMAGE_MAINTAINER" 
VOLUME /app/uploads
WORKDIR /app
RUN groupadd -r rocketchat \
&&  useradd -r -g rocketchat rocketchat \
&&  mkdir -p /app/uploads \
&&  chown rocketchat.rocketchat /app/uploads \
&& apt-get update && apt-get install gpg-agent curl  -y \
&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 0E163286C20D07B9787EBE9FD7F9D0414FD08104 \
&& cd /app \
&& echo "Download https://releases.rocket.chat/${IMAGE_TAG}/download" \
&& curl -fSL "https://releases.rocket.chat/${IMAGE_TAG}/download" -o rocket.chat.tgz \
&& curl -fSL "https://releases.rocket.chat/${IMAGE_TAG}/asc" -o rocket.chat.tgz.asc \
&& gpg --batch --verify rocket.chat.tgz.asc rocket.chat.tgz \
&& tar zxvf rocket.chat.tgz \
&& rm rocket.chat.tgz rocket.chat.tgz.asc \
&& cd bundle/programs/server \
&& npm install \
&& chown -R rocketchat:rocketchat  /app/
USER rocketchat

WORKDIR /app/bundle

ENV DEPLOY_METHOD=docker-official \
    MONGO_URL=mongodb://db:27017/meteor \
    HOME=/tmp \
    PORT=3000 \
    ROOT_URL=http://localhost:3000 \
    Accounts_AvatarStorePath=/app/uploads

EXPOSE 3000

CMD ["node", "main.js"]
