$LOAD_PATH << File.dirname(__FILE__) + "/../lib/repo"
require 'repo'
require 'tmpdir'

RSpec.describe Repo do

  around do |example|
    Dir.mktmpdir do |dir|
      @repository_dir = "#{dir}/sample-repo/.git"
      `unzip -d "#{dir}" "#{sample_repo_zip}"`

      example.run
      @repository_dir = nil
    end
  end

  context "repo with one commit" do
    let(:sample_repo_zip) { File.dirname(__FILE__) + "/fixtures/sample-repo.zip" }

    it "lists the merge commits for a given repo" do
      merges = Repo.new(@repository_dir).merges_to_master
      expect(merges.size).to eq(1)
      expect(merges.first).to eq({
        :sha=>"ae8a2e884e4a33ce8d90f1deb2e1e793e67f30c3",
        :author=>"David Heath <david.heath@digital.cabinet-office.gov.uk>",
        :date=>"Wed Sep 7 11:09:13 2016 +0100",
        :message=>"Merge pull request #123",
        :pull_request => "123"
      }
      )
    end
  end

  context "repo with two merge commit" do
    let(:sample_repo_zip) { File.dirname(__FILE__) + "/fixtures/sample-repo2.zip" }

    it "lists the merge commits for a given repo" do
      merges = Repo.new(@repository_dir).merges_to_master
      expect(merges.size).to eq(2)
    end

    it "lists the merge commits for a given repo" do
      merges = Repo.new(@repository_dir).merges_to_master('12073f172c3d90ae9cdda1a0fd2c07b3d1e3c78f')
      expect(merges.size).to eq(1)
    end
  end

end
