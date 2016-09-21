#!/usr/bin/env ruby
$LOAD_PATH << File.dirname(__FILE__) + "/lib"

require 'pp'
require 'repo'
require 'date'
require 'time'

class RepoMergeTimelinePrinter
  def repos
    {
        "pay-cardid" => "0df2fa96628fc9a6077d7eb90f7ec4deb9cd6318",
        "pay-connector" => "1375df7361b4ceab461a01ac8b5db24e80628053",
        "pay-frontend" => "d1bde6f44dd2ebae74afb2ae4fe0a2b3a8e28320",
        "pay-logger" => "HEAD",
        "pay-publicapi" => "4df8b8f5f4b4cc73a3cec57af77bf64aa2f54418",
        "pay-publicauth" => "d9496e09563cb8e6647a62849dd61fd1688b9759",
        "pay-selfservice" => "bd04e2740a0600d443ab0d7c6192afe20de477c0",
    }
  end

  def merge_timeline
    repos.map do |repo, sha|
      Repo.new("../#{repo}/.git").merges_to_master(sha).map do |m|
        m.merge({
                    repo: repo,
                    pr_url: "https://github.com/alphagov/#{repo}/pull/#{m[:pull_request]}",
                    datetime: DateTime.parse(m[:date])
                })
      end
    end.flatten.sort_by {|m| m[:datetime]}
  end

  def print_timeline
    puts "<table>"
    merge_timeline.each do |merge|
      parts = [merge[:date],merge[:repo],%{<a href="#{merge[:pr_url]}">#{merge[:message]}</a>}]
      puts "<tr><td>#{parts.join('</td><td>')}</td></tr>"
    end
    puts "</table>"
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
    "<th class='summary' colspan='2'>Latest release</th>" \
    "<th class='summary' colspan='2'>Approved to staging</th>" \
    "<th class='summary' colspan='2'>Deployed to staging</th>" \
    "<th class='summary' colspan='2'>Approved to production</th>" \
    "<th class='summary' colspan='2'>Deployed to production</th>" \
    "</tr>"
    repos.map do |repo, _|
      status = Repo.new("../#{repo}/.git").repo_status
      unless status[:latest_release].nil?
        puts "<tr>" \
          "<td class='summary'>#{repo}</td>" \
          "<td class='summary'>#{status[:latest_release][:build_number]}</td>" \
          "<td class='summary'><font size='2'>(#{status[:latest_release][:date]})</font></td>" \
          "<td class='summary'>#{status[:approved_to_staging][:build_number]}</td>" \
          "<td class='summary'><font size='2'>(#{status[:latest_release][:date]})</font> <font size='1'>(#{status[:approved_to_staging][:approver]})</font></td>" \
          "<td class='summary'>#{status[:deployed_to_staging][:build_number]}</td>" \
          "<td class='summary'> <font size='2'>(#{status[:latest_release][:date]})</font></td>" \
          "<td class='summary'>#{status[:approved_to_production][:build_number]}</td>" \
          "<td class='summary'><font size='2'>(#{status[:latest_release][:date]})</font>  <font size='1'>(#{status[:approved_to_production][:approver]})</font></td>" \
          "<td class='summary'>#{status[:deployed_to_production][:build_number]}</td>" \
          "<td class='summary'><font size='2'>(#{status[:latest_release][:date]})</font></td>" \
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


