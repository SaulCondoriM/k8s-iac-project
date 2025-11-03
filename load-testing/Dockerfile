FROM python:3.11-slim

WORKDIR /locust

RUN pip install locust

COPY locustfile.py /locust/

EXPOSE 8089

CMD ["locust"]
