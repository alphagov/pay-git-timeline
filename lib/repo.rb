require 'logger'

class Repo
  def initialize(path, git_client: nil, logger: Logger.new(nil))
    @path = path
    @git_client = git_client || default_git_client
    @logger = logger
  end

  def merges_to_master(since = nil)
    output = @git_client.log(@path, since)
    commits = output.split(/^commit /).reject(&:empty?)

    commits.map { |c| parse(c) }
  end

  def parse(commit)
    lines = commit.split(/[\r\n]/)

    if lines[5] =~ /Merge pull request #([0-9]+)/
      pr_number = $1
    end

    {
      sha: lines[0],
      author: lines[2].split(": ")[1],
      date: lines[3].split(/Date: */)[1],
      message: lines[5].lstrip,
      pull_request: pr_number
    }
  end

  def repo_status
    tagList = @git_client.tags(@path).split(/[\r\n]/).map { |line| parse_tag(line) }
    sorted = tagList.sort_by {|t| t[:build_number].to_i }
    grouped = sorted.group_by {|t| [t[:approved], t[:stage]]}
    last_for_each_stage = Hash[grouped.map { |k, v| [k, {:build_number => v.last[:build_number], :date => v.last[:date], :approver => v.last[:approver]}] }]

    {
     latest_release: last_for_each_stage[[nil, "release"]],
     approved_to_staging: last_for_each_stage[["approved-", "release"]],
     deployed_to_staging: last_for_each_stage[[nil, "staging"]],
     approved_to_production: last_for_each_stage[["approved-", "staging"]],
     deployed_to_production: last_for_each_stage[[nil, "production"]]
    }
  end

  def parse_tag(line)
    if line =~ /(approved-)?alpha_(release|staging|production)(-[0-9]+)?-([0-9]+) \[(.*)\] (.*)$/
      {
          approved: $1,
          stage: $2,
          environment_number: $3,
          build_number: $4,
          date: DateTime.strptime($5, '%s %z').to_time.localtime.strftime("%F %T"),
          approver: $6
      }
    else
      @logger.error "Couldn't parse #{line}"
      {}
    end
  end

  private
  def default_git_client
    GitClient.new
  end

  class GitClient
    def log(path, since = nil)
      cmd = %{git --git-dir="#{path}" log --merges --format=medium}
      cmd << " #{since}..HEAD" if since
      `#{cmd}`
    end

    def tags(path)
      `git --git-dir="#{path}" for-each-ref --sort=refname --format '%(refname:short) [%(taggerdate:raw)] %(taggername)'`
    end
  end
end
