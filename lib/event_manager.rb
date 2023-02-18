# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zip_code(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives somewhere else'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_num)
  phone_num = phone_num.to_s.scan(/\d/).join('')
  phone_num = phone_num[1..] if phone_num.length == 11 && phone_num[0] == '1'
  return '' unless phone_num.length == 10

  phone_num
end

puts 'Event Manager Initialized!'
template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hour_histogram = Array.new(24, 0)
day_of_week = Array.new(7,0)

contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zip_code(zipcode)
  form_letter = erb_template.result(binding)
  # save_thank_you_letter(id, form_letter)
  phone_number = clean_phone_number(row[:homephone])
  time = Time.strptime(row[:regdate], '%m/%j/%y %H:%M')
  hour_histogram[time.hour] += 1
  day_of_week[time.wday] += 1

  # puts "#{name} #{phone_number}"
end

hour_histogram.each_with_index { |num, hour| puts "#{hour}: #{num} registrants" }
day_of_week.each_with_index { |num, day| puts "#{day}: #{num} registrants" }
