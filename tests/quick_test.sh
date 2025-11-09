#!/bin/bash

# Quick test runner - runs all tests and shows summary only
./test_api.sh 2>&1 | grep -E "(TEST [0-9]+:|✓|✗|TEST SUMMARY|Tests |All tests passed|Some tests failed)"
