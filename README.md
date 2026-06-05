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

## REST API

A read-only JSON API is available under the `/api/v1/` namespace. Every endpoint takes a `:model` path parameter that selects the ranking model (e.g., `b`). If the model does not exist, the endpoint responds with `400 Bad Request` and a body like `{"error": "..."}`.

Endpoints that list teams or players accept an optional `show_names=true` query parameter, which adds team/player names (and other details) to the response. They are off by default.

Paginated endpoints (`teams` and `players` for a release) accept `page` (default `1`) and `page_size` (default `500`) query parameters, and include `current_page`, `pages`, and `all_items_count` in the response alongside the `items` array.

### Endpoints

#### Teams in a release
```
GET /api/v1/:model/teams/:release_id
```
Returns the ranked teams in a release, each with their tournaments in that release and their current/previous top and bottom places. Use `latest` as `:release_id` to get the most recent release. Paginated. Supports `show_names=true`.

#### Releases history for a team
```
GET /api/v1/:model/teams/:team_id/releases
```
Returns a team's rating in every release, with the rated tournaments grouped under each release. Supports `show_names=true`.

#### Players in a release
```
GET /api/v1/:model/players/:release_id
```
Returns the ranked players in a release, each with their rating components per tournament and their current/previous top and bottom places. Use `latest` as `:release_id` to get the most recent release. Paginated. Supports `show_names=true`.

#### Releases history for a player
```
GET /api/v1/:model/players/:player_id/releases
```
Returns a player's rating in every release, with the rated tournaments grouped under each release. Supports `show_names=true`.

#### Tournament ratings
```
GET /api/v1/:model/tournaments/:tournament_id
```
Returns the per-team rating results for a tournament. Metadata includes the tournament's TrueDL difficulty. Supports `show_names=true` (adds team names to the items and the tournament title and start/end dates to the metadata).

#### All releases
```
GET /api/v1/:model/releases
```
Returns every release in the model, each with its `q` value and the IDs of its tournaments split into `in_rating` and `not_in_rating`.

#### Wrong team IDs
```
GET /api/v1/:model/wrong_team_ids
```
Returns the list of wrongly assigned team IDs. Tournament organizers can submit a team under any ID, and if a team in a tournament has 4+ players from some base roster, we should reassign this tournament’s result to that team’s ID. This happens on the rating.chgk.info side, we only find and report mismatches.

## Tests

In the [rating-db](https://github.com/chgk-gg/rating-db) repository, there is a job that builds a PostgreSQL image with the current database schema, which we use in tests here.

The reason for this complication is that the models-specific part of the schema is maintained in rating-b (which is a Python project). We might want to have a single place that defines the whole schema, but we would still need an image like that for tests.

However, you don’t need to do anything manually to use that image: this is handled by the [testcontainers](https://github.com/testcontainers/testcontainers-ruby) gem. Run tests with:

```bash
bundle exec rake test
```

When you run tests for the first on your machine, testcontainer will download the latest image with the schema. For each run, we create and destroy a container.

## Development

Again, use [rating-db](https://github.com/chgk-gg/rating-db) to download a recent backup and run it with Docker.

We use Bun to build frontend, so you would need it installed. Everything else is standard: `bundle install`, then `bin/dev`.
