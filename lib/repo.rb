class Repo
  def initialize(path)
    @path = path
  end

  def merges_to_master(since = nil)
    cmd = %{git --git-dir="#{@path}" log --merges --format=medium}
    cmd << " #{since}..HEAD" if since
    output = `#{cmd}`
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
end
