ARG IMAGE_TAG
FROM $IMAGE_TAG
USER root
RUN dnf install -y python3-pip redis \
		&& cd /var/lib/awx/venv \
    && pip3 install jmespath  pyapi-gitlab  \
    && ansible --version