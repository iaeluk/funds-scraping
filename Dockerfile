FROM ruby:3.0

WORKDIR /app

COPY Gemfile ./

RUN bundle install

COPY . .

CMD ["ruby", "app.rb", "-p", "8080"]
