FROM python:3.9-alpine3.13
LABEL maintainer="mellowCS"

ENV PYTHONUNBUFFERED 1
# Copy the local requirements.txt into the tmp folder on the docker image to install
# python dependencies
COPY ./requirements.txt /tmp/requirements.txt
# Copy the local requirements.dev.txt into the tmp folder on the docker image to install
# python dependencies for development
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
# helper scripts
COPY ./scripts /scripts
# Copy the local app dir into an app dir on the docker image
COPY ./app /app
# Make the app dir on the docker image the working directory
WORKDIR /app
# Use port 8000 for communication
EXPOSE 8000

ARG DEV=false
# Create a virtual environment so that none of the docker image python dependencies
# conflict with the project python dependencies.
# Install the postgres client and the build dependencies for the postgres python adapter.
# The dependencies are put into a virtual dependencies folder which makes the cleaning easier.
# Clean up the build dependencies afterwards as they are not needed for running postgres.
# Clear the temp dir after using it to keep the image as light as possible.
# Add a user without root access for security reasons.
RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    apk add --update --no-cache postgresql-client jpeg-dev && \
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base postgresql-dev musl-dev zlib zlib-dev linux-headers && \
    /py/bin/pip install -r /tmp/requirements.txt && \
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    rm -rf /tmp && \
    apk del .tmp-build-deps && \
    adduser \
        --disabled-password \
        --no-create-home \
        django-user && \
    mkdir -p /vol/web/media && \
    mkdir -p /vol/web/static && \
    chown -R django-user:django-user /vol && \
    chmod -R 755 /vol && \
    chmod -R +x /scripts

# Add the py folder to the path to simplify python commands
ENV PATH="/scripts:/py/bin:$PATH"

USER django-user

CMD ["run.sh"]