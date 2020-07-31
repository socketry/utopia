# Server Setup

This guide explains how to deploy a `utopia` web application.

## Deployment

The preferred method of deployment to a production server is via git. The `utopia` command assists with setup of a remote git repository on the server. It will setup a `git` `post-update` hook which will deploy the site correctly and restart the application server for that site.

To setup a server for deployment:

~~~ bash
$ mkdir /srv/http/www.example.com
$ cd /srv/http/www.example.com
$ sudo -u http utopia server create
~~~

On your development machine, you should setup the git remote:

~~~ bash
$ git remote add production ssh://remote/srv/http/www.example.com
$ git push --set-upstream production master
~~~

### Default Environment

Utopia will load `config/environment.yaml` and update `ENV` before executing any code. By default, [variant](https://github.com/socketry/variant) is used for handling different environments. You can set default environment values using the `utopia` command:

~~~ bash
$ utopia environment VARIANT=staging DATABASE_VARIANT=staging1
ENV["VARIANT"] will default to "staging" unless otherwise specified.
ENV["DATABASE_VARIANT"] will default to "staging1" unless otherwise specified.
~~~

To set a value, write `KEY=VALUE`. To unset a key, write `KEY`.

When you run `rake` tasks or spawn a server, the values in `config/environment.yaml` will be the defaults. You can override them by manually specifying them, e.g. `DATABASE_ENV=development rake db:info`.

## Platform

The best deployment platform for Utopia is Linux, using [falcon](https://github.com/socketry/falcon).

### Sudo Setup

Create a file `/etc/sudoers.d/http` with the following contents:

```sudoers
# Allow user samuel to check out code as user http using git:
%wheel ALL=(http) NOPASSWD: ALL
```

This allows the deploy task to correctly checkout code as user `http`.

## Automatic Deployment

Automatic deployment allows you to deploy updates to your site when they are committed to a specific branch.

### GitHub Actions

Here is a basic workflow, adapted from the [www.codeotaku.com workflow](https://github.com/ioquatix/www.codeotaku.com/blob/master/.github/workflows/development.yml).

~~~ yaml
name: Development

on: [push]

jobs:
  test:
    strategy:
      matrix:
        os:
          - ubuntu
        
        ruby:
          - 2.7
    
    runs-on: ${{matrix.os}}-latest
    
    steps:
    - uses: actions/checkout@v1
    - uses: ruby/setup-ruby@v1
      with:
        ruby-version: ${{matrix.ruby}}
    - uses: actions/cache@v1
      with:
        path: vendor/bundle
        key: ${{runner.os}}-${{matrix.ruby}}-${{hashFiles('**/Gemfile.lock')}}
        restore-keys: |
          ${{runner.os}}-${{matrix.ruby}}-
    - name: Bundle install
      run: |
        sudo apt-get install pkg-config
        gem install bundler:2.1.4
        bundle config path vendor/bundle
        bundle install --jobs 4 --retry 3
    - name: Run tests
      run: ${{matrix.env}} bundle exec rspec
  
  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/master'
    
    steps:
    - uses: actions/checkout@v1
    - name: Push to remote system
      env:
        DEPLOY_KEY: ${{secrets.deploy_key}}
      run: |
        eval "$(ssh-agent -s)"
        ssh-add - <<< $DEPLOY_KEY
        mkdir ~/.ssh
        ssh-keyscan -H www.oriontransfer.net >> ~/.ssh/known_hosts
        git push -f ssh://http@www.oriontransfer.net/srv/http/www.codeotaku.com/ HEAD:master
~~~

You will need to add your own DEPLOY_KEY to the GitHub Secrets of your repository andupdate the hostnames and directories to suit your own setup.
