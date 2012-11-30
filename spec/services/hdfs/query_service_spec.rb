require 'spec_helper'
require 'java'

describe Hdfs::QueryService, :hdfs_integration do
  let(:hdfs_params) { InstanceIntegration.instance_config_for_hadoop }
  before do
    devnull = java.io.PrintStream.new(java.io.File.new("/dev/null"))
    com.emc.greenplum.hadoop.Hdfs.logger_stream = devnull
  end

  describe ".instance_version" do
    context "existing hadoop server" do
      let(:instance) do
        HadoopInstance.new hdfs_params
      end

      it "returns the hadoop version" do
        version = described_class.instance_version(instance)
        version.should == "0.20.1gp"
      end
    end

    context "nonexistent hadoop server" do
      let(:instance) { "garbage" }
      let(:port) { 8888 }
      let(:username) { "pivotal" }
      let(:nonexistent_instance) do
        HadoopInstance.new :host => instance, :port => port, :username => username
      end

      it "raises ApiValidationError and prints to log file" do
        Timecop.freeze(Time.current)
        mock(Rails.logger).error("#{Time.current.strftime("%Y-%m-%d %H:%M:%S")} ERROR: Within JavaHdfs connection, failed to establish connection to #{instance}:#{port}")
        expect { described_class.instance_version(nonexistent_instance) }.to raise_error(ApiValidationError) { |error|
          error.record.errors.get(:connection).should == [[:generic, { :message => "Unable to determine HDFS server version or unable to reach server at #{instance}:#{port}. Check connection parameters." }]]
        }
        Timecop.return
      end
    end
  end

  describe "#list" do
    let(:service) { Hdfs::QueryService.new(hdfs_params["host"], hdfs_params["port"], hdfs_params["username"], "0.20.1gp") }

    context "listing root with sub content" do
      it "returns list of content for root directory" do
        response = service.list("/")
        response.count.should > 2
      end
    end

    context "listing empty directory" do
      it "should return an array with zero length" do
        response = service.list("/empty/")
        response.should have(0).files
      end
    end

    context "listing non existing directory" do
      it "should return an error" do
        expect { service.list("/non_existing/") }.to raise_error(Hdfs::DirectoryNotFoundError)
      end
    end

    context "connection is invalid" do
      let(:service) { Hdfs::QueryService.new("garbage", "8020", "pivotal", "0.20.1gp") }

      it "raises an exception" do
        expect { service.list("/") }.to raise_error(Hdfs::DirectoryNotFoundError)
      end
    end
  end

  describe "#show" do
    let(:service) { Hdfs::QueryService.new(hdfs_params["host"], hdfs_params["port"], hdfs_params["username"], "0.20.1gp") }
    before do
      any_instance_of(com.emc.greenplum.hadoop.Hdfs) do |java_hdfs|
        stub(java_hdfs).content(is_a(String), 200) { file_content }
      end
    end

    context "show an existing file" do
      let(:file_content) { "a, b, c" }

      it "returns part of the content" do
        response = service.show("/data/test.csv")
        response.should_not be_empty
        response.should include("a, b, c")
      end
    end

    context "show a non existing file" do
      let(:file_content) { nil }

      it "should return an error" do
        expect { service.show("/file") }.to raise_error(Hdfs::FileNotFoundError)
      end
    end
  end
end
