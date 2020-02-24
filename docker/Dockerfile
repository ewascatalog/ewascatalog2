FROM python:3
ENV PYTHONUNBUFFERED 1
RUN mkdir /code
WORKDIR /code
ADD python-requirements.txt /code/
RUN pip install -r python-requirements.txt
ADD . /code/
