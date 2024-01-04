# Base image
FROM node:18 as base
MAINTAINER Qiang Tang <tang08@ads.uni-passau.de>
WORKDIR /app
RUN git clone https://github.com/gbd-ufsc/JSONSchemaDiscovery.git .
RUN git checkout c70f4ab
COPY patches/* .
RUN patch -p1 < JSONSchemaDiscovery.patch

# Install dependencies
FROM base as dependencies
WORKDIR /app
RUN npm install --force

# Build the project
FROM base as build
WORKDIR /app
COPY --from=dependencies /app/node_modules /app/node_modules
RUN npm exec -- ng build --output-path dist/public
RUN npm exec -- tsc -p server
RUN npm prune --production --force

# Deployment
FROM base as deploy
RUN curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
    gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor && \
    echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] http://repo.mongodb.org/apt/debian bullseye/mongodb-org/7.0 main" | \
    tee /etc/apt/sources.list.d/mongodb-org-7.0.list
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    dumb-init \
    mongodb-org-tools \
    texlive-base \
    texlive-bibtex-extra \
    texlive-fonts-recommended \
    texlive-latex-extra \
    texlive-plain-generic \
    texlive-publishers \
    texlive-xetex
WORKDIR /app
RUN git clone https://github.com/tlab-unip/ReproEng_JSONSchemaDiscovery_Report.git report
RUN git clone https://github.com/feekosta/datasets.git datasets
RUN mkdir -p /app/logs /app/results
RUN chown 1000:1000 /app/logs /app/results /app/report /app/datasets
ENV NODE_ENV production
USER node
COPY --chown=node:node --from=build /app/dist /app/dist
COPY --chown=node:node --from=build /app/node_modules /app/node_modules
COPY --chown=node:node scripts /app/scripts
COPY --chown=node:node data /app/data
CMD ["dumb-init", "node", "dist/server/app.js"]
