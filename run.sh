#!/bin/bash
# Load environment variables and run Phoenix server
set -a
source .env
set +a

mix phx.server
