# ============================================================
# function_build.tf
# ============================================================
# Builds the Function App package by:
#   1. Installing Python dependencies for Linux x64 into
#      function_code/.python_packages/lib/site-packages/
#   2. Triggering archive_file to re-zip when either the
#      Python source OR requirements.txt changes
#
# This runs on every `terraform apply` so the GitHub Actions
# Linux runner gets the same Linux-compiled wheels as a manual
# `pip install --platform manylinux2014_x86_64` from your laptop.
#
# Cross-platform notes:
#   - Uses `python` command which works on both Windows and Linux
#   - --only-binary=:all: refuses source dists (we can't compile)
#   - --platform manylinux2014_x86_64 forces Linux x64 wheels
#   - --python-version 3.11 matches the Function App runtime
# ============================================================

# Hash of requirements.txt — used as a trigger so the pip
# install only re-runs when dependencies actually change.
locals {
  requirements_hash = filemd5("${path.module}/function_code/requirements.txt")
}

# Run pip install whenever requirements.txt changes.
resource "null_resource" "pip_install" {
  triggers = {
    requirements = local.requirements_hash
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/function_code"
    command     = "python -m pip install --target=.python_packages/lib/site-packages --platform manylinux2014_x86_64 --python-version 3.11 --only-binary=:all: --upgrade -r requirements.txt"
  }
}