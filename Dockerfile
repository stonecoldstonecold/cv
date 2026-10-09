FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    TORCH_HOME=/opt/torch

WORKDIR /srv

RUN pip install --index-url https://download.pytorch.org/whl/cpu \
        torch==2.2.2 torchvision==0.17.2

COPY requirements.txt .
RUN pip install -r requirements.txt

RUN python -c "from facenet_pytorch import InceptionResnetV1; InceptionResnetV1(pretrained='vggface2')"

COPY app ./app

ENV DATA_DIR=/data
ENTRYPOINT ["python", "-m", "app.main"]
CMD ["--help"]
