# See Politicians Tweet

Generate Twitter lists for elected representatives using [Popolo](http://www.popoloproject.com) data from [EveryPolitician](http://everypolitician.org).

## Install

First clone this repository from GitHub:

    git clone https://github.com/mysociety/political_tweets
    cd political_tweets

Now you can either proceed using vagrant or a manual install. See next two sections for details.

### With vagrant

    vagrant up

Once vagrant has finished creating the environment it will print further instruction about running the application. You will still need to manually fill in the `.env` file (see **Filling in `.env`** below).

### Manual install

You'll need to have ruby, bundler and redis installed locally in order to install this project.
Install the application dependencies using bundler:

    bundle install

Copy the example `.env` file.

    cp .env.example .env

Then you'll need to migrate the database.

    bundle exec rake db:migrate

## Filling in `.env`

First you'll need to [create a Twitter application](https://apps.twitter.com). Once created edit the `.env` file with the Consumer Key, Consumer secret, Access Token and Access Token Secret of your newly created app.

Next you'll need to generate a [Personal access token](https://github.com/settings/tokens) on GitHub. The token will need `public_repo` and `user` scoped ticked. Again, once generated add it to the `.env` file.

## Seed data

If you'd like some seed data to work with first sign in with Twitter to create a user account, then run the following:

    ruby db/seeds.rb

That will create some countries associated with your user account.

## Usage

The application is made up of a Sinatra app and Sidekiq background workers. In order to run all of these at once first install [Foreman](https://github.com/ddollar/foreman#installation) and then run:

    foreman start

Then you can view the application at http://localhost:5000/
