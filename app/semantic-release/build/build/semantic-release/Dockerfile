ARG BASE_IMAGE
FROM $BASE_IMAGE

RUN apt-get update && apt-get install -y --no-install-recommends git-core ca-certificates  curl ssh-client rsync bash jq \
	&& rm -rf /var/lib/apt/lists/ \
	&& npm install -g semantic-release @semantic-release/gitlab semantic-release-slack-bot @semantic-release/exec @semantic-release/changelog