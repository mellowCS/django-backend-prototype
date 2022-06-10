FROM python:3.9-alpine3.13
LABEL maintainer="mellowCS"

ENV PYTHONUNBUFFERED 1
# Copy the local requirements.txt into the tmp folder on the docker image to install
# python dependencies
COPY ./requirements.txt /tmp/requirements.txt
# Copy the local requirements.dev.txt into the tmp folder on the docker image to install
# python dependencies for development
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
# Copy the local app dir into an app dir on the docker image
COPY ./app /app
# Make the app dir on the docker image the working directory
WORKDIR /app
# Use port 8000 for communication
EXPOSE 8000

ARG DEV=false
# Create a virtual environment so that none of the docker image python dependencies
# conflict with the project python dependencies
# Clear the temp dir after using it to keep the image as light as possible
# Add a user without root access for security reasons
RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    /py/bin/pip install -r /tmp/requirements.txt && \
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    rm -rf /tmp && \
    adduser \
        --disabled-password \
        --no-create-home \
        django-user

# Add the py folder to the path to simplify python commands
ENV PATH="/py/bin:$PATH"

USER django-user