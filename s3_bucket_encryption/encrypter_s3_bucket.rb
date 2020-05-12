#!/usr/bin/env ruby
#
# This is a script that encrypts the content of an entire s3 bucket.
#
#The means used is to copy each object in the bucket onto itself whilst
#at the same time modifying its server side encryption.

# For the first version, credentials are taken from ~/.aws/credentials
####################################################
require 'aws-sdk'
require 'optparse'

def argument_parser
  options = {}
  OptionParser.new do |option|
    option.banner="Usage: encrypter_s3_bucket.rb [options]"
    option.on('-b', '--bucket NAME', 'REQUIRED - Name of the bucket to encrypt the contents of') { |v| options[:bucket] = v }
    option.on('-r', '--region NAME', 'REQUIRED - Region in which the bucket to be encrypted is located') { |v| options[:region] = v }
    option.on('-n', '--batch-size NUMBER', 'Size of batches to retrieve from bucket. Defaults to 100') { |v| options[:object_processingbatch_size] = v }
    option.on('-c', '--cipher NAME', 'Method with which the objects will encrypted. Accepts aws:kms or AES256. Defaults to AES256') { |v| options[:cipher] = v }
    option.on('-v', '--verbose', 'Output more information. Useful for debugging or if you want to be sure things are actually working') { |v| options[:verbose] = true }
    if options[:bucket].nil? || options[:region].nil?
      puts option
      exit 1
    end
  end.parse!
  options[:object_processingbatch_size] = 100 if options[:object_processingbatch_size].nil?
  options[:cipher] = "AES256" if options[:cipher].nil?
end

class S3ObjectEncrypter
  def initialize(option)
    aws_client_argumentkeys = %w( region credentials ).map(&:to_sym)
    aws_client_arguments = Hash[aws_client_argumentkeys.map {|k| [k, option[k]] unless option[k].nil? }.compact]
    @aws_client = Aws::S3::Client.new(aws_client_arguments)
    @object_processingbatch_size = option[:object_processingbatch_size]
    @cipher = option[:cipher]
    @bucket_name = option[:bucket]
    @verbose_output = !!option[:verbose]
  end

  def objects_in_bucket
    @objects_in_bucket ||= get_objects # only fetch the results the first time
  end

  def objects_content_encrypt
    objects_in_bucket.each_with_index do |s3_object, i|
      @aws_client.copy_object({
        bucket: @bucket_name,
        key: s3_object.key,
        copy_source: "#{@bucket_name}/#{s3_object.key}",
        server_side_encryption: @cipher
      })
      puts "Encrypted #{i+1} of #{objects_in_bucket.count} (#{s3_object.key})" if @verbose_output
    end
  end

  private

  def get_objects
    objects = []
    response_conttoken = nil
    i = 0
    begin
      resp = @aws_client.list_objects_v2(bucket: @bucket_name, response_conttoken: response_conttoken, max_keys: @object_processingbatch_size)
      response_conttoken = resp.next_response_conttoken
      objects.push(*resp.contents)
      puts "Retrieved objects #{i*@object_processingbatch_size} - #{(i+1)*@object_processingbatch_size} from #{@bucket_name}" if @verbose_output
      i+=1
    end while !response_conttoken.nil?

    objects
  end
end

S3ObjectEncrypter.new(argument_parser).objects_content_encrypt
