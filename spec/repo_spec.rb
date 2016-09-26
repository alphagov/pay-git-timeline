$LOAD_PATH << File.dirname(__FILE__) + "/../lib/repo"
require 'repo'
require 'tmpdir'

RSpec.describe Repo do
  let(:fixture_dir) { File.dirname(__FILE__) + "/fixtures" }

  describe "#merges_to_master" do
    around do |example|
      Dir.mktmpdir do |dir|
        @repository_dir = "#{dir}/sample-repo/.git"
        `unzip -d "#{dir}" "#{sample_repo_zip}"`

        example.run
        @repository_dir = nil
      end
    end

    context "repo with one commit" do
      let(:sample_repo_zip) { "#{fixture_dir}/sample-repo.zip" }

      it "lists the merge commits for a given repo" do
        merges = Repo.new(@repository_dir).merges_to_master
        expect(merges.size).to eq(1)
        expect(merges.first).to eq({
          :sha=>"ae8a2e884e4a33ce8d90f1deb2e1e793e67f30c3",
          :author=>"David Heath <david.heath@digital.cabinet-office.gov.uk>",
          :date=>"Wed, 7 Sep 2016 11:09:13 +0100",
          :message=>"Merge pull request #123",
          :pull_request => "123",
          :repo => "sample-repo",
          :pr_url => "https://github.com/alphagov/sample-repo/pull/123",
          :datetime => DateTime.parse("Wed, 7 Sep 2016 11:09:13 +0100"),
          :tags => []
        }
        )
      end
    end

    context "repo with two merge commit" do
      let(:sample_repo_zip) { "#{fixture_dir}/sample-repo2.zip" }

      it "lists the merge commits for a given repo" do
        merges = Repo.new(@repository_dir).merges_to_master
        expect(merges.size).to eq(2)
      end

      it "lists the merge commits for a given repo" do
        merges = Repo.new(@repository_dir).merges_to_master('12073f172c3d90ae9cdda1a0fd2c07b3d1e3c78f')
        expect(merges.size).to eq(1)
      end
    end

    context "repo with tags" do
      let(:sample_repo_zip) { "#{fixture_dir}/sample-repo3.zip" }

      it "lists the merge commits for a given repo" do
        merges = Repo.new(@repository_dir).merges_to_master
        expect(merges.first).to match(hash_including({tags: ['alpha_release-1']}))
      end
    end

  end

  describe "#repo_status" do
    let(:tag_output) { File.read("#{fixture_dir}/tagging-output-with-date.txt")}
    let(:mock_git_client) { double("my git client", tags: tag_output) }

    it "should return the latest tags for each tag type" do
      repo = Repo.new("not-real/.git", git_client: mock_git_client)

      expect(repo.repo_status).to eq({
          latest_release: {:build_number=>"17", :date=>"2016-09-20 16:37:44", :approver =>"Jenkins"},
          approved_to_staging: {:build_number=>"17", :date=>"2016-09-20 18:43:33", :approver =>"Ian Maddison"},
          deployed_to_staging: {:build_number=>"17", :date=>"2016-09-20 19:01:22", :approver =>"Jenkins"},
          approved_to_production: {:build_number=>"17", :date=>"2016-09-20 19:03:02", :approver =>"Ian Maddison" },
          deployed_to_production: {:build_number=>"17", :date=>"2016-09-20 19:08:58", :approver =>"Jenkins" }})
    end
  end
end
