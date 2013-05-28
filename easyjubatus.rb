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
          string_values << [keys[i], row[i].to_s]
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

def predict(client, datum)
  res = client.classify(options[:name], [datum])[0]
  max = res.max{ |x, y| x[1] <=> y[1] }
  return max[0] if max != nil
end

class EasyJubatus < Thor
  class_option :host, :aliases => "-h", :desc => "Host name of jubatus server", :type => :string, :default => "127.0.0.1"
  class_option :port, :aliases => "-p", :desc => "Port number of jubatus server", :type => :numeric, :default => 9199
  class_option :name, :aliases => "-n", :desc => "Cluster name of jubatus server", :type => :string, :default => ""

  desc "train FILE_NAME", "Train Jubatus with given labeled data."
  method_option :filetype, :aliases => "-t", :desc => "File type (csv|libsvm)", :type => :string, :default => "csv"
  def train(file)
    client = Jubatus::Classifier::Client::Classifier.new(options[:host], options[:port])
    open_data(options[:filetype], file) do |label, datum|
      client.train(options[:name], [[label, datum]])
    end
  end

  desc "eval FILE_NAME", "Evaluate Jubatus with given labeled data."
  method_option :filetype, :aliases => "-t", :desc => "File type (csv|libsvm)", :type => :string, :default => "csv"
  def eval(file)
    client = Jubatus::Classifier::Client::Classifier.new(options[:host], options[:port])
    correct = 0
    total = 0
    open_data(options[:filetype], file) do |label, datum|
      correct += 1 if predict(client, datum) == label
      total += 1
    end
    accuracy = 100.0 * correct / total
    puts "#{accuracy}% (#{correct} / #{total})"
  end

  desc "cv", "Run cross validation."
  method_option :fold, :aliases => "-f", :desc => "Number of folds", :type => :numeric, :default => 10
  def cv(file)
    client = Jubatus::Classifier::Client::Classifier.new(options[:host], options[:port])
    accuracies = []
    fold = options[:fold]
    (0...fold).each do |index|
      i = 0
      client.clear(options[:name])
      open_bazil_csv(file) do |label, datum|
        client.train(options[:name], [[label, datum]]) if i % fold != index
        i += 1
      end
      correct = 0
      total = 0
      i = 0
      open_bazil_csv(file) do |label, datum|
        if i % fold == index
          correct += 1 if predict(client, datum) == label
          total += 1
        end
        i += 1
      end
      accuracy = 100.0 * correct / total
      puts accuracy
      accuracies << accuracy
    end
    average = accuracies.reduce(:+) / accuracies.length
    puts "Average accuracy: #{average}"
  end

  desc "save MODEL_NAME", "Save the current model."
  def save(name)
    client = Jubatus::Classifier::Client::Classifier.new(options[:host], options[:port])
    client.save(options[:name], name)
  end

  desc "load MODEL_NAME", "Load the current model."
  def load(name)
    client = Jubatus::Classifier::Client::Classifier.new(options[:host], options[:port])
    client.load(options[:name], name)
  end
end

EasyJubatus.start
