require 'spec_helper'

describe "Email" do
  let(:email) { DelayedMailhopper::Email.new }

  it "should require a from address" do
      email.should_not be_valid
      email.from_address = 'user@example.com'
      email.should be_valid
  end

  describe "generated by a mailer" do
    let(:headers) {{
      :from =>     'from@example.com',
      :to =>       'to@example.com',
      :cc =>       'cc@example.com',
      :bcc =>      'bcc@example.com',
      :reply_to => 'reply_to@example.com',
      :subject =>  'Hiya!'
    }}
    let(:content) { 'Papaya' }

    before do
      SampleMailer.hello(headers, content).deliver
    end

    it "should match the intended headers and content" do
      email = DelayedMailhopper::Email.first
      email.from_address.should     eq(headers[:from])
      email.to_address.should       eq(headers[:to])
      email.cc_address.should       eq(headers[:cc])
      email.bcc_address.should      eq(headers[:bcc])
      email.reply_to_address.should eq(headers[:reply_to])
      email.subject.should          eq(headers[:subject])

      # Email content will include headers as well as content
      email.content.should include(content)

      email.sent_at.should eq(nil)
    end

    it "should be queued as a delayed job" do
      DelayedMailhopper::Email.count.should eq(1)
      Delayed::Job.count.should eq(1)
    end

    it "should be delivered via DelayedJob" do
      email = DelayedMailhopper::Email.first
      email.sent_at.should eq(nil)

      Delayed::Job.first.invoke_job

      email.reload
      email.sent_at.should_not eq(nil)
    end

    it "should be marked as sent once delivered" do
      email = DelayedMailhopper::Email.first
      email.sent_at.should eq(nil)

      email.send!

      email.sent_at.should_not eq(nil)
    end
  end
end
