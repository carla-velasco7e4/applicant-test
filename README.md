# Shopware 6 Playground

## Initialize your local environment

The environment can be set up by executing `make init` within this directory.

- Frontend is accessible at [http://localhost:8080](http://localhost:8080)
- Adminpanel is accessible at [http://localhost:8080/admin](http://localhost:8080/admin)
- Credentials for Adminpanel are defaults (username is "admin" and password is "shopware")

## What you should do

The functionality you should implement is nothing that one would do in a real-life
project. This functionality has been chosen to come around several spots of shopware
and symfony. So please don't wonder that it is not giving that much of a sense :)

Create a new Shopware plugin that is tracking product views. So whenever a user is visiting
the Productdetail page, we increase a simple counter for that product.
This functionality should be working without the use of any JavaScript.
To generate a report to see the "most viewed products" you should implement a CLI command,
that is outputting the product-ids, product-names and the count of product views.
The output format can be one of your choice.
The results should be ordered by the product views, most viewed product should be printed first.

Also the CLI command should have 2 optional parameters to generate a report for a specific timerange:

1. `--start` to define the start of the report's timerange
2. `--end` to define the end of the report's timerange

Both of the arguments should take a `ISO 8601 date` as the value, if the given value is not matching `ISO 8601`,
the command should output an informational message to the user.

## When you have finished

As soon as you have finished things, please open a pull request against the repository's main branch
itself and let us know 🎉
