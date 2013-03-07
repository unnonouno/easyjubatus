#!/usr/bin/env ruby

require 'rubygems'
require 'thor'
require 'csv'
require 'jubatus/classifier/client'

def open_bazil_csv(path)
  types = nil
  keys = nil
  CSV.foreach(path) do |row|
    raise "At least one column is required for annotation" if row.length == 0
    if types == nil
      types = row
      next
    elsif keys == nil
      raise "The first column name must be \"annotation\" but is \"#{row[0]}\"" if row[0] != "annotation"
      keys = row
      next
    else
      string_values = []
      num_values = []
      (1...types.length).each do |i|
        if types[i] == "string"
          string_values << [keys[i], row[i]]
        elsif types[i] == "number"
          num_values << [keys[i], row[i].to_f]
        else
          raise "unsupported data type: #{types[i]}"
        end
      end

      yield row[0], Jubatus::Classifier::Datum.new(string_values, num_values)
    end
  end
end

def open_libsvm(path)
  open(path).each_line do |line|
    ss = line.split
    label = ss[0]
    num_values = []
    ss.slice(1, ss.length).each do |s|
      key, value = s.split(":")
      num_values << [key, value.to_f]
    end

    yield label, Jubatus::Classifier::Datum.new([], num_values)
  end
end

def open_data(type, path, &block)
  if type == "csv"
    open_bazil_csv(path, &block)
  elsif type == "libsvm"
    open_libsvm(path, &block)
  else
    raise "unsupported file type: \"#{type}\""
  end
end

class EasyJubatus < Thor
  class_option :host, :aliases => "-h", :desc => "Host name of jubatus server", :type => :string, :default => "127.0.0.1"
  class_option :port, :aliases => "-p", :desc => "Port number of jubatus server", :type => :numeric, :default => 9199
  class_option :name, :aliases => "-n", :desc => "Cluster name of jubatus server", :type => :string, :default => ""

  desc "train", "Train Jubatus with given labeled data."
  method_option :filetype, :aliases => "-t", :desc => "File type (csv|libsvm)", :type => :string, :default => "csv"
  def train(file)
    client = Jubatus::Classifier::Client::Classifier.new(options[:host], options[:port])
    open_data(options[:filetype], file) do |label, datum|
      client.train(options[:name], [[label, datum]])
    end
  end

  desc "eval", "Evaluate Jubatus with given labeled data."
  method_option :filetype, :aliases => "-t", :desc => "File type (csv|libsvm)", :type => :string, :default => "csv"
  def eval(file)
    client = Jubatus::Classifier::Client::Classifier.new(options[:host], options[:port])
    correct = 0
    total = 0
    open_data(options[:filetype], file) do |label, datum|
      res = client.classify(options[:name], [datum])[0]
      max = res.max{ |x, y| x[1] <=> y[1]}
      correct += 1 if max and max[0] == label
      total += 1
    end
    accuracy = 100.0 * correct / total
    puts "#{accuracy}% (#{correct} / #{total})"
  end

  desc "save", "Save the current model."
  def save(name)
    client = Jubatus::Classifier::Client::Classifier.new(options[:host], options[:port])
    client.save(options[:name], name)
  end

  desc "load", "Load the current model."
  def load(name)
    client = Jubatus::Classifier::Client::Classifier.new(options[:host], options[:port])
    client.load(options[:name], name)
  end
end

EasyJubatus.start
