require 'spec_helper'

describe DataSourceConnection do
  # see greenplum_connection_spec for Greenplum specific specs

  describe ".escape_like_string" do
    it "escapes characters _ and %" do
      c = DataSourceConnection::LIKE_ESCAPE_CHARACTER
      like_string = "e_i%w$on_fe#ino%f"
      escaped_string = "e#{c}_i#{c}%w$on#{c}_fe#ino#{c}%f"
      DataSourceConnection.escape_like_string(like_string).should == escaped_string
    end

    it "escapes the escape character" do
      c = DataSourceConnection::LIKE_ESCAPE_CHARACTER
      like_string = "query#{c}string#{c}"
      escaped_string = "query#{c + c}string#{c + c}"
      DataSourceConnection.escape_like_string(like_string).should == escaped_string
    end
  end
end