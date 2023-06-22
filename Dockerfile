# syntax=docker/dockerfile:1.0.0-experimental
ARG levant_version
ARG nomad_version

FROM hashicorp/levant:$levant_version AS levant

FROM hendrikmaus/nomad-cli:$nomad_version AS nomad

FROM docker:latest

COPY --from=nomad /bin/nomad /bin/nomad
COPY --from=levant /bin/levant /bin/levant

RUN apk update && apk add bash

ADD ./interpol /bin/interpol

COPY ./entrypoint /entrypoint
RUN sed -i 's/\r$//g' /entrypoint
RUN chmod +x /entrypoint

ENTRYPOINT ["/entrypoint"]