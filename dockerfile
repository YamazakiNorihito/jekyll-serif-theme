# Dockerfile
FROM ruby:3.2-slim

# ビルドに必要なパッケージをインストール
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /srv/jekyll

# Gemfileをコピーしてバンドルインストール
COPY ./src/Gemfile ./src/Gemfile.lock* /srv/jekyll/
RUN bundle install

EXPOSE 4000
