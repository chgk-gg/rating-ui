# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Setup and Development
- `bundle install` - Install Ruby dependencies
- `bun install` - Install JavaScript dependencies  
- `bin/dev` - Start development server (runs Rails server, JS build watcher, CSS build watcher)
- `bin/rails server` - Start Rails server only
- `bun run build` - Build JavaScript assets
- `bun run build:css` - Build CSS assets

### Testing and Quality
- `bundle exec rake test` - Run all tests
- `bin/rails test test/system/player_page_test.rb` - Run a specific test file
- `bundle exec rubocop` - Run linting
- `bundle exec brakeman` - Run security analysis

### Database Development
This project requires a PostgreSQL database with specific schema from the [rating-db](https://github.com/chgk-gg/rating-db) repository. Use that repository to download a recent backup and run it with Docker for development.

## Architecture Overview

### Multi-Model Rating System
This Rails application displays team and player rankings for multiple rating models (e.g., model "b"). Each model uses separate database schemas/tables, requiring raw SQL queries for model-specific data while using standard ActiveRecord for shared tables like BaseRoster.

### Key Concepts
- **Models**: Different ranking calculation models stored in separate database schemas
- **Current Model**: Determined by URL parameter (`:model`) or defaults to "b" (InModel::DEFAULT_MODEL)
- **Model Switching**: Routes use `:model` parameter to switch between different rating schemas
- **Raw SQL Usage**: Model-specific queries use raw SQL due to dynamic table names

### Data Flow
1. Data imported from rating.chgk.info via [rating-importer](https://github.com/chgk-gg/rating-importer)
2. Rankings calculated in [rating-b](https://github.com/chgk-gg/rating-b) project
3. This app displays the calculated rankings with model switching capability

### Frontend Stack
- Rails with Turbo and Stimulus.js
- Tailwind CSS for styling
- Bun for JavaScript bundling
- View Components for reusable UI elements

### Background Jobs
- Uses SolidQueue for job processing
- Notable jobs: TrueDL difficulty calculation, tournament results processing
- Mission Control Jobs UI available at `/jobs`

### API Structure
- REST API under `/api/v1/` namespace
- All endpoints require `:model` parameter
- Provides data for teams, players, tournaments, and releases
