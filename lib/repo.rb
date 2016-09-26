require 'logger'
require 'pathname'

class Repo
  def initialize(path, repo_name: nil, git_client: nil, logger: Logger.new(nil))
    @path = path
    @repo_name = repo_name || Pathname.new(path).dirname.basename.to_s
    @git_client = git_client || default_git_client
    @logger = logger
  end

  def merges_to_master(since = nil)
    output = @git_client.log(@path, since)
    commits = output.split(/^commit /).reject(&:empty?)

    commits.map { |c| Commit.new(c, @repo_name).to_hash }
  end

  class Commit
    attr_reader :lines, :repo

    def initialize(commit, repo)
      @lines = commit.split(/[\r\n]/)
      @repo = repo
    end

    def to_hash
      {
        sha: sha,
        merged_by: merged_by,
        date: date,
        message: message,
        pull_request: pr_number,
        repo: repo,
        pr_url: pr_url,
        datetime: datetime,
        tags: tags
      }
    end

    def sha
      lines[0]
    end

    def merged_by
      lines[3].split(": ")[1]
    end

    def date
      lines[4].split(/Date: */)[1]
    end

    def datetime
      DateTime.parse(date)
    end

    def pr_number
      if lines[6] =~ /Merge pull request #([0-9]+)/
        $1
      else
        nil
      end
    end

    def message
      lines[6].lstrip
    end

    def tags
      lines[2].split(", ").select { |t| t =~ /^tag: / }.map {|t| t.split(": ")[1] }
    end

    def pr_url
      "https://github.com/alphagov/#{repo}/pull/#{pr_number}" if pr_number
    end

  end

  def author(path, buildNumber)
    `git --git-dir="#{path}" log --format='%an' alpha_release-#{buildNumber}^1..alpha_release-#{buildNumber}^2 | uniq | head -n1`
  end

  def tag_list
    @tag_list ||= @git_client.tags(@path).split(/[\r\n]/).map { |line| parse_tag(line) }.sort_by {|t| t[:build_number].to_i }
  end

  def last_tag_for_each_stage
    @last_tag_for_each_stage ||= begin
      grouped = tag_list.group_by {|t| [t[:approved], t[:stage]]}
      last_per_stage_as_tuples = grouped.map do |k, v|
        [
          k,
          {
            :build_number => v.last[:build_number],
            :date => v.last[:date],
            :approver => v.last[:approver]
          }
        ]
      end
      Hash[last_per_stage_as_tuples]
    end
  end

  def repo_status
    {
      latest_release: last_tag_for_each_stage.fetch([nil, "release"], {}),
      approved_to_staging: last_tag_for_each_stage.fetch(["approved-", "release"], {}),
      deployed_to_staging: last_tag_for_each_stage.fetch([nil, "staging"], {}),
      approved_to_production: last_tag_for_each_stage.fetch(["approved-", "staging"], {}),
      deployed_to_production: last_tag_for_each_stage.fetch([nil, "production"], {})
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
      cmd = %{git --git-dir="#{path}" log --merges --format='commit %H%nMerge: %P%n%D%nAuthor: %an <%ae>%nDate:   %aD%n%n%s%n%n%b%n'}
      cmd << " #{since}..HEAD" if since
      `#{cmd}`
    end

    def tags(path)
      `git --git-dir="#{path}" for-each-ref --sort=refname --format '%(refname:short) [%(taggerdate:raw)] %(taggername)'`
    end

    def authors(merge_commit)
      `git --git-dir="#{path}" log --format='%an' #{merge_commit}^1..#{merge_commit}^2`.split(/\n/)
    end
  end
end
