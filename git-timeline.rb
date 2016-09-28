#!/usr/bin/env ruby
$LOAD_PATH << File.dirname(__FILE__) + "/lib"

require 'pp'
require 'repo'
require 'date'
require 'time'

class RepoMergeTimelinePrinter
  def repos
    [
        "pay-cardid",
        "pay-connector",
        "pay-frontend",
        "pay-logger",
        "pay-publicapi",
        "pay-publicauth",
        "pay-selfservice"
    ]
  end

  def merge_timeline
    repos.map do |repo|
      status = status_for_repo(repo)
      build_number = status[:deployed_to_production][:build_number]
      tag = tag_name_for_stage(:deployed_to_production, build_number)
      Repo.new("../#{repo}/.git", repo_name: repo).merges_to_master(tag)
    end.flatten.sort_by {|m| m[:datetime]}
  end

  def print_timeline
    puts "<table>"
    merge_timeline.each do |merge|
      parts = [
        merge[:date],
        %{<a href="#{merge[:pr_url]}">#{merge[:message]}</a>},
        merge[:repo],
        merge[:authors].join(", "),
        merge[:tags].map {|t| "<a name='#{merge[:repo]}-#{t}'></a>#{t}" }.join(", ")
      ]
      puts "<tr><td>#{parts.join('</td><td>')}</td></tr>"
    end
    puts "</table>"
  end

  def tag_name_for_stage(stage, build_number)
    prefix = {
      :latest_release => "alpha_release",
      :approved_to_staging => "approved-alpha_release",
      :deployed_to_staging => "alpha_staging-1",
      :approved_to_production => "approved-alpha_staging-1",
      :deployed_to_production => "alpha_production-1"
    }.fetch(stage)
    "#{prefix}-#{build_number}"
  end

  def link_to_build(repo_name, status, stage, build_number)
    tag = tag_name_for_stage(stage, build_number)
    "<a href='##{repo_name}-#{tag}'>#{build_number}</a>"
  end

  def status_for_repo(repo)
    @statuses ||= {}
    @statuses[repo] ||= Repo.new("../#{repo}/.git").repo_status
  end

  def repo_status
    puts "<html>"
    puts "<head>"
    puts "<style>"
    puts ".summary {border: 1px solid black;}"
    puts "</style>"
    puts "</head>"
    puts "<table class='summary'>"
    puts "<tr>" \
    "<th class='summary'>Repo</th>" \
    "<th class='summary' colspan='3'>Latest release</th>" \
    "<th class='summary' colspan='3'>Approved to staging</th>" \
    "<th class='summary' colspan='2'>Deployed to staging</th>" \
    "<th class='summary' colspan='3'>Approved to production</th>" \
    "<th class='summary' colspan='2'>Deployed to production</th>" \
    "</tr>"
    repos.map do |repo, _|
      repoObj = Repo.new("../#{repo}/.git")
      status = repoObj.repo_status
      unless status[:latest_release].nil?
        author = repoObj.author("../#{repo}/.git", status[:latest_release][:build_number])
        puts "<tr>" \
          "<td class='summary'>#{repo}</td>" \
          "<td class='summary'>#{status[:latest_release][:build_number]}</td>" \
          "<td class='summary'>#{status[:latest_release][:date]}</td>" \
          "<td class='summary'>#{author}</td>" \
          "<td class='summary'>#{status[:approved_to_staging][:build_number]}</td>" \
          "<td class='summary'>#{status[:latest_release][:date]}</td>" \
          "<td class='summary'>#{status[:approved_to_staging][:approver]}</td>" \
          "<td class='summary'>#{status[:deployed_to_staging][:build_number]}</td>" \
          "<td class='summary'>#{status[:latest_release][:date]}</td>" \
          "<td class='summary'>#{status[:approved_to_production][:build_number]}</td>" \
          "<td class='summary'>#{status[:latest_release][:date]}</td>" \
          "<td class='summary'>#{status[:approved_to_production][:approver]}</font></td>" \
          "<td class='summary'>#{status[:deployed_to_production][:build_number]}</td>" \
          "<td class='summary'>#{status[:latest_release][:date]}</font></td>" \
          "</tr>"
      end
    end
    puts "</table>"
    puts "<html>"
  end
end

printer = RepoMergeTimelinePrinter.new
printer.repo_status
puts "<br />"
printer.print_timeline


