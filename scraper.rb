#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def member_data(url)
  noko = noko_for(url)
  noko.xpath('//table[.//th[contains(.,"Fonction")]]//tr[td]').map do |tr|
    tds = tr.css('td')
    {
      name: tds[0].text.tidy,
      wikiname: tds[0].xpath('.//a[not(@class="new")]/@title').text,
      party: tds[1].text.tidy,
      term: tr.xpath('.//preceding::h3').last.text[/(\d{4})/, 1],
      source: url,
    }
  end
end

data = member_data('https://fr.wikipedia.org/wiki/Conseil_territorial_de_Saint-Barth%C3%A9lemy')
data.each { |mem| puts mem.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h } if ENV['MORPH_DEBUG']

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
ScraperWiki.save_sqlite([:name, :party, :term], data)
