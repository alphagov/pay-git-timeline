## GOV.UK Pay git timeline

This is a quick hack to generate a single timeline of merges to master on multiple git repositories.

The list of repositories and the starting commit are hard-coded in the script.

The script expects the repositories to be checked out locally in sibling directories.

## Dependencies

* ruby 2.x or above
* `bundler` (`gem install bundler`)

## Usage

```
$ bundle install
$ bundle exec ./git-timeline.rb > timeline.html
```

The timeline is output as an html table.

