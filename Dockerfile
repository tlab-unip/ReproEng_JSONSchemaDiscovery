# Base image
FROM node:18 as base
MAINTAINER Qiang Tang <tang08@ads.uni-passau.de>
WORKDIR /app

# Original project
FROM base as build
WORKDIR /app
# Pull the original project from GitHub
RUN git clone https://github.com/gbd-ufsc/JSONSchemaDiscovery.git .
RUN git checkout c70f4ab
# Apply patches to the project
COPY patches/* .
RUN patch -p1 < JSONSchemaDiscovery.patch
RUN npm install --force
# Build the project
RUN npm exec -- ng build --output-path dist/public
RUN npm exec -- tsc -p server
RUN npm prune --production --force

# External dependencies
FROM base as dependencies
WORKDIR /app
# Pull the datasets from remote
RUN mkdir datasets && \
    wget https://github.com/feekosta/datasets/raw/master/companies/dbpedia_companies1.json.tar.bz2 -P datasets && \
    wget https://github.com/feekosta/datasets/raw/master/drugs/dbpedia-drugs1.json.tar.bz2 -P datasets && \
    wget https://github.com/feekosta/datasets/raw/master/movies/dbpedia_movies1.json.tar.bz2 -P datasets
# extract and repair the datasets
RUN npm install -g jsonrepair
RUN for f in datasets/*.tar.bz2; do jsonrepair datasets/$(tar -xvjf "$f" -C datasets) --overwrite && rm "$f"; done
# Pull the report from remote
ADD https://api.github.com/repos/tlab-unip/ReproEng_JSONSchemaDiscovery_Report/git/refs/heads/main version.json
RUN git clone -b main https://github.com/tlab-unip/ReproEng_JSONSchemaDiscovery_Report.git report

# Deployment
FROM base as deploy
# Install mongodb tools and latex dependencies
RUN curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
    gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor && \
    echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] http://repo.mongodb.org/apt/debian bullseye/mongodb-org/7.0 main" | \
    tee /etc/apt/sources.list.d/mongodb-org-7.0.list
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    mongodb-org-tools \
    texlive \
    texlive-bibtex-extra \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    texlive-latex-extra \
    texlive-plain-generic \
    texlive-publishers \
    texlive-xetex
# Install additional dependencies
RUN apt-get install -y --no-install-recommends \
    dumb-init \
    fonts-linuxlibertine \
    jq
# Configure working directory
WORKDIR /app
RUN mkdir -p logs results
RUN chown -R 1000:1000 logs results
ENV NODE_ENV production
USER node
# Copy build result from previous steps
COPY --chown=node:node --from=build /app/dist dist
COPY --chown=node:node --from=build /app/node_modules node_modules
COPY --chown=node:node --from=dependencies /app/datasets datasets
COPY --chown=node:node --from=dependencies /app/report report
COPY --chown=node:node --chmod=777 scripts scripts
CMD ["dumb-init", "node", "dist/server/app.js"]
