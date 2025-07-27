# frozen_string_literal: true

require "test_helper"

class RulesJobTest < ActiveSupport::TestCase
  def setup
    @job = RulesJob.new
    @original_max_length = RulesJob::TELEGRAM_MAX_MESSAGE_LENGTH
  end

  def teardown
    if defined?(@new_max_length)
      RulesJob.send(:remove_const, :TELEGRAM_MAX_MESSAGE_LENGTH)
      RulesJob.const_set(:TELEGRAM_MAX_MESSAGE_LENGTH, @original_max_length)
    end
  end

  class TestRule
    def self.message
      "Test message"
    end
  end

  class TestRuleWithLongMessage
    def self.message
      "This is a very long test message that exceeds the limit when concatenated with other messages"
    end
  end

  class TestRuleWithBlankMessage
    def self.message
      ""
    end
  end

  class TestRuleWithNilMessage
    def self.message
      nil
    end
  end

  def test_perform_sends_single_message_when_under_limit
    @job.stubs(:rules).returns([TestRule])
    expect_send_message("Test message")
    @job.perform
  end

  def test_perform_skips_blank_messages
    @job.stubs(:rules).returns([TestRuleWithBlankMessage, TestRuleWithNilMessage, TestRule])
    expect_send_message("Test message")
    @job.perform
  end

  def test_perform_batches_messages_when_over_limit
    set_telegram_max_length(20)
    @job.stubs(:rules).returns([TestRule, TestRule, TestRule])
    TelegramClient.expects(:send_message).times(3)
    @job.perform
  end

  def test_perform_handles_single_long_message
    set_telegram_max_length(30)
    @job.stubs(:rules).returns([TestRuleWithLongMessage])
    expect_send_message("This is a very long test message that exceeds the limit when concatenated with other messages")
    @job.perform
  end

  def test_perform_properly_accumulates_messages
    set_telegram_max_length(35)
    @job.stubs(:rules).returns([TestRule, TestRule, TestRule])
    expect_send_message("Test message\n\nTest message")
    expect_send_message("Test message")
    @job.perform
  end

  def test_perform_does_not_send_empty_accumulated_message
    @job.stubs(:rules).returns([TestRuleWithBlankMessage, TestRuleWithNilMessage])
    TelegramClient.expects(:send_message).never
    @job.perform
  end

  private

  def set_telegram_max_length(length)
    @new_max_length = length
    RulesJob.send(:remove_const, :TELEGRAM_MAX_MESSAGE_LENGTH)
    RulesJob.const_set(:TELEGRAM_MAX_MESSAGE_LENGTH, length)
  end

  def expect_send_message(message)
    TelegramClient.expects(:send_message).with(Rails.application.config.test_telegram_channel, message)
  end
end
