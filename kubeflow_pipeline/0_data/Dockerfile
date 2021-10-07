FROM python:3.6

COPY . /app
WORKDIR /app

RUN apt-get update && \
    apt-get install -y libgl1-mesa-dev && \
    pip install -r requirements.txt

ENTRYPOINT ["python"]
CMD ["run.py"]