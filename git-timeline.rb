#!/usr/bin/env ruby
$LOAD_PATH << File.dirname(__FILE__) + "/lib"

require 'pp'
require 'repo'
require 'date'
require 'time'

repos = {
  "pay-cardid" => "0df2fa96628fc9a6077d7eb90f7ec4deb9cd6318",
  "pay-connector" => "1375df7361b4ceab461a01ac8b5db24e80628053",
  "pay-frontend" => "d1bde6f44dd2ebae74afb2ae4fe0a2b3a8e28320",
  "pay-logger" => "HEAD",
  "pay-publicapi" => "4df8b8f5f4b4cc73a3cec57af77bf64aa2f54418",
  "pay-publicauth" => "d9496e09563cb8e6647a62849dd61fd1688b9759",
  "pay-selfservice" => "bd04e2740a0600d443ab0d7c6192afe20de477c0",
}

merges = []
repos.each do |repo, sha|
  merges += Repo.new("../#{repo}/.git").merges_to_master(sha).map do |m|
    m.merge({
      repo: repo,
      pr_url: "https://github.com/alphagov/#{repo}/pull/#{m[:pull_request]}",
      datetime: DateTime.parse(m[:date])
    })
  end
end

puts "<ul>"
merges.sort_by {|m| m[:datetime]}.each do |merge|
  puts %{<li>#{merge[:date]}: #{merge[:repo]} <a href="#{merge[:pr_url]}">#{merge[:message]}</a></li>\n}
end
