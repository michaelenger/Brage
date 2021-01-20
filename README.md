# Heimdall

Site builder for generating sites based on YAML, Markdown, and [Mustache](https://mustache.github.io/) templates.

**NOTE** This application is currently under development and a lot of this readme is reflecting ambitious plans rather than reality.

## Usage

Run the CLI tool along with any of the commands along with an optional site directory. If no directory is present it will use the current directory.

```shell
heimdall [command] [DIRECTORY]
```

### Commands

* `new` Create a new website based on a basic template.
* `build` Generate the HTML.
* `serve` Serve the HTML via a basic localhost server.

## Site Generation

The site generation is based on YAML files and Mustache templates. The only requirements to start with is a config file and an index template.

### Config

The config is defined in a `site.yml` file in the site directory. It defines some basic meta data as well as other contents (explained below).

* `title` Title of the site.
* `description` Description of the site, used in meta tags.
* `image` Image used for the icon and social media images.

### Assets

TODO

### Collections

TODO

### Forms

TODO

## Development

### Requirements

* [Swift 5](https://swift.org/)
