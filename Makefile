test/px_test.rb: .PHONY
	cutest test/px_test.rb

test: test/px_test.rb

test_integration:
	TEST_INTEGRATION=1 cutest test/px_test.rb

.PHONY:
