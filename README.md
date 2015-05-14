# Political Tweets

Generate Twitter lists for elected representatives using [Popolo](http://www.popoloproject.com) data from [EveryPolitician](http://everypolitician.org).

## Install

You'll need to have ruby, bundler and redis installed locally in order to install this project.

First clone this repository from GitHub:

    git clone https://github.com/mysociety/political_tweets
    cd political_tweets

Install the application dependencies using bundler:

    bundle install

Copy the example `.env` file.

    cp .env.example .env

Now you'll need to [create a Twitter application](https://apps.twitter.com). Once created edit the `.env` file with the Consumer Key and Consumer secret of your newly created app.

Then you'll need to migrate the database.

    bundle exec rake db:migrate

## Usage

The application is made up of a Sinatra app and Resque background workers. In order to run all of these at once first install [Foreman](https://github.com/ddollar/foreman#installation) and then run:

    foreman start

Then you can view the application at http://localhost:5000/
