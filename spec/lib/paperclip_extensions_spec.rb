require 'spec_helper'
require 'fakefs/spec_helpers'

describe Paperclip do
  class UploadedFile < OpenStruct;
  end

  context "UploadedFileAdapter#content_type" do
    it "get the content type for text file" do
      sql_file = test_file("workfile.sql", "text/sql")
      @file = UploadedFile.new(
          :original_filename => "workfile.sql",
          :content_type => "text/sql",
          :head => "",
          :path => sql_file
      )
      uploaded_file = Paperclip::UploadedFileAdapter.new(@file)
      uploaded_file.content_type.should == "text/plain"
    end
  end

  it "do not handle video file, so it should return nil" do
    video_file = test_file("sample_wmv.wmv", "video/x-ms-wmv")
    @file = UploadedFile.new(
        :original_filename => "sample_wmv.wmv",
        :content_type => "video/x-ms-wmv",
        :head => "",
        :path => video_file
    )
    uploaded_file = Paperclip::UploadedFileAdapter.new(@file)
    uploaded_file.content_type.should be_nil
  end

  context "Processor#convert" do
    it "should down size the image" do
      f = File.expand_path("spec/fixtures/User.png", Rails.root) # is 256x256
      t = Tempfile.new("test_image")
      t.write(File.read(f))
      t.flush

      p = Paperclip::Processor.new(t)
      o = Tempfile.new("output_image")
      p.convert(':source -resize "50x50>" :dest', {:source => t.path, :dest => o.path})

      g = Paperclip::Geometry.from_file(o)
      g.width.should == 50
      g.height.should == 50
    end

    it "should preserve the aspect ratio" do
      f = File.expand_path("spec/fixtures/User-hair.png", Rails.root) # is 246x93
      t = Tempfile.new("test_image")
      t.write(File.read(f))
      t.flush

      p = Paperclip::Processor.new(t)
      o = Tempfile.new("output_image")
      p.convert(':source -resize "50x50>" :dest', {:source => t.path, :dest => o.path})

      g = Paperclip::Geometry.from_file(o)
      g.width.should == 50
      g.height.should == 19
    end

    it "should up size the image" do
      f = File.expand_path("spec/fixtures/small1.gif", Rails.root) # is 5x7
      t = Tempfile.new("test_image")
      t.write(File.read(f))
      t.flush

      p = Paperclip::Processor.new(t)
      o = Tempfile.new("output_image")
      p.convert(':source -resize "24x24>" :dest', {:source => t.path, :dest => o.path})

      g = Paperclip::Geometry.from_file(o)
      g.width.should == 17
      g.height.should == 24
    end

    it "passes through if there is no resize argument" do
      f = File.expand_path("spec/fixtures/small1.gif", Rails.root) # is 5x7
      t = Tempfile.new("test_image")
      t.write(File.read(f))
      t.flush

      p = Paperclip::Processor.new(t)
      o = Tempfile.new("output_image")
      p.convert(':source -coalesce :dest', {:source => t.path, :dest => o.path})

      g = Paperclip::Geometry.from_file(o)
      g.width.should == 5
      g.height.should == 7
    end
  end

  context "Filesystem#flush_deletes" do
    include FakeFS::SpecHelpers

    class FakeFileUpload < StringIO
      attr_accessor :content_type, :original_filename
    end
    class PaperclippedThing < ActiveRecord::Base
      self.table_name = 'csv_files'
      has_attached_file :contents, :path => "/symlink/:class/:id/:basename.:extension"
    end

    let(:file_upload) do
      file = FakeFileUpload.new("select 1;")
      file.content_type = "text/sql"
      file.original_filename = "filename.sql"
      file
    end

    let(:paperclip_model) do
      model = PaperclippedThing.new({:contents => file_upload}, :without_protection => true)
      model.save!
      model
    end

    before do
      FileUtils.mkdir_p "/real_directory"
      FileUtils.ln_s("/real_directory", "/symlink")
    end

    it "does not delete symlinks" do
      model = paperclip_model
      File.exists?("/symlink/#{model.class.name.pluralize.underscore}/#{model.id}/filename.sql").should be_true
      paperclip_model.destroy

      File.exists?("/symlink/#{model.class.name.pluralize.underscore}/#{model.id}/filename.sql").should be_false
      File.exists?("/symlink").should be_true
    end
  end
end
