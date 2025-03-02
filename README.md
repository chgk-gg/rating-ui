# rating.chgk.gg

Displays team and player rankings at [rating.chgk.gg](https://rating.chgk.gg).

Rankings are calculated in the [rating-b](https://github.com/chgk-gg/rating-b) project.

Data for calculations is imported from [rating.chgk.info](https://rating.chgk.info) with [rating-importer](https://github.com/chgk-gg/rating-importer).

See the [rating-db](https://github.com/chgk-gg/rating-db) repository for information on how to download a copy of the database.

## Architecture notes

This is more or less a standard Rails application, with PostgreSQL as the database and a bit of Stimulus.js on the frontend.

The main complication is that we want to be able to show different ranking models, and those are implemented as different schemas in the same database. Because of this, we write queries that use model-specific tables in a raw SQL. For example, on a team page, a list of players in its base roster comes from the `BaseRoster` model, with queries being standard Active Record stuff. However, to get its history of ratings, we check what is the current model and then use a raw SQL query to get the data from the corresponding table.

## Things that are not just data display

We calculate [TrueDL difficulty for each tournament](https://pecheny.me/blog/truedl/) in a job in this repo. We also expose an endpoint which rating.chgk.info uses to get a list of wrongly assigned team IDs.

## Tests

In the [rating-db](https://github.com/chgk-gg/rating-db) repository, there is a job that builds a PostgreSQL image with the current database schema, which we use in tests here.

The reason for this complication is that the models-specific part of the schema is maintained in rating-b (which is a Python project). We might want to have a single place that defines the whole schema, but we would still need an image like that for tests.

## Development

Again, use [rating-db](https://github.com/chgk-gg/rating-db) to download a recent backup and run it with Docker.

We use Bun to build frontend, so you would need it installed. Everything else is standard: `bundle install`, then `bin/dev`.
