# Political Tweets

Generate Twitter lists for elected representatives using [Popolo](http://www.popoloproject.com) data from [EveryPolitician](http://everypolitician.org).

## Install

You'll need to have ruby and bundler installed locally in order to install this project.

First clone this repository from GitHub:

    git clone https://github.com/mysociety/political_tweets
    cd political_tweets

Install the application dependencies using bundler:

    bundle install

Copy the example `.env` file.

    cp .env.example .env

Now you'll need to [create a Twitter application](https://apps.twitter.com). Once created edit the `.env` file with the Consumer Key and Consumer secret of your newly created app.

## Usage

The application is a Sinatra app, to run it execute the `app.rb` file directly with ruby.

    bundle exec ruby app.rb
