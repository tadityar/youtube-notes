#!/bin/sh

hasura migrate apply --skip-update-check &&
hasura metadata apply --skip-update-check --from-file &&
exec hasura console --skip-update-check --no-browser --address 0.0.0.0
